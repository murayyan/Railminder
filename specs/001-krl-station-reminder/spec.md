# Feature Specification: Pengingat Stasiun Tujuan KRL

**Feature Branch**: `001-krl-station-reminder`

**Created**: 2026-11-08

**Status**: Draft

**Input**: User description: "aku ingin membuat aplikasi mobile untuk reminder posisi KRL jika sudah mendekati stasiun tujuan agar tidak kelewat turun di stasiun tujuan"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dapat peringatan sebelum sampai stasiun tujuan (Priority: P1)

Penumpang KRL memilih stasiun tujuan, menekan "Mulai Perjalanan", lalu menyimpan HP. Saat kereta mendekati stasiun tujuan, aplikasi mengirim notifikasi dan getaran sehingga penumpang terbangun atau berhenti mengobrol dan bersiap turun.

**Why this priority**: Ini inti nilai produk. Tanpa alur ini aplikasi tidak berguna; seluruh fitur lain hanya pendukung.

**Independent Test**: Dapat diuji dengan memulai perjalanan ke stasiun tujuan, lalu mensimulasikan pergerakan lokasi mendekati stasiun tersebut. Peringatan harus muncul sebelum titik stasiun tercapai dan perjalanan tercatat selesai setelah dikonfirmasi.

**Acceptance Scenarios**:

1. **Given** pengguna sudah memilih stasiun tujuan dan menekan "Mulai Perjalanan", **When** posisi perangkat masuk ke radius peringatan stasiun tujuan, **Then** aplikasi menampilkan notifikasi dan getaran bertuliskan nama stasiun tujuan.
2. **Given** peringatan sudah muncul, **When** pengguna membuka notifikasi, **Then** aplikasi menampilkan layar konfirmasi turun dengan nama stasiun dan tombol "Saya Sudah Turun" serta "Saya Masih di Kereta".
3. **Given** pengguna menekan "Saya Sudah Turun", **When** konfirmasi diterima, **Then** perjalanan berstatus selesai dan pemantauan lokasi berhenti.
4. **Given** pengguna menekan "Saya Masih di Kereta", **When** kereta bergerak melewati stasiun tujuan, **Then** aplikasi tetap memantau dan mengirim peringatan ulang pada interval yang ditentukan sampai perjalanan dihentikan.

---

### User Story 2 - Melihat posisi perjalanan dan stasiun berikutnya (Priority: P2)

Selama perjalanan, penumpang dapat membuka aplikasi dan melihat stasiun tujuan, perkiraan jarak ke stasiun tujuan, dan status pemantauan (aktif, menunggu sinyal, atau selesai).

**Why this priority**: Memberi rasa percaya bahwa pemantauan benar-benar berjalan, sehingga pengguna berani tidur atau melepas HP.

**Independent Test**: Dapat diuji dengan memulai perjalanan dan memeriksa bahwa layar perjalanan menampilkan status pemantauan, jarak yang terus diperbarui, dan nama stasiun tujuan.

**Acceptance Scenarios**:

1. **Given** perjalanan sedang aktif, **When** pengguna membuka layar perjalanan, **Then** aplikasi menampilkan stasiun tujuan, jarak terkini, dan indikator pemantauan aktif.
2. **Given** sinyal lokasi hilang lebih dari batas waktu yang ditentukan, **When** pengguna membuka layar perjalanan, **Then** aplikasi menampilkan status "menunggu sinyal lokasi" beserta saran tindakan.
3. **Given** perjalanan aktif dan aplikasi ditutup dari layar terakhir, **When** pengguna membukanya kembali, **Then** status perjalanan yang sedang berjalan tetap tampil.

---

### User Story 3 - Mengatur preferensi peringatan dan riwayat perjalanan (Priority: P3)

Pengguna dapat mengatur jarak/ambang peringatan, menyalakan atau mematikan getaran, serta melihat riwayat perjalanan sebelumnya.

**Why this priority**: Menambah kenyamanan dan kepercayaan, tetapi tidak diperlukan untuk fungsi inti.

