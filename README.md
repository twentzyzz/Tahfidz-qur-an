# Tahfidz Quran

Aplikasi Android berbasis **Flutter dan Dart** untuk menyiapkan perjalanan menghafal Al-Qur'an. Tahap pertama berfokus pada fondasi proyek, navigasi, desain Material 3 berwarna emerald, dan pipeline APK otomatis. Target Web juga disiapkan.

Anda **tidak perlu memasang Flutter, VS Code, atau Android Studio di laptop** untuk mendapatkan APK. Kode dapat dikerjakan di Codex Cloud, lalu APK dibangun oleh GitHub Actions setelah perubahan dikirim ke GitHub.

## Fitur tahap pertama

- Beranda dengan akses ke daftar surah, persiapan tahfidz, dan progres hafalan.
- Daftar **7 metadata surah nyata**: Al-Fatihah, Al-Baqarah, Al-Kahf, Yasin, Ar-Rahman, Al-Mulk, An-Nas. Pencarian berdasarkan nama (tanpa membedakan huruf besar/kecil) atau nomor surah.
- Detail surah menampilkan nama dan jumlah ayat. Area ayat, terjemahan, dan audio masih berupa empty state yang jelas.
- Pemilihan surah di halaman tahfidz, termasuk membawa pilihan dari detail surah.
- Halaman progres dengan keterangan bahwa penyimpanan lokal belum diaktifkan.
- Halaman dapat digulir untuk layar kecil; konten dibatasi lebarnya pada layar besar.

**Belum tersedia:** katalog lengkap 114 surah, teks ayat, terjemahan, pemutaran audio, pilihan qari, pengulangan, sesi hafalan, dan penyimpanan progres. Tombol fitur yang belum tersedia dinonaktifkan. Tidak ada teks ayat atau audio fiktif. Pilihan surah sementara di halaman tahfidz tidak disimpan setelah halaman ditutup.

## Teknologi dan struktur

- Flutter **3.47.9 stable**, Dart **3.13.7**, null safety, Material Design 3.
- Android application ID: `id.tahfidz.tahfidz_quran`.
- Proyek Dart: `tahfidz_quran`.
- Java 17 pada CI; versi Gradle dan Android Gradle Plugin mengikuti template SDK Flutter yang digunakan.
- Tidak memerlukan API key, backend, atau paket player/storage pada tahap pertama.

```text
lib/
  main.dart                   # Titik masuk
  app/app.dart                # MaterialApp dan tema
  core/constants/             # Warna
  core/theme/                 # Tema Material 3
  features/
    home/                     # Beranda
    surah/                    # Daftar, pencarian, detail
    tahfidz/                  # Pemilihan surah
    progress/                 # Empty state progres
  models/                     # Surah, Ayah, MemorizationProgress
  services/                   # Katalog awal dan kontrak API/audio/storage
  widgets/                    # Layout responsif dan empty state bersama
android/                      # Proyek native Android
web/                          # Bootstrap Flutter Web
test/                         # Tes model, pencarian, navigasi, responsivitas
.github/workflows/blank.yml
```

## Menjalankan di Codex Cloud atau mesin dengan Flutter

Gunakan checkout yang sudah tersedia di `/workspace/Tahfidz-qur-an`. Tiap tugas cloud sudah terisolasi; tidak perlu membuat Git worktree baru. Pada cloud saat pengembangan ini, SDK dipasang di `/workspace/tools/flutter`; gunakan `export PATH="/workspace/tools/flutter/bin:$PATH"` jika folder tersebut masih tersedia. Instalasi itu bukan bagian dari repository dan tidak dijamin tersedia di setiap mesin baru.

Dari root proyek:

```sh
flutter --version
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run -d chrome       # Memerlukan Chrome untuk pengujian browser
flutter build web          # Hasil: build/web
```

Untuk perangkat Android, mesin harus memiliki Android SDK serta perangkat/emulator yang terhubung:

```sh
flutter doctor -v
flutter run
flutter build apk --release
```

Build APK lokal tidak wajib untuk pengguna yang memakai GitHub Actions. Linux desktop bukan target proyek ini. Jangan memasukkan `android/local.properties`, folder SDK, file keystore, atau password ke Git.

## Build APK otomatis dengan GitHub Actions

