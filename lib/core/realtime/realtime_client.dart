import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/constants/api_constants.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';

/// Builds the wire frame the backend expects to subscribe to a channel:
/// `{"action":"subscribe","channel":"<channel>"}`. Extracted as a top-level
/// pure function so it's unit-testable without a socket — and it's the
/// single source of truth for the frame shape: both [RealtimeClient.subscribe]
/// and the reconnect replay in [RealtimeClient] call it, so the tested
/// function is the production implementation.
String buildSubscribeFrame(String channel) =>
    jsonEncode({'action': 'subscribe', 'channel': channel});

/// Maximum delay between reconnect attempts.
const int _maxBackoffSeconds = 30;

/// Exponential reconnect backoff, capped at [_maxBackoffSeconds]. Pure and
/// top-level so it's unit-testable without a socket. `attempt` is the
/// zero-based number of consecutive failed attempts so far; negative values
/// are treated as `0`.
Duration nextBackoff(int attempt) {
  final safeAttempt = (attempt < 0 ? 0 : attempt).clamp(0, 5);
  final seconds = 1 << safeAttempt; // 1, 2, 4, 8, 16, 32 (before capping)
  return Duration(
    seconds: seconds > _maxBackoffSeconds ? _maxBackoffSeconds : seconds,
  );
}

/// Reusable, feature-agnostic app-wide WebSocket realtime client.
///
/// A single instance lives behind [realtimeClientProvider]. It knows nothing
/// about any particular feature's event names — it authenticates with a
/// short-lived ticket, joins channels, forwards decoded frames, and
/// reconnects with backoff. Features consume [stream] (or the typed
/// [RealtimeEvent] bridge in `realtime_providers.dart`) and filter for the
/// events they care about.
class RealtimeClient {
  RealtimeClient(this._storage, this._api);

  static const int _maxBufferedEvents = 50;

  final SecureStorage _storage;
  final ApiClient _api;
  WebSocket? _socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  final List<_BufferedRealtimeEvent> _recentEvents = [];
  RealtimeStatus _status = const RealtimeStatus(
    state: RealtimeConnectionState.disconnected,
  );
  bool _connecting = false;
  final Set<String> _subscriptions = {};
  bool _autoReconnect = false;
  int _sessionGeneration = 0;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _currentUserId;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  Stream<RealtimeStatus> get statusStream => _statusController.stream;

  /// Fires (with no payload) each time the client successfully re-establishes
  /// a connection after having been connected before — i.e. on reconnect,
  /// not on the very first connect. Consumers can use this as a cue to
  /// re-sync any state they might have missed while disconnected.
  Stream<void> get reconnected => _reconnectedController.stream;
  RealtimeStatus get status => _status;

  /// Test-only. The set of channels the client intends to be subscribed to —
  /// replayed in full by [_resubscribeAll] on every (re)connect. Exposed
  /// read-only so tests can assert subscription intent without needing a
  /// live socket; not meant for production call sites.
  Set<String> get debugSubscriptions => Set.unmodifiable(_subscriptions);

  /// Number of currently buffered transient payloads, exposed for tests.
  int get debugBufferedEventCount => _recentEvents.length;

  /// Test-only helper for verifying account-bound buffer cleanup.
  void debugAddBufferedEvent(Map<String, dynamic> payload) {
    assert(() {
      _bufferEvent(payload);
      return true;
    }());
  }

  /// Ensures a connection exists and is subscribed to `user:<userId>`.
  ///
  /// Single-flight: if already connected or connecting for this same
  /// [userId], this is a no-op. The client itself doesn't know or care what
  /// a "user" is beyond this channel name — callers (e.g. auth/session code)
  /// decide when and for whom to call this.
  void ensureConnected(String userId) {
    if (userId.isEmpty) return;
    if (_currentUserId == userId && (_socket != null || _connecting)) {
      return;
    }
    _currentUserId = userId;
    // Record the subscription intent up front, independent of connection
    // state. subscribe() unconditionally adds the channel to
    // _subscriptions (the same set _resubscribeAll() replays on every
    // (re)connect) and only *also* sends it immediately if a socket is
    // already open. This guarantees the channel survives an in-flight
    // connect() — which would otherwise no-op on its single-flight guard
    // before ever seeing this channel — because _resubscribeAll() picks it
    // up from _subscriptions once that connect finishes.
    subscribe('user:$userId');
    if (_socket == null && !_connecting) {
      // Not connected and no connect() in flight — kick one off. If one is
      // already in flight, don't spawn a second (single-flight); the
      // subscription we just recorded will be replayed when it completes.
      unawaited(connect());
    }
  }

