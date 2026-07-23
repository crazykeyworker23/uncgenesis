import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required int id,
    required String email,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'full_name') required String fullName,
    String? phone,
    String? location,
    String? bio,
    required String status,
    String? avatar,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final first = json['first_name'] as String? ?? '';
    final last = json['last_name'] as String? ?? '';
    final combined = '$first $last'.trim();
    final email = json['email'] as String? ?? '';

    return UserModel(
      id: json['id'] as int? ?? 0,
      email: email,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String? ?? (combined.isNotEmpty ? combined : email),
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'full_name': fullName,
    'phone': phone,
    'location': location,
    'bio': bio,
    'status': status,
    'avatar': avatar,
  };
}
