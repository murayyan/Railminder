<!--
SYNC IMPACT REPORT
Version change: [TEMPLATE] -> 1.0.0
Modified principles: Initial constitution ratification for Railminder
Added sections: Core Principles, Technical Standards, Quality Gates, Governance
Removed sections: None
Deferred items: None
-->

# Railminder Constitution

## Core Principles

### I. Offline-First Architecture
The core journey workflow (station selection, distance calculation, approach alerting, and trip completion) MUST function with 100% reliability with zero internet connection.
- All station coordinates, line sequences, and metadata MUST be bundled locally inside application assets (`assets/data/krl_stations.json`).
- No external network API or operator server MAY be required to start or finish a trip.

### II. Privacy by Default & Zero Telemetry
User location samples, travel history, and travel patterns belong exclusively to the user's physical device.
- Location samples MUST NOT be sent to any remote server or third-party analytical SDK.
- The app MUST NOT require account registration, login, or personal identifiers.
- Travel history MUST be stored locally and fully clearable by the user at any time.

### III. Deterministic Pure Alert Engine
The alert trigger logic MUST be implemented as a pure, side-effect-free domain engine (`JourneyEngine`).
- Decision logic MUST NOT directly invoke platform plugins, read system clocks, or poll hardware sensors.
- State transitions, threshold evaluations, hysteresis, and debounce MUST be 100% reproducible via unit tests using deterministic location vectors.
- All 10 defined test vectors (TV-01 through TV-10) MUST pass before any release.

### IV. Battery & Background Reliability
Background location tracking is constrained by strict OS thermal and energy policies.
- Background location on Android MUST be encapsulated within a foreground service of type `location` (`FOREGROUND_SERVICE_LOCATION`) with a persistent status notification.
- Location streams MUST implement accuracy filtering (ignore samples with horizontal error >100 m) and reasonable distance filters (100 m) to prevent battery drain.
- Energy consumption MUST NOT exceed an average of 5% battery drain per hour of continuous tracking.

### V. Polite Public Transit Alerting
Alarms in commuter train cabins must alert the passenger without distressing neighboring commuters.
- The primary alert MUST be a high-importance heads-up notification with a distinctive vibration pattern.
- The app MUST NOT play loud audio alarms that bypass device silent/vibrate mode or disturb others in public carriages unless explicitly enabled by user override.
- Actionable notification buttons ("Saya Sudah Turun" and "Saya Masih di Kereta") MUST be provided directly on the lock screen.

## Technical Standards

### Platform Support
- Target framework: Flutter (Dart 3.5+, Flutter 3.24+).
- Android target: Android 10+ (API 29+), complying with Android 14/15 Foreground Service types and notification permissions.
- iOS target: iOS 16+, complying with `UIBackgroundModes: location` and CoreLocation usage disclosures.

### Storage & State Management
- Ephemeral active journey state: `shared_preferences`.
- Historical trip data: `sqflite` local database.
- Application state: `flutter_riverpod` with strict separation of data layer, services, and UI.

## Quality Gates

Before any pull request or merge to main:
1. `flutter analyze` MUST pass with 0 errors and 0 new warnings.
2. All unit tests (`flutter test test/unit/`) MUST pass.
3. Engine test vectors TV-01 through TV-10 MUST pass.
4. Android and iOS permission manifests MUST conform to the contracts.

## Governance

- This Constitution supersedes all informal coding practices or conflicting documentation.
- Any amendment to Core Principles requires bumping `CONSTITUTION_VERSION` according to Semantic Versioning:
  - MAJOR: Removal or fundamental relaxation of Core Principles.
  - MINOR: Addition of new principles or technical standards.
  - PATCH: Wording clarifications and non-semantic corrections.
- Ratified amendments MUST be dated and documented in the project log.

**Version**: 1.0.0 | **Ratified**: 2026-11-08 | **Last Amended**: 2026-11-08
