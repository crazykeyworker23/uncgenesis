import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genesis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:genesis_app/features/auth/data/models/user_model.dart';
import 'package:genesis_app/features/auth/data/models/auth_token_model.dart';
import 'package:genesis_app/features/auth/presentation/providers/auth_provider.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldFail = false;
  UserModel? mockUser;
  AuthTokenModel? mockTokens;

  @override
  Future<AuthTokenModel> login(String email, String password) async {
    if (shouldFail) throw Exception('Login Failed');
    return mockTokens ?? const AuthTokenModel(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<UserModel> register(String email, String password, String fullName) async {
    if (shouldFail) throw Exception('Register Failed');
    return mockUser ?? const UserModel(id: 1, email: 't@t.com', fullName: 'Test', status: 'ACTIVE');
  }

  @override
  Future<AuthTokenModel> loginWithGoogle(String idToken) async {
    return const AuthTokenModel(accessToken: 'access', refreshToken: 'refresh');
  }

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<UserModel> getMe() async {
    if (shouldFail) throw Exception('Profile Failed');
    return mockUser ?? const UserModel(id: 1, email: 't@t.com', fullName: 'Test', status: 'ACTIVE');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
    String? bio,
    String? avatarFilePath,
  }) async {
    return mockUser ?? const UserModel(id: 1, email: 't@t.com', fullName: 'Test', status: 'ACTIVE');
  }
}

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
  }) async {
    return data[key];
  }

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
    data[key] = value ?? '';
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

void main() {
  group('AuthNotifier Tests', () {
    late FakeAuthRepository repository;
    late FakeSecureStorage storage;
    late AuthNotifier notifier;

    setUp(() {
      repository = FakeAuthRepository();
      storage = FakeSecureStorage();
      notifier = AuthNotifier(repository: repository, storage: storage);
    });

    test('initial state is unauthenticated when no token is present', () async {
      await notifier.checkAuth();
      expect(notifier.state, const AuthState.unauthenticated());
    });

    test('login success sets state to authenticated', () async {
      await notifier.login('test@test.com', 'password');
      expect(
        notifier.state,
        const AuthState.authenticated(
          user: UserModel(id: 1, email: 't@t.com', fullName: 'Test', status: 'ACTIVE'),
        ),
      );
      expect(storage.data['access_token'], 'access');
      expect(storage.data['refresh_token'], 'refresh');
    });

    test('login failure sets a user friendly error message', () async {
      repository.shouldFail = true;
      await notifier.login('test@test.com', 'password');

      final message = notifier.state.maybeWhen(error: (msg) => msg, orElse: () => '');
      expect(message, isNotEmpty);
      // El detalle técnico de la excepción no debe llegar a la pantalla.
      expect(message, isNot(contains('Exception')));
      expect(message, isNot(contains('Login Failed')));
    });

    test('guest login sets state to guest', () async {
      await notifier.loginAsGuest();
      expect(notifier.state, const AuthState.guest());
    });

    test('logout clears tokens and sets state to unauthenticated', () async {
      storage.data['access_token'] = 'some_token';
      await notifier.logout();
      expect(notifier.state, const AuthState.unauthenticated());
      expect(storage.data.containsKey('access_token'), isFalse);
    });
  });
}
