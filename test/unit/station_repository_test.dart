import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/data/local/station_asset_loader.dart';
import 'package:railminder/data/repositories/station_repository.dart';

class _FileAssetBundle extends CachingAssetBundle {
  final Map<String, String> _files;

  _FileAssetBundle(this._files);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final content = _files[key];
    if (content == null) {
      throw ArgumentError('Unable to load asset: $key');
    }
    return content;
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    final bytes = utf8.encode(str);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StationRepository repository;

  setUp(() async {
    final rawJson = await File('assets/data/krl_stations.json').readAsString();
    final bundle = _FileAssetBundle({
      StationAssetLoader.defaultAssetPath: rawJson,
    });
    repository = StationRepository(
      loader: StationAssetLoader(bundle: bundle),
    );
    await repository.initialize();
  });

  test('dataset loads all stations and lines without error', () {
    expect(repository.isLoaded, isTrue);
    expect(repository.version, isNotEmpty);
    expect(repository.getAllStations().length, 81);
    expect(repository.getAllLines().length, 6);
  });

  test('no orphan line or station references', () {
    final stations = repository.getAllStations();
    final lines = repository.getAllLines();
    final lineIds = {for (final l in lines) l.id};
    final stationIds = {for (final s in stations) s.id};

    for (final s in stations) {
      for (final lid in s.lineIds) {
        expect(lineIds.contains(lid), isTrue,
            reason: '${s.id} points to unknown line $lid');
      }
    }

    for (final l in lines) {
      for (final sid in l.stationIds) {
        expect(stationIds.contains(sid), isTrue,
            reason: '${l.id} points to unknown station $sid');
      }
    }
  });

  test('station ids are unique', () {
    final stations = repository.getAllStations();
    final ids = stations.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('search finds stations by partial name case-insensitive', () {
    final bogor = repository.searchStations('bogor');
    expect(bogor.any((s) => s.id == 'BOO'), isTrue);

    final manggarai = repository.searchStations('MANGGARAI');
    expect(manggarai.any((s) => s.id == 'MRI'), isTrue);

    final empty = repository.searchStations('');
    expect(empty.length, 81);
  });

  test('getStationById returns exact station or null', () {
    final boo = repository.getStationById('BOO');
    expect(boo, isNotNull);
    expect(boo!.name, 'Bogor');

    final missing = repository.getStationById('XYZ99');
    expect(missing, isNull);
  });
}
