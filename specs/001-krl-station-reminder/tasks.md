# Tasks: Pengingat Stasiun Tujuan KRL

**Input**: Design documents from `/specs/001-krl-station-reminder/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Wajib. [Constitution v1.0.0](../.specify/memory/constitution.md) Prinsip III dan Quality Gates mewajibkan test vector TV-01..TV-10 lulus, dan [quickstart.md](./quickstart.md) §2 menetapkan perintah test sebagai gate rilis.

**Organization**: Task dikelompokkan per user story agar tiap increment dapat diimplementasi dan diuji mandiri.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Boleh berjalan paralel (file berbeda, tanpa dependensi task yang belum selesai)
- **[Story]**: US1 / US2 / US3 sesuai user story di spec.md
- Setiap task mencantumkan path file absolut-relatif terhadap root repo

## Path Conventions

Flutter single-app: `lib/`, `test/`, `integration_test/`, `assets/`, `android/`, `ios/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold proyek Flutter dan konfigurasi platform.

- [x] T001 Scaffold Flutter app Android+iOS dengan `flutter create --org app.railminder --platforms android,ios .` di root repo, lalu pastikan `pubspec.yaml` memakai `name: railminder`
- [x] T002 Tambahkan dependensi runtime di `pubspec.yaml`: `flutter_riverpod`, `geolocator`, `flutter_local_notifications`, `shared_preferences`, `sqflite`, `permission_handler`, `intl`; lalu jalankan `flutter pub get`
- [x] T003 [P] Tambahkan dev dependencies `flutter_lints` dan `integration_test` serta konfigurasi linter di `analysis_options.yaml`
- [x] T004 [P] Daftarkan izin dan foreground service type `location` di `android/app/src/main/AndroidManifest.xml` persis sesuai [contracts/permissions.md](./contracts/permissions.md), termasuk `POST_NOTIFICATIONS`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE_LOCATION`
- [x] T005 [P] Daftarkan `UIBackgroundModes: location` dan tiga `NSLocation*UsageDescription` di `ios/Runner/Info.plist` sesuai [contracts/permissions.md](./contracts/permissions.md)
- [x] T006 [P] Set `minSdk 29`, `compileSdk 36`, `targetSdk 36` di `android/app/build.gradle.kts`; set deployment target `16.0` di `ios/Podfile`
- [x] T007 [P] Buat `lib/core/constants.dart` berisi channel ID `station_approach`/`journey_status`, `armMargin = 500`, `minAlertCooldown = 30s`, `maxSampleAge = 30s`, dan default ambang 1500 m
- [x] T008 [P] Buat `lib/core/theme.dart` dengan tema Material 3 dan warna jalur KRL
- [x] T009 [P] Susun dataset `assets/data/krl_stations.json` untuk stasiun KRL Jabodetabek dan validasi terhadap [contracts/station-data.schema.json](./contracts/station-data.schema.json); daftarkan folder `assets/data/` di `pubspec.yaml`
- [x] T010 [P] Siapkan track GPX uji pendekatan Bogor di `test/fixtures/bogor_approach.gpx` (titik 2.5 km → 1.6 km → 1.4 km → 0.3 km dari BOO)

**Checkpoint**: Proyek bisa di-build di Android; aset dan izin siap.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Model, storage, dan service dasar yang dipakai semua user story.

**⚠️ CRITICAL**: Tidak ada user story yang boleh dimulai sebelum fase ini selesai.

- [x] T011 [P] Buat `lib/data/models/station.dart`: field `id` (2–5 huruf kapital), `name` (3–80 char), `lineIds`, `latitude` (-7.0..-5.8), `longitude` (106.3..107.4), `orderIndex` (≥0) sesuai [data-model.md](./data-model.md), termasuk `fromJson` dengan validasi rentang
- [x] T012 [P] Buat `lib/data/models/line.dart`: field `id`, `name`, `colorHex` (`^#[0-9A-F]{6}$`), `stationIds` (min 2, unik)
- [x] T013 [P] Buat `lib/data/models/enums.dart`: `JourneyStatus {active, completed, cancelled}`, `ResolutionType {confirmedArrived, manualStop, stillOnTrainTimeout}`, `UserAlertAction {arrived, stillOnTrain, dismissed, timedOut}`
- [x] T014 [P] Buat `lib/data/models/location_sample.dart`: `latitude`, `longitude`, `accuracy`, `speed?`, `timestamp`, plus getter `isReliable` (accuracy ≤100 m dan umur ≤30 s)
- [x] T015 [P] Buat `lib/data/models/journey.dart`: seluruh field di [data-model.md](./data-model.md) §3 termasuk `alertThresholdMeters`, `alertTriggeredCount`, `firstAlertTriggeredAt`, `finalResolution`
- [x] T016 [P] Buat `lib/data/models/alert_event.dart`: `id`, `journeyId`, `triggeredAt`, `distanceMeters`, `accuracyMeters`, `isRepeat`, `userAction?`, `actionTimestamp?`
- [x] T017 [P] Buat `lib/data/models/user_settings.dart` dengan default `alertDistanceMeters: 1500`, `enableVibration: true`, `repeatIntervalMinutes: 3`, `maxRepeats: 3`
- [x] T018 [P] Implementasikan haversine dan filter sampel di `lib/core/distance.dart` (meter, akurasi, umur sampel) agar tidak bergantung pada plugin geolocator di unit test
- [x] T019 [P] Buat `lib/data/local/app_database.dart`: sqflite schema v1 untuk tabel `journeys` dan `alert_events` sesuai [data-model.md](./data-model.md), plus `onCreate`/`onUpgrade`
- [x] T020 [P] Buat `lib/data/local/station_asset_loader.dart` untuk membaca `assets/data/krl_stations.json` dan mem-parse ke `Station`/`Line`
- [x] T021 Buat `lib/data/repositories/station_repository.dart`: load aset sekali, validasi silang `lineIds`/`stationIds`/keunikan id, sediakan pencarian nama tanpa jaringan
- [x] T022 [P] Buat `test/unit/station_repository_test.dart`: dataset lolos schema, tidak ada referensi jalur/stasiun yatim, id unik, urutan jalur konsisten
- [x] T023 [P] Buat `lib/data/repositories/settings_repository.dart` (shared_preferences) dengan round-trip semua field `UserSettings`
- [x] T024 Buat `lib/data/repositories/journey_repository.dart`: simpan `ActiveJourneyState` ke shared_preferences, tulis `Journey`/`AlertEvent` ke sqflite, query riwayat, hapus riwayat
- [x] T025 [P] Buat `lib/providers/providers.dart` yang mendaftarkan provider repository, settings, station list, dan database
- [x] T026 [P] Buat `lib/app.dart` dan `lib/main.dart`: `ProviderScope`, MaterialApp, rute awal ke `HomeScreen`
- [x] T027 Buat `lib/services/permission_service.dart`: cek `Geolocator.isLocationServiceEnabled`, status izin, `openAppSettings`, `openLocationSettings`, dan hasil terstruktur untuk UI (FR-011)
- [x] T028 Buat `lib/services/notification_service.dart`: inisialisasi channel `station_approach` (importance max, vibration `[0,500,200,500,200,800]`, sound null) dan `journey_status`, iOS category `STATION_APPROACH` dengan dua action, serta parser payload JSON sesuai [contracts/notifications.md](./contracts/notifications.md)
- [x] T029 Implementasikan bootstrap pemulihan `ActiveJourneyState` saat app start di `lib/main.dart` dan provider `activeJourneyProvider` (fondasi FR-013)
- [x] T030 [P] Buat `test/unit/settings_repository_test.dart` dan `test/unit/journey_repository_test.dart` untuk round-trip storage dan query riwayat

