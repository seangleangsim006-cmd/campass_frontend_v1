import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({Dio? dio, TokenStore? tokenStore})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl:
                  '${ApiConstants.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ),
      _tokenStore = tokenStore ?? SecureTokenStore();

  final Dio _dio;
  final TokenStore _tokenStore;
  String? _token;
  String _languageCode = 'en';
  Future<void>? _initialization;

  bool get isAuthenticated => _token?.isNotEmpty ?? false;
  String get languageCode => _languageCode;

  Future<void> initialize() {
    return _initialization ??= _loadToken();
  }

  Future<void> setToken(String? token) async {
    _token = token;
    await _tokenStore.write(token);
  }

  void setLanguage(String languageCode) {
    _languageCode = languageCode;
  }

  Future<Map<String, Object?>> get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) {
    return _request(path, method: 'GET', queryParameters: queryParameters);
  }

  Future<Map<String, Object?>> post(String path, {Map<String, Object?>? data}) {
    return _request(path, method: 'POST', data: data);
  }

  Future<Map<String, Object?>> patch(
    String path, {
    Map<String, Object?>? data,
  }) {
    return _request(path, method: 'PATCH', data: data);
  }

  Future<Map<String, Object?>> put(String path, {Map<String, Object?>? data}) {
    return _request(path, method: 'PUT', data: data);
  }

  Future<Map<String, Object?>> delete(String path) {
    return _request(path, method: 'DELETE');
  }

  Future<Map<String, Object?>> _request(
    String path, {
    required String method,
    Map<String, Object?>? data,
    Map<String, Object?>? queryParameters,
  }) async {
    try {
      await initialize();
      final response = await _dio.request<Object?>(
        path.startsWith('/') ? path.substring(1) : path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: {
            'Accept-Language': _languageCode,
            if (_token != null) 'Authorization': 'Bearer $_token',
          },
        ),
      );
      return _asJsonObject(response.data);
    } on DioException catch (error) {
      final body = error.response?.data;
      final json = body is Map ? Map<String, Object?>.from(body) : null;
      final errors = json?['errors'];
      final validationMessage = errors is Map
          ? errors.values
                .whereType<List>()
                .expand((messages) => messages)
                .whereType<String>()
                .firstOrNull
          : null;
      final message =
          validationMessage ??
          (json?['message'] is String ? json!['message'] as String : null) ??
          error.message ??
          'The request could not be completed.';
      throw ApiException(message, code: error.response?.statusCode?.toString());
    } on FormatException catch (error) {
      throw ApiException('The server returned an invalid response: $error');
    }
  }

  Future<void> _loadToken() async {
    _token = await _tokenStore.read();
  }

  Map<String, Object?> _asJsonObject(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    if (value == null) return const {};
    throw const ApiException('The server returned an unexpected response.');
  }
}
