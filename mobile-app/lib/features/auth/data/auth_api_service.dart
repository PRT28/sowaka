import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_models.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApiService {
  AuthApiService({
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
    http.Client? client,
  }) : _baseUrl = baseUrl.isEmpty ? _defaultBaseUrl : baseUrl,
       _client = client ?? http.Client();

  static String get _defaultBaseUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:4000';
    }
    return 'http://10.0.2.2:4000';
  }

  final String _baseUrl;
  final http.Client _client;

  Future<void> requestOtp(String email) async {
    await _post('/auth/request-otp', {'email': email});
  }

  Future<AuthSession> verifyOtp(String email, String otp) async {
    final json = await _post('/auth/verify-otp', {'email': email, 'otp': otp});
    return AuthSession.fromJson(json);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final raw = utf8.decode(response.bodyBytes);
    final data = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        data['message'] as String? ?? 'Authentication failed',
      );
    }

    return data;
  }
}
