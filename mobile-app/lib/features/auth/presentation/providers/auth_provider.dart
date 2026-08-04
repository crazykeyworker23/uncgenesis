import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dio/dio.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/api_error.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required UserModel user}) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.guest() = _Guest;
  const factory AuthState.error(String message) = _Error;
}

extension AuthStateX on AuthState {
  /// `true` sólo cuando hay una sesión real con el backend.
  bool get isAuthenticated => maybeWhen(authenticated: (_) => true, orElse: () => false);

  /// Cualquier estado que NO sea una sesión iniciada se navega como invitado.
  bool get isGuest => !isAuthenticated;

  bool get isLoading => maybeWhen(loading: () => true, orElse: () => false);

  UserModel? get user => maybeWhen(authenticated: (user) => user, orElse: () => null);

  /// Identidad de la sesión activa; se usa para refrescar los datos que
  /// dependen del usuario cuando cambia entre invitado y sesión iniciada.
  String get identity => maybeWhen(
        authenticated: (user) => 'user:${user.id}',
        orElse: () => 'guest',
      );
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(dio: apiClient.dio, storage: storage);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  AuthNotifier({
    required AuthRepository repository,
    required FlutterSecureStorage storage,
  })  : _repository = repository,
        _storage = storage,
        super(const AuthState.initial()) {
    Future.microtask(() => checkAuth());
  }

  /// El interceptor HTTP avisa cuando el backend invalidó la sesión para que
  /// la interfaz deje de mostrar al usuario como conectado.
  void handleSessionExpired() {
    if (!mounted) return;
    state.maybeWhen(
      authenticated: (_) => state = const AuthState.unauthenticated(),
      orElse: () {},
    );
  }

  Future<void> checkAuth() async {
    state = const AuthState.loading();
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null || accessToken.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await _repository.getMe();
      state = AuthState.authenticated(user: user);
      NotificationService().registerToken();
    } catch (e) {
      // Un fallo de red NO debe destruir la sesión: sin internet el usuario
      // perdía su cuenta y tenía que volver a escribir sus credenciales.
      // Sólo cerramos sesión cuando el servidor rechaza el token.
      if (ApiError.isNetworkIssue(e)) {
        state = const AuthState.unauthenticated();
        return;
      }
      await logout();
    }
  }

  /// Reintenta recuperar la sesión guardada (usado al recuperar conexión).
  Future<void> retrySession() => checkAuth();

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final tokens = await _repository.login(email, password);
      await _storage.write(key: 'access_token', value: tokens.accessToken);
      await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
      final user = await _repository.getMe();
      state = AuthState.authenticated(user: user);
      NotificationService().registerToken();
    } catch (e) {
      state = AuthState.error(_handleError(e));
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = const AuthState.loading();
    try {
      // 1. Register account
      await _repository.register(email, password, fullName);
      // 2. Automatically log in after registration
      final tokens = await _repository.login(email, password);
      await _storage.write(key: 'access_token', value: tokens.accessToken);
      await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
      final user = await _repository.getMe();
      state = AuthState.authenticated(user: user);
      NotificationService().registerToken();
    } catch (e) {
      state = AuthState.error(_handleError(e));
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AuthState.loading();
    try {
      final tokens = await _repository.loginWithGoogle(idToken);
      await _storage.write(key: 'access_token', value: tokens.accessToken);
      await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
      final user = await _repository.getMe();
      state = AuthState.authenticated(user: user);
      NotificationService().registerToken();
    } catch (e) {
      state = AuthState.error(_handleError(e));
    }
  }

  Future<void> forgotPassword(String email) async {
    state = const AuthState.loading();
    try {
      await _repository.forgotPassword(email);
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(_handleError(e));
    }
  }

  String _handleError(dynamic e) {
    // Credenciales inválidas: el backend responde 401 con "No active account…",
    // que no le dice nada al usuario final.
    if (e is DioException && e.response?.statusCode == 401) {
      return 'Correo o contraseña incorrectos. Verifica tus datos e intenta de nuevo.';
    }
    return ApiError.message(
      e,
      fallback: 'No pudimos completar la operación. Intenta de nuevo.',
    );
  }

  /// Limpia un estado de error para que la pantalla vuelva a un estado usable.
  void clearError() {
    state.maybeWhen(
      error: (_) => state = const AuthState.unauthenticated(),
      orElse: () {},
    );
  }

  Future<void> loginAsGuest() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    state = const AuthState.guest();
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _repository.logout();
    } catch (_) {}
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    state = const AuthState.unauthenticated();
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
    String? bio,
    String? avatarFilePath,
  }) async {
    await state.maybeWhen(
      authenticated: (currentUser) async {
        state = const AuthState.loading();
        try {
          final updatedUser = await _repository.updateProfile(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            location: location,
            bio: bio,
            avatarFilePath: avatarFilePath,
          );
          state = AuthState.authenticated(user: updatedUser);
        } catch (e) {
          state = AuthState.authenticated(user: currentUser);
          rethrow;
        }
      },
      orElse: () async {},
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  final notifier = AuthNotifier(repository: repository, storage: storage);
  ref.watch(apiClientProvider).onSessionExpired = notifier.handleSessionExpired;
  return notifier;
});
