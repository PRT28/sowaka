import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/api_config.dart';
import 'auth_models.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthApiService {
  AuthApiService({String? baseUrl, http.Client? client})
    : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<void> requestOtp(String email) async {
    await _post('/auth/request-otp', {'email': email});
  }

  Future<AuthSession> verifyOtp(String email, String otp) async {
    final json = await _post('/auth/verify-otp', {'email': email, 'otp': otp});
    return AuthSession.fromJson(json);
  }

  Future<AuthUser> fetchCurrentUser(String token) async {
    final uri = Uri.parse('$_baseUrl/auth/me');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    final raw = utf8.decode(response.bodyBytes);
    final data = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        data['message'] as String? ?? 'Could not refresh profile',
        statusCode: response.statusCode,
      );
    }

    return AuthUser.fromJson(
      data['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
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
        statusCode: response.statusCode,
      );
    }

    return data;
  }
}
