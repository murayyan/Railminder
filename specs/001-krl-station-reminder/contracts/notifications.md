# Contract: Notifications

Menggunakan `flutter_local_notifications`. Semua notifikasi bersifat lokal (dijadwalkan/dikirim dari perangkat), tanpa push server.

## Channels (Android)

| Channel ID | Name | Importance | Priority | Vibration | Sound |
|---|---|---|---|---|---|
| `station_approach` | Peringatan Stasiun Tujuan | `Importance.max` | `Priority.high` | `[0, 500, 200, 500, 200, 800]` (ms) | Silent |
| `journey_status` | Status Perjalanan | `Importance.low` | `Priority.low` | None | Silent |

Catatan:
- `station_approach` memakai importance `max` agar muncul sebagai heads-up notification saat layar mati, tetapi **tidak** memutar suara (sesuai keputusan pengguna: notifikasi + getar saja).
- Channel dibuat sekali saat first launch; perubahan pengaturan getaran diterapkan per-notifikasi melalui `NotificationDetails.enableVibration`, bukan dengan membuat channel baru.

## iOS

- Kategori `STATION_APPROACH` dengan `UNNotificationAction`:
  - `saya_sudah_turun` — "Saya Sudah Turun"
  - `saya_masih_di_kereta` — "Saya Masih di Kereta"
- `UNNotificationSettings.alertStyle = .alert`, `sound = nil`, dan getaran mengikuti pengaturan haptic sistem.
- Izin yang diminta: `alert`, `badge`, `sound` (untuk kompatibilitas), tanpa `criticalAlert`.

## Payload

Semua notifikasi perjalanan membawa payload JSON:

```json
{
  "type": "station_approach",
  "journeyId": "3f2c...",
  "destinationStationId": "BOO",
  "triggeredAt": "2026-11-08T09:12:33+07:00",
  "isRepeat": false
}
```

Aturan:
- `type`: `station_approach` | `journey_status`
- `journeyId` wajib ada dan harus cocok dengan perjalanan aktif; jika tidak cocok, notifikasi diabaikan (mencegah aksi pada perjalanan lama).
- `isRepeat` membedakan judul: `"Mendekati Bogor"` vs `"Masih menuju Bogor?"`.

## Aksi & Routing

| Sumber aksi | Aksi | Efek |
|---|---|---|
| Tap body notifikasi | Buka app | Membuka `ActiveJourneyScreen` untuk `journeyId` |
| Action `saya_sudah_turun` | Konfirmasi turun | `Journey.status = completed`, `finalResolution = confirmed_arrived`, `AlertEvent.userAction = arrived`, hentikan location stream, hapus active journey |
| Action `saya_masih_di_kereta` | Tetap di kereta | `AlertEvent.userAction = still_on_train`, jadwalkan repeat sesuai `repeatIntervalMinutes` (maks `maxRepeats`) |
| Swipe/dismiss | Dismiss | `AlertEvent.userAction = dismissed`; repeat berikutnya tetap berjalan selama `alertCount < maxRepeats` |

## Reliability Rules

- Peringatan dikirim **setelah** `Journey` dan `AlertEvent` tersimpan lokal (write-before-notify) agar riwayat tidak hilang jika proses dibunuh setelah notifikasi.
- Notifikasi memiliki `id` stabil: `destinationStationId.hashCode & 0x7fffffff`, sehingga peringatan ulang memperbarui notifikasi yang sama (tidak menumpuk).
- Jika aplikasi di background dan notifikasi ditolak pengguna, engine tetap mencatat `AlertEvent` dengan `deliveryStatus = denied` dan UI menampilkan peringatan saat dibuka.
- `journey_status` menampilkan aksi "Hentikan Perjalanan" (bukan aksi konfirmasi) dan tidak bergetar.