Workflow: **Build Tahfidz Quran APK**, file `.github/workflows/blank.yml`.

Workflow berjalan ketika ada push ke **main**, pull request ke **main**, atau pemicu manual. Runner `ubuntu-latest` menyiapkan Java 17 dan Flutter stable versi yang dipatok, memulihkan cache, menjalankan `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`, lalu `flutter build apk --release`.

APK diunggah hanya jika langkah sebelumnya berhasil dan file benar-benar ada:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Nama artifact: **Tahfidz-Quran-APK**. Masa simpan: **14 hari**. Jalankan workflow kembali jika artifact sudah kedaluwarsa.

### Menjalankan secara manual

1. Pastikan commit proyek beserta workflow sudah dikirim/di-merge ke branch **main** di GitHub. Commit lokal Codex saja belum memicu Actions.
2. Buka repository **twentzyzz/Tahfidz-qur-an** di GitHub → **Actions**.
3. Jika diminta, aktifkan GitHub Actions untuk repository ini.
4. Pilih **Build Tahfidz Quran APK** → **Run workflow** → pilih **main** → **Run workflow**.
5. Tunggu semua langkah berwarna hijau. Jika gagal, buka langkah merah untuk membaca log; jangan menganggap APK sudah tersedia.

`workflow_dispatch` muncul setelah file workflow tersedia di default branch. Anda memerlukan hak akses untuk menjalankan workflow; perubahan pada branch lain dapat divalidasi melalui pull request ke main.

### Mengunduh dan memasang APK

1. Buka run workflow yang **berhasil** di halaman Actions.
2. Di bagian **Artifacts**, klik **Tahfidz-Quran-APK**. Login GitHub mungkin diperlukan.
3. Ekstrak ZIP yang diunduh untuk mendapatkan `app-release.apk`.
4. Kirim APK ke HP Android, lalu buka file tersebut.
5. Izinkan pemasangan aplikasi dari sumber tersebut jika Android meminta izin, kemudian pilih **Instal**.

**Signing tahap pertama:** APK memakai build mode release dengan **debug signing bawaan Flutter**. Ini APK untuk pengujian pribadi, **belum siap dipublikasikan di Google Play**. Build ini bukan APK debug meskipun kunci penandatangannya adalah debug key. Untuk distribusi resmi perlu application ID final, release keystore privat, konfigurasi signing melalui GitHub Secrets, serta build App Bundle (`.aab`). Tidak ada kunci privat atau password yang disimpan di repository.

Debug key runner dapat berbeda antar-run. Jika Android menolak pembaruan karena signature berbeda, hapus aplikasi pengujian lama sebelum memasang APK baru; uninstall dapat menghapus data aplikasi. Jangan gunakan pendekatan ini untuk distribusi produksi.

## Arsitektur tahap berikutnya

- `QuranService` menyediakan kontrak `getSurahs()` dan `getAyahs()` dengan base URL **https://equran.id/api/v2**. Adapter jaringan belum diimplementasikan; tambahkan penanganan timeout, kegagalan jaringan, validasi respons, dan cache sebelum memakainya.
- `Surah.fromEquranJson` dan `Ayah.fromEquranJson` memetakan field API v2, termasuk map audio per qari. Metadata awal tidak diperlakukan sebagai respons API lengkap.
- `AudioService` menyiapkan kontrak play/pause/stop/dispose dan jumlah pengulangan. Implementasi player, pemilihan qari, serta pengelolaan lifecycle akan ditambahkan kemudian.
- `ProgressService` dan `MemorizationProgress` menyiapkan kontrak penyimpanan progres. Adapter lokal (misalnya SQLite), validasi nomor ayat, dan pemulihan sesi belum diimplementasikan.
- Izin Internet Android telah disiapkan untuk integrasi HTTPS berikutnya. Teks Al-Qur'an harus berasal dari sumber tepercaya, dengan tampilan kanan-ke-kiri dan font Arab yang diuji sebelum dirilis.

## Validasi

Hasil aktual pengembangan ini dicatat pada `VALIDATION.md`. File workflow yang tersedia tidak berarti GitHub Actions telah dijalankan atau APK berhasil dibuat. Status APK harus dibuktikan melalui run Actions yang sukses dan artifact yang tersedia.
