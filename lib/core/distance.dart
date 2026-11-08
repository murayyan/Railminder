import 'dart:math' as math;

import '../data/models/location_sample.dart';

const double _earthRadiusMeters = 6371000.0;

double haversineMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusMeters * c;
}

double _radians(double degrees) => degrees * math.pi / 180.0;

/// True when the sample is fresh and accurate enough to drive alerting.
bool isSampleUsable(LocationSample sample, DateTime now) {
  if (!sample.latitude.isFinite || !sample.longitude.isFinite) return false;
  if (sample.latitude < -90 || sample.latitude > 90) return false;
  if (sample.longitude < -180 || sample.longitude > 180) return false;
  return sample.isReliableAt(now);
}
