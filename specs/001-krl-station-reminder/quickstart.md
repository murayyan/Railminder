# Quickstart Validation: Pengingat Stasiun Tujuan KRL

Panduan ini membuktikan fitur bekerja end-to-end. Detail aturan ada di [alert-engine.md](./contracts/alert-engine.md), skema data di [station-data.schema.json](./contracts/station-data.schema.json), dan entitas di [data-model.md](./data-model.md).

## Prerequisites

| Kebutuhan | Versi | Catatan |
|---|---|---|
| Flutter SDK | 3.24+ (stable) | Terpasang: Flutter 3.47.9 / Dart 3.13.7 via `brew install --cask flutter` |
| Dart | 3.5+ | Bundled dengan Flutter |
| CocoaPods | 1.17+ | Terpasang via `brew install cocoapods` |
| Xcode | 15+ | **Belum lengkap di mesin ini** — perlu instalasi penuh dari App Store, lalu `sudo xcodebuild -runFirstLaunch` |
| Android SDK | Platform 36, Build Tools 36 | Terpasang di `~/Library/Android/sdk`; lisensi sudah diterima |
| Perangkat/emulator | Android 10+ / iOS 16+ | Emulator Android wajib mendukung Google Play Services untuk Fused Location |

Verifikasi lingkungan:

```bash
flutter doctor -v          # harus lolos untuk target Android dan iOS
flutter devices            # minimal satu emulator/simulator aktif
```

## 1. Setup Project

```bash
flutter create --org app.railminder --platforms android,ios .
flutter pub add flutter_riverpod geolocator flutter_local_notifications shared_preferences sqflite permission_handler intl
flutter pub add --dev flutter_lints integration_test
flutter pub get
```

Langkah manual yang wajib setelah `flutter create`:

1. Salin izin dan service declaration dari [contracts/permissions.md](./contracts/permissions.md) ke `android/app/src/main/AndroidManifest.xml`.
2. Salin `UIBackgroundModes` dan usage descriptions dari file yang sama ke `ios/Runner/Info.plist`.
3. Tambahkan `assets/data/krl_stations.json` ke bagian `flutter: assets:` di `pubspec.yaml` dan validasi terhadap [station-data.schema.json](./contracts/station-data.schema.json).
4. Set `minSdkVersion 29` di `android/app/build.gradle` dan iOS deployment target `16.0` di `ios/Podfile`.

## 2. Automated Validation

```bash
flutter analyze                      # 0 error, 0 warning baru
flutter test                         # unit + widget tests
flutter test integration_test        # alur end-to-end di emulator
```

Tes wajib lulus sebelum uji manual:

| Perintah | Cakupan | Bukti |
|---|---|---|
| `flutter test test/unit/journey_engine_test.dart` | 10 test vector TV-01..TV-10 dari kontrak alert engine | SC-001, SC-002, SC-006 |
| `flutter test test/unit/distance_test.dart` | Haversine vs `Geolocator.distanceBetween`, filter akurasi | FR-004, FR-012 |
| `flutter test test/unit/station_repository_test.dart` | Dataset lolos schema + cross-reference + urutan jalur | FR-001, FR-015 |
| `flutter test test/widget/active_journey_test.dart` | Status `active` / `waiting_for_signal` / selesai | FR-010 |
| `flutter test integration_test/journey_flow_test.dart` | Pilih tujuan → mulai → alert → konfirmasi turun → riwayat | US1, US2, FR-008 |

## 3. Simulasi Lokasi (tanpa naik KRL)

Gunakan satu track uji yang mendekati stasiun tujuan, mis. `Bogor (BOO)`.

**Android Emulator**
1. Buka `Extended Controls (...) → Location`.
2. Muat file GPX berisi rute Jakarta Kota → Bogor, atau isi koordinat manual berurutan:
   - 2.5 km dari BOO
   - 1.6 km dari BOO
   - 1.4 km dari BOO (harus memicu notifikasi)
3. Atur kecepatan playback ±60 km/jam agar menyerupai KRL.

**iOS Simulator**
1. `Features → Location → Custom Location…`
2. Masukkan koordinat dari file GPX yang sama, atau gunakan `Features → Location → Freeway Drive` lalu ganti manual saat mendekati koordinat BOO.

**Perangkat fisik**
- Aktifkan mode pengembang "Mock location app" (Android) atau gunakan Xcode GPX (iOS).

## 4. Skenario Validasi Manual

| # | Skenario | Langkah | Hasil yang Diharapkan | Requirement |
|---|---|---|---|---|
| V1 | Alur bahagia | Pilih BOO → Mulai → simulasikan 2.5 km → 1.4 km | Notifikasi + getar "Mendekati Bogor" muncul ≤10 detik setelah 1.4 km | US1, FR-004, FR-005, SC-002 |
| V2 | Konfirmasi turun | Tekan aksi "Saya Sudah Turun" dari notifikasi | Perjalanan selesai, location stream berhenti, entri muncul di Riwayat | FR-007, FR-008 |
| V3 | Masih di kereta | Tekan "Saya Masih di Kereta" | Peringatan ulang setelah 3 menit, maksimal 3 kali | FR-006 |
| V4 | Layar mati | Kunci perangkat sebelum melewati ambang | Notifikasi tetap muncul dan bergetar | FR-003, SC-002 |
| V5 | GPS mati | Matikan location service saat perjalanan aktif | Status berubah "Menunggu sinyal lokasi", tidak ada alert palsu | FR-011, FR-012 |
| V6 | Akurasi buruk | Set lokasi dengan akurasi >100 m | Sampel diabaikan, tidak ada false alarm | FR-012, SC-006 |
| V7 | Mode pesawat | Aktifkan airplane mode, ulangi V1 | Seluruh alur tetap berjalan | SC-005 |
| V8 | Restart app | Force-stop lalu buka kembali saat perjalanan aktif | Perjalanan aktif dipulihkan | FR-013 |
| V9 | Tujuan = posisi awal | Mulai perjalanan saat berada <500 m dari tujuan | Pesan "Anda sudah berada di dekat tujuan" + tawaran konfirmasi, tanpa spam alert | Edge case |
| V10 | Arah berlawanan | Simulasikan jarak yang terus membesar | Peringatan "Periksa arah perjalanan" setelah 3 sampel | Edge case, R8 |

## 5. Pengukuran Kinerja

| Metrik | Cara ukur | Target |
|---|---|---|
| Baterai | Android Studio Energy Profiler / Xcode Energy Log selama 30 menit tracking | ≤5% per jam (SC-003) |
| Latensi alert | Log timestamp `AlertEvent.triggeredAt` vs waktu sampel melewati ambang | ≤10 detik (SC-002) |
| Cold start | `flutter run --profile` lalu ukur time-to-first-frame | <2 detik |
| False alarm | Jalankan 100 track uji (V1 + V6) | ≤5 (SC-006) |

## 6. Checklist Rilis

- [ ] `flutter analyze` bersih
- [ ] Semua test lulus
- [ ] V1–V10 lulus di minimal satu perangkat Android fisik dan satu iOS (jika iOS dirilis)
- [ ] Deklarasi foreground service type `location` diisi di Play Console
- [ ] Kebijakan privasi menyatakan lokasi diproses di perangkat dan tidak dikirim ke server
- [ ] Dataset stasiun divalidasi terhadap schema dan tanggal `version` diperbarui
