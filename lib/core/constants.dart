class AppConstants {
  static const String appName = 'Railminder';

  // Notification channels
  static const String channelApproachId = 'station_approach';
  static const String channelApproachName = 'Peringatan Stasiun Tujuan';
  static const String channelApproachDescription =
      'Notifikasi dan getaran saat kereta mendekati stasiun tujuan.';

  static const String channelStatusId = 'journey_status';
  static const String channelStatusName = 'Status Perjalanan';
  static const String channelStatusDescription =
      'Status pemantauan posisi saat perjalanan aktif.';

  // Notification action IDs
  static const String actionArrived = 'saya_sudah_turun';
  static const String actionStillOnTrain = 'saya_masih_di_kereta';
  static const String actionStopJourney = 'hentikan_perjalanan';

  // Vibration pattern in ms: wait, buzz, pause, buzz, pause, long buzz
  static const List<int> approachVibrationPattern = [
    0,
    500,
    200,
    500,
    200,
    800,
  ];

  // Engine & alerting math (contracts/alert-engine.md)
  static const double armMarginMeters = 500.0;
  static const Duration minAlertCooldown = Duration(seconds: 30);
  static const Duration maxSampleAge = Duration(seconds: 30);
  static const double maxSampleAccuracyMeters = 100.0;
  static const int routeMismatchHoldSamples = 3;
  static const double routeMismatchDeltaMeters = 300.0;
  static const double routeMismatchMinDistanceMeters = 1000.0;

  // Defaults
  static const int defaultAlertThresholdMeters = 1500;
  static const int defaultRepeatIntervalMinutes = 3;
  static const int defaultMaxRepeats = 3;
  static const List<int> thresholdOptionsMeters = [1000, 1500, 2000];

  // Asset paths
  static const String stationsAssetPath = 'assets/data/krl_stations.json';
}
