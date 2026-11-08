# Contract: Alert Engine

Mesin pemicu peringatan adalah **pure Dart** (tanpa plugin) agar dapat diuji deterministik. Semua keputusan diambil dari input eksplisit dan tidak membaca jam, sensor, atau storage secara langsung.

## Interface

```dart
enum AlertDecisionType {
  ignore,           // sampel tidak dipakai (alasan diisi)
  track,            // lanjut memantau, belum ada peringatan
  triggerAlert,     // kirim peringatan (awal atau ulang)
  alreadyArrived,   // tujuan terlalu dekat sejak awal perjalanan
  routeMismatch,    // jarak konsisten membesar (kemungkinan salah arah)
}

class AlertDecision {
  final AlertDecisionType type;
  final double? distanceMeters;
  final bool isRepeat;
  final String? reason; // mis. 'low_accuracy', 'stale_sample', 'cooldown'
}

class JourneyEngine {
  AlertDecision evaluate({
    required LocationSample sample,
    required Station destination,
    required EngineState state,     // immutable; berisi armed, lastDistance, lastAlertAt, alertCount
    required UserSettings settings,
    required DateTime now,          // waktu sistem, diinjeksi
  });
}
```

`EngineState` yang dikembalikan bersama setiap keputusan:

```dart
class EngineState {
  final bool armed;              // true setelah jarak pernah > threshold + armMargin
  final double? lastDistance;    // jarak sampel valid terakhir
  final DateTime? lastAlertAt;
  final int alertCount;
  final double? minDistance;     // jarak terkecil yang pernah teramati
}
```

## Rules (evaluated in order)

| # | Condition | Decision |
|---|-----------|----------|
| R1 | `now - sample.timestamp > 30s` | `ignore(reason: 'stale_sample')` |
| R2 | `sample.accuracy > 100 m` | `ignore(reason: 'low_accuracy')` |
| R3 | `sample.accuracy <= 0` atau koordinat di luar batas valid | `ignore(reason: 'invalid_sample')` |
| R4 | `distance <= threshold` dan `state.armed == false` dan `state.alertCount == 0` dan `distance > 0` dan ini sampel valid pertama | `alreadyArrived` |
| R5 | `state.armed == false` dan `distance > threshold + armMargin` | `track` + set `armed = true` |
| R6 | `state.armed == true` dan `alertCount == 0` dan `distance <= threshold` dan (`lastDistance == null` atau `distance < lastDistance`) | `triggerAlert(isRepeat: false)` |
| R7 | `alertCount > 0` dan `alertCount < settings.maxRepeats` dan `distance <= threshold` dan `now - lastAlertAt >= settings.repeatIntervalMinutes` | `triggerAlert(isRepeat: true)` |
| R8 | `lastDistance != null` dan `distance > lastDistance + 300 m` selama 3 sampel berturut-turut dan `minDistance > threshold + 1000 m` | `routeMismatch` |
| R9 | lainnya | `track` |

**Constants**

- `armMargin = 500 m`
- `minAlertCooldown = 30 s` (tidak pernah dua peringatan lebih cepat dari ini, termasuk repeat)
- `routeMismatchHoldSamples = 3`
- `maxSampleAge = 30 s`

**Invariants**

- Satu sampel menghasilkan tepat satu `AlertDecision`.
- `triggerAlert` tidak pernah dipancarkan saat `armed == false`.
- Setelah `triggerAlert`, `lastAlertAt` dan `alertCount` wajib diperbarui oleh pemanggil sebelum evaluasi berikutnya.
- `routeMismatch` hanya informatif; tidak menghentikan pemantauan dan tidak mengubah `armed`.

## Test vectors (wajib ada di `test/unit/journey_engine_test.dart`)

| ID | Input | Expected |
|----|-------|----------|
| TV-01 | Sampel pertama, jarak 8 km, akurasi 10 m | `track`, `armed = true` |
| TV-02 | Setelah armed, jarak 2.4 km → 1.4 km | `triggerAlert(isRepeat: false)` |
| TV-03 | Sampel berikutnya masih 1.3 km, 10 detik kemudian | `track` (cooldown) |
| TV-04 | Sampel 1.3 km, 3 menit setelah alert | `triggerAlert(isRepeat: true)` |
| TV-05 | 3 repeat terkirim, masih di radius | `track` (maxRepeats tercapai) |
| TV-06 | Akurasi 250 m | `ignore(low_accuracy)` |
| TV-07 | `sample.timestamp` 45 detik lalu | `ignore(stale_sample)` |
| TV-08 | Perjalanan dimulai 800 m dari tujuan, belum armed | `alreadyArrived` |
| TV-09 | Jarak membesar 5 km → 7 km → 9 km | `routeMismatch` pada sampel ke-3 |
| TV-10 | Jarak 1.6 km → 1.4 km → 1.55 km → 1.35 km | alert hanya pada penurunan di bawah threshold |
