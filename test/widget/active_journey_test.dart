import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/features/active_journey/active_journey_screen.dart';
import 'package:railminder/providers/journey_providers.dart';

import '../support/station_dataset.dart';
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

  testWidgets('renders active journey, receives sample, and completes on tap',
      (tester) async {
    final bogor = harness.bogor;
    await harness.container
        .read(activeJourneyProvider.notifier)
        .startJourney(destination: bogor);

    await tester.pumpWidget(
      wrapWithScope(const ActiveJourneyScreen(), harness.container),
    );
    await tester.pump();

    expect(find.text('Bogor'), findsOneWidget);
    expect(find.text('Saya Sudah Turun'), findsOneWidget);
    expect(find.text('Hentikan Perjalanan'), findsOneWidget);

    // Send a location sample 1400m away
    final t0 = DateTime.now();
    harness.locations.controller.add(
      sampleAtDistance(bogor, 1400, timestamp: t0),
    );

    // Pump to process stream
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1.4 km'), findsOneWidget);

    // Tap "Saya Sudah Turun"
    await tester.tap(find.text('Saya Sudah Turun'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(harness.container.read(activeJourneyProvider), isNull);
  });
}