  List<Map<String, dynamic>> recentEvents({
    Duration maxAge = const Duration(seconds: 30),
  }) {
    final cutoff = DateTime.now().subtract(maxAge);
    _recentEvents.removeWhere((event) => event.receivedAt.isBefore(cutoff));
    return [
      for (final event in _recentEvents)
        Map<String, dynamic>.from(event.payload),
    ];
  }

  Future<void> connect({List<String> channels = const []}) async {
    if (_connecting || _socket != null) return;
    final sessionGeneration = _sessionGeneration;
    _connecting = true;
    _autoReconnect = true;
    _emitStatus(
      _status.copyWith(
        state: _reconnectAttempts > 0
            ? RealtimeConnectionState.reconnecting
            : RealtimeConnectionState.connecting,
      ),
    );

    // Quick pre-check: no point hitting the network if we're not logged in.
    final token = await _storage.getToken();
    if (token == null) {
      _connecting = false;
      _emitStatus(
        _status.copyWith(state: RealtimeConnectionState.disconnected),
      );
      return;
    }

    _subscriptions.addAll(channels);

    // Exchange the Bearer token for a single-use, 30s-TTL ticket so the raw
    // JWT is never written to server access logs as a query parameter.
    String ticket;
    try {
      final resp = await _api.post<Map<String, dynamic>>(
        ApiConstants.wsTicketPath,
      );
      if (sessionGeneration != _sessionGeneration) {
        _connecting = false;
        return;
      }
      final body = resp.data as Map<String, dynamic>;
      ticket = ((body['data'] as Map<String, dynamic>)['ticket']) as String;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) {
        _connecting = false;
        return;
      }
      _connecting = false;
      // 401/403 means the token is revoked or the session is gone.
      // Stop reconnecting — a new login is required.
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 401 || status == 403) {
          _autoReconnect = false;
          _emitStatus(
            _status.copyWith(state: RealtimeConnectionState.disconnected),
          );
          return;
        }
      }
      _emitStatus(
        _status.copyWith(state: RealtimeConnectionState.reconnecting),
      );
      _scheduleReconnect();
      return;
    }

    final url = ApiConstants.realtimeUrl(ticket);

    try {
      final socket = await WebSocket.connect(url);
      if (sessionGeneration != _sessionGeneration) {
        await socket.close();
        _connecting = false;
        return;
      }
      final wasReconnect = _reconnectAttempts > 0;
      _socket = socket;
      _connecting = false;
      _reconnectAttempts = 0;
      _emitStatus(
        _status.copyWith(
          state: RealtimeConnectionState.connected,
          lastConnectedAt: DateTime.now(),
        ),
      );
      _resubscribeAll();
      if (wasReconnect) {
        _reconnectedController.add(null);
      }

      socket.listen(
        (event) {
          try {
            final payload = jsonDecode(event as String);
            if (payload is Map<String, dynamic>) {
              final message = Map<String, dynamic>.from(payload);
              _bufferEvent(message);
              _controller.add(message);
              _emitStatus(_status.copyWith(lastEventAt: DateTime.now()));
            }
          } catch (_) {
            // Ignore malformed realtime payloads
          }
        },
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
    } catch (_) {
      if (sessionGeneration != _sessionGeneration) {
        _connecting = false;
        return;
      }
      _connecting = false;
      _emitStatus(
        _status.copyWith(state: RealtimeConnectionState.reconnecting),
      );
      _scheduleReconnect();
    }
  }

  void subscribe(String channel) {
    if (channel.isEmpty) return;
    if (_subscriptions.contains(channel)) return;
    _subscriptions.add(channel);
    _sendRaw(buildSubscribeFrame(channel));
  }

  void unsubscribe(String channel) {
    if (channel.isEmpty) return;
    if (!_subscriptions.contains(channel)) return;
    _subscriptions.remove(channel);
    _send({'action': 'unsubscribe', 'channel': channel});
  }

  // Deprecated: server auto-subscribes mobile clients to user:<userID> on connect.
  // Call sites can safely remove this — no-op if stationId is null.
  void setStationSubscription(String? stationId) {
    final existing = _subscriptions
        .where((c) => c.startsWith('station:'))
        .toList();
    for (final channel in existing) {
      unsubscribe(channel);
    }
    if (stationId == null || stationId.isEmpty) return;
    subscribe('station:$stationId');
  }

  void _resubscribeAll() {
    if (_socket == null) return;
    for (final channel in _subscriptions) {
      _sendRaw(buildSubscribeFrame(channel));
    }
  }

  void _send(Map<String, dynamic> payload) => _sendRaw(jsonEncode(payload));

  void _sendRaw(String frame) {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.add(frame);
    } catch (_) {
      // Ignore send failures (socket may be closing)
    }
  }

  void _bufferEvent(Map<String, dynamic> payload) {
    _recentEvents.add(_BufferedRealtimeEvent(payload, DateTime.now()));
    if (_recentEvents.length > _maxBufferedEvents) {
      _recentEvents.removeRange(0, _recentEvents.length - _maxBufferedEvents);
    }
  }

  void disconnect() {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _socket?.close();
    _socket = null;
    _connecting = false;
    _recentEvents.clear();
    _status = const RealtimeStatus(state: RealtimeConnectionState.disconnected);
    _emitStatus(_status);
  }

  /// Drops transient payloads without closing an intentionally active socket.
  void clearBufferedEvents() {
    _recentEvents.clear();
  }

  /// Disconnects and removes every user-specific subscription and event.
  void clearSession() {
    _sessionGeneration++;
    disconnect();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscriptions.clear();
    _currentUserId = null;
    _reconnectAttempts = 0;
  }

  /// Tears down the socket, timers, and closes every stream this client
  /// exposes. Intended for provider-container disposal (app/test teardown) —
  /// for a normal logout, call [disconnect] instead so the client remains
  /// reusable for the next login.
  void dispose() {
    disconnect();
    unawaited(_controller.close());
    unawaited(_statusController.close());
    unawaited(_reconnectedController.close());
  }

  void _handleDisconnect() {
    _socket = null;
    _connecting = false;
    _emitStatus(
      _status.copyWith(
        state: _autoReconnect
            ? RealtimeConnectionState.reconnecting
            : RealtimeConnectionState.disconnected,
      ),
    );
    if (_autoReconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_autoReconnect) return;
    if (_reconnectTimer != null) return;

    // Re-ticket + re-subscribe: connect() always fetches a fresh ticket, and
    // _resubscribeAll() (called on successful connect) replays every channel
    // still in _subscriptions, so a plain connect() here is sufficient.
    final delay = nextBackoff(_reconnectAttempts);
    _reconnectAttempts += 1;

    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      await connect();
    });
  }

  void _emitStatus(RealtimeStatus status) {
    _status = status;
    _statusController.add(status);
  }
}

class _BufferedRealtimeEvent {
  const _BufferedRealtimeEvent(this.payload, this.receivedAt);

  final Map<String, dynamic> payload;
  final DateTime receivedAt;
}

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final api = ref.watch(apiClientProvider);
  final client = RealtimeClient(storage, api);
  ref.onDispose(client.dispose);
  return client;
});

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class RealtimeStatus {
  const RealtimeStatus({
    required this.state,
    this.lastConnectedAt,
    this.lastEventAt,
  });

  final RealtimeConnectionState state;
  final DateTime? lastConnectedAt;
  final DateTime? lastEventAt;

  RealtimeStatus copyWith({
    RealtimeConnectionState? state,
    DateTime? lastConnectedAt,
    DateTime? lastEventAt,
  }) {
    return RealtimeStatus(
      state: state ?? this.state,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastEventAt: lastEventAt ?? this.lastEventAt,
    );
  }
}
