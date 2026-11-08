import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/features/settings/settings_screen.dart';
import 'package:railminder/providers/providers.dart';

import '../support/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestHarness harness;

  setUp(() async {
    harness = await TestHarness.create();
  });

  tearDown(() async {
    await harness.dispose();
  });

  testWidgets('alert threshold can be changed to 2 km', (tester) async {
    await tester.pumpWidget(
      wrapWithScope(const SettingsScreen(), harness.container),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 km'), findsWidgets);
    expect(find.text('2 km'), findsWidgets);

    await tester.tap(find.text('2 km').last);
    await tester.pumpAndSettle();

    expect(harness.container.read(settingsProvider).alertDistanceMeters, 2000);
  });

  testWidgets('vibration toggle persists the change', (tester) async {
    await tester.pumpWidget(
      wrapWithScope(const SettingsScreen(), harness.container),
    );
    await tester.pumpAndSettle();

    expect(harness.container.read(settingsProvider).enableVibration, isTrue);

    await tester.tap(find.text('Aktifkan getaran'));
    await tester.pumpAndSettle();

    expect(harness.container.read(settingsProvider).enableVibration, isFalse);
  });

  testWidgets('repeat interval dropdown updates settings', (tester) async {
    await tester.pumpWidget(
      wrapWithScope(const SettingsScreen(), harness.container),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('3 menit').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('5 menit').last);
    await tester.pumpAndSettle();

    expect(
      harness.container.read(settingsProvider).repeatIntervalMinutes,
      5,
    );
  });
}
