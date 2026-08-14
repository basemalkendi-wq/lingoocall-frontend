import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AuthBrowserService {
  static const String defaultRedirectUri = 'lingoocall://oauth/callback';
  static String lastRedirectUrl = '';

  static Map<String, String> parseCallbackFromUri(Uri uri) {
    final params = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      params[entry.key] = entry.value;
    }
    return params;
  }

  static Future<Map<String, String>> openOAuthFlow({
    required String authorizationUrl,
    String redirectUri = defaultRedirectUri,
    bool useSystemBrowser = true,
  }) async {
    if (authorizationUrl.trim().isEmpty) {
      return const <String, String>{};
    }

    try {
      final callbackScheme = _extractCallbackScheme(redirectUri);
      final result = await FlutterWebAuth2.authenticate(
        url: authorizationUrl,
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(preferEphemeral: true),
      );

      lastRedirectUrl = result;
      final uri = Uri.tryParse(result);
      if (uri == null) {
        return const <String, String>{};
      }

      return parseCallbackFromUri(uri);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OAuth browser flow failed: $e');
      }
      return const <String, String>{};
    }
  }

  static String _extractCallbackScheme(String redirectUri) {
    final uri = Uri.tryParse(redirectUri);
    if (uri == null || uri.scheme.isEmpty) {
      return 'lingoocall';
    }
    return uri.scheme;
  }
}
