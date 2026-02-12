import 'package:dio/dio.dart';
import '../../core/env.dart';

class ABibliaClient {
  ABibliaClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        "Authorization": "Bearer ${Env.abibliaToken}",
        "Content-Type": "application/json",
      },
    ));
  }

  late final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  
}
