import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:railminder/data/local/station_asset_loader.dart';
import 'package:railminder/data/models/location_sample.dart';
import 'package:railminder/data/models/station.dart';

class FileAssetBundle extends CachingAssetBundle {
  final Map<String, String> files;

  FileAssetBundle(this.files);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final content = files[key];
    if (content == null) {
      throw ArgumentError('Unable to load asset: $key');
    }
    return content;
  }

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(await loadString(key));
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

StationAssetLoader fileStationLoader() {
  final raw = File('assets/data/krl_stations.json').readAsStringSync();
  return StationAssetLoader(
    bundle: FileAssetBundle({
      StationAssetLoader.defaultAssetPath: raw,
    }),
  );
}

/// Builds a sample [meters] north of [destination].
LocationSample sampleAtDistance(
  Station destination,
  double meters, {
  double accuracy = 10.0,
  required DateTime timestamp,
}) {
  const radius = 6371000.0;
  const bearing = 0.0;
  final angular = meters / radius;
  final lat1 = destination.latitude * math.pi / 180.0;
  final lon1 = destination.longitude * math.pi / 180.0;
  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angular) +
        math.cos(lat1) * math.sin(angular) * math.cos(bearing),
  );
  final lon2 = lon1 +
      math.atan2(
        math.sin(bearing) * math.sin(angular) * math.cos(lat1),
        math.cos(angular) - math.sin(lat1) * math.sin(lat2),
      );

  return LocationSample(
    latitude: lat2 * 180.0 / math.pi,
    longitude: lon2 * 180.0 / math.pi,
    accuracy: accuracy,
    timestamp: timestamp,
  );
}
