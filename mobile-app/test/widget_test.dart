import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_app/app/app.dart';

void main() {
  testWidgets('Smoke test loading GenesisApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GenesisApp(),
      ),
    );

    // Verify that we render something on splash screen
    expect(find.textContaining('GÉNESIS'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
