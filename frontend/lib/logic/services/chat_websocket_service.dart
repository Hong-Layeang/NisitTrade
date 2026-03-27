import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/app_config.dart';
import '../../data/dtos/conversation_dto.dart';

class ChatWebSocketService {
  static const String _tag = 'ChatWebSocketService';

  io.Socket? _socket;
  String? _token;
  String _activeBaseUrl = AppConfig.baseUrl;
  bool _retryingFallback = false;
  bool _isConnecting = false;
  final Set<int> _joinedConversationIds = <int>{};

  // Stream controllers for each event type
  final _messageReceivedController = StreamController<MessageDto>.broadcast();
  final _messageNotifyController = StreamController<MessageDto>.broadcast();
  final _messageUpdatedController =
      StreamController<MessageUpdateEvent>.broadcast();
  final _messageDeletedController =
      StreamController<MessageDeleteEvent>.broadcast();
  final _messageReadController = StreamController<MessageReadEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();

  bool get isConnected => _socket?.connected == true;

  Stream<MessageDto> get onMessageReceived => _messageReceivedController.stream;
  Stream<MessageDto> get onMessageNotify => _messageNotifyController.stream;
  Stream<MessageUpdateEvent> get onMessageUpdated =>
      _messageUpdatedController.stream;
  Stream<MessageDeleteEvent> get onMessageDeleted =>
      _messageDeletedController.stream;
  Stream<MessageReadEvent> get onMessageRead => _messageReadController.stream;
  Stream<TypingEvent> get onTyping => _typingController.stream;

  Future<void> connect({required String token}) async {
    _token = token;

    if (_socket != null) {
      if (_socket!.connected || _isConnecting) {
        return;
      }

      _isConnecting = true;
      _socket!.connect();
      return;
    }

    _activeBaseUrl = AppConfig.baseUrl;
    _retryingFallback = false;
    _connectTo(_activeBaseUrl);
  }

