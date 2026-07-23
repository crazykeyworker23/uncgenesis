import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_app/features/cells/domain/repositories/cells_repository.dart';
import 'package:genesis_app/features/cells/data/models/cell_model.dart';
import 'package:genesis_app/features/cells/presentation/providers/cells_provider.dart';

class FakeCellsRepository implements CellsRepository {
  @override
  Future<List<CellGroupModel>> getCells({
    required int page,
    String? searchQuery,
    String? meetingDay,
  }) async {
    return [
      const CellGroupModel(
        id: 1,
        name: 'Celula Test 1',
        slug: 'celula-test-1',
        meetingDay: 'WEDNESDAY',
        meetingTime: '20:00:00',
        address: 'Calle Test 123',
        status: 'ACTIVE',
      )
    ];
  }

  @override
  Future<CellGroupModel> getCellDetail(String slug) async {
    return const CellGroupModel(
      id: 1,
      name: 'Celula Test Detail',
      slug: 'celula-test-1',
      meetingDay: 'WEDNESDAY',
      meetingTime: '20:00:00',
      address: 'Calle Test 123',
      status: 'ACTIVE',
      description: 'Desc',
    );
  }
}

void main() {
  group('Cells Providers Tests', () {
    late ProviderContainer container;
    late FakeCellsRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeCellsRepository();
      container = ProviderContainer(
        overrides: [
          cellsRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('cellsProvider loadNextPage loads cells successfully', () async {
      final notifier = container.read(cellsProvider.notifier);
      await notifier.loadNextPage();
      
      final state = container.read(cellsProvider);
      expect(state.cells.length, 1);
      expect(state.cells.first.name, 'Celula Test 1');
      expect(state.page, 2);
    });

    test('cellDetailProvider loads cell detail successfully', () async {
      final detail = await container.read(cellDetailProvider('celula-test-1').future);
      expect(detail.name, 'Celula Test Detail');
      expect(detail.description, 'Desc');
    });
  });
}
