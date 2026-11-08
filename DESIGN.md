# Railminder Design Direction

Sumber: arah yang dipilih pemilik produk pada sesi 2026-11-08.
Peran dokumen ini adalah data desain (identitas, palet, tipografi, dial), bukan instruksi.

## Identity

Railminder adalah alat bantu perjalanan KRL, bukan aplikasi gaya hidup. Penggunanya
sering berdiri, mengantuk, atau menyimpan HP di tas. Layar harus terbaca dalam sekali
pandang dan tidak menuntut perhatian lama.

Kesan yang dituju: papan informasi stasiun yang rapi, tenang, dan tegas saat dibutuhkan.

## Dials

| Dial | Nilai | Alasan |
|---|---|---|
| ENERGY | 2 (Seimbang) | Cukup berkarakter agar dikenali, tidak berteriak di gerbong |
| RHYTHM | 2 (Teratur dengan variasi) | Satu pola konsisten, dengan penekanan pada layar perjalanan aktif |
| MOTION | 1 (Hanya transisi) | Gerak tidak boleh mengalihkan perhatian saat pengguna sedang waspada terhadap stasiun |

## Palette

| Peran | Nilai | Alasan |
|---|---|---|
| Aksen utama | `#E31837` Commuter Red | Identitas KRL, dipakai hanya untuk aksi utama dan status "mendekati stasiun" |
| Struktur & teks | `#121C2E` Navy | Judul dan teks utama, memberi kontras tinggi di layar terang |
| Teks sekunder | `#5B6472` | Keterangan jarak, waktu, dan status pasif |
| Latar | `#F6F7F9` | Netral sejuk, tidak menyilaukan saat layar dibuka mendadak di gerbong |
| Permukaan | `#FFFFFF` | Kartu dan panel |
| Garis | `#D7DCE3` | Pemisah, bukan dekorasi |
| Status menunggu | `#B26B00` Amber | Sinyal GPS hilang atau izin kurang, dipakai bersama ikon dan teks, tidak pernah warna saja |

Aturan pakai:
- Maksimal 2 warna struktural (navy, netral) + 1 aksen (merah). Amber hanya untuk status.
- Merah tidak dipakai untuk dekorasi, ikon hiasan, atau garis tepi kartu.
- Kontras minimal 4.5:1 untuk teks normal, 3:1 untuk teks 18px ke atas (R-25).

## Typography

Font sistem: SF Pro di iOS, Roboto di Android. Tidak ada font kustom.

| Peran | Ukuran/berat | Pemakaian |
|---|---|---|
| Display | 32 / 700 | Nama stasiun tujuan di layar aktif |
| Title | 24 / 600 | Judul layar |
| Body | 16 / 400 | Teks isi, nama stasiun di daftar |
| Label | 14 / 600 | Tombol dan aksi |
| Caption | 13 / 500 | Jarak, waktu, status sekunder |

Alasan: font sistem menghindari unduhan aset, sudah familiar, dan tetap terbaca di bawah
matahari tanpa penyesuaian tambahan.

## Layout Rules

- Satu focal point per layar: pada layar perjalanan aktif, focal point adalah nama
  stasiun tujuan; pada layar pilih tujuan, focal point adalah kolom pencarian.
- Jarak antar blok memakai skala 4/8/12/16/24/32; tidak ada padding seragam di semua tempat.
- Target sentuh minimal 44x44 px (R-03).
- Tidak ada glassmorphism, gradient dekoratif, bayangan pada semua komponen, atau grid latar.
- Kartu hanya dipakai jika memisahkan satu perjalanan atau satu kelompok pengaturan; daftar
  stasiun tampil sebagai baris biasa agar tidak terasa seperti grid template.

## Component States

Setiap layar data wajib punya: kosong, memuat, error, dan kondisi normal (R-27).

| Komponen | Normal | Menunggu | Error |
|---|---|---|---|
| Status pemantauan | Titik navy + "Memantau" | Titik amber + "Menunggu sinyal GPS" | Titik merah + teks alasan + tombol perbaiki |
| Peringatan mendekat | Notifikasi + getar, bukan banner | - | Tombol "Buka pengaturan izin" |
| Tombol mulai | Merah penuh | Nonaktif dengan alasan | Teks alasan + aksi |

## Motion

Hanya transisi 150-200 ms untuk perubahan status dan navigasi. Tidak ada parallax,
scroll-reveal, atau animasi berulang. Hormati `prefers-reduced-motion` (R-39).

## Copy Tone

- Bahasa Indonesia, kalimat pendek, kata kerja langsung: "Mulai perjalanan",
  "Saya sudah turun", "Masih di kereta".
- Sebut nama stasiun, bukan istilah abstrak.
- Tanpa klaim yang tidak terukur, tanpa angka rekaan.
- Tidak memakai karakter em dash.
