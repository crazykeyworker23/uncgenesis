import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_app/features/leader/data/models/leader_models.dart';
import 'package:genesis_app/features/leader/presentation/providers/leader_providers.dart';

LeaderCell _cell(int id, String name) => LeaderCell(
      id: id,
      name: name,
      slug: name.toLowerCase(),
      meetingDay: 'MONDAY',
      meetingTime: '19:00:00',
      address: 'Calle $id',
    );

ProviderContainer _containerWith(MyCells response) {
  return ProviderContainer(
    overrides: [
      myCellsProvider.overrideWith((ref) async => response),
    ],
  );
}

void main() {
  group('Célula activa', () {
    test('empieza por una que se pueda gestionar, no por la primera que se alcanza', () async {
      // El coordinador supervisa la 7 y además pertenece a la 3. Sin esto
      // abriría la sección sobre un grupo en el que no puede tocar nada.
      final container = _containerWith(
        MyCells(
          cells: [_cell(3, 'Ajena'), _cell(7, 'Supervisada')],
          scope: const SessionScope(
            level: 'ASSIGNED_CELLS',
            cellIds: [3, 7],
            coordinatedCellIds: [7],
          ),
        ),
      );
      addTearDown(container.dispose);

      await container.read(myCellsProvider.future);

      expect(container.read(activeCellProvider)?.id, 7);
    });

    test('respeta la célula que se eligió a mano', () async {
      final container = _containerWith(
        MyCells(
          cells: [_cell(3, 'Norte'), _cell(7, 'Sur')],
          scope: const SessionScope(churchWide: true),
        ),
      );
      addTearDown(container.dispose);

      await container.read(myCellsProvider.future);
      container.read(selectedCellIdProvider.notifier).state = 3;

      expect(container.read(activeCellProvider)?.id, 3);
    });

    test('una selección que quedó fuera de alcance no deja la pantalla en blanco', () async {
      // Pasa cuando cambia el rol o se reasigna la célula con la app abierta.
      final container = _containerWith(
        MyCells(
          cells: [_cell(7, 'Sur')],
          scope: const SessionScope(ledCellIds: [7], cellIds: [7]),
        ),
      );
      addTearDown(container.dispose);

      await container.read(myCellsProvider.future);
      container.read(selectedCellIdProvider.notifier).state = 999;

      expect(container.read(activeCellProvider)?.id, 7);
    });

    test('sin células a cargo no hay célula activa', () async {
      final container = _containerWith(const MyCells());
      addTearDown(container.dispose);

      await container.read(myCellsProvider.future);

      expect(container.read(activeCellProvider), isNull);
    });
  });

  group('Reunión que espera lista', () {
    // Es la que abre el atajo «Pasar lista» del inicio y la que anuncia el
    // bloque de pendientes: los dos hablan de la misma, así que sale de un
    // solo sitio.

    CellMeeting meeting(int id, String date, {bool marcada = false}) => CellMeeting(
          id: id,
          cellId: 7,
          cellName: 'Norte',
          date: date,
          attendances: marcada
              ? [
                  const AttendanceEntry(
                    id: 1,
                    member: PersonBrief(id: 30, fullName: 'Ana', email: 'a@x.org'),
                    status: AttendanceStatus.present,
                    statusDisplay: 'Asistió',
                  ),
                ]
              : const [],
        );

    ProviderContainer containerCon(List<CellMeeting> meetings) {
      return ProviderContainer(
        overrides: [
          cellMeetingsProvider(7).overrideWith(
            (ref) => PagedListNotifier<CellMeeting>((_) async =>
                Paged<CellMeeting>(items: meetings, count: meetings.length)),
          ),
        ],
      );
    }

    test('es la más reciente sin marcar', () async {
      // Llegan de más nueva a más antigua; la del 11 ya está pasada.
      final container = containerCon([
        meeting(2, '2026-08-11', marcada: true),
        meeting(1, '2026-08-04'),
      ]);
      addTearDown(container.dispose);
      // Los providers son perezosos: hay que leer la lista para que se
      // construya, y sólo entonces esperar a que cargue.
      container.read(cellMeetingsProvider(7));
      await pumpEventQueue();

      expect(container.read(pendingRollCallProvider(7))?.id, 1);
    });

    test('no hay ninguna cuando están todas al día', () async {
      final container = containerCon([meeting(2, '2026-08-11', marcada: true)]);
      addTearDown(container.dispose);
      // Los providers son perezosos: hay que leer la lista para que se
      // construya, y sólo entonces esperar a que cargue.
      container.read(cellMeetingsProvider(7));
      await pumpEventQueue();

      expect(container.read(pendingRollCallProvider(7)), isNull);
    });

    test('tampoco la hay si aún no se registró ninguna reunión', () async {
      final container = containerCon([]);
      addTearDown(container.dispose);
      // Los providers son perezosos: hay que leer la lista para que se
      // construya, y sólo entonces esperar a que cargue.
      container.read(cellMeetingsProvider(7));
      await pumpEventQueue();

      expect(container.read(pendingRollCallProvider(7)), isNull);
    });
  });

  group('Listas paginadas', () {
    Paged<String> page(List<String> items, {bool hasMore = false}) =>
        Paged<String>(items: items, count: items.length, hasMore: hasMore);

    test('acumula las páginas en lugar de reemplazarlas', () async {
      var requested = <int>[];
      final notifier = PagedListNotifier<String>((p) async {
        requested.add(p);
        return p == 1 ? page(['a', 'b'], hasMore: true) : page(['c']);
      });
      addTearDown(notifier.dispose);

      await pumpEventQueue();
      expect(notifier.state.items, ['a', 'b']);
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();
      expect(notifier.state.items, ['a', 'b', 'c']);
      expect(notifier.state.hasMore, isFalse);
      expect(requested, [1, 2]);
    });

    test('no vuelve a pedir cuando ya no quedan más', () async {
      var calls = 0;
      final notifier = PagedListNotifier<String>((p) async {
        calls++;
        return page(['único']);
      });
      addTearDown(notifier.dispose);

      await pumpEventQueue();
      await notifier.loadMore();
      await notifier.loadMore();

      expect(calls, 1);
    });

    test('refrescar vuelve a empezar por la primera página', () async {
      var requested = <int>[];
      final notifier = PagedListNotifier<String>((p) async {
        requested.add(p);
        return page(['a'], hasMore: true);
      });
      addTearDown(notifier.dispose);

      await pumpEventQueue();
      await notifier.refresh();

      expect(requested, [1, 1]);
      expect(notifier.state.items, ['a']);
    });

    test('un fallo se cuenta en español y no como excepción', () async {
      final notifier = PagedListNotifier<String>(
        (p) async => throw Exception('boom'),
        fallbackError: 'No pudimos cargar las reuniones.',
      );
      addTearDown(notifier.dispose);

      await pumpEventQueue();

      expect(notifier.state.errorMessage, 'No pudimos cargar las reuniones.');
      expect(notifier.state.isLoading, isFalse);
      // Sin esto la lista intentaría pedir la página siguiente sin descanso.
      expect(notifier.state.hasMore, isFalse);
    });

    test('una lista vacía se distingue de una que todavía carga', () async {
      final notifier = PagedListNotifier<String>((p) async => page([]));
      addTearDown(notifier.dispose);

      expect(notifier.state.isEmpty, isFalse);
      await pumpEventQueue();
      expect(notifier.state.isEmpty, isTrue);
    });
  });
}
