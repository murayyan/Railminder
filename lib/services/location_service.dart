import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/location_sample.dart';

class LocationService {
  /// 100 m is the contract value: at KRL speeds it yields a sample roughly
  /// every 8-12 seconds and keeps the stream idle while the train waits.
  static const int distanceFilterMeters = 100;

  /// Accuracy stays `high` for the whole journey on purpose. `medium` often
  /// reports 100 m+ errors, which the engine discards as unreliable, so the
  /// alert would arrive later than the contract allows. The battery budget is
  /// protected by the distance filter, the accuracy filter and by cancelling
  /// the stream as soon as a journey ends.
  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Railminder memantau perjalanan',
          notificationText:
              'Peringatan getar aktif saat kereta mendekati stasiun tujuan.',
          notificationChannelName: 'Pemantauan Perjalanan',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
        activityType: ActivityType.other,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );
  }

  /// Position stream used while a journey runs. On Android the foreground
  /// service keeps the process alive with the screen off; on iOS the background
  /// location mode does the same job.
  Stream<LocationSample> journeyPositions() =>
      Geolocator.getPositionStream(locationSettings: _settings()).map(_toSample);

  Stream<ServiceStatus> serviceStatus() => Geolocator.getServiceStatusStream();

  Future<LocationSample?> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _settings(),
    );
    return _toSample(position);
  }

  LocationSample _toSample(Position position) => LocationSample(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
    speed: position.speed,
    timestamp: position.timestamp,
  );
}
