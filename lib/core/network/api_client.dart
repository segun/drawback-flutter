import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    void Function()? onUnauthorized,
  })
      : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _httpClient = httpClient ?? http.Client(),
        _onUnauthorized = onUnauthorized;

  final String _baseUrl;
  final http.Client _httpClient;
  final void Function()? _onUnauthorized;

  static const String _offlineErrorMessage =
      'No internet connection. Please check your network and try again.';

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _sendRequest(() {
      return _httpClient.get(
        Uri.parse('$_baseUrl$path'),
        headers: <String, String>{
          'Accept': 'application/json',
          ...?headers,
        },
      );
    });

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _sendRequest(() {
      return _httpClient.get(
        Uri.parse('$_baseUrl$path'),
        headers: <String, String>{
          'Accept': 'application/json',
          ...?headers,
        },
      );
    });

    return _decodeObjectResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _sendRequest(() {
      return _httpClient.post(
        Uri.parse('$_baseUrl$path'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body ?? <String, dynamic>{}),
      );
    });

    return _decodeObjectResponse(response);
  }

  Future<void> postEmpty(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _sendRequest(() {
      return _httpClient.post(
        Uri.parse('$_baseUrl$path'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body ?? <String, dynamic>{}),
      );
    });

    if (!response.statusCode.toString().startsWith('2')) {
      throw _toApiException(response);
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final response = await _sendRequest(() {
      return _httpClient.patch(
        Uri.parse('$_baseUrl$path'),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body ?? <String, dynamic>{}),
      );
    });

    return _decodeObjectResponse(response);
  }

  Future<dynamic> deleteJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final response = await _sendRequest(() {
      return _httpClient.delete(
        Uri.parse('$_baseUrl$path'),
        headers: <String, String>{
          'Accept': 'application/json',
          ...?headers,
        },
      );
    });

    if (!response.statusCode.toString().startsWith('2')) {
      throw _toApiException(response);
    }

    // DELETE may return empty body or JSON response
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  dynamic _decodeResponse(http.Response response) {
    if (!response.statusCode.toString().startsWith('2')) {
      throw _toApiException(response);
    }

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(response.body);
  }

  Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    if (!response.statusCode.toString().startsWith('2')) {
      throw _toApiException(response);
    }

    if (response.body.isEmpty) {
      throw const ApiException(500, 'Expected JSON response but got empty body.');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(500, 'Unexpected response shape.');
  }

  ApiException _toApiException(http.Response response) {
    if (response.statusCode == 401) {
      _onUnauthorized?.call();
    }

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

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (error) {
      if (_isConnectivityError(error)) {
        throw const ApiException(0, _offlineErrorMessage);
      }
      rethrow;
    }
  }

  bool _isConnectivityError(Object error) {
    if (error is http.ClientException &&
        _containsConnectivityText(error.message)) {
      return true;
    }
    return _containsConnectivityText(error.toString());
  }

  bool _containsConnectivityText(String value) {
    final String text = value.toLowerCase();
    const List<String> connectivityHints = <String>[
      'socketexception',
      'failed host lookup',
      'network is unreachable',
      'connection refused',
      'connection reset',
      'connection closed',
      'connection terminated',
      'timed out',
      'failed to fetch',
      'xmlhttprequest error',
      'network request failed',
      'name or service not known',
      'no address associated with hostname',
      'dns',
    ];

    return connectivityHints.any(text.contains);
  }
}