**Checkpoint**: Foundation siap — model, storage, notifikasi, dan izin tersedia untuk semua story.

---

## Phase 3: User Story 1 - Dapat peringatan sebelum sampai stasiun tujuan (Priority: P1) 🎯 MVP

**Goal**: Pengguna memilih stasiun tujuan, memulai perjalanan, menerima notifikasi + getar saat mendekat, lalu mengonfirmasi turun.

**Independent Test**: Jalankan `test/unit/journey_engine_test.dart` (TV-01..TV-10) dan `integration_test/journey_flow_test.dart` dengan fake location stream; peringatan harus muncul pada ambang dan perjalanan tersimpan selesai.

### Tests for User Story 1 ⚠️

> **NOTE: Tulis test lebih dulu dan pastikan FAIL sebelum implementasi.**

- [x] T031 [P] [US1] Tulis 10 test vector TV-01..TV-10 dari [contracts/alert-engine.md](./contracts/alert-engine.md) di `test/unit/journey_engine_test.dart`
- [x] T032 [P] [US1] Tulis test `lib/core/distance.dart` (haversine vs nilai acuan, filter akurasi >100 m, sampel usang) di `test/unit/distance_test.dart`
- [x] T033 [P] [US1] Tulis test pemetaan payload notifikasi dan penanganan aksi `saya_sudah_turun`/`saya_masih_di_kereta` di `test/unit/notification_service_test.dart`
- [x] T034 [P] [US1] Tulis widget test alur mulai → peringatan → konfirmasi turun di `test/widget/active_journey_test.dart`

