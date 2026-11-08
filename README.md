# Railminder

Pengingat stasiun tujuan KRL. Pilih stasiun tujuan, mulai perjalanan, lalu terima notifikasi dan getaran sebelum kereta tiba. Sepenuhnya offline, tanpa akun, tanpa telemetri.

## Fitur

- Peringatan bergetar saat jarak ke stasiun tujuan melewati ambang (1, 1.5, atau 2 km).
- Pengulangan peringatan dengan interval dan batas jumlah yang dapat diatur.
- Pemantauan tetap berjalan saat layar mati (foreground service Android, background location iOS).
- Status pemantauan terlihat: aktif, menunggu sinyal GPS, atau izin bermasalah.
- Saran "Periksa arah perjalanan" bila posisi konsisten menjauh dari tujuan.
- Riwayat perjalanan lokal, dapat dihapus kapan saja.
- Dataset 81 stasiun KRL Jabodetabek dibundel di `assets/data/krl_stations.json`.

## Stack

| Bagian | Teknologi |
|--------|-----------|
| Framework | Flutter 3.24+ / Dart 3.5+ |
| State | `flutter_riverpod` |
| Lokasi | `geolocator` (foreground service type `location`) |
| Notifikasi | `flutter_local_notifications` |
| Penyimpanan | `shared_preferences` (perjalanan aktif, preferensi), `sqflite` (riwayat) |
| Izin | `permission_handler` + `geolocator` |
| Format | `intl` |

## Struktur Proyek

```text
lib/
├── main.dart                    # bootstrap: prefs, database, dataset, notifikasi
├── app.dart                     # MaterialApp + tema
├── core/                        # konstanta, tema, haversine
├── data/
│   ├── models/                  # Station, Line, Journey, AlertEvent, settings, state
│   ├── local/                   # sqflite schema, pemuat aset stasiun
│   └── repositories/            # station, journey (SQLite + memori), settings
├── services/
│   ├── journey_engine.dart      # mesin R1-R9, pure Dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── permission_service.dart
├── features/
│   ├── home/                    # mulai perjalanan, kartu perjalanan aktif
│   ├── destination_picker/      # pencarian stasiun offline
│   ├── active_journey/          # layar perjalanan + controller
│   ├── history/
│   └── settings/
└── providers/                   # riverpod providers

specs/001-krl-station-reminder/  # spec, plan, tasks, contracts (Spec Kit)
assets/data/krl_stations.json    # dataset stasiun
test/                            # unit, widget, support, fixtures
integration_test/                # alur end-to-end
docs/                            # privasi, justifikasi Play Console
```

## Menjalankan

Prasyarat: Flutter stable, Android SDK 37 + NDK 28.2 (atau Xcode 16 untuk iOS).

```bash
flutter pub get
flutter run
```

Izin yang harus diberikan saat pertama kali: lokasi (termasuk latar belakang) dan notifikasi. Tanpa izin latar belakang, peringatan hanya berjalan saat aplikasi di depan.

### Catatan build Android

Konfigurasi berikut wajib ada di `android/app/build.gradle.kts`, kalau tidak build gagal:

| Setelan | Nilai | Alasan |
|---------|-------|--------|
| `compileSdk` | 37 | `flutter_local_notifications` dan `permission_handler_android` dikompilasi terhadap SDK 37 |
| `isCoreLibraryDesugaringEnabled` | `true` | `flutter_local_notifications` memakai API `java.time` |
| `coreLibraryDesugaring` | `com.android.tools:desugar_jdk_libs:2.1.4` | Implementasi desugaring untuk minSdk 29 |
| `multiDexEnabled` | `true` | Jumlah method melewati batas 64K |

Paket `sqlite3` (dependensi test lewat `sqflite_common_ffi`) mengunduh pustaka native dari GitHub Release saat build pertama. Bila unduhan itu gagal (mis. `504` dari GitHub), unduh manual aset `libsqlite3.<abi>.android.so` dari rilis `sqlite3-3.5.2`, ganti nama jadi `libsqlite3.so`, lalu letakkan di `.dart_tool/hooks_runner/shared/sqlite3/build/download-<8 karakter awal sha256>/`.

## Test

```bash
flutter analyze
flutter test                       # unit + widget (51 test)
flutter test integration_test      # butuh emulator/perangkat
```

Test vector mesin peringatan (TV-01..TV-10) ada di `test/unit/journey_engine_test.dart` dan mengikuti `specs/001-krl-station-reminder/contracts/alert-engine.md`.

## Dataset Stasiun

`assets/data/krl_stations.json` berisi 6 jalur dan 81 stasiun dengan koordinat WGS84 hasil pencarian OpenStreetMap. Validasi silang `lineIds`/`stationIds` dijalankan saat aplikasi start dan di `test/unit/station_repository_test.dart`. Untuk membangun ulang dataset:

```bash
python3 tools/build_station_dataset.py
```

## Dokumen

- `DESIGN.md` untuk arah visual dan aturan UI.
- `docs/privacy-policy.md` untuk kebijakan privasi.
- `docs/play-console-foreground-service.md` untuk deklarasi foreground service.
- `specs/001-krl-station-reminder/` untuk spec, rencana, dan kontrak.
