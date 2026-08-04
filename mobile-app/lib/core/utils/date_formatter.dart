/// Formateo de fechas en español sin dependencias externas.
///
/// El backend entrega fechas ISO-8601 (`2026-08-04T19:00:00Z`) y, en algunos
/// modelos, sólo la fecha (`2026-08-04`). Antes se mostraban en crudo y varias
/// pantallas hacían `split('T')[1]`, lo que reventaba con RangeError cuando el
/// valor no traía hora.
class DateFormatter {
  static const List<String> _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static const List<String> _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  /// Convierte el valor recibido del API a `DateTime` local. Devuelve `null`
  /// cuando el texto es vacío o no se puede interpretar.
  static DateTime? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  /// `4 de agosto de 2026`
  static String fullDate(String? raw, {String fallback = 'Fecha por confirmar'}) {
    final date = parse(raw);
    if (date == null) return fallback;
    return '${date.day} de ${_months[date.month - 1]} de ${date.year}';
  }

  /// `Martes 4 de agosto`
  static String longDate(String? raw, {String fallback = 'Fecha por confirmar'}) {
    final date = parse(raw);
    if (date == null) return fallback;
    final weekday = _weekdays[date.weekday - 1];
    final capitalized = weekday[0].toUpperCase() + weekday.substring(1);
    return '$capitalized ${date.day} de ${_months[date.month - 1]}';
  }

  /// `04/08/2026`
  static String shortDate(String? raw, {String fallback = 'Sin fecha'}) {
    final date = parse(raw);
    if (date == null) return fallback;
    return '${_two(date.day)}/${_two(date.month)}/${date.year}';
  }

  /// `07:30 PM`. Devuelve `null` cuando el valor no incluye hora.
  static String? time(String? raw) {
    final date = parse(raw);
    if (date == null) return null;
    // Un valor tipo `2026-08-04` se interpreta como medianoche: no hay hora útil.
    if (!(raw!.contains('T') || raw.contains(' '))) return null;
    final hour24 = date.hour;
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return '${_two(hour12)}:${_two(date.minute)} $suffix';
  }

  /// `4 de agosto de 2026 · 07:30 PM`
  static String dateAndTime(String? raw, {String fallback = 'Fecha por confirmar'}) {
    final date = parse(raw);
    if (date == null) return fallback;
    final hour = time(raw);
    final base = fullDate(raw, fallback: fallback);
    return hour == null ? base : '$base · $hour';
  }

  /// `Hace 5 min`, `Ayer`, `04/08/2026`
  static String relative(String? raw, {String fallback = ''}) {
    final date = parse(raw);
    if (date == null) return fallback;
    final diff = DateTime.now().difference(date);

    if (diff.isNegative) return shortDate(raw, fallback: fallback);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return shortDate(raw, fallback: fallback);
  }

  /// Recorta una hora del backend (`19:00:00`) a `19:00` sin reventar cuando
  /// llega vacía o con un formato inesperado.
  static String clockTime(dynamic raw, {String fallback = ''}) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return fallback;
    final parts = text.split(':');
    if (parts.length < 2) return text;
    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
