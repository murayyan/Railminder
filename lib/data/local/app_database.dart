import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String databaseName = 'railminder.db';
  static const int databaseVersion = 1;

  final Database _db;

  AppDatabase(this._db);

  Database get raw => _db;

  static Future<AppDatabase> open({DatabaseFactory? factory, String? path}) async {
    final effectiveFactory = factory ?? databaseFactory;
    final fullPath = path ?? '${await effectiveFactory.getDatabasesPath()}/$databaseName';

    final db = await effectiveFactory.openDatabase(
      fullPath,
      options: OpenDatabaseOptions(
        version: databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
      ),
    );
    return AppDatabase(db);
  }

  static Future<void> _createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE journeys (
        id TEXT PRIMARY KEY,
        destination_station_id TEXT NOT NULL,
        destination_station_name TEXT NOT NULL,
        origin_station_id TEXT,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        status TEXT NOT NULL,
        alert_threshold_meters INTEGER NOT NULL,
        alert_triggered_count INTEGER NOT NULL,
        first_alert_triggered_at TEXT,
        final_resolution TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE alert_events (
        id TEXT PRIMARY KEY,
        journey_id TEXT NOT NULL,
        triggered_at TEXT NOT NULL,
        distance_meters REAL NOT NULL,
        accuracy_meters REAL NOT NULL,
        is_repeat INTEGER NOT NULL,
        user_action TEXT,
        action_timestamp TEXT,
        FOREIGN KEY (journey_id) REFERENCES journeys(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_alert_events_journey ON alert_events(journey_id)',
    );
    await db.execute(
      'CREATE INDEX idx_journeys_started_at ON journeys(started_at DESC)',
    );
  }

  Future<void> close() async {
    await _db.close();
  }
}
