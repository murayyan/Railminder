import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/data/models/station.dart';
import 'package:railminder/data/models/user_settings.dart';
import 'package:railminder/services/journey_engine.dart';

import '../support/station_dataset.dart';

void main() {
  const engine = JourneyEngine();
  const bogor = Station(
    id: 'BOO',
    name: 'Bogor',
    lineIds: ['BOGOR_LINE'],
    latitude: -6.594289,
    longitude: 106.790769,
    orderIndex: 23,
  );

  test('changing alertDistanceMeters from 1500 to 2000 triggers alert earlier', () {
    final t0 = DateTime(2026, 11, 8, 8, 0);
    final stateArmed = EngineState(
      armed: true,
      lastDistanceMeters: 2500,
    );

    // At 1800m, standard 1500m threshold does not trigger
    const defaultSettings = UserSettings(alertDistanceMeters: 1500);
    final res1500 = engine.evaluate(
      sample: sampleAtDistance(bogor, 1800, timestamp: t0),
      destination: bogor,
      state: stateArmed,
      settings: defaultSettings,
      now: t0,
    );
    expect(res1500.decision.type, AlertDecisionType.track);

    // At 1800m with 2000m threshold, it triggers
    const widerSettings = UserSettings(alertDistanceMeters: 2000);
    final res2000 = engine.evaluate(
      sample: sampleAtDistance(bogor, 1800, timestamp: t0),
      destination: bogor,
      state: stateArmed,
      settings: widerSettings,
      now: t0,
    );
    expect(res2000.decision.type, AlertDecisionType.triggerAlert);
  });

  test('repeat interval 5 minutes delays second alert', () {
    final t0 = DateTime(2026, 11, 8, 8, 0);
    const slowRepeatSettings = UserSettings(
      alertDistanceMeters: 1500,
      repeatIntervalMinutes: 5,
      maxRepeats: 3,
    );

    final stateAlerted = EngineState(
      armed: true,
      alertCount: 1,
      lastAlertAt: t0,
      lastDistanceMeters: 1400,
    );

    // 3 minutes later: should still be track
    final t3 = t0.add(const Duration(minutes: 3));
    final res3 = engine.evaluate(
      sample: sampleAtDistance(bogor, 1300, timestamp: t3),
      destination: bogor,
      state: stateAlerted,
      settings: slowRepeatSettings,
      now: t3,
    );
    expect(res3.decision.type, AlertDecisionType.track);

    // 5 minutes later: should trigger repeat
    final t5 = t0.add(const Duration(minutes: 5, seconds: 1));
    final res5 = engine.evaluate(
      sample: sampleAtDistance(bogor, 1200, timestamp: t5),
      destination: bogor,
      state: stateAlerted,
      settings: slowRepeatSettings,
      now: t5,
    );
    expect(res5.decision.type, AlertDecisionType.triggerAlert);
    expect(res5.decision.isRepeat, isTrue);
  });
}
