import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/app_database.dart';
import '../data/models/journey.dart';
import '../data/models/user_settings.dart';
import '../data/repositories/journey_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/station_repository.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';

/// Bound in `main()` once platform plugins are ready.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider must be overridden'),
);

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('appDatabaseProvider must be overridden'),
);

/// Bound in `main()` after the bundled station dataset has been validated.
final stationRepositoryProvider = Provider<StationRepository>(
  (ref) => throw StateError('stationRepositoryProvider must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final journeyRepositoryProvider = Provider<JourneyStore>(
  (ref) => JourneyRepository(
    prefs: ref.watch(sharedPreferencesProvider),
    database: ref.watch(appDatabaseProvider),
  ),
);

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class SettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(UserSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setAlertDistance(int meters) =>
      update(state.copyWith(alertDistanceMeters: meters));

  Future<void> setVibration(bool enabled) =>
      update(state.copyWith(enableVibration: enabled));

  Future<void> setRepeatInterval(int minutes) =>
      update(state.copyWith(repeatIntervalMinutes: minutes));

  Future<void> setMaxRepeats(int repeats) =>
      update(state.copyWith(maxRepeats: repeats));
}

final settingsProvider = NotifierProvider<SettingsNotifier, UserSettings>(
  SettingsNotifier.new,
);

final historyProvider = FutureProvider<List<Journey>>(
  (ref) => ref.watch(journeyRepositoryProvider).getHistory(),
);

class AlreadyArrivedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final alreadyArrivedProvider =
    NotifierProvider<AlreadyArrivedNotifier, bool>(AlreadyArrivedNotifier.new);

class RouteMismatchNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final routeMismatchProvider =
    NotifierProvider<RouteMismatchNotifier, bool>(RouteMismatchNotifier.new);
