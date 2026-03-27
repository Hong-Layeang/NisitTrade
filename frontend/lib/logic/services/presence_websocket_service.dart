import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/app_config.dart';

class UserPresenceEvent {
  final int userId;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const UserPresenceEvent({
    required this.userId,
    required this.isOnline,
    required this.lastSeenAt,
  });

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory UserPresenceEvent.fromJson(Map<String, dynamic> json) {
    final rawLastSeen = json['last_seen_at'] ?? json['lastSeenAt'];

    return UserPresenceEvent(
      userId: _toInt(json['user_id'] ?? json['userId']),
      isOnline: (json['is_online'] ?? json['isOnline'] ?? false) == true,
      lastSeenAt: rawLastSeen is String && rawLastSeen.isNotEmpty
          ? DateTime.tryParse(rawLastSeen)
          : null,
    );
  }
}

class PresenceWebSocketService {
  PresenceWebSocketService();

  io.Socket? _socket;
  final _eventsController = StreamController<UserPresenceEvent>.broadcast();

  String? _token;
  String _activeBaseUrl = AppConfig.baseUrl;
  bool _retryingFallback = false;
  bool _isConnecting = false;
  final Set<int> _watchedUserIds = <int>{};

  bool get isConnected => _socket?.connected == true;
  bool get isConnecting => _isConnecting;
  Stream<UserPresenceEvent> get events => _eventsController.stream;

  Future<void> connect({required String token}) async {
    _token = token;

    if (_socket != null) {
      if (_socket!.connected || _isConnecting) {
        _emitWatchList();
        return;
      }

      _isConnecting = true;
      _socket!.connect();
      _emitWatchList();
      return;
    }

    _activeBaseUrl = AppConfig.baseUrl;
    _retryingFallback = false;
    _connectTo(_activeBaseUrl);
  }

  void watchUserIds(Iterable<int> userIds) {
    final sanitizedIds = userIds.where((id) => id > 0);
    _watchedUserIds.addAll(sanitizedIds);
    _emitWatchList();
  }

  Future<void> disconnect() async {
    final socket = _socket;
    if (socket == null) return;

    _isConnecting = false;
    socket.off('connect');
    socket.off('disconnect');
    socket.off('connect_error');
    socket.off('presence:changed');
    socket.off('presence:snapshot');
    socket.disconnect();
    socket.dispose();

    _socket = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventsController.close();
  }

  void _connectTo(String baseUrl) {
    final token = _token;
    if (token == null || token.isEmpty) {
      return;
    }

    _isConnecting = true;
    _socket?.dispose();

    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      _isConnecting = false;
      debugPrint('[PresenceWebSocketService] Connected to $baseUrl');
      _emitWatchList();
    });

    socket.onDisconnect((reason) {
      _isConnecting = false;
      debugPrint('[PresenceWebSocketService] Disconnected: $reason');
    });

    socket.onConnectError((error) {
      _isConnecting = false;
      debugPrint('[PresenceWebSocketService] Connect error: $error');
      _handleConnectError();
    });

    socket.on('presence:changed', (payload) {
      _handlePresencePayload(payload);
    });

    socket.on('presence:snapshot', (payload) {
      final data = payload is Map ? Map<String, dynamic>.from(payload) : null;
      final users = data?['users'];
      if (users is! List) return;

      for (final raw in users) {
        _handlePresencePayload(raw);
      }
    });

    _socket = socket;
    socket.connect();
  }

  void _handleConnectError() {
    if (!Platform.isAndroid || _retryingFallback) {
      return;
    }

    _retryingFallback = true;
    _activeBaseUrl = AppConfig.fallbackBaseUrl;
    _connectTo(_activeBaseUrl);
  }

  void _handlePresencePayload(dynamic payload) {
    if (payload is! Map) {
      return;
    }

    final event = UserPresenceEvent.fromJson(
      Map<String, dynamic>.from(payload),
    );

    if (event.userId <= 0) {
      return;
    }

    _eventsController.add(event);
  }

  void _emitWatchList() {
    final socket = _socket;
    if (socket == null || !socket.connected || _watchedUserIds.isEmpty) {
      return;
    }

    socket.emit('presence:watch', {
      'user_ids': _watchedUserIds.toList(growable: false),
    });
  }
}