  void _connectTo(String baseUrl) {
    final token = _token;
    if (token == null || token.isEmpty) return;

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
      debugPrint('[$_tag] Connected to $baseUrl');
      _rejoinTrackedConversations();
    });

    socket.onDisconnect((reason) {
      _isConnecting = false;
      debugPrint('[$_tag] Disconnected: $reason');
    });

    socket.onConnectError((error) {
      _isConnecting = false;
      debugPrint('[$_tag] Connect error: $error');
      _handleConnectError();
    });

    socket.on('chat:receive', (data) {
      try {
        if (data is Map) {
          final message = MessageDto.fromJson(Map<String, dynamic>.from(data));
          _messageReceivedController.add(message);
        }
      } catch (e) {
        debugPrint('[$_tag] Error parsing received message: $e');
      }
    });

    socket.on('chat:notify', (data) {
      try {
        if (data is Map) {
          final message = MessageDto.fromJson(Map<String, dynamic>.from(data));
          _messageNotifyController.add(message);
        }
      } catch (e) {
        debugPrint('[$_tag] Error parsing notify message: $e');
      }
    });

    socket.on('chat:updated', (data) {
      try {
        if (data is Map) {
          final event = MessageUpdateEvent.fromJson(
            Map<String, dynamic>.from(data),
          );
          _messageUpdatedController.add(event);
        }
      } catch (e) {
        debugPrint('[$_tag] Error parsing message update: $e');
      }
    });

    socket.on('chat:deleted', (data) {
      try {
        if (data is Map) {
          final event = MessageDeleteEvent.fromJson(
            Map<String, dynamic>.from(data),
          );
          _messageDeletedController.add(event);
        }
      } catch (e) {
        debugPrint('[$_tag] Error parsing message delete: $e');
      }
    });

    socket.on('chat:read', (data) {
      try {
        if (data is Map) {
          final event = MessageReadEvent.fromJson(
            Map<String, dynamic>.from(data),
          );
          _messageReadController.add(event);
        }
      } catch (e) {
        debugPrint('[$_tag] Error parsing read receipt: $e');
      }
    });

    socket.on('chat:typing', (data) {
      try {
        if (data is Map) {
          _typingController.add(
            TypingEvent(
              conversationId: _toInt(data['conversationId']),
              userId: _toInt(data['userId']),
              isTyping: true,
            ),
          );
        }
      } catch (e) {
        debugPrint('[$_tag] Error parsing typing event: $e');
      }
    });

    socket.on('chat:stop_typing', (data) {
      try {
        if (data is Map) {
          _typingController.add(
            TypingEvent(
              conversationId: _toInt(data['conversationId']),
              userId: _toInt(data['userId']),
              isTyping: false,
            ),
          );
        }
      } catch (e) {
        debugPrint('[$_tag] Error parsing stop typing event: $e');
      }
    });

    _socket = socket;
    socket.connect();
  }

  void _handleConnectError() {
    if (!Platform.isAndroid || _retryingFallback) return;
    _retryingFallback = true;
    _activeBaseUrl = AppConfig.fallbackBaseUrl;
    _connectTo(_activeBaseUrl);
  }

  void joinConversation(int conversationId) {
    if (conversationId <= 0) {
      return;
    }

    _joinedConversationIds.add(conversationId);
    if (!isConnected) {
      return;
    }

    _socket?.emit('chat:join', {'conversationId': conversationId});
  }

  void leaveConversation(int conversationId) {
    if (conversationId <= 0) {
      return;
    }

    _joinedConversationIds.remove(conversationId);
    if (!isConnected) {
      return;
    }

    _socket?.emit('chat:leave', {'conversationId': conversationId});
  }

  void sendMessage({required int conversationId, required String messageText}) {
    _socket?.emit('chat:send', {
      'conversationId': conversationId,
      'messageText': messageText,
    });
  }

  void markMessageRead(int messageId) {
    _socket?.emit('chat:read', {'messageId': messageId});
  }

  void notifyTyping(int conversationId) {
    _socket?.emit('chat:typing', {'conversationId': conversationId});
  }

  void stopTyping(int conversationId) {
    _socket?.emit('chat:stop_typing', {'conversationId': conversationId});
  }

  void editMessage({required int messageId, required String messageText}) {
    _socket?.emit('chat:edit', {
      'messageId': messageId,
      'messageText': messageText,
    });
  }

  void deleteMessages(List<int> messageIds) {
    _socket?.emit('chat:delete', {'messageIds': messageIds});
  }

  Future<void> disconnect() async {
    final socket = _socket;
    if (socket == null) return;

    _isConnecting = false;
    socket.off('connect');
    socket.off('disconnect');
    socket.off('connect_error');
    socket.off('chat:receive');
    socket.off('chat:notify');
    socket.off('chat:updated');
    socket.off('chat:deleted');
    socket.off('chat:read');
    socket.off('chat:typing');
    socket.off('chat:stop_typing');
    socket.disconnect();
    socket.dispose();
    _socket = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageReceivedController.close();
    await _messageNotifyController.close();
    await _messageUpdatedController.close();
    await _messageDeletedController.close();
    await _messageReadController.close();
    await _typingController.close();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _rejoinTrackedConversations() {
    final socket = _socket;
    if (socket == null || !socket.connected || _joinedConversationIds.isEmpty) {
      return;
    }

    for (final conversationId in _joinedConversationIds) {
      socket.emit('chat:join', {'conversationId': conversationId});
    }
  }
}

class MessageUpdateEvent {
  final int messageId;
  final int conversationId;
  final String messageText;
  final DateTime editedAt;

  const MessageUpdateEvent({
    required this.messageId,
    required this.conversationId,
    required this.messageText,
    required this.editedAt,
  });

  factory MessageUpdateEvent.fromJson(Map<String, dynamic> json) {
    return MessageUpdateEvent(
      messageId: ChatWebSocketService._toInt(json['messageId']),
      conversationId: ChatWebSocketService._toInt(json['conversationId']),
      messageText: (json['messageText'] ?? '') as String,
      editedAt: DateTime.parse(
        json['editedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class MessageDeleteEvent {
  final List<int> messageIds;
  final int conversationId;

  const MessageDeleteEvent({
    required this.messageIds,
    required this.conversationId,
  });

  factory MessageDeleteEvent.fromJson(Map<String, dynamic> json) {
    final rawIds = json['messageIds'] as List? ?? [];
    return MessageDeleteEvent(
      messageIds: rawIds
          .map((id) => ChatWebSocketService._toInt(id))
          .where((id) => id > 0)
          .toList(),
      conversationId: ChatWebSocketService._toInt(json['conversationId']),
    );
  }
}

class MessageReadEvent {
  final int messageId;
  final int conversationId;
  final int userId;
  final DateTime readAt;

  const MessageReadEvent({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.readAt,
  });

  factory MessageReadEvent.fromJson(Map<String, dynamic> json) {
    return MessageReadEvent(
      messageId: ChatWebSocketService._toInt(json['messageId']),
      conversationId: ChatWebSocketService._toInt(json['conversationId']),
      userId: ChatWebSocketService._toInt(json['userId']),
      readAt: DateTime.parse(
        json['readAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class TypingEvent {
  final int conversationId;
  final int userId;
  final bool isTyping;

  const TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
}
