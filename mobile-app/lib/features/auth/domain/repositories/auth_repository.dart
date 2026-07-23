import '../../data/models/user_model.dart';
import '../../data/models/auth_token_model.dart';

abstract class AuthRepository {
  Future<AuthTokenModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String fullName);
  Future<AuthTokenModel> loginWithGoogle(String idToken);
  Future<void> forgotPassword(String email);
  Future<UserModel> getMe();
  Future<void> logout();
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
    String? bio,
    String? avatarFilePath,
  });
}
