import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local/app_database.dart';
import 'data/repositories/station_repository.dart';
import 'providers/journey_providers.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id');

  final prefs = await SharedPreferences.getInstance();
  final database = await AppDatabase.open();

  final stationRepository = StationRepository();
  await stationRepository.initialize();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(database),
      stationRepositoryProvider.overrideWithValue(stationRepository),
    ],
  );

  final settings = container.read(settingsProvider);

  await container.read(notificationServiceProvider).initialize(
    onTap: (_) {},
    onAction: (actionId, payload) {
      container
          .read(activeJourneyProvider.notifier)
          .handleNotificationAction(actionId);
    },
    enableVibration: settings.enableVibration,
  );

  // Restoring the active journey keeps alerts alive across app restarts.
  container.read(activeJourneyProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RailminderApp(),
    ),
  );
}