**Independent Test**: Dapat diuji dengan mengubah ambang peringatan, menjalankan perjalanan simulasi, lalu memastikan peringatan muncul pada ambang baru dan riwayat mencatat perjalanan tersebut.

**Acceptance Scenarios**:

1. **Given** pengguna mengubah ambang peringatan menjadi lebih dekat, **When** perjalanan baru dimulai, **Then** peringatan dipicu pada ambang yang baru.
2. **Given** pengguna menyelesaikan perjalanan, **When** membuka riwayat, **Then** perjalanan tampil dengan stasiun tujuan, tanggal, dan status penyelesaian.

---

### Edge Cases

- Lokasi perangkat tidak tersedia atau GPS dimatikan saat perjalanan aktif: aplikasi memberi tahu pengguna dan berhenti mengklaim pemantauan aktif.
- Izin lokasi latar belakang dicabut saat aplikasi berjalan: aplikasi mendeteksi dan meminta pengguna mengaktifkan kembali sebelum perjalanan dimulai.
- Sinyal hilang di terowongan atau area tanpa sinyal: aplikasi menandai status menunggu sinyal; peringatan tidak dipicu berdasarkan posisi terakhir yang sudah usang.
- Kereta berhenti lama atau bergerak mundur: peringatan hanya dipicu ketika jarak menurun menuju stasiun tujuan, bukan saat menjauh.
- Pengguna salah jalur atau naik arah berlawanan: aplikasi mendeteksi jarak yang membesar secara konsisten dan menyarankan memeriksa arah perjalanan.
- Dua stasiun berdekatan: peringatan hanya dipicu untuk stasiun tujuan yang dipilih, bukan stasiun lain yang dilewati.
- Perangkat restart atau aplikasi dimatikan sistem saat perjalanan aktif: aplikasi memulihkan status perjalanan aktif setelah perangkat menyala kembali.
- Stasiun tujuan sama dengan stasiun asal: aplikasi menolak memulai perjalanan dan meminta tujuan berbeda.
- Baterai lemah atau mode hemat daya: aplikasi memberi tahu bahwa akurasi peringatan dapat berkurang dan menawarkan pengaturan yang lebih hemat daya.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Pengguna MUST dapat memilih stasiun tujuan dari daftar stasiun KRL yang tersedia di aplikasi tanpa koneksi internet.
- **FR-002**: Pengguna MUST dapat memulai dan menghentikan perjalanan dengan satu tindakan utama.
- **FR-003**: Aplikasi MUST terus memantau posisi perangkat selama perjalanan aktif, termasuk ketika layar mati atau aplikasi berada di latar belakang, sepanjang izin dan kemampuan perangkat mengizinkan.
- **FR-004**: Aplikasi MUST menghitung jarak perangkat ke stasiun tujuan dan memicu peringatan ketika jarak melewati ambang peringatan yang ditentukan.
- **FR-005**: Peringatan MUST berupa notifikasi yang berisi nama stasiun tujuan dan getaran; aplikasi tidak membunyikan alarm yang menembus mode senyap.
- **FR-006**: Peringatan MUST dipicu paling banyak sekali per ambang per pendekatan, dan dapat diulang setelah interval tertentu jika pengguna belum mengonfirmasi turun.
- **FR-007**: Pengguna MUST dapat mengonfirmasi "Saya Sudah Turun" atau "Saya Masih di Kereta" dari notifikasi maupun dari dalam aplikasi.
- **FR-008**: Aplikasi MUST mencatat setiap perjalanan (stasiun tujuan, waktu mulai, waktu selesai, status, jumlah peringatan) dan menampilkannya di riwayat.
- **FR-009**: Pengguna MUST dapat mengatur ambang peringatan dan preferensi getaran.
- **FR-010**: Aplikasi MUST menampilkan status pemantauan terkini: aktif, menunggu sinyal, izin kurang, atau selesai.
- **FR-011**: Aplikasi MUST mendeteksi ketiadaan izin lokasi latar belakang atau layanan lokasi yang mati dan memblokir dimulainya perjalanan sampai masalah tersebut diselesaikan.
- **FR-012**: Aplikasi MUST mengabaikan sampel lokasi yang akurasinya di luar batas wajar agar tidak memicu peringatan palsu.
- **FR-013**: Aplikasi MUST memulihkan perjalanan yang sedang aktif setelah aplikasi atau perangkat dimulai ulang.
- **FR-014**: Aplikasi MUST menolak memulai perjalanan jika stasiun tujuan sama dengan lokasi awal yang terdeteksi atau stasiun asal yang dipilih.
- **FR-015**: Aplikasi MUST berfungsi penuh tanpa koneksi internet untuk memilih stasiun, memantau perjalanan, dan mengirim peringatan.

