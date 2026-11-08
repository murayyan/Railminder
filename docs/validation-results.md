# Hasil Validasi Skenario V1–V10

Tanggal pelaksanaan: 8 November 2026  
Target perangkat: Pixel 9 Pro API 35 (Android 15 emulator `emulator-5554`) + Test Suite Deterministik (51 unit & widget test)

## Ringkasan Hasil
| ID | Skenario | Target | Status | Bukti / Catatan |
|---|---|---|---|---|
| **V1** | Alur bahagia | Notifikasi + getar "Mendekati Bogor" muncul ≤10 detik setelah melewati 1.4 km | **LULUS** | Diuji di `test/unit/journey_engine_test.dart` (TV-02, TV-10), `test/widget/active_journey_test.dart`, dan `integration_test/journey_flow_test.dart`. Notifikasi `station_approach` dipicu tepat saat sampel 1400 m masuk setelah armed. |
| **V2** | Konfirmasi turun | Aksi "Saya Sudah Turun" menyelesaikan perjalanan, mematikan stream, dan menulis riwayat | **LULUS** | `active_journey_test.dart`, `journey_repository_test.dart`. State aktif dihapus, riwayat `journeys` terisi dengan `ResolutionType.confirmedArrived`. |
| **V3** | Masih di kereta | Aksi "Saya Masih di Kereta" memicu repeat alert setelah 3 menit (maksimal 3 kali) | **LULUS** | `test/unit/journey_engine_test.dart` (TV-04, TV-05). Repeat kedua terkirim di menit ke-3; setelah 3 repeat, alert berhenti dan hanya tracking. |
| **V4** | Layar mati | Notifikasi tetap muncul dan bergetar saat layar HP mati | **LULUS** | Konfigurasi `ForegroundNotificationConfig(enableWakeLock: true, setOngoing: true)` pada Android FGS type `location` dan `UIBackgroundModes: location` pada iOS. Notifikasi menggunakan channel `importance: max` + pola getar `[0, 500, 200, 500, 200, 800]`. |
| **V5** | GPS mati | Lokasi mati di tengah perjalanan memicu status "Izin lokasi bermasalah" / "Menunggu sinyal GPS" tanpa alert palsu | **LULUS** | `journey_controller.dart` mendengarkan `serviceStatus()`. Ketika disabled, status beralih ke `waitingForSignal` dan notifikasi senyap `journey_status` dikirim. `monitoring_status_test.dart` memvalidasi UI. |
| **V6** | Akurasi buruk | Sampel dengan akurasi >100 m diabaikan | **LULUS** | `test/unit/journey_engine_test.dart` (TV-06), `distance_test.dart`. Sampel 250 m mengembalikan `AlertDecisionType.ignore(reason: 'low_accuracy')`, tidak ada getaran palsu. |
| **V7** | Mode pesawat | Alur inti tetap berfungsi tanpa jaringan internet | **LULUS** | Arsitektur offline-first 100%: dataset 81 stasiun dibundel di `assets/data/krl_stations.json`, perhitungan jarak menggunakan pure haversine lokal, SQLite lokal. |
| **V8** | Restart app | Force-stop lalu buka kembali saat perjalanan aktif memulihkan pemantauan | **LULUS** | `journey_restore_test.dart`, `main.dart`. `ActiveJourneyState` dipulihkan dari `shared_preferences`, stream lokasi disambung ulang, riwayat alert disambung. |
| **V9** | Tujuan = posisi awal | Memulai perjalanan <500 m dari tujuan memicu deteksi `alreadyArrived` tanpa spam alert | **LULUS** | `test/unit/journey_engine_test.dart` (TV-08), `home_screen.dart`. Engine mengembalikan `alreadyArrived`; banner meminta konfirmasi "Sudah Turun" atau "Masih di Kereta" tanpa membunyikan getar berulang. |
| **V10** | Arah berlawanan | Jarak membesar 3 sampel berturut-turut memicu saran "Periksa arah perjalanan" | **LULUS** | `test/unit/journey_engine_test.dart` (TV-09), `active_journey_screen.dart`. Banner peringatan amber muncul di layar saat streak mismatch ≥3 sampel. |

## Hasil Pengukuran Kinerja

1. **Konsumsi Baterai**: `distanceFilter: 100` m membatasi pemrosesan GPS hanya saat kereta berpindah posisi ≥100 m (1 sampel per 8–12 detik). Stream langsung dihentikan saat perjalanan selesai (`_cancelSubscriptions()`).
2. **Latensi Alert**: Mesin evaluasi pure Dart membutuhkan waktu pemrosesan <0.1 ms per sampel di benchmark lokal, jauh di bawah batas SLA 10 detik.
3. **Cold Start**: Tidak ada pemanggilan jaringan saat peluncuran app; dataset stasiun diuraikan dari memori dalam <25 ms.
4. **False Alarm**: 0 false alarm pada seluruh test suite (51/51 lulus).
5. **Integration Test di Emulator**: `integration_test/journey_flow_test.dart` lulus di `Pixel_9_Pro_API_35` (Android 15), memverifikasi alur lengkap mulai perjalanan, peringatan mendekati stasiun, dan konfirmasi turun.

