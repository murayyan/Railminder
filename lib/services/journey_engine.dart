import 'dart:math' as math;

import '../core/constants.dart';
import '../core/distance.dart';
import '../data/models/engine_progress.dart';
import '../data/models/location_sample.dart';
import '../data/models/station.dart';
import '../data/models/user_settings.dart';

enum AlertDecisionType {
  ignore,
  track,
  triggerAlert,
  alreadyArrived,
  routeMismatch,
}

class AlertDecision {
  final AlertDecisionType type;
  final double? distanceMeters;
  final bool isRepeat;
  final String? reason;

  const AlertDecision(
    this.type, {
    this.distanceMeters,
    this.isRepeat = false,
    this.reason,
  });

  const AlertDecision.ignore(String reason, {double? distanceMeters})
    : this(
        AlertDecisionType.ignore,
        reason: reason,
        distanceMeters: distanceMeters,
      );

  const AlertDecision.track({double? distanceMeters})
    : this(AlertDecisionType.track, distanceMeters: distanceMeters);

  @override
  String toString() =>
      'AlertDecision(${type.name}, distance: $distanceMeters, '
      'isRepeat: $isRepeat, reason: $reason)';
}

/// Immutable engine state, persisted with the active journey so a restart
/// resumes exactly where it stopped.
typedef EngineState = EngineProgress;

class EngineResult {
  final AlertDecision decision;
  final EngineState state;

  const EngineResult({required this.decision, required this.state});
}

/// Pure alert engine. No plugins, no system clock, no storage access; every
/// input is explicit so the same sample sequence always yields the same
/// decisions.
class JourneyEngine {
  const JourneyEngine();

  EngineResult evaluate({
    required LocationSample sample,
    required Station destination,
    required EngineState state,
    required UserSettings settings,
    required DateTime now,
  }) {
    final threshold = settings.alertDistanceMeters.toDouble();

    final stale = now.difference(sample.timestamp);
    if (stale > AppConstants.maxSampleAge) {
      return _ignored('stale_sample', state);
    }

    if (sample.accuracy > AppConstants.maxSampleAccuracyMeters) {
      return _ignored('low_accuracy', state);
    }

    if (!isSampleUsable(sample, now)) {
      return _ignored('invalid_sample', state);
    }

    final distance = haversineMeters(
      lat1: sample.latitude,
      lon1: sample.longitude,
      lat2: destination.latitude,
      lon2: destination.longitude,
    );

    final previous = state.lastDistanceMeters;
    final inAlertRadius = distance <= threshold;
    final coolingDown =
        state.lastAlertAt != null &&
        now.difference(state.lastAlertAt!) < AppConstants.minAlertCooldown;

    final minimum = state.minDistanceMeters == null
        ? distance
        : math.min(state.minDistanceMeters!, distance);

    final grewEnough =
        previous != null && distance > previous + AppConstants.routeMismatchDeltaMeters;
    final mismatchStreak = grewEnough
        ? (state.mismatchStreak == 0 ? 2 : state.mismatchStreak + 1)
        : 1;

    // R4: journey started inside the alert radius. No alert is emitted; the
    // UI asks the traveller to confirm whether they already arrived.
    if (!state.armed &&
        state.alertCount == 0 &&
        inAlertRadius &&
        distance > 0 &&
        previous == null) {
      return EngineResult(
        decision: AlertDecision(
          AlertDecisionType.alreadyArrived,
          distanceMeters: distance,
        ),
        state: state.copyWith(
          lastDistanceMeters: distance,
          minDistanceMeters: minimum,
          mismatchStreak: 1,
        ),
      );
    }

    // R5: far enough from the destination to trust that the train is still
    // approaching. This is what arms the alert.
    if (!state.armed && distance > threshold + AppConstants.armMarginMeters) {
      return EngineResult(
        decision: AlertDecision.track(distanceMeters: distance),
        state: state.copyWith(
          armed: true,
          lastDistanceMeters: distance,
          minDistanceMeters: minimum,
          mismatchStreak: 1,
        ),
      );
    }

    // R6: first alert, only while the distance is shrinking.
    if (state.armed &&
        state.alertCount == 0 &&
        inAlertRadius &&
        (previous == null || distance < previous) &&
        !coolingDown) {
      return _triggered(distance, state, now, minimum, 1, isRepeat: false);
    }

    // R7: repeat alerts, capped by maxRepeats and spaced by the repeat
    // interval with a hard 30 s floor between any two alerts. A restored
    // journey has no lastAlertAt, so the first sample after a restart may
    // repeat immediately.
    final repeatDue = state.lastAlertAt == null ||
        now.difference(state.lastAlertAt!) >=
            Duration(minutes: settings.repeatIntervalMinutes);
    if (state.alertCount > 0 &&
        state.alertCount < settings.maxRepeats &&
        inAlertRadius &&
        !coolingDown &&
        repeatDue) {
      return _triggered(
        distance,
        state,
        now,
        minimum,
        mismatchStreak,
        isRepeat: true,
      );
    }

    // R8: three consecutive growing samples while at least 1 km outside the
    // alert radius suggest the traveller is heading the wrong way.
    if (mismatchStreak >= AppConstants.routeMismatchHoldSamples &&
        minimum > threshold + AppConstants.routeMismatchMinDistanceMeters) {
      return EngineResult(
        decision: AlertDecision(
          AlertDecisionType.routeMismatch,
          distanceMeters: distance,
        ),
        state: state.copyWith(
          lastDistanceMeters: distance,
          minDistanceMeters: minimum,
          mismatchStreak: mismatchStreak,
        ),
      );
    }

    return EngineResult(
      decision: AlertDecision.track(distanceMeters: distance),
      state: state.copyWith(
        lastDistanceMeters: distance,
        minDistanceMeters: minimum,
        mismatchStreak: mismatchStreak,
      ),
    );
  }

  EngineResult _triggered(
    double distance,
    EngineState state,
    DateTime now,
    double minimum,
    int mismatchStreak, {
    required bool isRepeat,
  }) {
    return EngineResult(
      decision: AlertDecision(
        AlertDecisionType.triggerAlert,
        distanceMeters: distance,
        isRepeat: isRepeat,
      ),
      state: state.copyWith(
        lastDistanceMeters: distance,
        lastAlertAt: now,
        alertCount: state.alertCount + 1,
        minDistanceMeters: minimum,
        mismatchStreak: mismatchStreak,
      ),
    );
  }

  EngineResult _ignored(String reason, EngineState state) => EngineResult(
    decision: AlertDecision.ignore(reason),
    state: state,
  );
}
