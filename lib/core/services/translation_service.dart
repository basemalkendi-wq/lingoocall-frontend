import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final String _baseUrl = 'https://lingoocall-backend.onrender.com/api';

  String normalizeDialectText({
    required String text,
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) {
    if (text.trim().isEmpty) return text;

    String normalized = text.trim();
    final sourceLower = sourceLanguageCode.toLowerCase();
    final targetLower = targetLanguageCode.toLowerCase();

    if (sourceLower == 'ar' || sourceLower == 'auto') {
      normalized = normalized
          .replaceAll(RegExp(r'\bشو\b', caseSensitive: false), 'ما')
          .replaceAll(RegExp(r'\bشخبار\b', caseSensitive: false), 'ما الأخبار')
          .replaceAll(RegExp(r'\bالح\b', caseSensitive: false), 'ال')
          .replaceAll(RegExp(r'\bيلا\b', caseSensitive: false), 'هيا')
          .replaceAll(RegExp(r'\bعايز\b', caseSensitive: false), 'أريد')
          .replaceAll(RegExp(r'\bاى\b', caseSensitive: false), 'هل');
    }

    if (sourceLower == 'tr' || sourceLower == 'auto') {
      normalized = normalized
          .replaceAll('yapıyo', 'yapıyor')
          .replaceAll('Yapıyo', 'Yapıyor')
          .replaceAll('yapıyon', 'yapıyorsun')
          .replaceAll('Yapıyon', 'Yapıyorsun')
          .replaceAll('şu an', 'şimdi')
          .replaceAll('Şu an', 'Şimdi')
          .replaceAll('nasıl gidiyo', 'nasıl gidiyor')
          .replaceAll('Nasıl gidiyo', 'Nasıl gidiyor')
          .replaceAll('ne diyosun', 'ne diyorsun')
          .replaceAll('Ne diyosun', 'Ne diyorsun');
    }

    if (targetLower == 'ar') {
      normalized = normalized.replaceAll(
        RegExp(r'\bhello\b', caseSensitive: false),
        'مرحباً',
      );
    }

    return normalized;
  }

  Future<String> translateText({
    required String text,
    required String targetLanguageCode,
    String sourceLanguageCode = 'auto',
  }) async {
    if (text.trim().isEmpty) return text;

    final normalizedText = normalizeDialectText(
      text: text,
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': normalizedText,
          'target_lang': targetLanguageCode,
          'source_lang': sourceLanguageCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? text;
      }
      return _fallbackTranslate(normalizedText, targetLanguageCode);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [TranslationService Error]: $e');
      }
      return _fallbackTranslate(normalizedText, targetLanguageCode);
    }
  }

  Future<Map<String, String>> translateLiveSubtitle({
    required String speakerName,
    required String originalSentence,
    required String sourceLanguageCode,
    required String targetLanguageCode,
  }) async {
    final normalizedOriginal = normalizeDialectText(
      text: originalSentence,
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
    );

    final translatedText = await translateText(
      text: normalizedOriginal,
      targetLanguageCode: targetLanguageCode,
      sourceLanguageCode: sourceLanguageCode,
    );

    return {
      'speakerName': speakerName,
      'originalSentence': normalizedOriginal,
      'translatedSentence': translatedText,
      'originalLang': sourceLanguageCode.toUpperCase(),
      'targetLang': targetLanguageCode.toUpperCase(),
    };
  }

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
