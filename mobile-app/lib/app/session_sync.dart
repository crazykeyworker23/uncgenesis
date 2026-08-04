import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/events/presentation/providers/events_provider.dart';
import '../features/notifications/presentation/providers/notifications_provider.dart';
import '../features/requests/presentation/providers/requests_provider.dart';

/// Mantiene sincronizados los datos que dependen de quién está usando la app.
///
/// Antes, al iniciar o cerrar sesión, las listas seguían mostrando la
/// información cargada con la sesión anterior: un evento seguía marcado como
/// "INSCRITO" después de cerrar sesión, y tras iniciar sesión los eventos
/// cargados como invitado nunca mostraban las inscripciones reales.
class SessionSync {
  SessionSync(this._ref) {
    _identity = _ref.read(authProvider).identity;
    _ref.listen<AuthState>(authProvider, (previous, next) {
      // Ignoramos los estados intermedios de carga para no recargar de más.
      if (next.isLoading) return;
      final nextIdentity = next.identity;
      if (nextIdentity == _identity) return;
      _identity = nextIdentity;
      refreshUserScopedData();
    });
  }

  final Ref _ref;
  String _identity = 'guest';

  /// Vuelve a pedir al backend todo lo que cambia según la sesión activa.
  void refreshUserScopedData() {
    _ref.invalidate(eventDetailProvider);
    _ref.invalidate(cellStatusProvider);
    _ref.read(eventsProvider.notifier).refresh();
    _ref.read(localNotificationsProvider.notifier).resetForSessionChange();
  }
}

/// Se instancia una sola vez al arrancar la app (ver `GenesisApp`).
final sessionSyncProvider = Provider<SessionSync>((ref) => SessionSync(ref));
