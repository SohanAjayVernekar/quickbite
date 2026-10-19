import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final int status;
  final String code, message;
  final String? requestId;
  ApiException(this.status, this.code, this.message, [this.requestId]);
  @override
  String toString() => message;
  bool get uncertain => status == 0 || status >= 500;
}

class ApiClient {
  final http.Client _client;
  String? token;
  void Function()? onUnauthorized;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  Future<Json> get(String path, {bool public = false}) =>
      request('GET', path, public: public);
  Future<Json> post(
    String path,
    Json body, {
    bool public = false,
    String? idempotencyKey,
  }) => request(
    'POST',
    path,
    body: body,
    public: public,
    idempotencyKey: idempotencyKey,
  );
  Future<Json> patch(String path, Json body) => request('PATCH', path, body: body);
  Future<Json> delete(String path) => request('DELETE', path);
  Future<Json> request(
    String method,
    String path, {
    Json? body,
    bool public = false,
    String? idempotencyKey,
  }) async {
    final usedToken = token;
    if (!public && usedToken == null)
      throw ApiException(
        401,
        'AUTHENTICATION_REQUIRED',
        'Please sign in again.',
      );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (!public && usedToken != null) 'Authorization': 'Bearer $usedToken',
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    };
    try {
      final uri = Uri.parse(
        '${Environment.apiBase}$path',
      );
      final Future<http.Response> call = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => _client.patch(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ArgumentError.value(method, 'method', 'Unsupported HTTP method'),
      };
      final response = await call.timeout(const Duration(seconds: 15));
      Json payload;
      try {
        payload = Map<String, dynamic>.from(jsonDecode(response.body));
      } catch (_) {
        throw ApiException(
          response.statusCode >= 400 ? response.statusCode : 502,
          'INVALID_RESPONSE',
          'The service returned an unreadable response. Retry safely.',
        );
      }
      if (response.statusCode >= 400) {
        if (response.statusCode == 401 && !public && token == usedToken)
          onUnauthorized?.call();
        throw ApiException(
          response.statusCode,
          payload['code'] ?? 'REQUEST_FAILED',
          payload['message'] ?? 'Please try again.',
          payload['request_id'],
        );
      }
      return payload;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        0,
        'TIMEOUT',
        'The connection timed out. Your checkout may have been accepted. Retry with the saved request.',
      );
    } on http.ClientException {
      throw ApiException(
        0,
        'OFFLINE',
        'Unable to reach QuickBite. Check your connection and retry.',
      );
    }
  }

  void close() => _client.close();
}
