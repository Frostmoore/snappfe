import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Client HTTP verso il backend SNAPP. Normalizza il contratto {data, meta, errors}
/// e gli errori in [ApiException]. Aggiunge il token Sanctum se presente.
class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({Dio? dio, required this.tokenStorage})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
            )) {
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// GET → ritorna il campo `data`.
  Future<dynamic> getData(String path, {Map<String, dynamic>? query}) async {
    return _unwrap(() => dio.get(path, queryParameters: query));
  }

  /// GET → ritorna l'intera risposta `{data, meta}`.
  Future<Map<String, dynamic>> getRaw(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await dio.get(path, queryParameters: query);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<dynamic> postData(String path, {Object? body}) async {
    return _unwrap(() => dio.post(path, data: body));
  }

  Future<dynamic> deleteData(String path) async {
    return _unwrap(() => dio.delete(path));
  }

  Future<dynamic> _unwrap(Future<Response> Function() request) async {
    try {
      final res = await request();
      final data = res.data;
      if (data is Map && data.containsKey('data')) {
        return data['data'];
      }
      return data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final response = e.response;
    if (response != null && response.data is Map) {
      final map = response.data as Map;
      return ApiException(
        (map['message'] ?? 'Errore di rete').toString(),
        statusCode: response.statusCode,
        errors: map['errors'] is Map ? Map<String, dynamic>.from(map['errors']) : null,
      );
    }
    return ApiException(
      'Impossibile contattare il server. Controlla la connessione.',
      statusCode: response?.statusCode,
    );
  }
}
