# Validasi tahap pertama

Tanggal laporan: 1 November 2026 (Asia/Bangkok).

## Lingkungan dan hasil aktual

- Repository awal hanya berisi `README.md`. Pemeriksaan ulang branch `main` menemukan tambahan `.github/workflows/blank.yml`; workflow tersebut dipertahankan sebagai satu-satunya workflow APK, sementara seluruh struktur Flutter ditambahkan.
- Flutter dipasang dari branch stable repositori resmi: **3.47.9**, Dart **3.13.7**.
- `flutter pub get --enforce-lockfile`: **lulus**; lockfile disertakan di Git.
- `flutter analyze`: **lulus**, tidak ada issue.
- `flutter test`: **lulus, 5 tes**. Mencakup pencarian nama/nomor, decoding model API, navigasi beranda → daftar → detail → tahfidz dan kembali, empty state hasil pencarian/progres, pemilihan surah di layar 360 × 800, serta skala teks besar.
- `flutter build web`: **lulus**, menghasilkan `build/web`. Ini validasi kompilasi Web; belum ada pengujian interaktif di Chrome karena browser tidak tersedia.
- Workflow YAML berhasil diparse dan diperiksa untuk trigger, urutan pub get/analyze/test/build, nama artifact, serta path APK. Versi major checkout, setup-java, dan upload-artifact yang dipakai telah dikonfirmasi tersedia di repositori resmi masing-masing.
- `flutter build apk --release`: **terblokir**, exit 1: `No Android SDK found`. Java tersedia, tetapi Android SDK belum terpasang di cloud ini. Tidak ada APK lokal yang berhasil dibuat.
- GitHub Actions **belum dijalankan** dari tugas ini. Build APK dan artifact **belum terverifikasi pada runner GitHub**. Workflow disiapkan agar runner membangun APK setelah perubahan dikirim ke GitHub.

## Batas validasi

Tidak ada klaim keberhasilan API, audio, atau penyimpanan progres; implementasi tersebut memang belum tersedia pada tahap pertama. Tujuh metadata surah awal bukan respons katalog 114 surah. Tes model hanya memeriksa pemetaan field, bukan koneksi API.

Konfigurasi Android release masih memakai debug signing template Flutter. APK yang nantinya dibangun CI ditujukan untuk pengujian pribadi, bukan publikasi Google Play. Build Web dan kelulusan tes widget tidak membuktikan build atau pemasangan APK Android berhasil.

Untuk validasi Android selanjutnya, kirim commit ke GitHub, jalankan **Build Tahfidz Quran APK**, pastikan semua langkah lulus, unduh **Tahfidz-Quran-APK**, lalu uji instalasi dan navigasi pada HP Android. Panduan lengkap ada di README.