### Implementation for User Story 1

- [x] T035 [US1] Implementasikan `AlertDecision`, `EngineState`, dan `JourneyEngine.evaluate` aturan R1–R9 + konstanta di `lib/services/journey_engine.dart` (tanpa plugin, tanpa jam sistem langsung)
- [x] T036 [US1] Implementasikan `lib/services/location_service.dart` dengan `AndroidSettings(foregroundNotificationConfig: ...)` dan `AppleSettings(pauseLocationUpdatesAutomatically: false, showBackgroundLocationIndicator: true, distanceFilter: 100, accuracy: high)`
- [x] T037 [US1] Buat `lib/features/destination_picker/destination_picker_screen.dart`: pencarian offline dari `StationRepository`, tampilkan nama + jalur, tolak stasiun yang sama dengan posisi awal (FR-014)
- [x] T038 [US1] Buat `lib/features/home/home_screen.dart`: tombol utama "Mulai Perjalanan", gate izin via `permission_service.dart`, dan daftar perjalanan aktif
- [x] T039 [US1] Buat `lib/features/active_journey/active_journey_screen.dart`: nama stasiun tujuan, jarak terkini, tombol "Saya Sudah Turun" dan "Hentikan Perjalanan"
- [x] T040 [US1] Implementasikan `JourneyController` (riverpod `Notifier`) di `lib/features/active_journey/journey_controller.dart`: mulai perjalanan, konsumsi stream lokasi, panggil engine, perbarui state
- [x] T041 [US1] Implementasikan pengiriman alert write-before-notify di `lib/features/active_journey/journey_controller.dart`: simpan `AlertEvent` → kirim notifikasi dengan id stabil `destinationStationId.hashCode & 0x7fffffff`
- [x] T042 [US1] Hubungkan aksi notifikasi ke penyelesaian perjalanan di `lib/services/notification_service.dart` dan `lib/features/active_journey/journey_controller.dart` (status `completed`, `finalResolution`, hentikan stream, hapus active journey)
- [x] T043 [US1] Implementasikan pengulangan peringatan (`repeatIntervalMinutes`, `maxRepeats`, cooldown 30 s) sesuai R7 di `lib/services/journey_engine.dart` dan `lib/features/active_journey/journey_controller.dart`
- [x] T044 [US1] Tangani kasus `alreadyArrived` (R4) di `lib/features/home/home_screen.dart` dengan tawaran konfirmasi tanpa spam alert
- [x] T045 [US1] Tulis integration test alur penuh dengan fake stream di `integration_test/journey_flow_test.dart`

**Checkpoint**: US1 berfungsi penuh dan independen — ini MVP yang bisa didemokan.

---

## Phase 4: User Story 2 - Melihat posisi perjalanan dan stasiun berikutnya (Priority: P2)

**Goal**: Layar perjalanan menunjukkan status pemantauan (aktif / menunggu sinyal / izin kurang) dan jarak yang terus diperbarui, termasuk bertahan setelah app ditutup.

**Independent Test**: Buka layar perjalanan dengan fake stream yang berhenti mengirim sampel dan pastikan status berubah ke `waiting_for_signal`; force-stop dan buka ulang app lalu pastikan perjalanan aktif kembali.

