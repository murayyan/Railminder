import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/data/models/engine_progress.dart';
import 'package:railminder/data/models/enums.dart';
import 'package:railminder/data/models/journey.dart';
import 'package:railminder/data/models/user_settings.dart';
import 'package:railminder/data/repositories/journey_repository.dart';
import 'package:railminder/services/journey_engine.dart';
import 'package:railminder/data/models/station.dart';

import '../support/station_dataset.dart';

void main() {
  const bogor = Station(
    id: 'BOO',
    name: 'Bogor',
    lineIds: ['BOGOR_LINE'],
    latitude: -6.594289,
    longitude: 106.790769,
    orderIndex: 23,
  );

  test('settings threshold changes when the engine fires', () {
    const engine = JourneyEngine();
    const tightSettings = UserSettings(
      alertDistanceMeters: 1000,
      repeatIntervalMinutes: 3,
      maxRepeats: 3,
    );

    final t0 = DateTime(2026, 11, 8, 9, 0);
    var result = engine.evaluate(
      sample: sampleAtDistance(bogor, 4000, timestamp: t0),
      destination: bogor,
      state: const EngineState(),
      settings: tightSettings,
      now: t0,
    );
    expect(result.state.armed, isTrue);

    final t1 = t0.add(const Duration(minutes: 2));
    result = engine.evaluate(
      sample: sampleAtDistance(bogor, 1200, timestamp: t1),
      destination: bogor,
      state: result.state,
      settings: tightSettings,
      now: t1,
    );
    expect(result.decision.type, AlertDecisionType.track,
        reason: '1200m is outside the 1000m threshold');

    final t2 = t1.add(const Duration(minutes: 2));
    result = engine.evaluate(
      sample: sampleAtDistance(bogor, 950, timestamp: t2),
      destination: bogor,
      state: result.state,
      settings: tightSettings,
      now: t2,
    );
    expect(result.decision.type, AlertDecisionType.triggerAlert);
  });

  test('maxRepeats 0 disables repeat alerts entirely', () {
    const engine = JourneyEngine();
    const noRepeats = UserSettings(
      alertDistanceMeters: 1500,
      repeatIntervalMinutes: 3,
      maxRepeats: 0,
    );

    final t0 = DateTime(2026, 11, 8, 9, 0);
    final state = EngineState(
      armed: true,
      alertCount: 1,
      lastAlertAt: t0,
      lastDistanceMeters: 1400,
      minDistanceMeters: 1400,
    );

    final res = engine.evaluate(
      sample: sampleAtDistance(bogor, 1200, timestamp: t0.add(const Duration(minutes: 10))),
      destination: bogor,
      state: state,
      settings: noRepeats,
      now: t0.add(const Duration(minutes: 10)),
    );

    expect(res.decision.type, AlertDecisionType.track);
    expect(res.state.alertCount, 1);
  });

  test('active journey survives serialisation with the same engine state', () {
    final state = ActiveJourneyState(
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
      health: MonitoringHealth.active,
      currentDistanceMeters: 1400,
    );

    final restored = ActiveJourneyState.fromJson(state.toJson());
    expect(restored.journeyId, state.journeyId);
    expect(restored.progress.armed, isTrue);
    expect(restored.progress.alertCount, 1);
    expect(restored.progress.lastDistanceMeters, 1400);
    expect(restored.currentDistanceMeters, 1400);
  });

  test('in-memory store restores the active journey after a restart', () async {
    final store = InMemoryJourneyStore();
    final state = ActiveJourneyState(
      journeyId: 'j1',
      destinationStationId: 'BOO',
      destinationStationName: 'Bogor',
      startedAt: DateTime(2026, 11, 8, 9, 0),
      alertThresholdMeters: 1500,
      progress: const EngineProgress(armed: true, alertCount: 2),
    );

    await store.saveActive(state);

    final restored = store.loadActive();
    expect(restored, isNotNull);
    expect(restored!.journeyId, 'j1');
    expect(restored.progress.alertCount, 2);

    await store.clearActive();
    expect(store.loadActive(), isNull);
  });

  test('a restored journey keeps alerting without repeating the first alert', () {
    const engine = JourneyEngine();
    const settings = UserSettings();

    final restored = ActiveJourneyState(
      journeyId: 'j1',
      destinationStationId: 'BOO',
      destinationStationName: 'Bogor',
      startedAt: DateTime(2026, 11, 8, 9, 0),
      alertThresholdMeters: 1500,
      progress: const EngineProgress(
        armed: true,
        alertCount: 1,
        lastDistanceMeters: 1400,
        lastAlertAt: null,
      ),
    );

    final now = DateTime(2026, 11, 8, 9, 20);
    final res = engine.evaluate(
      sample: sampleAtDistance(bogor, 1300, timestamp: now),
      destination: bogor,
      state: restored.progress,
      settings: settings,
      now: now,
    );

    // lastAlertAt was lost with a restart, so the engine treats this as a
    // repeat candidate rather than a brand new first alert.
    expect(res.decision.isRepeat, isTrue);
    expect(res.state.alertCount, 2);
  });

  test('a completed journey keeps its resolution in history', () async {
    final store = InMemoryJourneyStore();
    await store.insertJourney(
      Journey(
        id: 'j1',
        destinationStationId: 'BOO',
        destinationStationName: 'Bogor',
        startedAt: DateTime(2026, 11, 8, 9, 0),
        completedAt: DateTime(2026, 11, 8, 10, 0),
        status: JourneyStatus.completed,
        alertThresholdMeters: 1500,
        alertTriggeredCount: 1,
        finalResolution: ResolutionType.confirmedArrived,
      ),
    );

    final history = await store.getHistory();
    expect(history.single.finalResolution, ResolutionType.confirmedArrived);
  });
}
