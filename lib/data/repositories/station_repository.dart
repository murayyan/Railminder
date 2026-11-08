import '../local/station_asset_loader.dart';
import '../models/line.dart';
import '../models/station.dart';

class StationRepository {
  final StationAssetLoader loader;

  StationDataset? _cached;
  Map<String, Station> _stationMap = const {};
  Map<String, StationLine> _lineMap = const {};

  StationRepository({StationAssetLoader? loader})
    : loader = loader ?? StationAssetLoader();

  bool get isLoaded => _cached != null;

  String get version => _cached?.version ?? '';

  Future<void> initialize() async {
    if (_cached != null) return;
    final dataset = await loader.load();
    validateDataset(dataset);
    _cached = dataset;
    _stationMap = {for (final s in dataset.stations) s.id: s};
    _lineMap = {for (final l in dataset.lines) l.id: l};
  }

  List<Station> getAllStations() => _cached?.stations ?? const [];

  List<StationLine> getAllLines() => _cached?.lines ?? const [];

  Station? getStationById(String id) => _stationMap[id];

  StationLine? getLineById(String id) => _lineMap[id];

  List<Station> searchStations(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return getAllStations();

    return getAllStations()
        .where(
          (s) =>
              s.name.toLowerCase().contains(trimmed) ||
              s.id.toLowerCase() == trimmed,
        )
        .toList(growable: false);
  }

  static void validateDataset(StationDataset dataset) {
    final stations = {for (final s in dataset.stations) s.id: s};
    final lines = {for (final l in dataset.lines) l.id: l};

    if (stations.length != dataset.stations.length) {
      throw const FormatException('Dataset contains duplicate station ids');
    }
    if (lines.length != dataset.lines.length) {
      throw const FormatException('Dataset contains duplicate line ids');
    }

    for (final s in dataset.stations) {
      for (final lineId in s.lineIds) {
        if (!lines.containsKey(lineId)) {
          throw FormatException(
            'Station ${s.id} (${s.name}) references missing line $lineId',
          );
        }
      }
    }

    for (final l in dataset.lines) {
      for (final stationId in l.stationIds) {
        if (!stations.containsKey(stationId)) {
          throw FormatException(
            'Line ${l.id} (${l.name}) references missing station $stationId',
          );
        }
      }
    }
  }
}
