import 'package:dio/dio.dart';

/// Traduce cualquier error de red a un mensaje entendible por el usuario final.
///
/// Antes varias pantallas mostraban `Error: DioException [connection error]...`
/// directamente en un SnackBar.
class ApiError {
  /// Mensaje corto y en español listo para mostrar en pantalla.
  static String message(
    Object? error, {
    String fallback = 'Ocurrió un error inesperado. Intenta de nuevo.',
  }) {
    if (error is! DioException) return fallback;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'El servidor está tardando en responder. Revisa tu conexión e intenta de nuevo.';
      case DioExceptionType.connectionError:
        return 'No pudimos conectar con el servidor. Verifica tu conexión a internet.';
      case DioExceptionType.cancel:
        return 'La operación fue cancelada.';
      default:
        break;
    }

    final status = error.response?.statusCode;
    final detail = _extractDetail(error.response?.data);
    if (detail != null && detail.isNotEmpty) return detail;

    if (status == null) return fallback;
    if (status == 401) return 'Tu sesión expiró. Vuelve a iniciar sesión.';
    if (status == 403) return 'No tienes permisos para realizar esta acción.';
    if (status == 404) return 'No encontramos la información solicitada.';
    if (status == 429) return 'Demasiados intentos. Espera un momento e inténtalo otra vez.';
    if (status >= 500) return 'El servidor no está disponible en este momento. Intenta más tarde.';
    return fallback;
  }

  /// `true` cuando el backend rechazó la petición por sesión inválida.
  static bool isUnauthorized(Object? error) =>
      error is DioException && error.response?.statusCode == 401;

  /// `true` cuando el problema es de conectividad y no del servidor.
  static bool isNetworkIssue(Object? error) {
    if (error is! DioException) return false;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.type == DioExceptionType.unknown && error.response == null);
  }

  static String? _extractDetail(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final trimmed = data.trim();
      // El servidor puede devolver una página HTML de error: no sirve mostrarla.
      if (trimmed.isEmpty || trimmed.startsWith('<')) return null;
      return trimmed;
    }

    if (data is Map) {
      for (final key in ['detail', 'message', 'error', 'non_field_errors']) {
        final value = data[key];
        final parsed = _stringify(value);
        if (parsed != null) return parsed;
      }
      // Errores de validación por campo: `{"email": ["Ya existe"]}`
      final messages = <String>[];
      data.forEach((key, value) {
        final parsed = _stringify(value);
        if (parsed != null) messages.add(parsed);
      });
      if (messages.isNotEmpty) return messages.join('\n');
    }

    return null;
  }

  static String? _stringify(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is List) {
      final parts = value.map((e) => e?.toString().trim()).whereType<String>().where((e) => e.isNotEmpty);
      return parts.isEmpty ? null : parts.join(' ');
    }
    if (value is Map) {
      final parts = value.values.map((e) => _stringify(e)).whereType<String>();
      return parts.isEmpty ? null : parts.join(' ');
    }
    return value.toString();
  }
}
