import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl$path'),
      headers: <String, String>{
        'Accept': 'application/json',
        ...?headers,
      },
    );

    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl$path'),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decodeObjectResponse(response);
  }

  Future<void> postEmpty(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl$path'),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    if (!response.statusCode.toString().startsWith('2')) {
      throw _toApiException(response);
    }
  }

  Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    if (!response.statusCode.toString().startsWith('2')) {
      throw _toApiException(response);
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(500, 'Unexpected response shape.');
  }

  ApiException _toApiException(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final dynamic message = decoded['message'];
        if (message is String) {
          return ApiException(response.statusCode, message);
        }
        if (message is List) {
          return ApiException(
            response.statusCode,
            message.whereType<String>().join('. '),
          );
        }
      }
    } catch (_) {
      // no-op
    }

    return ApiException(response.statusCode, 'Request failed: ${response.statusCode}');
  }
}
