import 'dart:async';
import 'dart:io' show Platform, HttpClient;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  static String _resolvedBaseUrl = 'http://192.168.1.183:8000/api/v1';

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    
    return _resolvedBaseUrl;
  }

  static Future<void> determineBaseUrl() async {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      _resolvedBaseUrl = envUrl;
      return;
    }

    const port = 8000;
    
    if (kIsWeb) {
      _resolvedBaseUrl = 'http://127.0.0.1:$port/api/v1';
      return;
    }

    final candidates = [
      '192.168.1.183', // Local LAN IP for physical phones & emulators
      '10.0.2.2',      // Android Emulator host loopback
      '127.0.0.1',      // iOS Simulator / Mac Desktop
    ];

    final completer = Completer<String>();

    for (final host in candidates) {
      Future(() async {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 3);
        try {
          final request = await client.getUrl(Uri.parse('http://$host:$port/api/v1/settings/public/'));
          final response = await request.close();
          if (response.statusCode == 200 && !completer.isCompleted) {
            completer.complete('http://$host:$port/api/v1');
          }
        } catch (_) {} finally {
          client.close();
        }
      });
    }

    try {
      _resolvedBaseUrl = await completer.future.timeout(const Duration(seconds: 3));
    } catch (_) {
      try {
        if (Platform.isAndroid) {
          _resolvedBaseUrl = 'http://192.168.1.183:$port/api/v1';
        } else {
          _resolvedBaseUrl = 'http://127.0.0.1:$port/api/v1';
        }
      } catch (_) {
        _resolvedBaseUrl = 'http://192.168.1.183:$port/api/v1';
      }
    }
  }

  ApiClient({
    required this.dio,
    required FlutterSecureStorage storage,
  }) : _storage = storage {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = baseUrl;
          final accessToken = await _storage.read(key: 'access_token');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final retries = (error.requestOptions.extra['retry_count'] as int?) ?? 0;
          if (retries < 2 &&
              (error.type == DioExceptionType.connectionTimeout ||
               error.type == DioExceptionType.connectionError ||
               error.type == DioExceptionType.receiveTimeout ||
               error.type == DioExceptionType.unknown)) {
            error.requestOptions.extra['retry_count'] = retries + 1;
            await determineBaseUrl();
            await Future.delayed(Duration(milliseconds: 250 * (retries + 1)));
            try {
              final retryDio = Dio(BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ));
              final accessToken = await _storage.read(key: 'access_token');
              final headers = Map<String, dynamic>.from(error.requestOptions.headers);
              if (accessToken != null) {
                headers['Authorization'] = 'Bearer $accessToken';
              }
              final response = await retryDio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: Options(
                  method: error.requestOptions.method,
                  headers: headers,
                  responseType: error.requestOptions.responseType,
                  contentType: error.requestOptions.contentType,
                  extra: error.requestOptions.extra,
                ),
              );
              return handler.resolve(response);
            } catch (retryError) {
              if (retryError is DioException) {
                return handler.next(retryError);
              }
              return handler.next(error);
            }
          }

          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;

            if (requestOptions.path.contains('/auth/token/refresh/')) {
              await _logout();
              return handler.next(error);
            }

            try {
              final newAccessToken = await _performTokenRefresh();
              if (newAccessToken != null) {
                final refreshDio = Dio(BaseOptions(
                  baseUrl: baseUrl,
                  connectTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                ));
                final opts = Options(
                  method: requestOptions.method,
                  headers: Map<String, dynamic>.from(requestOptions.headers)
                    ..['Authorization'] = 'Bearer $newAccessToken',
                  responseType: requestOptions.responseType,
                  contentType: requestOptions.contentType,
                  extra: requestOptions.extra,
                );
                final response = await refreshDio.request(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: opts,
                );
                return handler.resolve(response);
              } else {
                await _logout();
                return handler.next(error);
              }
            } catch (e) {
              await _logout();
              if (e is DioException) {
                return handler.next(e);
              }
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _performTokenRefresh() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final refreshDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await refreshDio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access'];
      if (newAccessToken != null) {
        await _storage.write(key: 'access_token', value: newAccessToken);
        
        final newRefreshToken = response.data['refresh'];
        if (newRefreshToken != null) {
          await _storage.write(key: 'refresh_token', value: newRefreshToken);
        }
        
        _refreshCompleter?.complete(newAccessToken);
        return newAccessToken;
      }
      
      throw Exception('Invalid token response');
    } catch (e) {
      _refreshCompleter?.completeError(e);
      _refreshCompleter = null;
      rethrow;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
