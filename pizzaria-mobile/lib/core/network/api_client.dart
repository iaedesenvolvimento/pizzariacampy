import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({AppConfig? config, http.Client? client})
      : _config = config ?? AppConfig.fromEnvironment(),
        _client = client ?? http.Client();

  final AppConfig _config;
  final http.Client _client;
  static const _requestTimeout = Duration(seconds: 20);

  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    final response = await _send(() =>
        _client.get(_uri(path), headers: headers).timeout(_requestTimeout));
    return _decode(response);
  }

  Future<dynamic> post(String path,
      {Object? body, Map<String, String>? headers}) async {
    final response = await _send(
      () => _client
          .post(_uri(path), headers: _jsonHeaders(headers), body: _encode(body))
          .timeout(_requestTimeout),
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path,
      {Object? body, Map<String, String>? headers}) async {
    final response = await _send(
      () => _client
          .patch(_uri(path),
              headers: _jsonHeaders(headers), body: _encode(body))
          .timeout(_requestTimeout),
    );
    return _decode(response);
  }

  Future<void> delete(String path, {Map<String, String>? headers}) async {
    final response = await _send(
      () => _client
          .delete(_uri(path), headers: _jsonHeaders(headers))
          .timeout(_requestTimeout),
    );
    _decode(response);
  }

  Future<dynamic> put(String path,
      {Object? body, Map<String, String>? headers}) async {
    final response = await _send(
      () => _client
          .put(_uri(path), headers: _jsonHeaders(headers), body: _encode(body))
          .timeout(_requestTimeout),
    );
    return _decode(response);
  }

  Future<dynamic> uploadFile(String path,
      {required String filePath,
      required String fieldName,
      Map<String, String>? headers}) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll({'Accept': 'application/json', ...?headers});
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Uri _uri(String path) => Uri.parse('${_config.apiBaseUrl}$path');

  Map<String, String> _jsonHeaders(Map<String, String>? headers) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      };

  String? _encode(Object? body) => body == null ? null : jsonEncode(body);

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on Exception catch (error) {
      throw NetworkException(message: error.toString());
    }
  }

  dynamic _decode(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
      final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
      final message = error is Map<String, dynamic>
          ? error['message']?.toString()
          : detail?.toString() ?? 'Ocorreu um erro na comunicação.';
      final code =
          error is Map<String, dynamic> ? error['code']?.toString() : null;
      throw ApiException(
        message: message ?? 'Ocorreu um erro na comunicação.',
        code: code,
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
