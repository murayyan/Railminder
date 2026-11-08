import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:railminder/app.dart';
import 'package:railminder/data/local/station_asset_loader.dart';
import 'package:railminder/data/repositories/journey_repository.dart';
import 'package:railminder/data/repositories/station_repository.dart';
import 'package:railminder/providers/journey_providers.dart';
import 'package:railminder/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/station_dataset.dart';
import '../test/support/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('start journey, approach Bogor, alert, confirm arrival',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final stationRepository = StationRepository(loader: StationAssetLoader());
    await stationRepository.initialize();

    final notifications = FakeNotificationService();
    final permissions = FakePermissionService();
    final locations = FakeLocationService();
    final journeys = InMemoryJourneyStore();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        stationRepositoryProvider.overrideWithValue(stationRepository),
        journeyRepositoryProvider.overrideWithValue(journeys),
        notificationServiceProvider.overrideWithValue(notifications),
        permissionServiceProvider.overrideWithValue(permissions),
        locationServiceProvider.overrideWithValue(locations),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RailminderApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Start a journey
    await tester.tap(find.text('Mulai Perjalanan'));
    await tester.pumpAndSettle();

    // Search and choose Bogor
    await tester.enterText(find.byType(TextField), 'Bogor');
    await tester.pumpAndSettle();
    // Tap the list row, not the search field that also contains "Bogor".
    await tester.tap(find.widgetWithText(ListTile, 'Bogor').first);
    // pumpAndSettle would never settle here: the active journey keeps a
    // periodic health timer running, so pump a bounded number of frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Perjalanan Aktif'), findsOneWidget);

    final bogor = stationRepository.getStationById('BOO')!;
    final now = DateTime.now();

    // Far away first so the engine arms itself
    locations.controller.add(
      sampleAtDistance(bogor, 6000, timestamp: now),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Inside the 1500 m alert radius
    locations.controller.add(
      sampleAtDistance(bogor, 1400, timestamp: now.add(const Duration(minutes: 4))),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(notifications.alerts.length, 1);
    expect(notifications.alerts.single.stationId, 'BOO');
    expect(notifications.alerts.single.isRepeat, isFalse);

    // Confirm arrival
    await tester.tap(find.text('Saya Sudah Turun'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(activeJourneyProvider), isNull);

    final history = await journeys.getHistory();
    expect(history.length, 1);
    expect(history.single.destinationStationId, 'BOO');

    container.dispose();
    await locations.controller.close();
  });
}
