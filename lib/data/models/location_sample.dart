import '../../core/constants.dart';

class LocationSample {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final DateTime timestamp;

  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed,
  });

  bool isReliableAt(DateTime now) {
    if (accuracy <= 0 || accuracy > AppConstants.maxSampleAccuracyMeters) {
      return false;
    }
    final age = now.difference(timestamp);
    if (age.isNegative) return true;
    return age <= AppConstants.maxSampleAge;
  }
}
