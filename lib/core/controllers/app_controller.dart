import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingoocall/core/services/socket_service.dart';
import 'package:lingoocall/core/services/translation_service.dart';
import 'package:lingoocall/features/auth/domain/models/user_profile.dart';
import 'package:lingoocall/features/call/domain/models/live_subtitle.dart';
import 'package:lingoocall/features/chat/domain/models/chat_message.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class AppController extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  final TranslationService _translationService = TranslationService();

  Locale _appLocale = const Locale('ar');
  Locale get appLocale => _appLocale;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  int _selectedBottomTab = 0;
  int get selectedBottomTab => _selectedBottomTab;

  UserProfile _currentUser = UserProfile(
    id: 'usr_me',
    name: 'Basem Al-Kendi',
    phone: '+967 771234567',
    nativeLanguage: 'Arabic',
    nativeFlag: '🇾🇪',
    targetLanguage: 'Turkish',
    targetFlag: '🇹🇷',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
  );
  UserProfile get currentUser => _currentUser;

  ContactItem? _activeChatContact;
  ContactItem? get activeChatContact => _activeChatContact;

  bool _isInCall = false;
  bool get isInCall => _isInCall;
  ContactItem? _activeCallContact;
  ContactItem? get activeCallContact => _activeCallContact;
  bool _isMicMuted = false;
  bool get isMicMuted => _isMicMuted;
  bool _isVideoOff = false;
  bool get isVideoOff => _isVideoOff;
  bool _showSubtitles = true;
  bool get showSubtitles => _showSubtitles;

  LiveSubtitle? _currentSubtitle;
  LiveSubtitle? get currentSubtitle => _currentSubtitle;
  Timer? _subtitleTimer;
  int _callSeconds = 0;
  Timer? _callDurationTimer;
  int get callSeconds => _callSeconds;

  final Map<String, List<ChatMessage>> _chatHistory = {};
  final List<ContactItem> _activeChatsList = [];

  AppController() {
    _initMockData();
    _connectToSocketServer();
  }

  List<ContactItem> get activeChats {
    if (_activeChatsList.isNotEmpty) {
      return _activeChatsList;
    }
    return [
      ContactItem(
        id: 'c1',
        name: 'Ayla Yılmaz',
        phone: '+90 532 111 2233',
        nativeLanguage: 'Turkish',
        flag: '🇹🇷',
        isRegistered: true,
        isOnline: true,
      ),
    ];
  }

  void _connectToSocketServer() {
    _socketService.initSocket(
      userId: _currentUser.id,
      onUserStatusChanged: (data) {
        notifyListeners();
      },
    );

    _socketService.listenToIncomingMessages((data) {
      final incomingMsg = ChatMessage(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: data['senderId'] ?? 'unknown',
        originalText: data['originalText'] ?? '',
        translatedText: data['translatedText'] ?? '',
        senderLanguage: data['senderLanguage'] ?? 'TR 🇹🇷',
        targetLanguage: data['targetLanguage'] ?? 'AR 🇾🇪',
        timestamp: data['timestamp'] != null
            ? DateTime.parse(data['timestamp'])
            : DateTime.now(),
      );

      final senderId = incomingMsg.senderId;
      if (!_chatHistory.containsKey(senderId)) {
        _chatHistory[senderId] = [];
      }
      _chatHistory[senderId]!.add(incomingMsg);
      notifyListeners();
    });

    _socketService.listenToLiveSubtitles((data) {
      if (_isInCall) {
        _currentSubtitle = LiveSubtitle(
          speakerName: data['speakerName'] ?? _activeCallContact?.name ?? 'Speaker',
          originalSentence: data['originalSentence'] ?? '',
          translatedSentence: data['translatedSentence'] ?? '',
          originalLang: data['originalLang'] ?? 'TR',
          targetLang: data['targetLang'] ?? 'AR',
        );
        notifyListeners();
      }
    });
  }

  void _initMockData() {
    _chatHistory['c1'] = [
      ChatMessage(
        id: 'm1',
        senderId: 'c1',
        originalText:
            'Merhaba! Nasılsın? Bugün LingooCall projesini konuşabilir miyiz?',
        translatedText:
            'مرحباً! كيف حالك؟ هل يمكننا التحدث عن مشروع LingooCall اليوم؟',
        senderLanguage: 'TR 🇹🇷',
        targetLanguage: 'AR 🇾🇪',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      ChatMessage(
        id: 'm2',
        senderId: 'usr_me',
        originalText:
            'أهلاً أيلا! نعم بكل سرور، النظام يترجم الصوت والفيديو فوراً.',
        translatedText:
            'Merhaba Ayla! Evet memnuniyetle, sistem ses ve videoyu anında çeviriyor.',
        senderLanguage: 'AR 🇾🇪',
        targetLanguage: 'TR 🇹🇷',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        id: 'm3',
        senderId: 'c1',
        originalText: 'Harika bir haber! Sesli mesaj gönderiyorum.',
        translatedText: 'أخبار رائعة! سأرسل لك رسالة صوتية.',
        senderLanguage: 'TR 🇹🇷',
        targetLanguage: 'AR 🇾🇪',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isAudio: true,
        audioDuration: '0:14',
      ),
    ];
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setAppLanguage(String languageCode) {
    if (_appLocale.languageCode != languageCode) {
      _appLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  void setBottomTab(int index) {
    _selectedBottomTab = index;
    notifyListeners();
  }

  void login() {
    _isAuthenticated = true;
    _connectToSocketServer();
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _isInCall = false;
    _socketService.disconnect();
    notifyListeners();
  }

  void updateNativeLanguage(String name, String flag) {
    _currentUser = UserProfile(
      id: _currentUser.id,
      name: _currentUser.name,
      phone: _currentUser.phone,
      nativeLanguage: name,
      nativeFlag: flag,
      targetLanguage: _currentUser.targetLanguage,
      targetFlag: _currentUser.targetFlag,
      avatarUrl: _currentUser.avatarUrl,
    );
    notifyListeners();
  }

  void updateTargetLanguage(String name, String flag) {
    _currentUser = UserProfile(
      id: _currentUser.id,
      name: _currentUser.name,
      phone: _currentUser.phone,
      nativeLanguage: _currentUser.nativeLanguage,
      nativeFlag: _currentUser.nativeFlag,
      targetLanguage: name,
      targetFlag: flag,
      avatarUrl: _currentUser.avatarUrl,
    );
    notifyListeners();
  }

  void openChat(ContactItem contact) {
    _activeChatContact = contact;
    if (!_chatHistory.containsKey(contact.id)) {
      _chatHistory[contact.id] = [];
    }

    if (!_activeChatsList.any((item) => item.id == contact.id)) {
      _activeChatsList.add(contact);
    }
    notifyListeners();
  }

  List<ChatMessage> getMessagesForContact(String contactId) {
    return _chatHistory[contactId] ?? [];
  }

  Future<void> sendMessage(String text) async {
    if (_activeChatContact == null || text.trim().isEmpty) return;

    String targetLangCode = 'tr';
    final targetLangLower = _activeChatContact!.nativeLanguage.toLowerCase();

    if (targetLangLower.contains('arabic') || targetLangLower.contains('عربي')) {
      targetLangCode = 'ar';
    } else if (targetLangLower.contains('english') || targetLangLower.contains('إنجليزي')) {
      targetLangCode = 'en';
    } else if (targetLangLower.contains('french') || targetLangLower.contains('فرنسي')) {
      targetLangCode = 'fr';
    } else if (targetLangLower.contains('turkish') || targetLangLower.contains('تركي')) {
      targetLangCode = 'tr';
    }

    String translated = await _translationService.translateText(
      text: text,
      targetLanguageCode: targetLangCode,
    );

    final newMsgMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': _currentUser.id,
      'originalText': text,
      'translatedText': translated,
      'senderLanguage':
          '${_currentUser.nativeLanguage.substring(0, 2).toUpperCase()} ${_currentUser.nativeFlag}',
      'targetLanguage':
          '${_activeChatContact!.nativeLanguage.substring(0, 2).toUpperCase()} ${_activeChatContact!.flag}',
      'timestamp': DateTime.now().toIso8601String(),
    };

    final newMsg = ChatMessage(
      id: newMsgMap['id']!,
      senderId: newMsgMap['senderId']!,
      originalText: newMsgMap['originalText']!,
      translatedText: newMsgMap['translatedText']!,
      senderLanguage: newMsgMap['senderLanguage']!,
      targetLanguage: newMsgMap['targetLanguage']!,
      timestamp: DateTime.parse(newMsgMap['timestamp']!),
    );

    _chatHistory[_activeChatContact!.id]!.add(newMsg);

    _socketService.sendEncryptedMessage(
      to: _activeChatContact!.id,
      payload: newMsgMap,
    );

    notifyListeners();
  }

  /// 🟢 بدء المكالمة مع إمكانية التمييز بين الاتصال الصوتي والاتصال المرئي
  void startCall(ContactItem contact, {bool isVideo = true}) {
    _activeCallContact = contact;
    _isInCall = true;
    _callSeconds = 0;
    _isMicMuted = false;
    
    // إذا كانت المكالمة صوتية تُغلق الكاميرا افتراضياً، وإذا كانت فيديو تُفتح الكاميرا مباشرة
    _isVideoOff = !isVideo;
    _showSubtitles = true;

    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callSeconds++;
      notifyListeners();
    });

    _startSimulatedLiveSubtitles();
    notifyListeners();
  }

  void _startSimulatedLiveSubtitles() {
    _subtitleTimer?.cancel();
    final sampleSubtitles = [
      LiveSubtitle(
        speakerName: _activeCallContact?.name ?? 'Ayla Yılmaz',
        originalSentence: 'Sesimi net bir şekilde alabiliyor musunuz?',
        translatedSentence: 'هل يمكنك سماع صوتي بشكل واضح؟',
        originalLang: 'TR',
        targetLang: 'AR',
      ),
      LiveSubtitle(
        speakerName: _currentUser.name,
        originalSentence: 'نعم صوتك واضح والترجمة المباشرة تظهر فوراً على الشاشة!',
        translatedSentence: 'Evet, sesiniz net ve canlı altyazı ekranda anında görünüyor!',
        originalLang: 'AR',
        targetLang: 'TR',
      ),
      LiveSubtitle(
        speakerName: _activeCallContact?.name ?? 'Ayla Yılmaz',
        originalSentence: 'LingooCall sayesinde hiçbir dil engeli kalmadı.',
        translatedSentence: 'بفضل LingooCall، لم تعد هناك أي حواجز لغوية.',
        originalLang: 'TR',
        targetLang: 'AR',
      ),
    ];

    int index = 0;
    _currentSubtitle = sampleSubtitles[0];
    _subtitleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      index = (index + 1) % sampleSubtitles.length;
      _currentSubtitle = sampleSubtitles[index];
      notifyListeners();
    });
  }

  void updateLiveSubtitle(LiveSubtitle subtitle) {
    _currentSubtitle = subtitle;
    notifyListeners();
  }

  void endCall() {
    _isInCall = false;
    _activeCallContact = null;
    _callDurationTimer?.cancel();
    _subtitleTimer?.cancel();
    _currentSubtitle = null;
    notifyListeners();
  }

  void toggleMic() {
    _isMicMuted = !_isMicMuted;
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    notifyListeners();
  }

  void toggleSubtitles() {
    _showSubtitles = !_showSubtitles;
    notifyListeners();
  }

  @override
  void dispose() {
    _subtitleTimer?.cancel();
    _callDurationTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
}