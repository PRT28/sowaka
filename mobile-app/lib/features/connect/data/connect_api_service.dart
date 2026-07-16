import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/api_config.dart';
import '../../auth/data/auth_models.dart';
import 'connect_models.dart';

class ConnectApiService {
  ConnectApiService({
    required this.session,
    String? baseUrl,
    http.Client? client,
  }) : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _client = client ?? http.Client();

  final AuthSession session;
  final String _baseUrl;
  final http.Client _client;

  Future<List<ConnectPost>> fetchFeed() async {
    final json = await _request('GET', '/connect/feed');
    final values = json['posts'] as List<dynamic>? ?? const [];
    return values
        .map((value) => ConnectPost.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  Future<ConnectPost> createPost(ConnectPostDraft draft) async {
    if (draft.media != null) {
      final json = await _multipartRequest('POST', '/connect/posts', draft);
      return ConnectPost.fromJson(json['post'] as Map<String, dynamic>);
    }
    final json = await _request('POST', '/connect/posts', body: draft.toJson());
    return ConnectPost.fromJson(json['post'] as Map<String, dynamic>);
  }

  Future<ConnectPost> updatePost(String postId, ConnectPostDraft draft) async {
    if (draft.media != null) {
      final json = await _multipartRequest(
        'PATCH',
        '/connect/posts/$postId',
        draft,
      );
      return ConnectPost.fromJson(json['post'] as Map<String, dynamic>);
    }
    final json = await _request(
      'PATCH',
      '/connect/posts/$postId',
      body: draft.toJson(),
    );
    return ConnectPost.fromJson(json['post'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await _request('DELETE', '/connect/posts/$postId');
  }

  Future<ConnectPost> toggleReaction(String postId) async {
    final json = await _request('POST', '/connect/posts/$postId/reaction');
    return ConnectPost.fromJson(json['post'] as Map<String, dynamic>);
  }

  Future<ConnectPost> addComment(String postId, String text) async {
    final json = await _request(
      'POST',
      '/connect/posts/$postId/comments',
      body: {'text': text},
    );
    return ConnectPost.fromJson(json['post'] as Map<String, dynamic>);
  }

  Future<ConnectPost> performAction(String postId, {String? optionId}) async {
    final json = await _request(
      'POST',
      '/connect/posts/$postId/actions',
      body: optionId == null ? null : {'optionId': optionId},
    );
    return ConnectPost.fromJson(json['post'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Authorization': 'Bearer ${session.token}',
      'Content-Type': 'application/json',
    };
    final response = await switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'PATCH' => _client.patch(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      'DELETE' => _client.delete(uri, headers: headers),
      _ => throw UnsupportedError('Unsupported method $method'),
    };

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded['message'] as String? ?? 'Connect request failed';
    throw ConnectApiException(message, response.statusCode);
  }

  Future<Map<String, dynamic>> _multipartRequest(
    String method,
    String path,
    ConnectPostDraft draft,
  ) async {
    final media = draft.media;
    if (media == null) throw StateError('Missing media attachment');
    final request = http.MultipartRequest(method, Uri.parse('$_baseUrl$path'));
    request.headers['Authorization'] = 'Bearer ${session.token}';
    request.fields['type'] = connectPostTypeToWire(draft.type);
    request.fields['removeMedia'] = draft.removeMedia ? 'true' : 'false';
    request.fields['body'] = jsonEncode(draft.body);
    request.files.add(
      await http.MultipartFile.fromPath(
        'media',
        media.path,
        filename: media.name,
      ),
    );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded['message'] as String? ?? 'Connect request failed';
    throw ConnectApiException(message, response.statusCode);
  }
}

class ConnectApiException implements Exception {
  const ConnectApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
