import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show ServiceStatus;

import '../../core/constants.dart';
import '../../data/models/alert_event.dart';
import '../../data/models/engine_progress.dart';
import '../../data/models/enums.dart';
import '../../data/models/journey.dart';
import '../../data/models/location_sample.dart';
import '../../data/models/station.dart';
import '../../providers/providers.dart';
import '../../services/journey_engine.dart';
import '../../services/notification_service.dart';

class JourneyController extends Notifier<ActiveJourneyState?> {
  final JourneyEngine _engine = const JourneyEngine();

  StreamSubscription<LocationSample>? _locationSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Timer? _staleCheckTimer;
  DateTime? _lastSampleReceivedAt;

  @override
  ActiveJourneyState? build() {
    final initial = ref.watch(journeyRepositoryProvider).loadActive();
    ref.onDispose(() {
      _cancelSubscriptions();
    });

    if (initial != null) {
      // Resume monitoring in the background after the first frame
      Future.microtask(() => _startListening());
    }
    return initial;
  }

  bool get isMonitoring => state != null;

  Future<void> startJourney({
    required Station destination,
    Station? origin,
    int? customThresholdMeters,
    Stream<LocationSample>? testStream,
  }) async {
    final settings = ref.read(settingsProvider);
    final threshold =
        customThresholdMeters ?? settings.alertDistanceMeters;
    final journeyId =
        'j_${DateTime.now().millisecondsSinceEpoch}_${destination.id}';
    final startedAt = DateTime.now();

    final active = ActiveJourneyState(
      journeyId: journeyId,
      destinationStationId: destination.id,
      destinationStationName: destination.name,
      startedAt: startedAt,
      alertThresholdMeters: threshold,
      progress: const EngineProgress(),
      health: MonitoringHealth.active,
    );

    final record = Journey(
      id: journeyId,
      destinationStationId: destination.id,
      destinationStationName: destination.name,
      originStationId: origin?.id,
      startedAt: startedAt,
      status: JourneyStatus.active,
      alertThresholdMeters: threshold,
    );

    await ref.read(journeyRepositoryProvider).insertJourney(record);
    await ref.read(journeyRepositoryProvider).saveActive(active);

    state = active;
    ref.read(alreadyArrivedProvider.notifier).set(false);
    ref.read(routeMismatchProvider.notifier).set(false);
    _startListening(customStream: testStream);
  }

