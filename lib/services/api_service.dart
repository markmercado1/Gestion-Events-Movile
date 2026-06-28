import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;
  ApiException(this.message, {this.statusCode, this.body});
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 10);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await StorageService.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _send(
      Future<http.Response> Function() fn) async {
    try {
      return await fn().timeout(_timeout);
    } on SocketException catch (e) {
      throw NetworkException('Sin conexión: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado');
    }
  }

  static dynamic _parse(http.Response res) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      body = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map)
        ? (body['error'] ?? body['mensaje'] ?? 'Error ${res.statusCode}')
        : 'Error ${res.statusCode}';
    throw ApiException(msg, statusCode: res.statusCode, body: body);
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await _send(() async => http.get(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: await _headers(auth: auth),
        ));
    return _parse(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final res = await _send(() async => http.post(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        ));
    return _parse(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await _send(() async => http.put(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        ));
    return _parse(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await _send(() async => http.patch(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        ));
    return _parse(res);
  }

  static Future<dynamic> delete(String path) async {
    final res = await _send(() async => http.delete(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: await _headers(),
        ));
    return _parse(res);
  }
}
