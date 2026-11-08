# Implementation Plan: Pengingat Stasiun Tujuan KRL

**Branch**: `001-krl-station-reminder` | **Date**: 2026-11-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-krl-station-reminder/spec.md`

## Summary

Aplikasi mobile Flutter (Android + iOS) yang memantau posisi GPS pengguna selama perjalanan KRL dan mengirim notifikasi + getar ketika kereta mendekati stasiun tujuan. Deteksi berbasis perhitungan jarak ke koordinat stasiun yang dibundel offline, dijalankan oleh location stream di dalam foreground service (Android) / background location mode (iOS). Seluruh data perjalanan dan daftar stasiun tersimpan di perangkat; tidak ada backend, akun, atau ketergantungan API operator.

## Technical Context

**Language/Version**: Dart 3.5+ / Flutter 3.24+ (stable channel)

**Primary Dependencies**: `flutter_riverpod` (state), `geolocator` 14.x (location stream + foreground service config), `flutter_local_notifications` (notification channel, actions, vibration), `shared_preferences` (active journey + settings), `sqflite` (journey history), `permission_handler` (permission prompts & settings deep-link), `intl` (date formatting). Versi minor dikunci saat `flutter pub add` di fase implementasi.

**Storage**: Local-only — `shared_preferences` untuk state perjalanan aktif dan preferensi; `sqflite` untuk riwayat perjalanan; aset JSON `assets/data/krl_stations.json` untuk daftar stasiun. Tidak ada database server.

**Testing**: `flutter_test` (unit + widget), `integration_test` untuk alur end-to-end, dan simulasi location stream melalui `TestLocationSource` (fake stream) agar logika alert deterministik. GPX track untuk uji di emulator/simulator.

**Target Platform**: Android 10+ (API 29) dengan target SDK 35 dan deklarasi foreground service type `location`; iOS 16+ dengan `UIBackgroundModes: location`.

**Project Type**: mobile-app (single Flutter application, tanpa backend)

**Performance Goals**: Konsumsi baterai ≤5% per jam pemantauan; notifikasi terkirim ≤10 detik setelah ambang terlewati; cold start <2 detik; pemrosesan sampel lokasi <5 ms per event.

**Constraints**: Offline-first 100% untuk alur inti; izin lokasi latar belakang wajib; notifikasi harus muncul saat layar mati; tidak ada alarm yang menembus mode senyap; tidak ada pengumpulan data pribadi.

**Scale/Scope**: ±100 stasiun KRL Jabodetabek, satu pengguna perangkat, 5 layar utama (Beranda, Pilih Tujuan, Perjalanan Aktif, Riwayat, Pengaturan).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution diratifikasi pada 2026-11-08 sebagai **Railminder Constitution v1.0.0** (`.specify/memory/constitution.md`).

| Gate | Prinsip | Status |
|------|---------|--------|
| Offline-first: alur inti berjalan tanpa jaringan | I. Offline-First Architecture | PASS — data stasiun dibundel di `assets/data/`, tanpa panggilan jaringan (FR-001, FR-015, SC-005) |
| Privacy: data lokasi & riwayat hanya di perangkat | II. Privacy by Default & Zero Telemetry | PASS — tanpa akun, tanpa telemetry, tanpa cloud (Assumptions) |
| Deterministic engine: logika alert murni & reproducible | III. Deterministic Pure Alert Engine | PASS — `journey_engine.dart` tanpa plugin, TV-01..TV-10 wajib lulus |
| Battery & background reliability | IV. Battery & Background Reliability | PASS — FGS type `location`, `distanceFilter: 100`, filter akurasi 100 m, target ≤5%/jam (SC-003) |
| Polite alerting: notifikasi + getar, tanpa audio paksa | V. Polite Public Transit Alerting | PASS — importance `max` + vibration pattern, tanpa suara (FR-005) |
| Platform compliance: FGS type & izin sesuai kebijakan store | Technical Standards | PASS — kontrak izin terdokumentasi di `contracts/permissions.md` |

**Post-Design Re-check**: Seluruh gate tetap PASS setelah Phase 1. Tidak ada pelanggaran yang perlu dijustifikasi; Complexity Tracking dibiarkan kosong.

## Project Structure

### Documentation (this feature)

```text
specs/001-krl-station-reminder/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── alert-engine.md
│   ├── notifications.md
│   ├── permissions.md
│   └── station-data.schema.json
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants.dart          # ambang default, interval, channel id
│   ├── theme.dart
│   └── distance.dart           # haversine + filter akurasi
├── data/
│   ├── models/
│   │   ├── station.dart
│   │   ├── line.dart
│   │   ├── journey.dart
│   │   ├── alert_event.dart
│   │   └── user_settings.dart
│   ├── local/
│   │   ├── app_database.dart   # sqflite schema + migrations
│   │   ├── journey_store.dart  # active journey in shared_preferences
│   │   └── station_asset_loader.dart
│   └── repositories/
│       ├── station_repository.dart
│       ├── journey_repository.dart
│       └── settings_repository.dart
├── services/
│   ├── permission_service.dart
│   ├── location_service.dart   # geolocator stream + platform settings
│   ├── journey_engine.dart     # pure alert logic (no plugin calls)
│   └── notification_service.dart
├── features/
│   ├── home/
│   ├── destination_picker/
│   ├── active_journey/
│   ├── history/
│   └── settings/
└── providers/
    └── providers.dart

assets/
└── data/
    └── krl_stations.json

test/
├── unit/
│   ├── journey_engine_test.dart
│   ├── distance_test.dart
│   └── station_repository_test.dart
└── widget/
    └── active_journey_test.dart

integration_test/
└── journey_flow_test.dart

android/app/src/main/AndroidManifest.xml   # FGS type location + permissions
ios/Runner/Info.plist                      # UIBackgroundModes + usage descriptions
```

**Structure Decision**: Satu aplikasi Flutter dengan pemisahan `core`/`data`/`services`/`features`. Logika pemicu alert dipisah ke `journey_engine.dart` tanpa dependensi plugin agar dapat diuji sebagai fungsi murni. Tidak ada direktori backend.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
