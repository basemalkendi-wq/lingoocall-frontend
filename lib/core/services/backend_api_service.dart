import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:lingoocall/core/constants/app_constants.dart';
import 'package:lingoocall/features/auth/domain/models/user_profile.dart';
import 'package:lingoocall/features/contacts/domain/models/contact_item.dart';

class BackendApiService {
  BackendApiService._();

  static final BackendApiService instance = BackendApiService._();

  Uri _uri(String path) => Uri.parse('${AppConstants.backendBaseUrl}$path');

  Future<Map<String, dynamic>> requestOtp({
    required String email,
    required String username,
    required String fullName,
    required String phone,
    required String password,
    required String nativeLanguage,
    required String avatarUrl,
  }) async {
    final response = await http.post(
      _uri('/api/auth/request-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'fullName': fullName,
        'phone': phone,
        'password': password,
        'isSignUp': true,
        'nativeLanguage': nativeLanguage,
        'avatarUrl': avatarUrl,
      }),
    );

    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required bool isSignUp,
  }) async {
    final response = await http.post(
      _uri('/api/auth/verify-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'isSignUp': isSignUp}),
    );

    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );

    return _decodeJson(response);
  }

  Future<List<ContactItem>> syncContacts({
    required List<Map<String, String>> contacts,
  }) async {
    final response = await http.post(
      _uri('/api/contacts/sync'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'contacts': contacts}),
    );

    final payload = _decodeJson(response);
    final registeredContacts = payload['registeredContacts'];
    if (registeredContacts is! List) {
      return const [];
    }

    return registeredContacts
        .whereType<Map>()
        .map((item) {
          final phone = item['phone']?.toString() ?? '';
          final rawId = item['id']?.toString() ?? '';
          final id = rawId.isNotEmpty ? rawId : phone;
          return ContactItem(
            id: id,
            name: item['name']?.toString() ?? item['fullName']?.toString() ?? item['username']?.toString() ?? phone,
            phone: phone,
            nativeLanguage: item['nativeLanguage']?.toString() ?? 'Arabic',
            flag: item['nativeFlag']?.toString() ?? '🇾🇪',
            isRegistered: item['isRegistered'] == true,
            isOnline: item['isOnline'] == true,
          );
        })
        .toList(growable: false);
  }

  Future<UserProfile?> lookupUser(String identifier) async {
    final response = await http.get(_uri('/api/users/lookup?identifier=${Uri.encodeComponent(identifier)}'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final payload = jsonDecode(response.body);
    if (payload is Map<String, dynamic> && payload['user'] is Map<String, dynamic>) {
      return UserProfile.fromJson(Map<String, dynamic>.from(payload['user'] as Map));
    }
    return null;
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (kDebugMode) {
      debugPrint('Unexpected JSON payload: ${response.body}');
    }
    return <String, dynamic>{'message': response.body};
  }
}