  void _startListening({Stream<LocationSample>? customStream}) {
    _locationSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    _staleCheckTimer?.cancel();

    final locationService = ref.read(locationServiceProvider);
    final stream = customStream ?? locationService.journeyPositions();

    _lastSampleReceivedAt = DateTime.now();
    _locationSubscription = stream.listen(
      _handleSample,
      onError: (Object error) {
        _setHealth(MonitoringHealth.permissionLost);
      },
    );

    _serviceStatusSubscription = locationService.serviceStatus().listen(
      (status) {
        if (state == null) return;
        if (status == ServiceStatus.disabled) {
          _setHealth(MonitoringHealth.permissionLost);
        } else {
          _setHealth(MonitoringHealth.active);
        }
      },
      onError: (Object _) {},
    );

    _staleCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkHealth(),
    );
  }

  void _cancelSubscriptions() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    _staleCheckTimer?.cancel();
    _staleCheckTimer = null;
  }

  void _checkHealth() {
    final current = state;
    if (current == null) return;

    final lastAt = _lastSampleReceivedAt;
    if (lastAt == null) return;

    final staleFor = DateTime.now().difference(lastAt);
    if (staleFor > const Duration(seconds: 35)) {
      if (current.health != MonitoringHealth.waitingForSignal) {
        _setHealth(MonitoringHealth.waitingForSignal);
      }
    }
  }

  void _setHealth(MonitoringHealth health) {
    final current = state;
    if (current == null) return;
    if (current.health == health) return;

    final updated = current.copyWith(health: health);
    state = updated;
    ref.read(journeyRepositoryProvider).saveActive(updated);

    if (health == MonitoringHealth.active) {
      ref
          .read(notificationServiceProvider)
          .cancel(1);
    } else {
      // Status notification is silent: importance low, no vibration.
      ref.read(notificationServiceProvider).showJourneyStatus(
        journeyId: current.journeyId,
        message: health == MonitoringHealth.permissionLost
            ? 'Lokasi tidak tersedia. Periksa izin atau GPS untuk melanjutkan peringatan.'
            : 'Tidak ada sinyal GPS. Peringatan dijeda sampai posisi terbaca lagi.',
      );
    }
  }

  Future<void> _handleSample(LocationSample sample) async {
    final current = state;
    if (current == null) return;

    _lastSampleReceivedAt = DateTime.now();

    final stationRepo = ref.read(stationRepositoryProvider);
    final destination =
        stationRepo.getStationById(current.destinationStationId);
    if (destination == null) return;

    final settings = ref.read(settingsProvider);
    final now = DateTime.now();

    final eval = _engine.evaluate(
      sample: sample,
      destination: destination,
      state: current.progress,
      settings: settings,
      now: now,
    );

    final decision = eval.decision;
    final nextProgress = eval.state;

    MonitoringHealth nextHealth = MonitoringHealth.active;
    if (decision.type == AlertDecisionType.ignore &&
        (decision.reason == 'stale_sample' ||
            decision.reason == 'low_accuracy')) {
      nextHealth = MonitoringHealth.waitingForSignal;
    }

    final updated = current.copyWith(
      progress: nextProgress,
      health: nextHealth,
      currentDistanceMeters: decision.distanceMeters ?? current.currentDistanceMeters,
    );

    state = updated;
    await ref.read(journeyRepositoryProvider).saveActive(updated);

    if (decision.type == AlertDecisionType.alreadyArrived) {
      ref.read(alreadyArrivedProvider.notifier).set(true);
    } else if (decision.type == AlertDecisionType.routeMismatch) {
      ref.read(routeMismatchProvider.notifier).set(true);
    }

    if (decision.type == AlertDecisionType.triggerAlert &&
        decision.distanceMeters != null) {
      await _emitAlert(
        current: updated,
        distanceMeters: decision.distanceMeters!,
        accuracyMeters: sample.accuracy,
        isRepeat: decision.isRepeat,
        now: now,
      );
    }
  }

  Future<void> _emitAlert({
    required ActiveJourneyState current,
    required double distanceMeters,
    required double accuracyMeters,
    required bool isRepeat,
    required DateTime now,
  }) async {
    final eventId = 'alert_${now.millisecondsSinceEpoch}_${current.journeyId}';
    final event = AlertEvent(
      id: eventId,
      journeyId: current.journeyId,
      triggeredAt: now,
      distanceMeters: distanceMeters,
      accuracyMeters: accuracyMeters,
      isRepeat: isRepeat,
    );

    // Write-before-notify: log the event locally before asking the OS to display it.
    await ref.read(journeyRepositoryProvider).recordAlertEvent(event);

    final notif = ref.read(notificationServiceProvider);
    final settings = ref.read(settingsProvider);

    await notif.showApproachAlert(
      journeyId: current.journeyId,
      stationId: current.destinationStationId,
      stationName: current.destinationStationName,
      distanceMeters: distanceMeters,
      isRepeat: isRepeat,
      enableVibration: settings.enableVibration,
    );
  }

  Future<void> confirmArrived() async {
    await _finish(
      status: JourneyStatus.completed,
      resolution: ResolutionType.confirmedArrived,
      userAction: UserAlertAction.arrived,
    );
  }

  /// The traveller said they are still on the train, so enable alerts even
  /// though the journey started inside the alert radius.
  Future<void> armMonitoring() async {
    final current = state;
    if (current == null) return;

    final updated = current.copyWith(
      progress: current.progress.copyWith(armed: true),
    );
    state = updated;
    await ref.read(journeyRepositoryProvider).saveActive(updated);
  }

  Future<void> confirmStillOnTrain() async {
    final current = state;
    if (current == null) return;

    final events = await ref
        .read(journeyRepositoryProvider)
        .getAlertEvents(current.journeyId);
    if (events.isNotEmpty) {
      final last = events.last;
      await ref.read(journeyRepositoryProvider).updateAlertEvent(
            last.copyWith(
              userAction: UserAlertAction.stillOnTrain,
              actionTimestamp: DateTime.now(),
            ),
          );
    }
  }

  Future<void> stopJourney({
    ResolutionType resolution = ResolutionType.manualStop,
  }) async {
    await _finish(
      status: JourneyStatus.cancelled,
      resolution: resolution,
      userAction: UserAlertAction.dismissed,
    );
  }

  Future<void> handleNotificationAction(String actionId) async {
    switch (actionId) {
      case AppConstants.actionArrived:
        await confirmArrived();
        break;
      case AppConstants.actionStillOnTrain:
        await confirmStillOnTrain();
        break;
      case AppConstants.actionStopJourney:
        await stopJourney(resolution: ResolutionType.manualStop);
        break;
    }
  }

  Future<void> _finish({
    required JourneyStatus status,
    required ResolutionType resolution,
    UserAlertAction? userAction,
  }) async {
    final current = state;
    if (current == null) return;

    _cancelSubscriptions();

    final now = DateTime.now();
    final journeyRepo = ref.read(journeyRepositoryProvider);

    final notifId = NotificationPayload.notificationIdFor(
      current.destinationStationId,
    );
    await ref.read(notificationServiceProvider).cancel(notifId);
    await ref.read(notificationServiceProvider).cancel(1);

    final events = await journeyRepo.getAlertEvents(current.journeyId);
    if (events.isNotEmpty && userAction != null) {
      final last = events.last;
      await journeyRepo.updateAlertEvent(
        last.copyWith(
          userAction: userAction,
          actionTimestamp: now,
        ),
      );
    }

    final finished = Journey(
      id: current.journeyId,
      destinationStationId: current.destinationStationId,
      destinationStationName: current.destinationStationName,
      startedAt: current.startedAt,
      completedAt: now,
      status: status,
      alertThresholdMeters: current.alertThresholdMeters,
      alertTriggeredCount: current.progress.alertCount,
      firstAlertTriggeredAt: current.progress.lastAlertAt,
      finalResolution: resolution,
    );

    await journeyRepo.updateJourney(finished);
    await journeyRepo.clearActive();

    state = null;
    ref.invalidate(historyProvider);
  }
}
