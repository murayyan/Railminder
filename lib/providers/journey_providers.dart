import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/engine_progress.dart';
import '../data/models/enums.dart';
import '../features/active_journey/journey_controller.dart';

export '../features/active_journey/journey_controller.dart'
    show JourneyController;

final activeJourneyProvider =
    NotifierProvider<JourneyController, ActiveJourneyState?>(
  JourneyController.new,
);

/// Distance to the destination in metres, or null while no sample has landed.
final distanceToDestinationProvider = Provider<double?>((ref) {
  return ref.watch(activeJourneyProvider)?.currentDistanceMeters;
});

final monitoringHealthProvider = Provider<MonitoringHealth>((ref) {
  return ref.watch(activeJourneyProvider)?.health ??
      MonitoringHealth.waitingForSignal;
});

final isMonitoringProvider = Provider<bool>((ref) {
  return ref.watch(activeJourneyProvider) != null;
});