- [x] T046 [P] [US2] Tulis widget test status pemantauan (`active`, `waiting_for_signal`, `permission_lost`) di `test/widget/monitoring_status_test.dart`
- [x] T047 [P] [US2] Tulis test pemulihan state setelah restart di `test/unit/journey_restore_test.dart`
- [x] T048 [US2] Buat `lib/features/active_journey/monitoring_status_widget.dart` yang menampilkan indikator status, jarak, dan alasan bila tidak aktif
- [x] T049 [US2] Implementasikan deteksi `waiting_for_signal` (tidak ada sampel valid >30 s atau akurasi >100 m) di `lib/features/active_journey/journey_controller.dart`
- [x] T050 [US2] Implementasikan `lib/providers/journey_providers.dart` agar jarak dan status diperbarui reaktif dari stream lokasi
- [x] T051 [US2] Tangani `Geolocator.getServiceStatusStream` dan kehilangan izin saat perjalanan aktif di `lib/services/location_service.dart` dan `lib/features/active_journey/journey_controller.dart`
- [x] T052 [US2] Tampilkan banner saran "Periksa arah perjalanan" saat engine mengembalikan `routeMismatch` (R8) di `lib/features/active_journey/active_journey_screen.dart`
- [x] T053 [US2] Kirim notifikasi `journey_status` saat GPS terputus tanpa getar di `lib/services/notification_service.dart`
- [x] T054 [US2] Implementasikan pemulihan penuh perjalanan aktif setelah app/perangkat restart di `lib/main.dart` menggunakan `journey_repository.dart`

**Checkpoint**: US1 dan US2 berfungsi independen.

---

## Phase 5: User Story 3 - Mengatur preferensi peringatan dan riwayat perjalanan (Priority: P3)

**Goal**: Pengguna dapat mengubah ambang peringatan, mematikan getaran, mengatur interval pengulangan, serta melihat dan menghapus riwayat.

**Independent Test**: Ubah ambang ke 1000 m, jalankan perjalanan simulasi, pastikan alert dipicu di 1 km; buka riwayat dan pastikan entri tercatat lalu bisa dihapus.

- [x] T055 [P] [US3] Tulis widget test pengaturan (pilihan 1000/1500/2000 m, toggle getaran, interval) di `test/widget/settings_screen_test.dart`
- [x] T056 [P] [US3] Tulis widget test riwayat (daftar, detail, hapus semua) di `test/widget/history_screen_test.dart`
- [x] T057 [P] [US3] Tulis test persistensi preferensi dan pengaruhnya ke `JourneyEngine` di `test/unit/settings_effect_test.dart`
- [x] T058 [US3] Buat `lib/features/settings/settings_screen.dart` dengan pilihan ambang 1000/1500/2000 m, toggle getaran, dan `repeatIntervalMinutes`
- [x] T059 [US3] Buat `lib/features/history/history_screen.dart`: daftar perjalanan (tujuan, tanggal, status) dan layar detail alert
- [x] T060 [US3] Terapkan `UserSettings` ke engine dan `NotificationDetails.enableVibration` di `lib/features/active_journey/journey_controller.dart` dan `lib/services/notification_service.dart`
- [x] T061 [US3] Tambahkan aksi hapus seluruh riwayat di `lib/features/history/history_screen.dart` via `journey_repository.dart`

**Checkpoint**: Semua user story berfungsi independen.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Perbaikan lintas cerita dan validasi rilis.

- [x] T062 [P] Tulis `README.md` berisi cara build/run, struktur proyek, dan ringkasan fitur
- [x] T063 [P] Tulis `docs/privacy-policy.md`: lokasi diproses di perangkat, tidak ada telemetri, riwayat dapat dihapus
- [x] T064 [P] Tulis `docs/play-console-foreground-service.md` berisi justifikasi foreground service type `location` untuk deklarasi Play Console
- [x] T065 Optimalkan konsumsi baterai di `lib/services/location_service.dart` (adaptive distanceFilter saat kecepatan rendah, hentikan stream saat perjalanan selesai) dan ukur dengan profiler
- [x] T066 Jalankan `flutter analyze` dan perbaiki seluruh error/warning di seluruh `lib/`, `test/`, `integration_test/`
- [x] T067 Jalankan `flutter test` dan `flutter test integration_test` sampai 100% lulus
- [x] T068 Validasi skenario V1–V10 dari [quickstart.md](./quickstart.md) di emulator Android dan catat hasilnya di `docs/validation-results.md`
- [x] T069 Verifikasi kepatuhan Constitution v1.0.0 (Prinsip I–V) dan perbarui Complexity Tracking di [plan.md](./plan.md) bila ada penyimpangan

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Tanpa dependensi — dapat mulai langsung
- **Foundational (Phase 2)**: Bergantung pada Setup — MEMBLOKIR semua user story
- **User Stories (Phase 3–5)**: Bergantung pada Foundational
  - Dapat berjalan paralel jika ada lebih dari satu developer
  - Atau berurutan sesuai prioritas (P1 → P2 → P3)
- **Polish (Phase 6)**: Bergantung pada seluruh story yang ingin dirilis

