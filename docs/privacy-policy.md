# Kebijakan Privasi Railminder

**Berlaku sejak**: 8 November 2026

Railminder dibangun dengan prinsip **Privacy by Default** dan **Zero Telemetry**. Kami tidak mengumpulkan, menyimpan di server, menyebarkan, atau menjual data pribadi Anda.

## 1. Pemrosesan Data di Perangkat

- **Lokasi Geografis (GPS)**: Data koordinat GPS Anda hanya diproses di dalam memori perangkat untuk menghitung jarak ke stasiun tujuan KRL yang dipilih. Data ini tidak pernah dikirim ke internet atau server pihak mana pun.
- **Riwayat Perjalanan**: Catatan perjalanan (stasiun tujuan, waktu mulai, waktu selesai, dan log peringatan) disimpan secara lokal di basis data perangkat Anda (SQLite). Anda dapat menghapus seluruh riwayat kapan saja melalui menu Riwayat di dalam aplikasi.

## 2. Izin Perangkat yang Digunakan

| Izin | Alasan Penggunaan |
|------|-------------------|
| **Lokasi Saat Aplikasi Digunakan** (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) | Menghitung jarak dari posisi Anda ke stasiun tujuan saat aplikasi dibuka. |
| **Lokasi di Latar Belakang** (`ACCESS_BACKGROUND_LOCATION`) | Memastikan aplikasi dapat mendeteksi kedatangan saat layar HP mati atau aplikasi diminimalkan di saku/tas. |
| **Layanan Foreground Lokasi** (`FOREGROUND_SERVICE_LOCATION`) | Menjaga agar sistem operasi Android tidak menghentikan pemantauan GPS saat perjalanan kereta sedang berlangsung. |
| **Notifikasi** (`POST_NOTIFICATIONS`) | Menampilkan pemberitahuan dan getaran saat kereta mendekati stasiun tujuan Anda. |
| **Getar** (`VIBRATE`) | Memberi peringatan fisik tanpa suara audio yang mengganggu penumpang lain di gerbong. |

## 3. Tanpa Akun & Tanpa Pelacak

- Railminder tidak memerlukan pendaftaran akun, nomor HP, email, atau identitas apa pun.
- Tidak ada SDK pelacak, iklan pihak ketiga, atau alat analitik (Google Analytics, Firebase, Facebook SDK, dll).

## 4. Penghapusan Data

Karena seluruh data berada di perangkat Anda:
- Anda dapat menghapus riwayat kapan saja melalui tombol **Hapus Semua Riwayat** di menu Riwayat.
- Menghapus aplikasi dari perangkat akan langsung menghapus seluruh preferensi dan riwayat secara permanen.
