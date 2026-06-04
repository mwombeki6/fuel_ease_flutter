import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/api/api_client.dart';
import 'package:fuel_ease_flutter/core/constants/api_constants.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';

class RealtimeClient {
  RealtimeClient(this._storage, this._api);

  static const int _maxBufferedEvents = 50;

  final SecureStorage _storage;
  final ApiClient _api;
  WebSocket? _socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<RealtimeStatus>.broadcast();
  final List<_BufferedRealtimeEvent> _recentEvents = [];
  RealtimeStatus _status =
      const RealtimeStatus(state: RealtimeConnectionState.disconnected);
  bool _connecting = false;
  final Set<String> _subscriptions = {};
  bool _autoReconnect = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  Stream<RealtimeStatus> get statusStream => _statusController.stream;
  RealtimeStatus get status => _status;

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
      final body = resp.data as Map<String, dynamic>;
      ticket = ((body['data'] as Map<String, dynamic>)['ticket']) as String;
    } catch (e) {
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

      socket.listen(
        (event) {
          try {
            final payload = jsonDecode(event as String);
            if (payload is Map<String, dynamic>) {
              final message = Map<String, dynamic>.from(payload);
              _bufferEvent(message);
              _controller.add(message);
              _emitStatus(
                _status.copyWith(lastEventAt: DateTime.now()),
              );
            }
          } catch (_) {
            // Ignore malformed realtime payloads
          }
        },
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
    } catch (_) {
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
    _send({'action': 'subscribe', 'channel': channel});
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
    final existing = _subscriptions.where((c) => c.startsWith('station:')).toList();
    for (final channel in existing) {
      unsubscribe(channel);
    }
    if (stationId == null || stationId.isEmpty) return;
    subscribe('station:$stationId');
  }

  void _resubscribeAll() {
    if (_socket == null) return;
    for (final channel in _subscriptions) {
      _send({'action': 'subscribe', 'channel': channel});
    }
  }

  void _send(Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.add(jsonEncode(payload));
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
    _emitStatus(
      _status.copyWith(state: RealtimeConnectionState.disconnected),
    );
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

    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 30);
    _reconnectAttempts += 1;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
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
  return RealtimeClient(storage, api);
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
