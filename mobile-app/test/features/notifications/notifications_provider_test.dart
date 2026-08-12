import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

LocalNotification _notification({
  required String id,
  bool isRead = false,
  bool sentByMe = false,
}) {
  return LocalNotification(
    id: id,
    title: 'Aviso $id',
    body: 'Cuerpo',
    receivedAt: '2026-08-12T10:00:00Z',
    isRead: isRead,
    sentByMe: sentByMe,
  );
}

Future<ProviderContainer> _containerWith(List<LocalNotification> stored) async {
  SharedPreferences.setMockInitialValues({
    'local_push_notifications': stored.map((n) => json.encode(n.toJson())).toList(),
  });

  final container = ProviderContainer();
  // Los providers son perezosos: hay que leerlo para que se construya, y sólo
  // entonces esperar a que termine de leer el almacenamiento local.
  container.read(localNotificationsProvider);
  await pumpEventQueue();
  return container;
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('Constancia de lo enviado', () {
    test('la marca sobrevive al guardado local', () {
      final original = _notification(id: '1', sentByMe: true);

      final revivida = LocalNotification.fromJson(json.decode(json.encode(original.toJson())));

      expect(revivida.sentByMe, isTrue);
      expect(revivida.id, '1');
    });

    test('un historial antiguo, sin la marca, se lee como recibido', () {
      // Quien ya tenía avisos guardados antes de este cambio no debe perderlos
      // ni verlos convertidos en propios.
      final antigua = LocalNotification.fromJson({
        'id': '9',
        'title': 'De antes',
        'body': 'x',
        'receivedAt': '2026-08-01T10:00:00Z',
        'isRead': false,
      });

      expect(antigua.sentByMe, isFalse);
    });
  });

  group('Contador de avisos sin leer', () {
    test('no cuenta lo que uno mismo envió', () async {
      // El líder manda un recordatorio a su célula: aparece en su listado como
      // constancia, pero no es algo que tenga que leer.
      final container = await _containerWith([
        _notification(id: '1', sentByMe: true),
      ]);
      addTearDown(container.dispose);

      expect(container.read(localNotificationsProvider).length, 1);
      expect(container.read(unreadNotificationsCountProvider), 0);
    });

    test('sí cuenta lo que llega de fuera sin leer', () async {
      final container = await _containerWith([
        _notification(id: '1', sentByMe: true),
        _notification(id: '2'),
        _notification(id: '3'),
        _notification(id: '4', isRead: true),
      ]);
      addTearDown(container.dispose);

      expect(container.read(unreadNotificationsCountProvider), 2);
    });

    test('sin nada guardado el contador es cero', () async {
      final container = await _containerWith([]);
      addTearDown(container.dispose);

      expect(container.read(unreadNotificationsCountProvider), 0);
    });
  });
}
