import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  /// Se invoca cuando el backend invalida la sesión y hay que limpiar el
  /// estado de la app. Sin esto, los tokens se borraban en silencio y la
  /// interfaz seguía mostrando al usuario como conectado.
  void Function()? onSessionExpired;

  static String _resolvedBaseUrl = 'http://72.61.48.152:8080/api/v1';

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return _resolvedBaseUrl;
  }

  static Future<void> determineBaseUrl() async {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      _resolvedBaseUrl = envUrl;
      return;
    }
    _resolvedBaseUrl = 'http://72.61.48.152:8080/api/v1';
  }

  /// Dirección propia de esta instancia. Sin valor se usa la del servidor
  /// configurado para la app; sirve para apuntar a otro entorno sin tocar la
  /// configuración global.
  final String? _baseUrlOverride;

  String get _effectiveBaseUrl => _baseUrlOverride ?? baseUrl;

  ApiClient({
    required this.dio,
    required FlutterSecureStorage storage,
    String? baseUrlOverride,
  })  : _storage = storage,
        _baseUrlOverride = baseUrlOverride {
    dio.options.baseUrl = _effectiveBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = _effectiveBaseUrl;
          final accessToken = await _storage.read(key: 'access_token');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        // El handler se invoca exactamente una vez, al final y fuera de
        // cualquier try/catch. Antes `handler.resolve()` estaba dentro de un
        // try cuyo catch volvía a llamar al handler: si la resolución
        // propagaba cualquier excepción, el interceptor lo llamaba dos veces y
        // Dio lanzaba "The `handler` has already been called".
        onError: (DioException error, handler) async {
          Response<dynamic>? recovered;
          DioException failure = error;

          try {
            recovered = await _tryRecover(error);
          } on DioException catch (e) {
            failure = e;
          } catch (_) {
            // Cualquier otro fallo durante la recuperación deja el error
            // original, que es el que le interesa a quien hizo la petición.
          }

          if (recovered != null) {
            handler.resolve(recovered);
          } else {
            handler.next(failure);
          }
        },
      ),
    );
  }

  /// Intenta rescatar una petición fallida.
  ///
  /// Devuelve la respuesta si lo consigue y `null` si el error debe llegar a
  /// quien hizo la llamada. Nunca toca el handler del interceptor: esa decisión
  /// es de `onError`, que así lo invoca una sola vez.
  Future<Response<dynamic>?> _tryRecover(DioException error) async {
    final options = error.requestOptions;
    final retries = (options.extra['retry_count'] as int?) ?? 0;

    final isTransient = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.unknown;

    // 1. Fallo pasajero de red: se reintenta con una espera creciente.
    if (retries < 2 && isTransient) {
      options.extra['retry_count'] = retries + 1;
      if (_baseUrlOverride == null) {
        await determineBaseUrl();
      }
      await Future.delayed(Duration(milliseconds: 250 * (retries + 1)));
      return _replay(options);
    }

    // 2. Sesión caducada: se renueva el token y se repite la petición.
    if (error.response?.statusCode == 401) {
      if (options.path.contains('/auth/token/refresh/')) {
        // Si es el propio refresco el que falla, no hay nada que renovar.
        await _logout();
        return null;
      }

      final newAccessToken = await _performTokenRefresh();
      if (newAccessToken == null) {
        await _logout();
        return null;
      }
      return _replay(options, accessToken: newAccessToken);
    }

    return null;
  }

  /// Repite una petición con un cliente sin interceptores, para no reentrar en
  /// esta misma lógica y provocar una cadena de reintentos.
  Future<Response<dynamic>> _replay(RequestOptions options, {String? accessToken}) async {
    final client = Dio(BaseOptions(
      baseUrl: _effectiveBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final headers = Map<String, dynamic>.from(options.headers);
    final token = accessToken ?? await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return client.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: headers,
        responseType: options.responseType,
        contentType: options.contentType,
        extra: options.extra,
      ),
    );
  }

  /// Renueva el token de acceso.
  ///
  /// Devuelve `null` cuando no se puede renovar. Las peticiones que fallen a la
  /// vez comparten el mismo refresco en lugar de lanzar uno cada una.
  Future<String?> _performTokenRefresh() async {
    final inFlight = _refreshCompleter;
    if (_isRefreshing && inFlight != null) {
      return inFlight.future;
    }

    final completer = Completer<String?>();
    _isRefreshing = true;
    _refreshCompleter = completer;

    String? newAccessToken;

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final refreshDio = Dio(BaseOptions(
          baseUrl: _effectiveBaseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        final response = await refreshDio.post(
          '/auth/token/refresh/',
          data: {'refresh': refreshToken},
        );

        final access = response.data['access'];
        if (access is String && access.isNotEmpty) {
          await _storage.write(key: 'access_token', value: access);

          final rotated = response.data['refresh'];
          if (rotated is String && rotated.isNotEmpty) {
            await _storage.write(key: 'refresh_token', value: rotated);
          }
          newAccessToken = access;
        }
      }
    } catch (_) {
      // Un refresco fallido se comunica como ausencia de token: quien espera
      // ya lo interpreta como sesión caducada.
      newAccessToken = null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
      // Se completa una sola vez y siempre con un valor, para que las
      // peticiones que esperaban este mismo refresco no queden colgadas.
      if (!completer.isCompleted) {
        completer.complete(newAccessToken);
      }
    }

    return newAccessToken;
  }

  Future<void> _logout() async {
    final hadSession = await _storage.read(key: 'access_token') != null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    if (hadSession) {
      onSessionExpired?.call();
    }
  }
}
