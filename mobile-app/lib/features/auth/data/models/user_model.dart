import 'package:freezed_annotation/freezed_annotation.dart';

import 'session_scope.dart';

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

    // El servidor ya venía enviando estos tres campos en /auth/me/; la app
    // simplemente los descartaba. Sin ellos no hay forma de saber que quien
    // inició sesión lidera una célula, y la sección de líder no podía existir.
    @Default(<String>[]) List<String> roles,
    @Default(<String>[]) List<String> permissions,
    @JsonKey(name: 'leads_cells') @Default(0) int leadsCells,
    @Default(SessionScope()) SessionScope scope,
  }) = _UserModel;

  /// `true` cuando la persona tiene alguna célula a su cargo.
  ///
  /// Se mira la responsabilidad, no el rol: el pastor y el coordinador también
  /// supervisan células sin ser `CELL_LEADER`, y a ellos la sección les
  /// corresponde igual. Y al revés: pertenecer a una célula no basta, o la
  /// gestión se le ofrecería a toda la congregación.
  bool get leadsAnyCell => scope.managesAnyCell || leadsCells > 0;

  /// `true` si el rol tiene concedido ese permiso del catálogo.
  ///
  /// Sirve para no ofrecer en pantalla lo que el servidor va a rechazar: es
  /// una cortesía de la interfaz, nunca la autorización, que siempre la
  /// resuelve el backend.
  bool can(String permission) => permissions.contains(permission);

  /// `true` si tiene alguno de los permisos indicados.
  bool canAny(List<String> codenames) => codenames.any(permissions.contains);

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
      roles: _stringList(json['roles']),
      permissions: _stringList(json['permissions']),
      leadsCells: json['leads_cells'] as int? ?? 0,
      scope: json['scope'] is Map
          ? SessionScope.fromJson(Map<String, dynamic>.from(json['scope'] as Map))
          : const SessionScope(),
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
    'roles': roles,
    'permissions': permissions,
    'leads_cells': leadsCells,
    'scope': scope.toJson(),
  };
}

/// Listas de texto que llegan del servidor, tolerando ausencia o nulos.
///
/// El perfil también se actualiza con PATCH /auth/me/, y una respuesta parcial
/// no debe dejar a la persona sin sus permisos.
List<String> _stringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value.map((e) => e?.toString()).whereType<String>().toList(growable: false);
}
