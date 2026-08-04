import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipo de solicitud enviada desde la app.
enum SubmittedRequestType { prayer, visitor }

/// Registro local de una solicitud enviada.
///
/// El backend sólo expone el listado de solicitudes a usuarios con permisos
/// administrativos, por lo que un miembro (o un invitado) no puede consultar lo
/// que envió. Guardamos un historial en el dispositivo para que "Mis
/// Solicitudes" funcione en ambos modos.
class SubmittedRequest {
  final String id;
  final SubmittedRequestType type;
  final String subject;
  final String detail;
  final String sentAt;
  final bool isAnonymous;

  const SubmittedRequest({
    required this.id,
    required this.type,
    required this.subject,
    required this.detail,
    required this.sentAt,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'subject': subject,
        'detail': detail,
        'sentAt': sentAt,
        'isAnonymous': isAnonymous,
      };

  factory SubmittedRequest.fromJson(Map<String, dynamic> json) => SubmittedRequest(
        id: json['id']?.toString() ?? '',
        type: json['type'] == SubmittedRequestType.visitor.name
            ? SubmittedRequestType.visitor
            : SubmittedRequestType.prayer,
        subject: json['subject']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        sentAt: json['sentAt']?.toString() ?? '',
        isAnonymous: json['isAnonymous'] == true,
      );

  String get typeLabel =>
      type == SubmittedRequestType.prayer ? 'Petición de oración' : 'Solicitud de visita / información';
}

class SubmittedRequestsNotifier extends StateNotifier<List<SubmittedRequest>> {
  static const _key = 'submitted_requests_history';
  static const _maxItems = 50;

  SubmittedRequestsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      state = raw
          .map((item) {
            try {
              return SubmittedRequest.fromJson(json.decode(item) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<SubmittedRequest>()
          .toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _persist(List<SubmittedRequest> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.map((e) => json.encode(e.toJson())).toList());
  }

  Future<void> add({
    required SubmittedRequestType type,
    required String subject,
    required String detail,
    bool isAnonymous = false,
  }) async {
    final entry = SubmittedRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      subject: subject,
      detail: detail,
      sentAt: DateTime.now().toIso8601String(),
      isAnonymous: isAnonymous,
    );
    final updated = [entry, ...state].take(_maxItems).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> remove(String id) async {
    final updated = state.where((e) => e.id != id).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final submittedRequestsProvider =
    StateNotifierProvider<SubmittedRequestsNotifier, List<SubmittedRequest>>((ref) {
  return SubmittedRequestsNotifier();
});
