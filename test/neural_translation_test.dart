import 'package:flutter_test/flutter_test.dart';
import 'package:lingoocall/core/services/translation_service.dart';

void main() {
  group('TranslationService dialect normalization', () {
    test('normalizes common dialect phrases before neural translation', () {
      final service = TranslationService();

      expect(
        service.normalizeDialectText(
          text: 'شو أخبارك يا صاحبي؟',
          sourceLanguageCode: 'ar',
          targetLanguageCode: 'en',
        ),
        contains('أخبارك'),
      );

      expect(
        service.normalizeDialectText(
          text: 'şu an ne yapıyo?',
          sourceLanguageCode: 'tr',
          targetLanguageCode: 'ar',
        ),
        contains('şimdi'),
      );
    });
  });
}
