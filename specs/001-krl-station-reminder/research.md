# Phase 0 Research: Pengingat Stasiun Tujuan KRL

## Decision: Framework & Target Platform
- **Decision**: Flutter (Dart 3.5+, Flutter 3.24+ targeting Android 10+ / API 29-34+ and iOS 16+)
- **Rationale**: User opted for Android + iOS via single codebase. Flutter provides unified UI with battle-tested platform channels for background geolocation and local notifications.
- **Alternatives considered**:
  - Native Kotlin / Jetpack Compose: Highest background reliability on Android, but requires writing the whole iOS app separately later.
  - React Native: Good ecosystem, but Flutter provides lower overhead for self-contained local state and easier offline asset management.

## Decision: Background Location & Foreground Service Architecture
- **Decision**: `geolocator` (v14+) combined with native Android `ForegroundService` of type `location` (`FOREGROUND_SERVICE_LOCATION`), plus iOS `UIBackgroundModes: ['location']`.
- **Rationale**:
  - Android 14+ strictly mandates `FOREGROUND_SERVICE_LOCATION` and active foreground notification when monitoring in the background. `geolocator`'s `AndroidSettings.foregroundNotificationConfig` automatically binds the Android foreground service lifecycle to the location stream.
  - On iOS, `AppleSettings(showBackgroundLocationIndicator: true, pauseLocationUpdatesAutomatically: false)` keeps location stream alive while on the train.
  - Native OS geofencing (`GeofenceClient` / `CLCircularRegion`) has severe limits (max 100 geofences, wake delay up to several minutes when moving at high train speed ~60-80 km/h). Continuous high-accuracy distance calculation on location stream guarantees prompt alert within 10 seconds of entering the threshold radius.
- **Alternatives considered**:
  - OS-native Geofencing API: Energy-efficient, but OS throttle may delay firing by 1–3 minutes, causing passengers on fast trains to overshoot the station.
  - Background Fetch / WorkManager periodic poll: Minimum interval 15 minutes, completely unsuitable for real-time train approach.

## Decision: Station Data & Geolocation Matching
- **Decision**: Bundled offline static JSON (`assets/data/krl_stations.json`) containing Jabodetabek KRL Commuter Line station names, station codes, line identifiers, and latitude/longitude coordinates (WGS84).
- **Rationale**:
  - Eliminates external API dependencies and works 100% offline (satisfying FR-001, FR-015, and SC-005).
  - Haversine distance formula / `Geolocator.distanceBetween(lat1, lon1, lat2, lon2)` calculates real-time distance in meters with negligible CPU overhead.
  - Station coordinates do not change frequently; updates can be bundled in app updates or cached locally.
- **Alternatives considered**:
  - Live API fetch from KAI Commuter: Unofficial APIs are fragile, break frequently, and fail completely in tunnels/dead zones.

## Decision: Alerting Mechanism (Notification & Vibration)
- **Decision**: `flutter_local_notifications` with High Importance / Max Priority Notification Channel on Android, with a distinctive repeating vibration pattern, plus iOS Alert & Sound/Haptic settings.
- **Rationale**:
  - User requested "Notifikasi + getar saja" (no screaming audio alarm that disturbs passengers).
  - High importance channel produces heads-up notification and phone vibration even if device screen is locked or user is in another app.
  - Interactive notification actions (`Saya Sudah Turun`, `Saya Masih di Kereta`) allow instant acknowledgment directly from lock screen.
- **Alternatives considered**:
  - Media player full-volume alarm: Disturbs public transit passengers and rejected by user choice.
  - Silent badge notification: Too easily missed when passenger is asleep or phone is in bag.

## Decision: Local Persistence & Journey State Restoration
- **Decision**: `shared_preferences` for active journey state and user settings; `sqflite` (or structured local storage) for past journey history.
- **Rationale**:
  - Fast atomic read on app startup to recover interrupted journeys (FR-013).
  - Zero heavy database overhead for active state tracking.
- **Alternatives considered**:
  - Cloud Firestore / Supabase: Violates offline-first requirement and introduces unnecessary privacy/auth surface.

## Decision: State Management
- **Decision**: `flutter_riverpod` (v2.5+) with `AsyncNotifier` and `StreamProvider`.
- **Rationale**:
  - Clean separation of background stream lifecycle, geolocation service, journey engine, and UI presentation.
  - Highly testable with unit and mock tests.
