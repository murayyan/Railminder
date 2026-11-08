import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/data/local/app_database.dart';
import 'package:railminder/data/models/alert_event.dart';
import 'package:railminder/data/models/engine_progress.dart';
import 'package:railminder/data/models/enums.dart';
import 'package:railminder/data/models/journey.dart';
import 'package:railminder/data/repositories/journey_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();

  late AppDatabase database;
  late JourneyRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = JourneyRepository(prefs: prefs, database: database);
  });

  tearDown(() async {
    await database.close();
  });

  Journey buildJourney({String id = 'j1'}) => Journey(
    id: id,
    destinationStationId: 'BOO',
    destinationStationName: 'Bogor',
    originStationId: 'JAKK',
    startedAt: DateTime(2026, 11, 8, 9, 0),
    completedAt: DateTime(2026, 11, 8, 10, 15),
    status: JourneyStatus.completed,
    alertThresholdMeters: 1500,
    alertTriggeredCount: 2,
    firstAlertTriggeredAt: DateTime(2026, 11, 8, 10, 5),
    finalResolution: ResolutionType.confirmedArrived,
  );

  test('active journey state round-trips through preferences', () async {
    final real = ActiveJourneyState(
      journeyId: 'j1',
      destinationStationId: 'BOO',
      destinationStationName: 'Bogor',
      startedAt: DateTime(2026, 11, 8, 9, 0),
      alertThresholdMeters: 1500,
      progress: const EngineProgress(
        armed: true,
        alertCount: 1,
        lastDistanceMeters: 1400,
        minDistanceMeters: 1350,
        mismatchStreak: 1,
        lastAlertAt: null,
      ),
      health: MonitoringHealth.waitingForSignal,
      currentDistanceMeters: 1350,
    );

    await repository.saveActive(real);
    final loaded = repository.loadActive();

    expect(loaded, isNotNull);
    expect(loaded!.journeyId, 'j1');
    expect(loaded.progress.armed, isTrue);
    expect(loaded.progress.alertCount, 1);
    expect(loaded.currentDistanceMeters, 1350);
    expect(loaded.health, MonitoringHealth.waitingForSignal);

    await repository.clearActive();
    expect(repository.loadActive(), isNull);
  });

  test('journeys are stored, updated, and returned newest first', () async {
    final older = buildJourney(id: 'j1');
    final newer = Journey(
      id: 'j2',
      destinationStationId: 'TNG',
      destinationStationName: 'Tangerang',
      startedAt: DateTime(2026, 11, 9, 7, 0),
      status: JourneyStatus.cancelled,
      alertThresholdMeters: 1000,
      finalResolution: ResolutionType.manualStop,
    );

    await repository.insertJourney(older);
    await repository.insertJourney(newer);

    final history = await repository.getHistory();
    expect(history.length, 2);
    expect(history.first.id, 'j2');
    expect(history.last.finalResolution, ResolutionType.confirmedArrived);

    final updated = newer.copyWith(status: JourneyStatus.completed);
    await repository.updateJourney(updated);

    final refreshed = await repository.getHistory();
    expect(refreshed.first.status, JourneyStatus.completed);
  });

  test('alert events are attached to their journey and can be updated', () async {
    await repository.insertJourney(buildJourney());

    final event = AlertEvent(
      id: 'a1',
      journeyId: 'j1',
      triggeredAt: DateTime(2026, 11, 8, 10, 5),
      distanceMeters: 1400,
      accuracyMeters: 12,
      isRepeat: false,
    );
    await repository.recordAlertEvent(event);

    final events = await repository.getAlertEvents('j1');
    expect(events.length, 1);
    expect(events.first.userAction, isNull);

    await repository.updateAlertEvent(
      event.copyWith(
        userAction: UserAlertAction.arrived,
        actionTimestamp: DateTime(2026, 11, 8, 10, 6),
      ),
    );

    final updated = await repository.getAlertEvents('j1');
    expect(updated.first.userAction, UserAlertAction.arrived);
    expect(updated.first.actionTimestamp, isNotNull);
  });

  test('clearAllHistory removes journeys and their alert events', () async {
    await repository.insertJourney(buildJourney());
    await repository.recordAlertEvent(
      AlertEvent(
        id: 'a1',
        journeyId: 'j1',
        triggeredAt: DateTime(2026, 11, 8, 10, 5),
        distanceMeters: 1400,
        accuracyMeters: 12,
        isRepeat: false,
      ),
    );

    await repository.clearAllHistory();

    expect(await repository.getHistory(), isEmpty);
    expect(await repository.getAlertEvents('j1'), isEmpty);
  });
}
