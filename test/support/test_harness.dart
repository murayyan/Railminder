import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:railminder/core/theme.dart';
import 'package:railminder/data/models/location_sample.dart';
import 'package:railminder/data/models/station.dart';
import 'package:railminder/data/repositories/journey_repository.dart';
import 'package:railminder/data/repositories/station_repository.dart';
import 'package:railminder/providers/providers.dart';
import 'package:railminder/services/location_service.dart';
import 'package:railminder/services/notification_service.dart';
import 'package:railminder/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'station_dataset.dart';

class FakeNotificationService extends NotificationService {
  final List<({String stationId, String stationName, bool isRepeat})> alerts =
      [];

  bool initialized = false;
  bool vibrationEnabled = true;
  final List<int> cancelledIds = [];

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
    required void Function(String actionId, String? payload) onAction,
    required bool enableVibration,
  }) async {
    initialized = true;
    vibrationEnabled = enableVibration;
  }

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> showApproachAlert({
    required String journeyId,
    required String stationId,
    required String stationName,
    required double distanceMeters,
    required bool isRepeat,
    required bool enableVibration,
  }) async {
    alerts.add((
      stationId: stationId,
      stationName: stationName,
      isRepeat: isRepeat,
    ));
  }

  @override
  Future<void> showJourneyStatus({
    required String journeyId,
    required String message,
  }) async {}

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }
}

class FakePermissionService extends PermissionService {
  bool locationEnabled = true;
  bool notificationsGranted = true;
  LocationPermission permission = LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => locationEnabled;

  @override
  Future<LocationPermission> checkLocationPermission() async => permission;

  @override
  Future<LocationPermission> requestLocationPermission() async => permission;

  @override
  Future<bool> checkNotificationPermission() async => notificationsGranted;

  @override
  Future<bool> requestNotificationPermission() async => notificationsGranted;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

class FakeLocationService extends LocationService {
  final StreamController<LocationSample> controller =
      StreamController<LocationSample>.broadcast();

  @override
  Stream<LocationSample> journeyPositions() => controller.stream;

  @override
  Stream<ServiceStatus> serviceStatus() =>
      const Stream<ServiceStatus>.empty();
}

class TestHarness {
  final ProviderContainer container;
  final FakeNotificationService notifications;
  final FakePermissionService permissions;
  final FakeLocationService locations;
  final InMemoryJourneyStore journeys;

  TestHarness._(
    this.container,
    this.notifications,
    this.permissions,
    this.locations,
    this.journeys,
  );

  static Future<TestHarness> create({Map<String, Object>? prefs}) async {
    SharedPreferences.setMockInitialValues(prefs ?? {});

    final sharedPrefs = await SharedPreferences.getInstance();

    final repository = StationRepository(loader: fileStationLoader());
    await repository.initialize();

    final notifications = FakeNotificationService();
    final permissions = FakePermissionService();
    final locations = FakeLocationService();
    final journeys = InMemoryJourneyStore();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        stationRepositoryProvider.overrideWithValue(repository),
        journeyRepositoryProvider.overrideWithValue(journeys),
        notificationServiceProvider.overrideWithValue(notifications),
        permissionServiceProvider.overrideWithValue(permissions),
        locationServiceProvider.overrideWithValue(locations),
      ],
    );

    return TestHarness._(
      container,
      notifications,
      permissions,
      locations,
      journeys,
    );
  }

  Station get bogor =>
      container.read(stationRepositoryProvider).getStationById('BOO')!;

  Future<void> dispose() async {
    container.dispose();
    await locations.controller.close();
  }
}

Widget wrapWithScope(Widget child, ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}
