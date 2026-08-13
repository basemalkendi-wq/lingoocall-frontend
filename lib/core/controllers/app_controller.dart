import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingoocall/core/services/contacts_sync_service.dart';
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

  bool _isContactsSyncing = false;
  bool get isContactsSyncing => _isContactsSyncing;

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
  final List<ContactItem> _registeredContacts = [];

  List<ContactItem> get registeredContacts =>
      List.unmodifiable(_registeredContacts);

  AppController() {
    _initMockData();
    _restoreSessionFromPreferences();
    _connectToSocketServer();
  }

  List<ContactItem> get activeChats {
    return List.unmodifiable(_activeChatsList);
  }

  Future<void> _restoreSessionFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserJson = prefs.getString('current_user');

    if (storedUserJson != null && storedUserJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedUserJson);
        if (decoded is Map<String, dynamic>) {
          _currentUser = UserProfile.fromJson(decoded);
          _isAuthenticated = true;
        }
      } catch (_) {
        // Fallback to legacy session keys below.
      }
    }

    if (!_isAuthenticated && prefs.getBool('is_logged_in') == true) {
      _currentUser = _currentUser.copyWith(
        id: prefs.getString('user_id') ?? _currentUser.id,
        username: prefs.getString('username') ?? _currentUser.username,
        email: prefs.getString('email') ?? _currentUser.email,
      );
      _isAuthenticated = true;
    }

    _connectToSocketServer();
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', _isAuthenticated);
    await prefs.setString('user_id', _currentUser.id);
    await prefs.setString('username', _currentUser.username);
    await prefs.setString('email', _currentUser.email);
    await prefs.setString('current_user', jsonEncode(_currentUser.toJson()));
  }

  void _connectToSocketServer() {
    if (_currentUser.id.isEmpty) {
      return;
    }

    _socketService.disconnect();
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
          speakerName:
              data['speakerName'] ?? _activeCallContact?.name ?? 'Speaker',
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
    _persistSession();
    notifyListeners();
  }

  Future<void> applyAuthenticatedUser(UserProfile user) async {
    _currentUser = user;
    _isAuthenticated = true;
    await _persistSession();
    _connectToSocketServer();
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _isInCall = false;
    _registeredContacts.clear();
    _socketService.disconnect();
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.remove('is_logged_in');
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('current_user');
    });
    notifyListeners();
  }

  void updateNativeLanguage(String name, String flag) {
    _currentUser = _currentUser.copyWith(
      nativeLanguage: name,
      nativeFlag: flag,
    );
    _persistSession();
    notifyListeners();
  }

  void updateTargetLanguage(String name, String flag) {
    _currentUser = _currentUser.copyWith(
      targetLanguage: name,
      targetFlag: flag,
    );
    _persistSession();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
  }) async {
    _currentUser = _currentUser.copyWith(
      name: name,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
    );
    await _persistSession();
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

    final targetLangCode = _resolveLanguageCode(
      _activeChatContact!.isRegistered
          ? _activeChatContact!.nativeLanguage
          : _currentUser.targetLanguage,
    );

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

  Future<void> syncRegisteredContacts() async {
    _isContactsSyncing = true;
    notifyListeners();

    try {
      final contacts = await ContactsSyncService.instance.syncDeviceContacts();
      _registeredContacts
        ..clear()
        ..addAll(contacts);
    } catch (_) {
      _registeredContacts.clear();
    } finally {
      _isContactsSyncing = false;
      notifyListeners();
    }
  }

  String _resolveLanguageCode(String languageName) {
    final normalized = languageName.toLowerCase();
    if (normalized.contains('arab') || normalized.contains('عربي')) return 'ar';
    if (normalized.contains('engl') || normalized.contains('إنجليزي'))
      return 'en';
    if (normalized.contains('fran') || normalized.contains('فرنسي'))
      return 'fr';
    if (normalized.contains('span') || normalized.contains('إسباني'))
      return 'es';
    if (normalized.contains('ger') || normalized.contains('ألماني'))
      return 'de';
    if (normalized.contains('chin') || normalized.contains('صيني')) return 'zh';
    if (normalized.contains('turk') || normalized.contains('تركي')) return 'tr';
    return 'auto';
  }

  /// 🟢 بدء المكالمة مع إمكانية التمييز بين الاتصال الصوتي والاتصال المرئي
  void startCall(ContactItem contact, {bool isVideo = true}) {
    _activeCallContact = contact;
    _isInCall = true;
    _callSeconds = 0;
    _isMicMuted = false;

    _isVideoOff = !isVideo;
    _showSubtitles = true;

    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callSeconds++;
      notifyListeners();
    });

    _startRealtimeLiveSubtitles();
    notifyListeners();
  }

  void _startRealtimeLiveSubtitles() {
    _subtitleTimer?.cancel();

    final samplePhrases = [
      'Merhaba, bugün nasıl gidiyor?',
      'Şu an çok net duydum, teşekkür ederim.',
      'LingooCall sayesinde her dil anlaşılır hale geliyor.',
    ];

    Future<void> pushSubtitle(int index) async {
      if (!_isInCall || _activeCallContact == null) return;

      final sourceLanguageCode = _resolveLanguageCode(
        _currentUser.nativeLanguage,
      );
      final targetLanguageCode = _resolveLanguageCode(
        _activeCallContact!.nativeLanguage,
      );
      final originalText = samplePhrases[index % samplePhrases.length];

      final subtitleMap = await _translationService.translateLiveSubtitle(
        speakerName: _activeCallContact!.name,
        originalSentence: originalText,
        sourceLanguageCode: sourceLanguageCode,
        targetLanguageCode: targetLanguageCode,
      );

      _currentSubtitle = LiveSubtitle(
        speakerName: subtitleMap['speakerName'] ?? _activeCallContact!.name,
        originalSentence: subtitleMap['originalSentence'] ?? originalText,
        translatedSentence: subtitleMap['translatedSentence'] ?? originalText,
        originalLang:
            subtitleMap['originalLang'] ?? sourceLanguageCode.toUpperCase(),
        targetLang:
            subtitleMap['targetLang'] ?? targetLanguageCode.toUpperCase(),
      );

      _socketService.sendLiveSubtitle(
        to: _activeCallContact!.id,
        subtitlePayload: subtitleMap,
      );
      notifyListeners();
    }

    unawaited(pushSubtitle(0));
    int index = 0;
    _subtitleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      index += 1;
      unawaited(pushSubtitle(index));
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
