# Deklarasi Foreground Service `location` untuk Google Play Console

Dokumen ini menyalin justifikasi yang diminta Play Console pada bagian **App content > Foreground service permissions** untuk Railminder.

## Jenis yang dideklarasikan

`location` (`FOREGROUND_SERVICE_LOCATION`)

## Alasan bisnis inti

Railminder adalah pengingat stasiun tujuan untuk penumpang KRL. Perjalanan kereta berlangsung di dalam gerbong, sementara aplikasi berada di latar belakang dan layar ponsel dalam keadaan mati. Pengguna harus tetap menerima getaran peringatan sebelum kereta tiba tanpa perlu membuka aplikasi atau mengawasi layar.

Pemantauan lokasi berkelanjutan saat aplikasi tidak sedang dibuka adalah fitur inti, bukan fitur pendukung. Tanpa foreground service bertipe `location`, Android 10+ akan menghentikan aliran lokasi dalam beberapa menit saat perangkat diam di dalam saku, sehingga pengingat tidak pernah muncul.

## Teks justifikasi (siap tempel)

> Railminder memantau posisi pengguna di sepanjang jalur KRL untuk mengirim notifikasi dan getaran sebelum kereta mencapai stasiun tujuan yang dipilih. Penumpang menyimpan ponsel di tas atau saku dengan layar mati selama perjalanan, sehingga pemantauan harus tetap berjalan di latar belakang. Layanan ini hanya aktif saat pengguna secara eksplisit menekan "Mulai Perjalanan", menampilkan notifikasi persisten selama perjalanan, dan berhenti segera setelah pengguna menekan "Saya Sudah Turun" atau "Hentikan Perjalanan". Tidak ada data lokasi yang dikirim ke server; seluruh perhitungan jarak dilakukan di perangkat.

## Perilaku teknis yang mendukung deklarasi

| Aspek | Implementasi |
|-------|--------------|
| Kapan layanan dimulai | Hanya setelah pengguna memilih stasiun tujuan dan menekan `Mulai Perjalanan` |
| Notifikasi persisten | Channel `Pemantauan Perjalanan`, `setOngoing: true`, tidak dapat dihapus saat perjalanan aktif |
| Kapan layanan berhenti | `Saya Sudah Turun`, `Hentikan Perjalanan`, atau perjalanan selesai |
| Izin yang diminta | `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `POST_NOTIFICATIONS` |
| Data keluar perangkat | Tidak ada (tanpa backend, tanpa telemetri, tanpa akun) |
| Kebijakan privasi | `docs/privacy-policy.md` |

## Checklist sebelum unggah

- [ ] Video demo untuk peninjau Play Console yang memperlihatkan alur mulai perjalanan, notifikasi persisten, dan getaran peringatan.
- [ ] Kebijakan privasi dipublikasikan pada URL publik yang dapat diakses peninjau.
- [ ] Formulir Data safety diisi: lokasi **tidak** dikumpulkan, **tidak** dibagikan.
- [ ] Pastikan target SDK mengikuti kebijakan Play terbaru (saat ini 36).
