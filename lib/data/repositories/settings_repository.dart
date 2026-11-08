import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';

class SettingsRepository {
  static const String _key = 'railminder.settings.v1';

  final SharedPreferences prefs;

  SettingsRepository(this.prefs);

  UserSettings load() {
    final raw = prefs.getString(_key);
    if (raw == null) return const UserSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserSettings.fromJson(decoded);
      }
    } on FormatException {
      return const UserSettings();
    }
    return const UserSettings();
  }

  Future<void> save(UserSettings settings) =>
      prefs.setString(_key, jsonEncode(settings.toJson()));
}
