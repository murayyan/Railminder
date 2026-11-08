import 'package:flutter_test/flutter_test.dart';
import 'package:railminder/data/models/user_settings.dart';
import 'package:railminder/data/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults are returned when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    final settings = repo.load();
    expect(settings.alertDistanceMeters, 1500);
    expect(settings.enableVibration, isTrue);
    expect(settings.repeatIntervalMinutes, 3);
    expect(settings.maxRepeats, 3);
  });

  test('round-trips every field', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    const custom = UserSettings(
      alertDistanceMeters: 2000,
      enableVibration: false,
      repeatIntervalMinutes: 5,
      maxRepeats: 2,
    );
    await repo.save(custom);

    final loaded = repo.load();
    expect(loaded.alertDistanceMeters, 2000);
    expect(loaded.enableVibration, isFalse);
    expect(loaded.repeatIntervalMinutes, 5);
    expect(loaded.maxRepeats, 2);
  });

  test('corrupted preferences fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'railminder.settings.v1': 'not json at all',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    final settings = repo.load();
    expect(settings.alertDistanceMeters, 1500);
  });

  test('out-of-range stored values are repaired', () async {
    SharedPreferences.setMockInitialValues({
      'railminder.settings.v1':
          '{"alertDistanceMeters":-5,"repeatIntervalMinutes":0,'
              '"maxRepeats":-1,"enableVibration":"yes"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository(prefs);

    final settings = repo.load();
    expect(settings.alertDistanceMeters, 1500);
    expect(settings.repeatIntervalMinutes, 3);
    expect(settings.maxRepeats, 3);
    expect(settings.enableVibration, isTrue);
  });
}
