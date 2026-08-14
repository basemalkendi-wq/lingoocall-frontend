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
  String? _currentUserId; // تخزين معرّف أو رقم هاتف المستخدم الحالي

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  /// تهيئة الاتصال بالسيرفر وتسجيل هوية المستخدم الحقيقية ورمز FCM
  void initSocket({
    required String userId,
    required Function(dynamic) onUserStatusChanged,
  }) {
    _currentUserId = userId;

    final String serverUrl = buildSocketUrl();

    _socket?.disconnect();
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) async {
      _isConnected = true;
      if (kDebugMode) {
        print('🔒 [Socket Connected Successfully as: $userId]');
      }

      // 1. تسجيل معرّف المستخدم في السيرفر فور الاتصال
      _socket!.emit('register_user', userId);

      // 2. جلب FCM Token وإرساله للسيرفر لربط الإشعارات
      await _registerFcmToken(userId);
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
  }

  /// دالة جلب وإرسال الـ FCM Token للسيرفر
  Future<void> _registerFcmToken(String userId) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
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

  // --- إرسال واستقبال الرسائل النصية ---
  void sendEncryptedMessage({
    required String to,
    required Map<String, dynamic> payload,
  }) {
    if (_socket == null || !_isConnected) {
      if (kDebugMode) {
        print('⚠️ Socket not connected, message not sent to $to');
      }
      return;
    }

    final updatedPayload = Map<String, dynamic>.from(payload);

    if (_currentUserId != null) {
      updatedPayload['senderId'] = _currentUserId;
    }
    updatedPayload['receiverId'] = to;

    _socket?.emit('send_encrypted_message', {
      'to': to,
      'payload': updatedPayload,
    });
  }

  void listenToIncomingMessages(Function(dynamic) onMessageReceived) {
    _socket?.off('receive_encrypted_message');
    _socket?.on('receive_encrypted_message', (data) {
      if (data is Map) {
        onMessageReceived(data);
      }
    });
  }

  // --- إرسال واستقبال الترجمة المباشرة للمكالمات (Live Call Translation Streaming) ---
  void sendLiveSubtitle({
    required String to,
    required Map<String, dynamic> subtitlePayload,
  }) {
    _socket?.emit('send_live_subtitle', {'to': to, 'payload': subtitlePayload});
  }

  void listenToLiveSubtitles(Function(dynamic) onSubtitleReceived) {
    _socket?.off('receive_live_subtitle');
    _socket?.on('receive_live_subtitle', (data) {
      onSubtitleReceived(data);
    });
  }

  // --- إرسال إشارات المكالمات ---
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

  // --- الاستماع لأحداث وإشارات المكالمات ---
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
    _socket?.disconnect();
    _isConnected = false;
  }
}
