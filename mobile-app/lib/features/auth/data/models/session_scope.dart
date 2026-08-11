/// Alcance de la sesión sobre las células, tal como lo describe `/auth/me/`.
///
/// El catálogo de permisos dice *qué* puede hacer alguien; esto dice *sobre
/// qué células*. Los dos juntos deciden qué se le ofrece en pantalla.
///
/// Importa distinguir dos cosas que se confunden con facilidad: un miembro
/// corriente **alcanza** su célula —por eso aparece en `cellIds`— pero no la
/// **gestiona**. Sin esa distinción, la sección de líder se le mostraría a
/// toda la congregación.
class SessionScope {
  /// Nivel declarado: `OWN_CELL`, `ASSIGNED_CELLS`, `CHURCH`…
  final String? level;
  final String? label;

  /// `true` para el pastorado: alcanza las células de toda la iglesia.
  final bool churchWide;

  /// Células que puede consultar. Vacío cuando `churchWide` es `true`, porque
  /// entonces el servidor no envía la lista: son todas.
  final List<int> cellIds;

  /// Células que lidera.
  final List<int> ledCellIds;

  /// Células que supervisa como coordinador.
  final List<int> coordinatedCellIds;

  const SessionScope({
    this.level,
    this.label,
    this.churchWide = false,
    this.cellIds = const [],
    this.ledCellIds = const [],
    this.coordinatedCellIds = const [],
  });

  factory SessionScope.fromJson(Map<String, dynamic> json) => SessionScope(
        level: json['scope'] as String?,
        label: json['scope_label'] as String?,
        churchWide: json['church_wide'] as bool? ?? false,
        cellIds: _ints(json['cell_ids']),
        ledCellIds: _ints(json['leads_cell_ids']),
        coordinatedCellIds: _ints(json['coordinates_cell_ids']),
      );

  Map<String, dynamic> toJson() => {
        'scope': level,
        'scope_label': label,
        'church_wide': churchWide,
        'cell_ids': cellIds,
        'leads_cell_ids': ledCellIds,
        'coordinates_cell_ids': coordinatedCellIds,
      };

  /// `true` si tiene alguna célula a su cargo: es la condición para que la
  /// sección de gestión exista para esta persona.
  bool get managesAnyCell =>
      churchWide || ledCellIds.isNotEmpty || coordinatedCellIds.isNotEmpty;

  /// `true` si puede registrar y modificar datos de esa célula.
  ///
  /// Reproduce la misma regla que aplica el servidor en `can_manage_cell`. Aquí
  /// sólo sirve para no ofrecer botones que van a ser rechazados; la
  /// autorización de verdad la hace siempre el backend.
  bool canManage(int cellId) =>
      churchWide || ledCellIds.contains(cellId) || coordinatedCellIds.contains(cellId);

  /// `true` si puede consultarla, aunque no pueda escribir en ella.
  bool canReach(int cellId) => churchWide || cellIds.contains(cellId);
}

List<int> _ints(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e is int ? e : int.tryParse('$e'))
      .whereType<int>()
      .toList(growable: false);
}
