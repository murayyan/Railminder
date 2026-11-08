# Contract: Permissions & Background Execution

Dokumen ini mendefinisikan persyaratan izin sistem operasi (Android & iOS), alur permintaan izin, dan penanganan kegagalan agar aplikasi dapat memantau lokasi secara andal tanpa ditolak oleh app store atau dibunuh oleh penghemat daya sistem.

## Android Permissions (`AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Lokasi dasar -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <!-- Lokasi latar belakang (Android 10+) -->
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- Foreground Service (Android 9+) & Service Type Location (Android 14+) -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

    <!-- Notifikasi (Android 13+) & Getar -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- Pemulihan setelah reboot (opsional, untuk FR-013) -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <application ...>
        <!-- Deklarasi Foreground Service wajib dengan tipe location -->
        <service
            android:name="com.baseflow.geolocator.GeolocatorLocationService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="location" />
    </application>
</manifest>
```

### Android Request Sequence (Wajib Bertahap)
1. **Langkah 1 (Saat Onboarding / Sebelum Mulai Pertama Kali)**:
   - Minta `POST_NOTIFICATIONS` (Android 13+).
   - Tampilkan dialog edukasi kenapa lokasi dibutuhkan saat naik KRL.
   - Minta `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` (Foreground/While in use).
2. **Langkah 2 (Saat Pengguna Menekan "Mulai Perjalanan" pertama kali)**:
   - Tampilkan penjelasan khusus bahwa HP akan disimpan di saku/tas dengan layar mati.
   - Minta `ACCESS_BACKGROUND_LOCATION` ("Izinkan Sepanjang Waktu" / "Allow all the time").
   - Jika ditolak permanen, arahkan ke `openAppSettings()` dengan panduan visual.

---

## iOS Permissions (`Info.plist`)

```xml
<dict>
    <!-- Background Modes wajib untuk pemantauan terus menerus -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>

    <!-- Keterangan wajib untuk Apple Review -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Railminder memantau posisi Anda di jalur KRL untuk menghitung jarak ke stasiun tujuan.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Railminder memantau posisi saat layar HP mati agar dapat memberi notifikasi getar sebelum Anda tiba di stasiun tujuan.</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>Railminder memerlukan izin lokasi di latar belakang agar notifikasi stasiun tujuan tetap berfungsi saat aplikasi tidak dibuka.</string>
</dict>
```

### iOS Execution Rules
- Gunakan `AppleSettings`:
  ```dart
  AppleSettings(
    accuracy: LocationAccuracy.high,
    activityType: ActivityType.fitness, // atau automotiveNavigation
    distanceFilter: 100, // meter
    pauseLocationUpdatesAutomatically: false,
    showBackgroundLocationIndicator: true,
  )
  ```
- `showBackgroundLocationIndicator: true` menampilkan kapsul biru di status bar iOS, memberi tahu pengguna dan sistem bahwa pelacakan lokasi aktif secara sah.

---

## Health Checks & Error Handling Matrix

| Kondisi Sistem | Deteksi API | Aksi Aplikasi |
|---|---|---|
| Layanan GPS Mati | `Geolocator.isLocationServiceEnabled() == false` | Blokir tombol "Mulai Perjalanan"; tampilkan tombol "Nyalakan Lokasi" (`openLocationSettings()`). |
| Izin Ditolak Sekali | `permission == LocationPermission.denied` | Tampilkan sheet penjelasan ramah pengguna, berikan tombol coba lagi. |
| Izin Ditolak Permanen | `permission == LocationPermission.deniedForever` | Tampilkan petunjuk langkah demi langkah menuju menu Settings HP (`openAppSettings()`). |
| Izin Background Tidak Diberikan | `permission == LocationPermission.whileInUse` | Tampilkan peringatan: "Jika layar mati, peringatan mungkin terlambat. Disarankan ubah izin ke 'Selalu Izinkan'." |
| Layanan Hilang di Tengah Perjalanan | Stream mengeluarkan `ServiceStatus.disabled` | Ubah status perjalanan menjadi `waiting_for_signal`, buat notifikasi status "GPS terputus, pemantauan ditunda". |
