import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/auth_token_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  @override
  Future<AuthTokenModel> login(String email, String password) async {
    final response = await _dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    return AuthTokenModel.fromJson(response.data);
  }

  @override
  Future<UserModel> register(String email, String password, String fullName) async {
    final parts = fullName.trim().split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final response = await _dio.post('/auth/register/', data: {
      'email': email,
      'password': password,
      'password_confirm': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone': '',
    });
    return UserModel.fromJson(response.data);
  }

  @override
  Future<AuthTokenModel> loginWithGoogle(String idToken) async {
    final response = await _dio.post('/auth/google/', data: {
      'id_token': idToken,
    });
    return AuthTokenModel.fromJson(response.data);
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password/', data: {
      'email': email,
    });
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _dio.get('/auth/me/');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        await _dio.post('/auth/logout/', data: {
          'refresh': refreshToken,
        });
      } catch (_) {
        // Suppress API logout failures to guarantee client side cleanup
      }
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? location,
    String? bio,
    String? avatarFilePath,
  }) async {
    final Map<String, dynamic> data = {};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (location != null) data['location'] = location;
    if (bio != null) data['bio'] = bio;

    if (avatarFilePath != null && avatarFilePath.isNotEmpty) {
      data['avatar'] = await MultipartFile.fromFile(
        avatarFilePath,
        filename: avatarFilePath.split('/').last,
      );
    }

    final formData = FormData.fromMap(data);
    final response = await _dio.patch('/auth/me/', data: formData);
    return UserModel.fromJson(response.data);
  }
}