### User Story Dependencies

- **US1 (P1)**: Mulai setelah Phase 2 — tidak bergantung pada story lain (MVP)
- **US2 (P2)**: Mulai setelah Phase 2 — memakai komponen US1 untuk menampilkan status, tetapi dapat diuji dengan fake stream sendiri
- **US3 (P3)**: Mulai setelah Phase 2 — mengubah parameter engine; tidak memerlukan US2

### Within Each User Story

- Test ditulis dan FAIL sebelum implementasi
- Model → service → UI
- Implementasi inti sebelum integrasi
- Selesaikan satu story sebelum pindah prioritas

### Concrete Blocking Example

```text
T001 → T002 → T003..
T009 (dataset) → T020 → T021 → T037 (pencarian stasiun)
T011–T018 (models+distance) → T035 (engine) → T040 (controller) → T041 (alert)
T028 (notification init) → T041 (dispatch) → T042 (actions)
T019/T024 (storage) → T029 (restore) → T054 (US2 restore)
```

---

## Parallel Opportunities

### Phase 1 (Setup)

```bash
# Setelah T001–T002 selesai, jalankan paralel:
T003 analysis_options.yaml
T004 AndroidManifest.xml
T005 Info.plist
T007 lib/core/constants.dart
T008 lib/core/theme.dart
T009 assets/data/krl_stations.json
T010 test/fixtures/bogor_approach.gpx
```

### Phase 2 (Foundational)

```bash
# Semua model + database + loader dapat dibuat paralel:
T011 station.dart   T012 line.dart   T013 enums.dart
T014 location_sample.dart   T015 journey.dart   T016 alert_event.dart
T017 user_settings.dart   T018 distance.dart   T019 app_database.dart
T020 station_asset_loader.dart
```

### Phase 3 (US1)

```bash
# Test dulu, paralel:
T031 journey_engine_test.dart
T032 distance_test.dart
T033 notification_service_test.dart
T034 active_journey_test.dart

# Lalu implementasi berurutan: T035 → T036 → T040 → T041 → T042
```

### Phase 4 & 5

```bash
# US2 test paralel dengan US3 test (file berbeda):
T046 monitoring_status_test.dart   T055 settings_screen_test.dart
T047 journey_restore_test.dart     T056 history_screen_test.dart
                                   T057 settings_effect_test.dart
```

---

## Parallel Example: User Story 1

```bash
# 1. Tulis semua test US1 sekaligus
Task: "TV-01..TV-10 di test/unit/journey_engine_test.dart"
Task: "Haversine + filter di test/unit/distance_test.dart"
Task: "Payload + aksi notifikasi di test/unit/notification_service_test.dart"
Task: "Alur konfirmasi turun di test/widget/active_journey_test.dart"

# 2. Setelah test merah, implementasi engine
Task: "JourneyEngine R1-R9 di lib/services/journey_engine.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Selesaikan Phase 1: Setup
2. Selesaikan Phase 2: Foundational (kritis — memblokir semua story)
3. Selesaikan Phase 3: US1
4. **STOP & VALIDASI**: jalankan TV-01..TV-10 dan integration test
5. Demo/MVP siap dipakai di perjalanan nyata

### Incremental Delivery

1. Setup + Foundational → fondasi siap
2. US1 → uji mandiri → demo (MVP)
3. US2 → uji mandiri → demo (visibilitas status)
4. US3 → uji mandiri → demo (kustomisasi + riwayat)
5. Polish → validasi quickstart V1–V10 → rilis

### Parallel Team Strategy

1. Tim menyelesaikan Setup + Foundational bersama
2. Setelah fondasi selesai:
   - Developer A: US1 (`lib/services/journey_engine.dart`, `features/active_journey/`)
   - Developer B: US2 (`monitoring_status_widget.dart`, `providers/journey_providers.dart`)
   - Developer C: US3 (`features/settings/`, `features/history/`)
3. Gabungkan setelah tiap story lulus test masing-masing

---

## Notes

- `[P]` menandakan file berbeda dan tidak bergantung pada task yang belum selesai
- `[Story]` memetakan task ke user story untuk traceability
- Test wajib merah sebelum implementasi (Constitution Prinsip III)
- Commit setelah setiap task atau kelompok logis
- Berhenti di setiap checkpoint untuk validasi mandiri
- Hindari: task kabur, konflik file yang sama, dependensi lintas story yang merusak independensi
