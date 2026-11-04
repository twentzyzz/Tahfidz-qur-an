# Redesign lanjutan — 4 November 2026

Melanjutkan main `649cd8e` (PR #3). Tidak membuat proyek baru.

## Implementasi

- Tema terang/gelap terpusat melalui AppColors, AppTypography, AppSpacing, AppRadius, AppIcons, dan AppTheme. Palet emerald sesuai brief; aksen emas digunakan terbatas.
- Inter dan Amiri dibundel untuk membaca offline; lisensi SIL OFL disertakan dan bisa dibuka lewat Pengaturan.
- Beranda: tanggal Masehi lokal, hero untuk melanjutkan hafalan terakhir dengan progres surah asli, akses cepat, qari pilihan, serta akses jadwal/checklist salat. Bacaan terakhir tetap tersimpan terpisah. Navigasi lima tab memiliki indikator aktif beranimasi dan safe area.
- Pemilihan qari: pencarian, filter favorit, penyimpanan favorit lokal, status qari aktif, contoh Al-Fatihah, dan mini player. Pemilihan qari mengganti sumber pada satu engine audio sambil mempertahankan indeks ayat dan status jeda.
- Mini player membuka pemutar penuh: nama surah/ayat, avatar/foto, teks Arab, durasi dan seek, previous/next, play/pause, pengulangan rentang, ganti qari, stop, serta pemulihan error.
- Pembaca: font Arab Amiri, identitas surah, pemisah ayat/terjemahan, salin ayat, dan pemilihan qari yang konsisten. Bookmark, sembunyikan Arab, pengulangan, dan status hafalan dipertahankan.
- 30 juz: rentang awal sampai akhir diperoleh dari batas data yang sama; ujung setiap rentang dicocokkan dengan ayat terakhir juz melalui tes.
- Progres: ring hafalan, target harian, grafik tujuh hari dari riwayat asli (deduplikasi ayat per hari, mengecualikan ayat yang telah direset), dan akses langsung ke latihan per surah.
- Ibadah: jam salat berikutnya ditampilkan bersama countdown; waktu berikutnya mendapat penanda halus. Pengaturan dikelompokkan menjadi Umum, Al-Qur'an, Ibadah, dan Aplikasi; dropdown menyesuaikan layar sempit dan teks besar.

## Foto dan aset

Foto **Yasser Al-Dosari** disimpan lokal dari Wikimedia Commons, karya **MAL MALDIVE**, **CC BY-SA 4.0**. Kredit, URL sumber, lisensi, dan keterangan pemotongan lingkaran tersedia di aplikasi. Detail audit: `assets/qari/ATTRIBUTION.md`.

Lima qari masih memakai avatar inisial: Abdullah Al-Juhany, Abdul Muhsin Al-Qasim, Abdurrahman As-Sudais, Ibrahim Al-Dossari, dan Mishary Rashid Alafasy. Sumber foto mereka belum selesai diverifikasi. Ini bukan klaim bahwa foto berlisensi tidak ada.

Tetap enam sumber audio EQuran. Empat belas qari tambahan belum diaktifkan karena sumber per ayat dan izin belum terverifikasi. Tidak menambahkan URL tebakan. Tanggal Hijriah dan terjemahan Inggris belum ditambahkan karena belum ada sumber yang diintegrasikan; terjemahan Quran tetap Indonesia. Progres membaca per juz tidak dibuat-buat karena belum ada pencatatan riwayat baca lengkap.

## Validasi

- Flutter 3.47.9 / Dart 3.13.7, sama dengan workflow.
- `flutter pub get --enforce-lockfile`: lulus; lockfile tidak berubah.
- `flutter analyze --no-pub`: bersih.
- `flutter test --no-pub`: 17 tes lulus. Termasuk tes lama Quran/audio/penyimpanan/salat/notifikasi serta regresi baru favorit, kelanjutan hafalan, rentang juz, dan statistik mingguan.
- Layar 360 × 800 dengan pembesaran teks 1,4: alur pengaturan dan qari tanpa overflow; bahasa/tema juga diuji pada 390 × 844.
- `flutter build web --no-pub`: lulus; web dipakai untuk pemeriksaan visual, bukan bukti GPS/notifikasi native bekerja.
- `.github/workflows/blank.yml`, konfigurasi signing, applicationId, data Quran, dan aset launcher/splash tidak diubah.
- Build APK dilakukan oleh workflow GitHub Actions pada PR; status dan tautan artifact dicatat di deskripsi PR setelah run selesai.

Belum diuji pada perangkat Android fisik: upgrade/instalasi APK, audio melalui speaker, izin GPS, notifikasi saat Doze/reboot, dan launcher vendor. Uji audio memakai engine palsu untuk memverifikasi sumber dan kontrol; tidak mengklaim telah mendengarkan semua berkas audio.
