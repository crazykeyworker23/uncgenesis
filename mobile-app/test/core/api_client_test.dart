import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/core/network/api_client.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) data[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

/// Servidor de prueba que imita al backend para los casos del interceptor.
class _FakeBackend {
  late final HttpServer _server;

  /// Peticiones recibidas, para comprobar cuántas veces se repitió cada una.
  final List<String> requests = [];

  /// Si es `true`, `/auth/token/refresh/` devuelve un token nuevo.
  bool refreshSucceeds = true;

  /// Rutas que dejan de responder 401 una vez renovado el token.
  bool acceptAfterRefresh = true;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final path = request.uri.path;
      requests.add(path);

      if (path.contains('/auth/token/refresh/')) {
        if (refreshSucceeds) {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'access': 'token-nuevo'}));
        } else {
          request.response.statusCode = 401;
        }
        await request.response.close();
        return;
      }

      final authorization = request.headers.value('Authorization') ?? '';
      final renewed = authorization.contains('token-nuevo');

      if (renewed && acceptAfterRefresh) {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true}));
      } else {
        request.response.statusCode = 401;
      }
      await request.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

void main() {
  group('ApiClient · interceptor de errores', () {
    late FakeSecureStorage storage;
    late _FakeBackend backend;
    late ApiClient client;

    setUp(() async {
      storage = FakeSecureStorage();
      backend = _FakeBackend();
      await backend.start();

      client = ApiClient(
        dio: Dio(),
        storage: storage,
        baseUrlOverride: backend.baseUrl,
      );
      client.dio.options.connectTimeout = const Duration(seconds: 2);
      client.dio.options.receiveTimeout = const Duration(seconds: 2);
    });

    tearDown(() => backend.stop());

    test('renueva el token y entrega la respuesta de la petición repetida', () async {
      // Esta es la ruta que estaba rota: el interceptor resolvía la petición
      // desde dentro de un try cuyo catch volvía a llamar al handler, y Dio
      // lanzaba StateError («The `handler` has already been called»).
      storage.data['access_token'] = 'token-caducado';
      storage.data['refresh_token'] = 'refresh-valido';

      final response = await client.dio.get('/eventos/');

      expect(response.statusCode, 200);
      expect(response.data['ok'], isTrue);
      expect(storage.data['access_token'], 'token-nuevo');
      expect(backend.requests, contains('/auth/token/refresh/'));
    });

    test('sin refresh token cierra la sesión y propaga el error', () async {
      storage.data['access_token'] = 'token-caducado';

      await expectLater(
        client.dio.get('/eventos/'),
        throwsA(isA<DioException>()),
      );

      expect(storage.data.containsKey('access_token'), isFalse);
    });

    test('si el refresco falla avisa una sola vez de la sesión expirada', () async {
      backend.refreshSucceeds = false;
      storage.data['access_token'] = 'token-caducado';
      storage.data['refresh_token'] = 'refresh-invalido';

      var avisos = 0;
      client.onSessionExpired = () => avisos++;

      await expectLater(
        client.dio.get('/eventos/'),
        throwsA(isA<DioException>()),
      );

      expect(avisos, 1);
      expect(storage.data.containsKey('refresh_token'), isFalse);
    });

    test('peticiones simultáneas comparten un único refresco', () async {
      storage.data['access_token'] = 'token-caducado';
      storage.data['refresh_token'] = 'refresh-valido';

      final responses = await Future.wait([
        client.dio.get('/uno/'),
        client.dio.get('/dos/'),
        client.dio.get('/tres/'),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(200));

      // Aunque fallaron tres peticiones a la vez, sólo se pidió un refresco.
      final refrescos = backend.requests.where((p) => p.contains('token/refresh')).length;
      expect(refrescos, 1);
    });

    test('un fallo de red se propaga como DioException tras reintentar', () async {
      // Se guarda la dirección antes de cerrar: después el servidor ya no la
      // conoce. Apuntar a un servidor apagado reproduce la caída de red.
      final direccion = backend.baseUrl;
      await backend.stop();

      final offline = ApiClient(
        dio: Dio(),
        storage: storage,
        baseUrlOverride: direccion,
      );
      offline.dio.options.connectTimeout = const Duration(milliseconds: 300);

      await expectLater(
        offline.dio.get('/eventos/'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
