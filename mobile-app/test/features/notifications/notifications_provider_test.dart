import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_app/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:genesis_app/features/notifications/presentation/providers/notifications_provider.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  bool tokenRegistered = false;
  String? registeredToken;
  String? registeredDeviceType;

  @override
  Future<void> registerDeviceToken(String token, String deviceType) async {
    tokenRegistered = true;
    registeredToken = token;
    registeredDeviceType = deviceType;
  }
}

void main() {
  group('Notifications Providers Tests', () {
    late ProviderContainer container;
    late FakeNotificationsRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeNotificationsRepository();
      container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('registerDeviceToken calls repository register', () async {
      final repo = container.read(notificationsRepositoryProvider);
      await repo.registerDeviceToken('token123', 'ANDROID');
      expect(fakeRepository.tokenRegistered, isTrue);
      expect(fakeRepository.registeredToken, 'token123');
      expect(fakeRepository.registeredDeviceType, 'ANDROID');
    });
  });
}
