import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_ease_flutter/core/constants/api_constants.dart';
import 'package:fuel_ease_flutter/core/storage/secure_storage.dart';

class RealtimeClient {
  RealtimeClient(this._storage);

  final SecureStorage _storage;
  WebSocket? _socket;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<RealtimeStatus>.broadcast();
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

    final token = await _storage.getToken();
    if (token == null) {
      _connecting = false;
      _emitStatus(
        _status.copyWith(state: RealtimeConnectionState.disconnected),
      );
      return;
    }

    _subscriptions.addAll(channels);

    final url = ApiConstants.realtimeUrl(Uri.encodeComponent(token));

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
              _controller.add(payload);
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
    _send({
      'type': 'subscribe',
      'channel': channel,
    });
  }

  void unsubscribe(String channel) {
    if (channel.isEmpty) return;
    if (!_subscriptions.contains(channel)) return;
    _subscriptions.remove(channel);
    _send({
      'type': 'unsubscribe',
      'channel': channel,
    });
  }

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
      _send({
        'type': 'subscribe',
        'channel': channel,
      });
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

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return RealtimeClient(storage);
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
