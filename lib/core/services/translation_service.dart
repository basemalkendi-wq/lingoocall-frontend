import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // رابط السيرفر الخاص بـ LingooCall للترجمة أو مفتاح خدمة الترجمة
  final String _baseUrl = 'https://lingoocall-backend.onrender.com/api';

  /// 1. ترجمة النصوص الفورية للرسائل النصية
  Future<String> translateText({
    required String text,
    required String targetLanguageCode, // مثال: 'ar', 'tr', 'en', 'fr'
    String sourceLanguageCode = 'auto',
  }) async {
    if (text.trim().isEmpty) return text;

    try {
      // إرسال طلب الترجمة للباك إند الخاص بالتطبيق
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'target_lang': targetLanguageCode,
          'source_lang': sourceLanguageCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? text;
      } else {
        // خيار احتياطي (Fallback) في حال تعذر الوصول للسيرفر محلياً
        return _fallbackTranslate(text, targetLanguageCode);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [TranslationService Error]: $e');
      }
      return _fallbackTranslate(text, targetLanguageCode);
    }
  }

  /// 2. تحويل الصوت المباشر إلى نص مصلح ومترجم (Real-time Speech-to-Text & Translation)
  Future<Map<String, String>> processLiveAudioChunk({
    required List<int> audioBytes,
    required String targetLang,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/speech-to-translate'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: audioBytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'original': data['original_speech'] ?? '',
          'translated': data['translated_speech'] ?? '',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error processing live audio chunk: $e');
      }
    }
    return {'original': '', 'translated': ''};
  }

  /// دالة احتياطية مجانية لترجمة النصوص (تضمن عمل التطبيق حتى بدون سيرفر)
  Future<String> _fallbackTranslate(String text, String targetLang) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data[0][0][0];
        return translatedText.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Fallback Google Translate Error: $e');
      }
    }
    return text;
  }
}