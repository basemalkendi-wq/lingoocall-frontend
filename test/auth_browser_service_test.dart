import 'package:flutter_test/flutter_test.dart';
import 'package:lingoocall/core/services/auth_browser_service.dart';

void main() {
  group('AuthBrowserService', () {
    test('parses OAuth callback parameters from a redirect URL', () {
      final uri = Uri.parse(
        'https://lingoocall.app/?code=test-code&state=test-state&access_token=token-123',
      );

      final params = AuthBrowserService.parseCallbackFromUri(uri);

      expect(params['code'], 'test-code');
      expect(params['state'], 'test-state');
      expect(params['access_token'], 'token-123');
    });

    test('returns empty map for URLs without auth params', () {
      final uri = Uri.parse('https://lingoocall.app/login');

      expect(AuthBrowserService.parseCallbackFromUri(uri), isEmpty);
    });
  });
}
