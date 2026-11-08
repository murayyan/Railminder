import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/line.dart';
import '../models/station.dart';

class StationDataset {
  final String version;
  final List<StationLine> lines;
  final List<Station> stations;

  const StationDataset({
    required this.version,
    required this.lines,
    required this.stations,
  });
}

class StationAssetLoader {
  static const String defaultAssetPath = 'assets/data/krl_stations.json';

  final AssetBundle bundle;
  final String assetPath;

  StationAssetLoader({AssetBundle? bundle, this.assetPath = defaultAssetPath})
    : bundle = bundle ?? rootBundle;

  Future<StationDataset> load() async {
    final raw = await bundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Station dataset must be a JSON object');
    }

    final version = decoded['version'];
    final linesJson = decoded['lines'];
    final stationsJson = decoded['stations'];

    if (version is! String) {
      throw const FormatException('Dataset version is missing');
    }
    if (linesJson is! List || stationsJson is! List) {
      throw const FormatException('Dataset lines and stations must be lists');
    }

    return StationDataset(
      version: version,
      lines: linesJson
          .map((item) => StationLine.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      stations: stationsJson
          .map((item) => Station.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}