### Key Entities *(include if data involved)*

- **Stasiun**: Titik pemberhentian KRL; memiliki nama, kode, jalur, dan posisi geografis. Menjadi tujuan perjalanan dan dasar perhitungan jarak.
- **Jalur**: Rangkaian stasiun yang dilayani satu layanan KRL; memiliki nama dan urutan stasiun.
- **Perjalanan**: Satu sesi pemantauan milik pengguna; memiliki stasiun tujuan, waktu mulai, waktu selesai, status (aktif, selesai, dibatalkan), dan riwayat peringatan.
- **Peringatan**: Kejadian saat ambang jarak terlewati; memiliki waktu, jarak saat dipicu, dan status konfirmasi pengguna.
- **Sampel Lokasi**: Pembacaan posisi perangkat selama perjalanan; memiliki koordinat, akurasi, dan waktu.
- **Preferensi Pengguna**: Pengaturan ambang peringatan, getaran, dan interval pengulangan peringatan.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pada 95% perjalanan uji dengan data lokasi terekam, peringatan muncul saat kereta berada 1–2 km sebelum stasiun tujuan dan sebelum kereta berhenti di stasiun tersebut.
- **SC-002**: Notifikasi muncul dalam waktu 10 detik setelah posisi perangkat melewati ambang peringatan.
- **SC-003**: Pemantauan lokasi menghabiskan rata-rata tidak lebih dari 5% baterai per jam perjalanan pada perangkat kelas menengah.
- **SC-004**: 90% pengguna baru dapat memulai perjalanan pertamanya dalam waktu kurang dari 30 detik setelah membuka aplikasi.
- **SC-005**: Aplikasi dapat menyelesaikan alur inti (pilih tujuan, mulai, terima peringatan, konfirmasi turun) tanpa koneksi internet pada 100% percobaan.
- **SC-006**: Dari 100 perjalanan uji, tidak lebih dari 5 peringatan palsu yang dipicu saat kereta masih lebih dari 2 km dari stasiun tujuan.

## Assumptions

- Cakupan awal adalah KRL Commuter Line di wilayah Jabodetabek; daftar stasiun dan jalurnya dibundel di dalam aplikasi dan diperbarui lewat rilis aplikasi.
- Pengguna menaiki KRL pada jalur yang terdaftar dan memilih stasiun tujuan sebelum atau saat perjalanan dimulai.
- Perangkat pengguna memiliki GPS dan mengizinkan akses lokasi latar belakang; aplikasi memandu pengguna mengaktifkannya.
- Peringatan dirancang sebagai notifikasi dan getaran, bukan alarm yang menembus mode senyap atau headset, sesuai pilihan pengguna.
- Aplikasi tidak bergantung pada data posisi atau jadwal real-time dari operator; akurasi bergantung pada kualitas sinyal GPS.
- Perjalanan dianggap satu arah menuju stasiun tujuan; perpindahan jalur di tengah perjalanan di luar cakupan versi pertama.
- Riwayat perjalanan disimpan di perangkat pengguna saja; tidak ada akun, sinkronisasi cloud, atau pengumpulan data pribadi.
