import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_app/features/requests/domain/repositories/requests_repository.dart';
import 'package:genesis_app/features/requests/data/models/requests_model.dart';
import 'package:genesis_app/features/requests/presentation/providers/requests_provider.dart';

class FakeRequestsRepository implements RequestsRepository {
  bool prayerSubmitted = false;
  bool visitorSubmitted = false;

  @override
  Future<void> submitPrayerRequest(PrayerRequestModel request) async {
    prayerSubmitted = true;
  }

  @override
  Future<void> submitVisitorRequest(VisitorRequestModel request) async {
    visitorSubmitted = true;
  }
}

void main() {
  group('Requests Providers Tests', () {
    late ProviderContainer container;
    late FakeRequestsRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeRequestsRepository();
      container = ProviderContainer(
        overrides: [
          requestsRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('submitPrayerRequest calls repository submit', () async {
      final repo = container.read(requestsRepositoryProvider);
      await repo.submitPrayerRequest(const PrayerRequestModel(
        requesterName: 'Juan',
        subject: 'Oracion',
        description: 'Por sanidad',
        isAnonymous: false,
      ));
      expect(fakeRepository.prayerSubmitted, isTrue);
    });

    test('submitVisitorRequest calls repository submit', () async {
      final repo = container.read(requestsRepositoryProvider);
      await repo.submitVisitorRequest(const VisitorRequestModel(
        fullName: 'Juan',
        ageRange: 'YOUTH',
        howDidYouFindUs: 'WEBSITE',
        message: 'Info',
        preferredContact: 'WHATSAPP',
      ));
      expect(fakeRepository.visitorSubmitted, isTrue);
    });
  });
}
