import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants.dart';

class NotificationPayload {
  final String type;
  final String journeyId;
  final String destinationStationId;
  final DateTime triggeredAt;
  final bool isRepeat;

  const NotificationPayload({
    required this.type,
    required this.journeyId,
    required this.destinationStationId,
    required this.triggeredAt,
    required this.isRepeat,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'journeyId': journeyId,
    'destinationStationId': destinationStationId,
    'triggeredAt': triggeredAt.toIso8601String(),
    'isRepeat': isRepeat,
  };

  String encode() => jsonEncode(toJson());

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final type = decoded['type'];
      final journeyId = decoded['journeyId'];
      final destination = decoded['destinationStationId'];
      final triggeredAt = decoded['triggeredAt'];
      if (type is! String || journeyId is! String || destination is! String) {
        return null;
      }
      if (triggeredAt is! String) return null;
      return NotificationPayload(
        type: type,
        journeyId: journeyId,
        destinationStationId: destination,
        triggeredAt: DateTime.parse(triggeredAt),
        isRepeat: decoded['isRepeat'] == true,
      );
    } on FormatException {
      return null;
    }
  }

  static int notificationIdFor(String stationId) =>
      stationId.hashCode & 0x7fffffff;
}

const String _approachCategoryId = 'STATION_APPROACH';

Int64List _vibrationPattern() =>
    Int64List.fromList(AppConstants.approachVibrationPattern);

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize({
    required void Function(String? payload) onTap,
    required void Function(String actionId, String? payload) onAction,
    required bool enableVibration,
  }) async {
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: false,
      requestBadgePermission: true,
      requestCriticalPermission: false,
      defaultPresentAlert: true,
      defaultPresentSound: false,
      defaultPresentBanner: true,
      notificationCategories: [
        DarwinNotificationCategory(
          _approachCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              AppConstants.actionArrived,
              'Saya Sudah Turun',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              AppConstants.actionStillOnTrain,
              'Saya Masih di Kereta',
            ),
          ],
        ),
      ],
    );

    await plugin.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final actionId = response.actionId;
        if (actionId == null || actionId.isEmpty) {
          onTap(response.payload);
        } else {
          onAction(actionId, response.payload);
        }
      },
    );

    await _ensureChannels(enableVibration: enableVibration);
  }

  Future<void> _ensureChannels({required bool enableVibration}) async {
    final android = plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        AppConstants.channelApproachId,
        AppConstants.channelApproachName,
        description: AppConstants.channelApproachDescription,
        importance: Importance.max,
        playSound: false,
        enableVibration: enableVibration,
        vibrationPattern: _vibrationPattern(),
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.channelStatusId,
        AppConstants.channelStatusName,
        description: AppConstants.channelStatusDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

  Future<void> requestPermissions() async {
    await plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: false);
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showApproachAlert({
    required String journeyId,
    required String stationId,
    required String stationName,
    required double distanceMeters,
    required bool isRepeat,
    required bool enableVibration,
  }) async {
    final payload = NotificationPayload(
      type: 'station_approach',
      journeyId: journeyId,
      destinationStationId: stationId,
      triggeredAt: DateTime.now(),
      isRepeat: isRepeat,
    );

    final title = isRepeat
        ? 'Masih menuju $stationName?'
        : 'Mendekati $stationName';
    final body = isRepeat
        ? 'Kereta masih di dekat $stationName. Siapkan turun.'
        : 'Sekitar ${(distanceMeters / 1000).toStringAsFixed(1)} km lagi. Bersiap turun.';

    final androidDetails = AndroidNotificationDetails(
      AppConstants.channelApproachId,
      AppConstants.channelApproachName,
      channelDescription: AppConstants.channelApproachDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: enableVibration,
      vibrationPattern: enableVibration ? _vibrationPattern() : null,
      category: AndroidNotificationCategory.reminder,
      actions: const [
        AndroidNotificationAction(
          AppConstants.actionArrived,
          'Saya Sudah Turun',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          AppConstants.actionStillOnTrain,
          'Saya Masih di Kereta',
        ),
      ],
      styleInformation: BigTextStyleInformation(body),
    );

    await plugin.show(
      id: NotificationPayload.notificationIdFor(stationId),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
          presentBadge: true,
          categoryIdentifier: _approachCategoryId,
        ),
      ),
      payload: payload.encode(),
    );
  }

  Future<void> showJourneyStatus({
    required String journeyId,
    required String message,
  }) async {
    final payload = NotificationPayload(
      type: 'journey_status',
      journeyId: journeyId,
      destinationStationId: '',
      triggeredAt: DateTime.now(),
      isRepeat: false,
    );

    await plugin.show(
      id: 1,
      title: 'Pemantauan dijeda',
      body: message,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.channelStatusId,
          AppConstants.channelStatusName,
          channelDescription: AppConstants.channelStatusDescription,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
          presentBadge: false,
        ),
      ),
      payload: payload.encode(),
    );
  }

  Future<void> cancel(int id) => plugin.cancel(id: id);
}
