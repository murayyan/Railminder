import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/core/distance.dart';
import 'package:railminder/data/models/location_sample.dart';

void main() {
  test('haversine calculates distance matching reference within 0.5%', () {
    // Jakarta Kota (lat -6.137583, lon 106.814620) to Bogor (lat -6.594289, lon 106.790769)
    // Reference distance roughly 50.85 km
    final d = haversineMeters(
      lat1: -6.137583,
      lon1: 106.814620,
      lat2: -6.594289,
      lon2: 106.790769,
    );
    expect((d - 50850).abs() < 500, isTrue,
        reason: 'Distance between JAKK and BOO should be ~50.8 km, got $d');
  });

  test('haversine returns 0 for identical points', () {
    final d = haversineMeters(
      lat1: -6.175,
      lon1: 106.827,
      lat2: -6.175,
      lon2: 106.827,
    );
    expect(d, 0.0);
  });

  test('isSampleUsable rejects inaccurate samples (>100m)', () {
    final now = DateTime(2026, 11, 8, 10, 0, 0);
    final accurate = LocationSample(
      latitude: -6.175,
      longitude: 106.827,
      accuracy: 50.0,
      timestamp: now,
    );
    final inaccurate = LocationSample(
      latitude: -6.175,
      longitude: 106.827,
      accuracy: 101.0,
      timestamp: now,
    );

    expect(isSampleUsable(accurate, now), isTrue);
    expect(isSampleUsable(inaccurate, now), isFalse);
  });

  test('isSampleUsable rejects stale samples (>30s)', () {
    final now = DateTime(2026, 11, 8, 10, 0, 0);
    final fresh = LocationSample(
      latitude: -6.175,
      longitude: 106.827,
      accuracy: 10.0,
      timestamp: now.subtract(const Duration(seconds: 25)),
    );
    final stale = LocationSample(
      latitude: -6.175,
      longitude: 106.827,
      accuracy: 10.0,
      timestamp: now.subtract(const Duration(seconds: 35)),
    );

    expect(isSampleUsable(fresh, now), isTrue);
    expect(isSampleUsable(stale, now), isFalse);
  });

  test('isSampleUsable rejects invalid coordinates and accuracy <= 0', () {
    final now = DateTime(2026, 11, 8, 10, 0, 0);
    final negAcc = LocationSample(
      latitude: -6.175,
      longitude: 106.827,
      accuracy: 0.0,
      timestamp: now,
    );
    final outOfBounds = LocationSample(
      latitude: 95.0,
      longitude: 106.827,
      accuracy: 10.0,
      timestamp: now,
    );

    expect(isSampleUsable(negAcc, now), isFalse);
    expect(isSampleUsable(outOfBounds, now), isFalse);
  });
}
