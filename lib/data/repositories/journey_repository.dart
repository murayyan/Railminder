import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/alert_event.dart';
import '../models/engine_progress.dart';
import '../models/journey.dart';

/// Storage surface used by the app. The SQLite implementation is the shipping
/// one; tests supply an in-memory implementation so widget tests stay
/// independent from platform channels.
abstract class JourneyStore {
  ActiveJourneyState? loadActive();

  Future<void> saveActive(ActiveJourneyState state);

  Future<void> clearActive();

  Future<void> insertJourney(Journey journey);

  Future<void> updateJourney(Journey journey);

  Future<void> recordAlertEvent(AlertEvent event);

  Future<void> updateAlertEvent(AlertEvent event);

  Future<List<Journey>> getHistory({int limit = 50});

  Future<List<AlertEvent>> getAlertEvents(String journeyId);

  Future<void> clearAllHistory();
}

class JourneyRepository implements JourneyStore {
  static const String _activeKey = 'railminder.active_journey.v1';

  final SharedPreferences prefs;
  final AppDatabase database;

  JourneyRepository({required this.prefs, required this.database});

  @override
  ActiveJourneyState? loadActive() {
    final raw = prefs.getString(_activeKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ActiveJourneyState.fromJson(decoded);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  @override
  Future<void> saveActive(ActiveJourneyState state) =>
      prefs.setString(_activeKey, jsonEncode(state.toJson()));

  @override
  Future<void> clearActive() => prefs.remove(_activeKey);

  @override
  Future<void> insertJourney(Journey journey) async {
    await database.raw.insert(
      'journeys',
      journey.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateJourney(Journey journey) async {
    await database.raw.update(
      'journeys',
      journey.toMap(),
      where: 'id = ?',
      whereArgs: [journey.id],
    );
  }

  @override
  Future<void> recordAlertEvent(AlertEvent event) async {
    await database.raw.insert(
      'alert_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateAlertEvent(AlertEvent event) async {
    await database.raw.update(
      'alert_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  @override
  Future<List<Journey>> getHistory({int limit = 50}) async {
    final rows = await database.raw.query(
      'journeys',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map((r) => Journey.fromMap(r)).toList(growable: false);
  }

  @override
  Future<List<AlertEvent>> getAlertEvents(String journeyId) async {
    final rows = await database.raw.query(
      'alert_events',
      where: 'journey_id = ?',
      whereArgs: [journeyId],
      orderBy: 'triggered_at ASC',
    );
    return rows.map((r) => AlertEvent.fromMap(r)).toList(growable: false);
  }

  @override
  Future<void> clearAllHistory() async {
    await database.raw.delete('alert_events');
    await database.raw.delete('journeys');
  }
}

class InMemoryJourneyStore implements JourneyStore {
  ActiveJourneyState? _active;
  final Map<String, Journey> _journeys = {};
  final List<AlertEvent> _events = [];

  @override
  ActiveJourneyState? loadActive() => _active;

  @override
  Future<void> saveActive(ActiveJourneyState state) async {
    _active = state;
  }

  @override
  Future<void> clearActive() async {
    _active = null;
  }

  @override
  Future<void> insertJourney(Journey journey) async {
    _journeys[journey.id] = journey;
  }

  @override
  Future<void> updateJourney(Journey journey) async {
    _journeys[journey.id] = journey;
  }

  @override
  Future<void> recordAlertEvent(AlertEvent event) async {
    _events.removeWhere((e) => e.id == event.id);
    _events.add(event);
  }

  @override
  Future<void> updateAlertEvent(AlertEvent event) async {
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      _events[idx] = event;
    } else {
      _events.add(event);
    }
  }

  @override
  Future<List<Journey>> getHistory({int limit = 50}) async {
    final list = _journeys.values.toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list.take(limit).toList();
  }

  @override
  Future<List<AlertEvent>> getAlertEvents(String journeyId) async {
    final list = _events.where((e) => e.journeyId == journeyId).toList()
      ..sort((a, b) => a.triggeredAt.compareTo(b.triggeredAt));
    return list;
  }

  @override
  Future<void> clearAllHistory() async {
    _journeys.clear();
    _events.clear();
  }
}
