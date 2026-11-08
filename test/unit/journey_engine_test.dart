import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/data/models/location_sample.dart';
import 'package:railminder/data/models/station.dart';
import 'package:railminder/data/models/user_settings.dart';
import 'package:railminder/services/journey_engine.dart';

void main() {
  const engine = JourneyEngine();
  const settings = UserSettings(
    alertDistanceMeters: 1500,
    repeatIntervalMinutes: 3,
    maxRepeats: 3,
  );

  const destination = Station(
    id: 'BOO',
    name: 'Bogor',
    lineIds: ['BOGOR_LINE'],
    latitude: -6.594289,
    longitude: 106.790769,
    orderIndex: 23,
  );

  LocationSample sampleAtDistance(
    double distanceMeters, {
    double accuracy = 10.0,
    required DateTime timestamp,
  }) {
    const r = 6371000.0;
    const bearing = 0.0; // north
    final dr = distanceMeters / r;
    final lat1 = destination.latitude * math.pi / 180.0;
    final lon1 = destination.longitude * math.pi / 180.0;
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(dr) +
          math.cos(lat1) * math.sin(dr) * math.cos(bearing),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(dr) * math.cos(lat1),
          math.cos(dr) - math.sin(lat1) * math.sin(lat2),
        );
    return LocationSample(
      latitude: lat2 * 180.0 / math.pi,
      longitude: lon2 * 180.0 / math.pi,
      accuracy: accuracy,
      timestamp: timestamp,
    );
  }

  test('TV-01: first sample 8 km arms the journey', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    final sample = sampleAtDistance(8000, timestamp: t0);
    final res = engine.evaluate(
      sample: sample,
      destination: destination,
      state: const EngineState(),
      settings: settings,
      now: t0,
    );
    expect(res.decision.type, AlertDecisionType.track);
    expect(res.state.armed, isTrue);
  });

  test('TV-02: after armed, approach 2.4 km -> 1.4 km triggers first alert', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    final t1 = t0.add(const Duration(minutes: 2));

    var res = engine.evaluate(
      sample: sampleAtDistance(2400, timestamp: t0),
      destination: destination,
      state: const EngineState(),
      settings: settings,
      now: t0,
    );
    expect(res.state.armed, isTrue);

    res = engine.evaluate(
      sample: sampleAtDistance(1400, timestamp: t1),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t1,
    );
    expect(res.decision.type, AlertDecisionType.triggerAlert);
    expect(res.decision.isRepeat, isFalse);
    expect(res.state.alertCount, 1);
  });

  test('TV-03: subsequent sample 1.3 km 10s later is throttled by cooldown', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    final t1 = t0.add(const Duration(minutes: 1));
    final t2 = t1.add(const Duration(seconds: 10));

    var res = engine.evaluate(
      sample: sampleAtDistance(2200, timestamp: t0),
      destination: destination,
      state: const EngineState(),
      settings: settings,
      now: t0,
    );

    res = engine.evaluate(
      sample: sampleAtDistance(1400, timestamp: t1),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t1,
    );
    expect(res.decision.type, AlertDecisionType.triggerAlert);

    res = engine.evaluate(
      sample: sampleAtDistance(1300, timestamp: t2),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t2,
    );
    expect(res.decision.type, AlertDecisionType.track);
    expect(res.state.alertCount, 1);
  });

  test('TV-04: sample 1.3 km 3 min after first alert triggers repeat', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    final t1 = t0.add(const Duration(minutes: 1));
    final t2 = t1.add(const Duration(minutes: 3, seconds: 1));

    var res = engine.evaluate(
      sample: sampleAtDistance(2200, timestamp: t0),
      destination: destination,
      state: const EngineState(),
      settings: settings,
      now: t0,
    );
    res = engine.evaluate(
      sample: sampleAtDistance(1400, timestamp: t1),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t1,
    );
    expect(res.decision.type, AlertDecisionType.triggerAlert);
    expect(res.decision.isRepeat, isFalse);

    res = engine.evaluate(
      sample: sampleAtDistance(1300, timestamp: t2),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t2,
    );
    expect(res.decision.type, AlertDecisionType.triggerAlert);
    expect(res.decision.isRepeat, isTrue);
    expect(res.state.alertCount, 2);
  });

  test('TV-05: 3 repeats sent, further samples in radius only track', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    var state = EngineState(
      armed: true,
      lastAlertAt: t0,
      alertCount: 3,
      lastDistanceMeters: 1200,
    );

    final res = engine.evaluate(
      sample: sampleAtDistance(1100, timestamp: t0.add(const Duration(minutes: 5))),
      destination: destination,
      state: state,
      settings: settings,
      now: t0.add(const Duration(minutes: 5)),
    );
    expect(res.decision.type, AlertDecisionType.track);
    expect(res.state.alertCount, 3);
  });

  test('TV-06: accuracy 250m is ignored (low_accuracy)', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    final res = engine.evaluate(
      sample: sampleAtDistance(1400, accuracy: 250, timestamp: t0),
      destination: destination,
      state: const EngineState(armed: true),
      settings: settings,
      now: t0,
    );
    expect(res.decision.type, AlertDecisionType.ignore);
    expect(res.decision.reason, 'low_accuracy');
  });

  test('TV-07: sample timestamp 45s in the past is ignored (stale_sample)', () {
    final now = DateTime(2026, 11, 8, 9, 0, 45);
    final sampleTime = DateTime(2026, 11, 8, 9, 0, 0);

    final res = engine.evaluate(
      sample: sampleAtDistance(1400, timestamp: sampleTime),
      destination: destination,
      state: const EngineState(armed: true),
      settings: settings,
      now: now,
    );
    expect(res.decision.type, AlertDecisionType.ignore);
    expect(res.decision.reason, 'stale_sample');
  });

  test('TV-08: journey starts 800m from destination -> alreadyArrived', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    final res = engine.evaluate(
      sample: sampleAtDistance(800, timestamp: t0),
      destination: destination,
      state: const EngineState(),
      settings: settings,
      now: t0,
    );
    expect(res.decision.type, AlertDecisionType.alreadyArrived);
    expect(res.state.armed, isFalse);
  });

  test('TV-09: distance grows 5 km -> 7 km -> 9 km triggers routeMismatch on 3rd sample', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    var res = engine.evaluate(
      sample: sampleAtDistance(5000, timestamp: t0),
      destination: destination,
      state: const EngineState(),
      settings: settings,
      now: t0,
    );
    expect(res.state.mismatchStreak, 1);

    res = engine.evaluate(
      sample: sampleAtDistance(7000, timestamp: t0.add(const Duration(minutes: 1))),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t0.add(const Duration(minutes: 1)),
    );
    expect(res.state.mismatchStreak, 2);

    res = engine.evaluate(
      sample: sampleAtDistance(9000, timestamp: t0.add(const Duration(minutes: 2))),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t0.add(const Duration(minutes: 2)),
    );
    expect(res.decision.type, AlertDecisionType.routeMismatch);
  });

  test('TV-10: 1.6 km -> 1.4 km -> 1.55 km -> 1.35 km alerts only on drop below threshold', () {
    final t0 = DateTime(2026, 11, 8, 9, 0, 0);
    final t1 = t0.add(const Duration(minutes: 1));
    final t2 = t1.add(const Duration(minutes: 1));
    final t3 = t2.add(const Duration(minutes: 1));

    // Arm journey first
    var res = engine.evaluate(
      sample: sampleAtDistance(2500, timestamp: t0.subtract(const Duration(minutes: 2))),
      destination: destination,
      state: const EngineState(),
      settings: settings,
      now: t0.subtract(const Duration(minutes: 2)),
    );
    expect(res.state.armed, isTrue);

    // 1.6 km (outside 1500m threshold)
    res = engine.evaluate(
      sample: sampleAtDistance(1600, timestamp: t0),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t0,
    );
    expect(res.decision.type, AlertDecisionType.track);
    expect(res.state.alertCount, 0);

    // 1.4 km (first alert)
    res = engine.evaluate(
      sample: sampleAtDistance(1400, timestamp: t1),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t1,
    );
    expect(res.decision.type, AlertDecisionType.triggerAlert);
    expect(res.decision.isRepeat, isFalse);
    expect(res.state.alertCount, 1);

    // 1.55 km (grew, but still under min cooldown / not shrinking / repeat interval not passed)
    res = engine.evaluate(
      sample: sampleAtDistance(1550, timestamp: t2),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t2,
    );
    expect(res.decision.type, AlertDecisionType.track);
    expect(res.state.alertCount, 1);

    // 1.35 km (1 min after alert, repeat interval 3 min not met)
    res = engine.evaluate(
      sample: sampleAtDistance(1350, timestamp: t3),
      destination: destination,
      state: res.state,
      settings: settings,
      now: t3,
    );
    expect(res.decision.type, AlertDecisionType.track);
    expect(res.state.alertCount, 1);
  });
}
