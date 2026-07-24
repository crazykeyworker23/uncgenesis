import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dio/dio.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/notifications/notification_service.dart';
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

  Future<void> checkAuth() async {
    state = const AuthState.loading();
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken != null) {
        final user = await _repository.getMe();
        state = AuthState.authenticated(user: user);
        NotificationService().registerToken();
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      // In case profile loading failed (e.g. token expired and refresh failed), clear session
      await logout();
    }
  }

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
    if (e is DioException) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          final messages = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              messages.add('$key: ${value.join(", ")}');
            } else if (value is Map) {
              value.forEach((k, v) {
                messages.add('$k: $v');
              });
            } else if (value is String) {
              messages.add('$key: $value');
            } else {
              messages.add('$key: ${value.toString()}');
            }
          });
          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        } else if (data is String && data.isNotEmpty) {
          return data;
        }
      }
      return e.message ?? e.toString();
    }
    return e.toString();
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
  return AuthNotifier(repository: repository, storage: storage);
});
