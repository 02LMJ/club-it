import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 서버와 통신하는 공통 모듈.
/// - 요청·응답을 JSON으로 변환
/// - 저장된 로그인 토큰을 Authorization 헤더에 자동으로 붙임
/// - 실패하면 화면에 보여줄 한글 메시지를 담은 [ApiException]을 던짐
///
/// ```dart
/// final data = await apiClient.post('/auth/login', body: {'email': e, 'password': p});
/// ```
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenStorage tokenStorage,
    http.Client? httpClient,
  })  : _tokenStorage = tokenStorage,
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _http;

  /// 로그인 상태에서 서버가 401(토큰 만료 등)을 보내면 호출됨 → 자동 로그아웃
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final token = await _tokenStorage.read();
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        message: '서버 응답이 너무 늦어요. 잠시 후 다시 시도해주세요.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: '서버에 연결할 수 없어요. 서버가 켜져 있는지 확인해주세요.',
      );
    }

    final data = _decode(response);
    final status = response.statusCode;
    if (status >= 200 && status < 300) return data;

    if (status == 401 && token != null) onUnauthorized?.call();
    throw ApiException(statusCode: status, message: _errorMessage(status, data));
  }

  /// 응답 본문을 JSON으로 변환 (한글이 깨지지 않도록 UTF-8로 읽음)
  static dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  /// 서버 오류 형식: {"detail": "한글 메시지"} / 422는 detail이 목록
  static String _errorMessage(int status, dynamic data) {
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (status == 422) return '입력값을 확인해주세요.';
    if (status >= 500) return '서버에 문제가 생겼어요. 잠시 후 다시 시도해주세요.';
    return '요청을 처리하지 못했어요. ($status)';
  }
}
