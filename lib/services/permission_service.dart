import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionAudit {
  final bool locationServiceEnabled;
  final LocationPermission locationPermission;
  final bool notificationGranted;

  const PermissionAudit({
    required this.locationServiceEnabled,
    required this.locationPermission,
    required this.notificationGranted,
  });

  bool get canStartTracking =>
      locationServiceEnabled &&
      (locationPermission == LocationPermission.always ||
          locationPermission == LocationPermission.whileInUse);

  bool get hasBackgroundLocation =>
      locationPermission == LocationPermission.always;
}

class PermissionService {
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkLocationPermission() =>
      Geolocator.checkPermission();

  Future<LocationPermission> requestLocationPermission() =>
      Geolocator.requestPermission();

  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<PermissionAudit> auditPrerequisites() async {
    final serviceEnabled = await isLocationServiceEnabled();
    final locationPerm = await checkLocationPermission();
    final notifGranted = await checkNotificationPermission();

    return PermissionAudit(
      locationServiceEnabled: serviceEnabled,
      locationPermission: locationPerm,
      notificationGranted: notifGranted,
    );
  }
}
