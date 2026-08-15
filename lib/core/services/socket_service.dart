import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:lingoocall/core/constants/app_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  static String buildSocketUrl() => AppConstants.backendBaseUrl;

  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  final List<Map<String, dynamic>> _pendingMessageQueue = [];
  Timer? _reconnectTimer;

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  void initSocket({
    required String userId,
    String? userPhone,
    required Function(dynamic) onUserStatusChanged,
  }) {
    _currentUserId = userId;

    final String serverUrl = buildSocketUrl();

    _socket?.disconnect();
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(500)
          .setReconnectionDelayMax(4000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) async {
      _isConnected = true;
      if (kDebugMode) {
        print('🔒 [Socket Connected Successfully as: $userId]');
      }

      _socket!.emit('register_user', {'id': userId, 'phone': userPhone});

      await _registerFcmToken(userId);
      _flushPendingMessageQueue();
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      if (kDebugMode) {
        print('⚠️ [Socket connect error]: $error');
      }
    });

    _socket!.on('user_status_changed', (data) {
      onUserStatusChanged(data);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      if (kDebugMode) {
        print('❌ [Socket Disconnected]');
      }
    });

    _socket!.connect();
  }

  Future<void> _registerFcmToken(String userId) async {
    try {
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        _socket?.emit('register_fcm', {'userId': userId, 'fcmToken': fcmToken});
        if (kDebugMode) {
          print('🚀 [FCM Token Sent to Server]: $fcmToken');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error fetching/sending FCM Token: $e');
      }
    }
  }

  void _queuePendingMessage(Map<String, dynamic> event) {
    _pendingMessageQueue.add(event);
    if (_pendingMessageQueue.length > 50) {
      _pendingMessageQueue.removeAt(0);
    }
  }

  void _flushPendingMessageQueue() {
    if (_socket == null || !_isConnected) {
      return;
    }

    while (_pendingMessageQueue.isNotEmpty) {
      final message = _pendingMessageQueue.removeAt(0);
      _socket?.emit('send_encrypted_message', message);
    }
  }

  void sendEncryptedMessage({
    required String to,
    required Map<String, dynamic> payload,
  }) {
    final updatedPayload = Map<String, dynamic>.from(payload);

    if (_currentUserId != null) {
      updatedPayload['senderId'] = _currentUserId;
    }
    updatedPayload['receiverId'] = to;

    final event = {'to': to, 'payload': updatedPayload};

    if (_socket == null || !_isConnected) {
      _queuePendingMessage(event);
      if (kDebugMode) {
        print('⚠️ Socket offline. Message queued for $to');
      }
      return;
    }

    _socket?.emit('send_encrypted_message', event);
  }

  void listenToIncomingMessages(Function(dynamic) onMessageReceived) {
    _socket?.off('receive_encrypted_message');
    _socket?.on('receive_encrypted_message', (data) {
      if (data is Map) {
        onMessageReceived(data);
      }
    });
  }

  void sendLiveSubtitle({
    required String to,
    required Map<String, dynamic> subtitlePayload,
  }) {
    if (_socket == null || !_isConnected) {
      return;
    }
    _socket?.emit('send_live_subtitle', {'to': to, 'payload': subtitlePayload});
  }

  void listenToLiveSubtitles(Function(dynamic) onSubtitleReceived) {
    _socket?.off('receive_live_subtitle');
    _socket?.on('receive_live_subtitle', (data) {
      onSubtitleReceived(data);
    });
  }

  void sendCallOffer({
    required String to,
    required dynamic offer,
    String? from,
  }) {
    _socket?.emit('call_offer', {
      'to': to,
      'offer': offer,
      'from': from ?? _currentUserId,
    });
  }

  void sendCallAnswer({
    required String to,
    required dynamic answer,
    String? from,
  }) {
    _socket?.emit('call_answer', {
      'to': to,
      'from': from ?? _currentUserId,
      'answer': answer,
    });
  }

  void sendIceCandidate({
    required String to,
    required dynamic candidate,
    String? from,
  }) {
    _socket?.emit('ice_candidate', {
      'to': to,
      'from': from ?? _currentUserId,
      'candidate': candidate,
    });
  }

  void sendCallRejected({required String to}) {
    _socket?.emit('call_rejected', {'to': to});
  }

  void rejectCall({required String to}) {
    sendCallRejected(to: to);
  }

  void listenToIncomingCall(Function(dynamic) onIncomingCall) {
    _socket?.off('incoming_call');
    _socket?.on('incoming_call', (data) => onIncomingCall(data));
  }

  void listenToCallAccepted(Function(dynamic) onCallAccepted) {
    _socket?.off('call_accepted');
    _socket?.on('call_accepted', (data) => onCallAccepted(data));
  }

  void listenToIceCandidate(Function(dynamic) onIceCandidate) {
    _socket?.off('ice_candidate');
    _socket?.on('ice_candidate', (data) => onIceCandidate(data));
  }

  void listenToCallRejected(Function(dynamic) onCallRejected) {
    _socket?.off('call_rejected');
    _socket?.on('call_rejected', (data) => onCallRejected(data));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pendingMessageQueue.clear();
    _socket?.disconnect();
    _isConnected = false;
  }
}
