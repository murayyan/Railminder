import '../../core/constants.dart';

class UserSettings {
  final int alertDistanceMeters;
  final bool enableVibration;
  final int repeatIntervalMinutes;
  final int maxRepeats;

  const UserSettings({
    this.alertDistanceMeters = AppConstants.defaultAlertThresholdMeters,
    this.enableVibration = true,
    this.repeatIntervalMinutes = AppConstants.defaultRepeatIntervalMinutes,
    this.maxRepeats = AppConstants.defaultMaxRepeats,
  });

  UserSettings copyWith({
    int? alertDistanceMeters,
    bool? enableVibration,
    int? repeatIntervalMinutes,
    int? maxRepeats,
  }) {
    return UserSettings(
      alertDistanceMeters: alertDistanceMeters ?? this.alertDistanceMeters,
      enableVibration: enableVibration ?? this.enableVibration,
      repeatIntervalMinutes: repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      maxRepeats: maxRepeats ?? this.maxRepeats,
    );
  }

  Map<String, dynamic> toJson() => {
    'alertDistanceMeters': alertDistanceMeters,
    'enableVibration': enableVibration,
    'repeatIntervalMinutes': repeatIntervalMinutes,
    'maxRepeats': maxRepeats,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final distance = json['alertDistanceMeters'];
    final interval = json['repeatIntervalMinutes'];
    final repeats = json['maxRepeats'];
    return UserSettings(
      alertDistanceMeters: distance is int && distance > 0
          ? distance
          : AppConstants.defaultAlertThresholdMeters,
      enableVibration: json['enableVibration'] is bool
          ? json['enableVibration'] as bool
          : true,
      repeatIntervalMinutes: interval is int && interval > 0
          ? interval
          : AppConstants.defaultRepeatIntervalMinutes,
      maxRepeats: repeats is int && repeats >= 0
          ? repeats
          : AppConstants.defaultMaxRepeats,
    );
  }
}
