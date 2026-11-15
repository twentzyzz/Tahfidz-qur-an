# Modern Islamic Minimalism

## Tahap pertama

Beranda, navigasi bawah, daftar surah untuk membaca, dan 30 juz. Halaman
hafalan, pembaca ayat, audio, progres, salat, pengaturan, dan AI offline
mempertahankan implementasi serta perilakunya sampai tahap pertama direview.

Panduan: [AntiSlop](https://github.com/muris11/anti-ai-slop), core filter,
diterapkan selama pengerjaan. Arah dari brief pengguna: Modern Islamic
Minimalism untuk aplikasi membaca dan menghafal Quran. ENERGY 1 / RHYTHM 2 /
MOTION 1. Rasa tenang berasal dari keterbacaan dan urutan aktivitas, bukan
ornamen masjid, animasi, atau klaim tentang AI.

## Keputusan visual

| Elemen | Keputusan dan alasan |
| --- | --- |
| Fokus beranda | Satu panel emerald untuk hafalan terakhir; tindakan berikutnya mudah ditemukan. Bacaan terakhir tetap terpisah agar posisi membaca tidak tertukar dengan hafalan. |
| Warna | Gunakan token yang sudah ada: emerald `#087F5B`, emerald tua `#064E3B`, kanvas `#F7F8F5`, teks `#172B25`. Identitas mushaf lama tetap dikenali. |
| Aksen | Emas `#C9A45C` hanya pada progres di panel emerald tua; tidak dipakai untuk teks kecil di putih. |
| Mode gelap | Permukaan, teks, pemisah, dan fokus memakai ColorScheme tema yang dipilih pengguna. Panel fokus memakai pasangan warna tetap dengan kontras tinggi. |
| Tipografi | Inter lokal untuk label dan angka yang mudah dipindai; Amiri lokal untuk nama surah Arab dengan ruang harakat. Tidak menambah font atau ketergantungan jaringan. |
| Motif identitas | Nomor katalog yang rapi, nama Latin dan Arab dari dataset asli, serta pasangan emerald dan warna kertas. Logo mushaf yang ada dipertahankan. |
| Komposisi | Panel hafalan, baris bacaan, akses aktivitas, ringkasan progres, salat, qari, bookmark. Katalog menggunakan baris berpemisah, bukan tumpukan kartu identik. |
| Spacing | Skala 4/8/12/16/24/32. Gutter 16 di ponsel, 24 pada layar lapang; lebar konten maksimal 850 agar baris tidak melebar tanpa batas. |
| Sudut | Panel fokus 24, kontrol 12, nomor katalog 8. Sudut membedakan peran elemen; bukan semua berbentuk kapsul. |
| Ikon | Buku untuk bacaan, headphone untuk audio, bookmark untuk hafalan; ikon Material yang sudah tersedia. Chevron hanya untuk baris yang membuka halaman. |
| Gerak | Umpan balik Material saat ditekan/fokus; tanpa animasi dekoratif. Navigasi mempertahankan posisi tiap tab melalui IndexedStack. |

## Hierarki dan perilaku

- Beranda menampilkan status nyata dari penyimpanan lokal. Tanpa hafalan,
  tampilkan ajakan memilih surah; tanpa bookmark, jelaskan cara menyimpan ayat.
- Lima tujuan tetap: Beranda, Al-Qur'an, 30 Juz, Hafalan, Progres. Mini player
  tetap di atas navigasi. Pengaturan dan notifikasi tetap dapat dibuka.
- Daftar surah: judul dan total dari dataset, pencarian nama Latin/Arab/nomor,
  jumlah hasil, hapus pencarian, lalu nomor, nama, dan jumlah ayat.
- Pada layar sempit atau teks besar, nama Arab berada di bawah nama Latin,
  bukan berkompetisi di trailing ListTile. Tidak memotong nama Arab.
- 30 juz: nomor, judul, batas awal dan akhir pada dua baris yang bisa membungkus.
  Seluruh batas tetap berasal dari repository Quran; tidak ada data buatan.
- Seluruh katalog memakai satu area scroll termasuk header dan pencarian,
  sehingga keyboard dan ukuran teks besar tidak menghabiskan tinggi konten.
- Navigasi memiliki target minimal 48 piksel, tooltip dan semantics terpilih.
  Untuk teks besar pada ponsel, ikon lima tujuan tetap tersedia dan label
  tujuan aktif ditampilkan penuh di bawahnya. Label lengkap setiap tujuan
  tetap tersedia melalui pembaca layar dan tooltip.
- Konten menghormati SafeArea. Tidak membatasi text scaler. Baris memanjang
  secara vertikal; tidak memakai tinggi kartu atau rasio grid tetap.
- Loading dan error inisialisasi Quran tetap ditangani TahfidzApp sebelum
  katalog tampil. Pencarian kosong memiliki pesan serta tombol reset.
  Status salat dan audio tetap memakai komponen asli.

## Audit kode sebelum perubahan

1. Beranda: empat kartu shortcut sama kuat dengan panel utama; copy uppercase
   berjarak lebar dan panah pada hampir semua aksi tidak membantu membaca.
2. Daftar surah: leading, nama Latin, nama Arab sampai 125 px, dan chevron
   bersaing dalam satu ListTile. Nama panjang dan skala teks besar berisiko
   terpotong; tidak ada tombol menghapus query atau jumlah hasil.
3. Juz: batas awal/akhir menjadi satu kalimat panjang; daftar tanpa pengantar
   dan tanpa batas lebar pada tablet.
4. Navigasi ponsel: label 10 px dipaksa satu baris dan ellipsis; animasi
   indikator tidak diperlukan untuk menjelaskan tujuan tab.
5. Positif yang dipertahankan: data asli offline, font lokal, tema terang/gelap,
   IndexedStack, state penyimpanan, mini player, semua route fitur, loading/error.

## Review dan validasi

Target review: lebar 320, 390, dan 1024; skala teks 1 dan 2; Indonesia/English;
terang/gelap; keyboard, kosong/terisi, pencarian tidak cocok, juz 1 dan 30,
resume hafalan berbeda dari resume bacaan, dan audio aktif saat pindah tab.
Pengujian regresi ditambahkan untuk dijalankan workflow GitHub Actions yang
sudah ada, bersama flutter analyze, flutter test, dan build APK.

Flutter dan Dart tidak tersedia lokal. Pemeriksaan sumber tidak membuktikan
rendering atau build berhasil. Status CI dan batas verifikasi dicatat pada
PR; review visual APK dan interaksi perangkat tetap diperlukan sebelum merge.
Tidak ada redesign tahap berikutnya atau merge otomatis dalam tahap ini.
