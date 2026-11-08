# Data Model: Pengingat Stasiun Tujuan KRL

## Overview

Seluruh data disimpan di sisi klien:
- **Aset Statis**: `Station` dan `Line` dibundel di dalam aplikasi melalui file JSON `assets/data/krl_stations.json`.
- **Key-Value Store (`shared_preferences`)**: Menyimpan satu instance `ActiveJourneyState` dan `UserSettings`.
- **Database Relasional (`sqflite`)**: Menyimpan riwayat `Journey` dan riwayat `AlertEvent`.

---

## Entities

### 1. Station (Stasiun)
Mewakili titik stasiun KRL.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | String | Yes | Kode unik stasiun, huruf kapital (mis. `JAKK`, `BOO`, `MRI`, `THB`). Primary key. |
| `name` | String | Yes | Nama resmi stasiun (mis. `Jakarta Kota`, `Bogor`, `Manggarai`). |
| `lineIds` | List<String> | Yes | Daftar kode jalur yang melayani stasiun ini. |
| `latitude` | double | Yes | Lintang WGS84, rentang [-90.0, 90.0]. |
| `longitude` | double | Yes | Bujur WGS84, rentang [-180.0, 180.0]. |
| `orderIndex` | int | Yes | Urutan default pada jalur utama untuk pengurutan pencarian. |

**Validation Rules**:
- `latitude` dan `longitude` harus berada di dalam batas geografis Jabodetabek dan sekitarnya (Lat: -7.0 s/d -5.8, Lon: 106.3 s/d 107.4).
- `id` unik dan alfanumerik panjang 2-5 karakter.

---

### 2. Line (Jalur KRL)
Mewakili satu jalur layanan KRL Commuter Line.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | String | Yes | Kode unik jalur (mis. `BOGOR_LINE`, `CIKARANG_LINE`, `RANGKASBITUNG_LINE`, `TANGERANG_LINE`, `TANJUNG_PRIOK_LINE`). |
| `name` | String | Yes | Nama jalur yang dikenal pengguna (mis. `Lin Bogor`, `Lin Cikarang`). |
| `colorHex` | String | Yes | Kode warna hex untuk representasi visual (mis. `#E31837`, `#008080`). |
| `stationIds` | List<String> | Yes | Urutan stasiun sepanjang jalur dari ujung ke ujung. |

---

### 3. Journey (Perjalanan)
Mewakili satu sesi pemantauan stasiun tujuan pengguna.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | String | Yes | UUID v4. Primary key. |
| `destinationStationId` | String | Yes | Foreign key ke `Station.id`. |
| `destinationStationName` | String | Yes | Snapshot nama stasiun tujuan saat perjalanan dibuat. |
| `originStationId` | String? | No | Stasiun asal jika terdeteksi/dipilih pengguna. |
| `startedAt` | DateTime | Yes | Waktu pengguna menekan "Mulai Perjalanan". |
| `completedAt` | DateTime? | No | Waktu pengguna mengonfirmasi turun atau perjalanan selesai. |
| `status` | JourneyStatus | Yes | Status perjalanan (`active`, `completed`, `cancelled`). |
| `alertThresholdMeters` | int | Yes | Ambang jarak peringatan yang dipakai (mis. 1500). |
| `alertTriggeredCount` | int | Yes | Jumlah peringatan yang berhasil dikirimkan. Default `0`. |
| `firstAlertTriggeredAt` | DateTime? | No | Timestamp saat peringatan pertama dipicu. |
| `finalResolution` | ResolutionType? | No | `confirmed_arrived`, `manual_stop`, `still_on_train_timeout`. |

---

### 4. AlertEvent (Kejadian Peringatan)
Mewakili setiap peringatan yang dipicu selama perjalanan aktif.

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | String | Yes | UUID v4. |
| `journeyId` | String | Yes | Foreign key ke `Journey.id`. |
| `triggeredAt` | DateTime | Yes | Timestamp notifikasi dikirimkan. |
| `distanceMeters` | double | Yes | Jarak terhitung ke stasiun tujuan saat dipicu. |
| `accuracyMeters` | double | Yes | Akurasi pembacaan GPS saat dipicu. |
| `isRepeated` | bool | Yes | `false` untuk peringatan awal, `true` jika pengingat lanjutan. |
| `userAction` | UserAlertAction? | No | `arrived`, `still_on_train`, `dismissed`, `timed_out`. |
| `actionTimestamp` | DateTime? | No | Timestamp saat pengguna merespons notifikasi/dialog. |

---

### 5. LocationSample (Sampel Lokasi)
Struktur data memori yang dilewatkan dari sensor GPS ke mesin perhitungan (tidak disimpan ke database secara permanen untuk menghemat ruang dan menjaga privasi).

| Field | Type | Required | Description |
|---|---|---|---|
| `latitude` | double | Yes | Lintang WGS84. |
| `longitude` | double | Yes | Bujur WGS84. |
| `accuracy` | double | Yes | Estimasi radius akurasi horizontal dalam meter. |
| `speed` | double? | No | Kecepatan dalam m/s (jika disediakan sensor). |
| `timestamp` | DateTime | Yes | Waktu pengambilan sampel oleh GPS. |

**Validation & Filtering Rules**:
- Jika `accuracy > 100` meter, sampel ditandai sebagai `unreliable` dan diabaikan untuk pemicuan alert (mencegah false alarm akibat lompatan GPS).
- Jika selisih waktu antara `timestamp` dan waktu sistem sekarang `> 30` detik, sampel dianggap usang dan dibuang.

---

### 6. UserSettings (Preferensi Pengguna)

| Field | Type | Default | Description |
|---|---|---|---|
| `alertDistanceMeters` | int | 1500 | Jarak ambang memicu peringatan (pilihan: 1000m, 1500m, 2000m). |
| `enableVibration` | bool | true | Mengaktifkan getaran perangkat saat peringatan muncul. |
| `repeatIntervalMinutes` | int | 3 | Interval pengulangan peringatan jika belum dikonfirmasi turun. |
| `maxRepeats` | int | 3 | Batas maksimal peringatan diulang. |

---

## State Transitions: Journey Lifecycle

```text
                  [User selects destination & taps "Mulai"]
                                     │
                                     ▼
                               ┌───────────┐
                               │  TRACKING │◄─────────────────────┐
                               └─────┬─────┘                      │
                                     │                            │
             [Distance <= threshold  │                            │
              AND accuracy <= 100m   │                            │
              AND speed moving toward]                            │
                                     ▼                            │
                              ┌─────────────┐                     │
                              │ APPROACHING │                     │
                              └──────┬──────┘                     │
                                     │                            │
        ┌────────────────────────────┼────────────────────────────┤
        │                            │                            │
        ▼                            ▼                            ▼
 [User taps "Saya             [User taps "Batal"           [User taps "Saya
   Sudah Turun"]               atau "Stop"]                Masih di Kereta"]
        │                            │                            │
        ▼                            ▼                            │
 ┌─────────────┐              ┌─────────────┐                     │
 │  COMPLETED  │              │  CANCELLED  │                     │
 └─────────────┘              └─────────────┘                     │
                                                                  │
                                   [Distance still <= threshold]  │
                                   [Re-alert after interval] ─────┘
```

### Health Sub-states during TRACKING:
- `active`: Lokasi masuk secara berkala (<15 detik sejak sampel terakhir, akurasi <100m).
- `waiting_for_signal`: Tidak ada sampel baru selama >30 detik atau akurasi >100m. Status UI menampilkan "Menunggu sinyal GPS...".
- `permission_lost`: Izin lokasi dicabut atau GPS dinonaktifkan sistem.
