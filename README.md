# Tahfidz Quran

Aplikasi Flutter/Dart untuk membaca Al-Qur'an, mengulang audio hafalan, mencatat progres, dan mengikuti jadwal salat Indonesia. Android dan Web tersedia. Versi **1.1.0+2**, application ID tetap `id.tahfidz.tahfidz_quran`.

## Fitur

- **114 surah / 6.236 ayat**, teks Arab berharakat, nama Arab/Latin, terjemahan Indonesia, pencarian nama/nomor, dan pembacaan **30 juz**.
- Dataset asli EQuran.id diambil melalui API v2 pada 1 November 2026 dan disertakan sebagai aset agar bacaan tersedia offline. Batas juz berasal dari metadata AlQuran Cloud. Tidak ada ayat atau terjemahan buatan. Pembaruan dataset dilakukan melalui pembaruan aplikasi; versi ini belum menyinkronkan teks Quran otomatis dari server.
- Pembaca satu ayat per halaman: geser kiri/kanan atau gunakan tombol panah. Halaman dapat digulir untuk ayat panjang. Bookmark, bacaan terakhir, ukuran Arab dan terjemahan disimpan lokal. Geser halaman memperbarui bacaan terakhir; tombol **Bacaan terakhir** menandai ayat yang sedang dibuka.
- **Enam qari**: Abdullah Al-Juhany, Abdul Muhsin Al-Qasim, Abdurrahman As-Sudais, Ibrahim Al-Dossari, Mishary Rashid Alafasy, Yasser Al-Dosari. Semua URL audio berasal dari respons EQuran.id. Tidak ada URL audio hasil tebakan.
- Audio streaming per ayat, play/pause/stop, sebelumnya/berikutnya, seluruh surah atau juz, pengulangan rentang **1/3/5/10 kali**, serta mini player. Pilihan qari terakhir disimpan; mengganti qari saat audio aktif memulai ulang rentang dengan suara baru. Koneksi Internet diperlukan untuk audio. Unduhan audio offline dan playback background belum disediakan.
- Mode hafalan: pilih surah, ayat awal/akhir, sembunyikan/tampilkan teks Arab, ulangi rentang, tandai **Sedang dihafal / Sudah hafal / Reset**. Target harian, progres per surah, persentase dan riwayat disimpan lokal.
- Navigasi bawah: **Beranda, Al-Qur'an, 30 Juz, Hafalan, Progres**. Jadwal salat dan pengaturan dapat dibuka dari ikon bagian atas.
- Bahasa Indonesia (default) dan English melalui sistem `LocalizationsDelegate` resmi Flutter beserta `flutter_localizations`. Bahasa antarmuka berubah; terjemahan Quran tetap bahasa Indonesia dari sumbernya. Tema terang/gelap dan ukuran teks dapat diubah.
- Jadwal MyQuran API sesuai kota, tanggal, serta WIB/WITA/WIT, salat berikutnya, hitung mundur, checklist harian dan riwayat. Checklist hanya berubah melalui tindakan pengguna, menggunakan kunci tanggal setempat; hari baru tidak mewarisi centang kemarin.
- Pilihan kota manual tetap tersedia tanpa izin lokasi. GPS meminta izin saat tombol ditekan, menggunakan reverse geocoding sistem operasi, kemudian menampilkan pencarian kota untuk dikonfirmasi pengguna. Koordinat GPS tidak disimpan.
- Notifikasi salat dan pengingat 5/10/15 menit sebelumnya. Izin Android diminta saat diaktifkan. Jadwal valid dicache, dan mode cache ditandai jika server tidak dapat dihubungi.
- Ikon mushaf emerald/emas, adaptive launcher icon Android, dan splash screen khusus. Nama launcher **Tahfidz Quran**.

## Batasan yang perlu diketahui

Hanya **6 dari 20 qari yang diminta** diaktifkan. Katalog tambahan MP3Quran diperiksa, tetapi akses API saja tidak membuktikan izin redistribusi atau ketersediaan audio per ayat yang cocok untuk fitur ini. Empat belas qari lainnya belum diintegrasikan; tidak ditampilkan sebagai pilihan aktif.

Notifikasi dijadwalkan untuk **7 hari ke depan** dan diperbarui saat aplikasi dibuka/dilanjutkan, atau kota/bahasa/pengaturan pengingat berubah. Buka aplikasi secara berkala agar jadwal terus terisi. Android dapat menunda alarm karena Doze, penghemat baterai, atau pembatasan vendor. Penjadwalan menggunakan `inexactAllowWhileIdle`, bukan janji alarm presisi. Receiver boot memulihkan notifikasi yang sudah dijadwalkan setelah reboot; force-stop dapat menghentikannya sampai aplikasi dibuka kembali. Notifikasi native ditargetkan untuk Android; Web tetap menyediakan bacaan, audio, pengaturan, dan pilihan kota manual.

Cache jadwal dipisahkan berdasarkan kota dan tanggal. Jadwal dari tanggal lain tidak digunakan sebagai pengganti. Jika jadwal besok gagal dimuat, jadwal hari ini tetap ditampilkan; setelah salat terakhir, hitung mundur berikutnya memerlukan jadwal besok.

Penyimpanan memakai SharedPreferences untuk data kecil pengguna. Tidak ada akun/sinkronisasi cloud. Uninstall atau menghapus data aplikasi dapat menghapus progres. Riwayat hafalan ditampilkan hingga 100 entri terbaru; seluruh entri tetap disimpan lokal.

## Sumber dan verifikasi

- Data Quran dan URL audio: https://equran.id/apidev dan https://equran.id/api/v2/surat
- Batas juz: https://api.alquran.cloud/v1/meta dan dokumentasi https://alquran.cloud/api
- Kota/jadwal: https://api.myquran.com/v2/sholat/kota/semua dan https://api.myquran.com
- Zona waktu: IANA `Asia/Jakarta`, `Asia/Makassar`, `Asia/Jayapura`; pengelompokan kota menurut provinsi dari ID MyQuran dan pembagian waktu Indonesia. Tidak memakai zona waktu mesin sebagai pengganti zona kota.

`assets/data/provenance.json` mencatat sumber, hash berkas, dan sampel audio yang benar-benar diverifikasi. Seluruh 114 surah, 6.236 ayat, enam pemetaan audio per ayat, serta batas 30 juz diperiksa otomatis. Sebanyak 18 sampel HTTP audio dari surah 1, 55, dan 114 diperiksa (enam qari per surah); ini bukan klaim bahwa seluruh 37.416 URL telah diunduh atau didengarkan. Audio tetap mengikuti hak penyedia masing-masing; tidak ada berkas audio yang disalin ke repository.

## Struktur

```text
lib/app/                   aplikasi, tema, dan dependensi sesi
lib/l10n/                  lokalisasi Indonesia/English
lib/features/home/         beranda dan navigasi bawah
lib/features/surah/        katalog, juz, pembaca
lib/features/tahfidz/      pemilihan surah hafalan
lib/features/progress/     progres dan riwayat
lib/features/prayer/       jadwal, countdown, checklist
lib/features/settings/     bahasa, tampilan, kota, GPS, notifikasi
lib/services/              repository Quran, player, storage, jadwal
lib/widgets/               komponen bersama dan mini player
assets/data/               data sumber asli dan provenance
assets/branding/           logo mushaf
android/                   konfigurasi platform, ikon, splash, izin
web/                       target browser
 test/                     pengujian data, UI, audio, jadwal, notifikasi
.github/workflows/blank.yml pipeline APK yang dipertahankan
```

## Mengembangkan dan menguji

Di Codex Cloud gunakan checkout yang tersedia; tiap tugas sudah terisolasi, tidak perlu Git worktree baru. Flutter stable yang dipatok workflow: **3.47.9**, Dart **3.13.7**, Java **17** untuk Android. SDK pada sesi pengembangan tersedia di `/workspace/tools/flutter/bin`; lokasi ini tidak dijamin ada di mesin baru.

```sh
export PATH="/workspace/tools/flutter/bin:$PATH"
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build web
# Jika tersedia Chrome atau perangkat Android:
flutter run -d chrome
flutter run
# Memerlukan Android SDK:
flutter build apk --release
```

`python3 tool/verify_data.py` memeriksa aset dan 18 sampel audio secara online, lalu memperbarui provenance. Periksa perubahan sebelum commit. Tes unit menggunakan mock jaringan/native agar tidak bergantung pada Internet; pemeriksaan HTTP nyata dilakukan secara terpisah.

## APK melalui GitHub Actions

Tidak perlu Flutter, VS Code, atau Android Studio di laptop. Workflow **Build Tahfidz Quran APK** tetap berada di `.github/workflows/blank.yml`; trigger push main, pull request ke main, dan manual `workflow_dispatch` dipertahankan. Pipeline menjalankan pub get dengan lockfile, analyze, test, build release, lalu upload file:

```text
build/app/outputs/flutter-apk/app-release.apk
```

1. Buka tab **Actions** di repository GitHub, pilih **Build Tahfidz Quran APK**.
2. Untuk manual: **Run workflow**, pilih branch yang berisi perubahan, lalu jalankan.
3. Tunggu run selesai hijau. Buka **Artifacts → Tahfidz-Quran-APK**.
4. Ekstrak ZIP dan pasang `app-release.apk` di HP Android. Izinkan pemasangan dari sumber tersebut jika diminta Android.

Artifact disimpan selama 14 hari. Status run terbaru adalah bukti apakah APK versi ini sudah dibangun; hasil build versi lama tidak memvalidasi versi baru.

Build number naik menjadi **2**, ID aplikasi dan konfigurasi debug signing dipertahankan. APK release ini untuk pengujian pribadi, belum Google Play. Runner GitHub dapat menghasilkan debug key berbeda, sehingga upgrade APK lama tidak dijamin diterima Android; build number saja tidak menyelesaikan ketidakcocokan signature. Release keystore stabil harus disiapkan melalui Secrets untuk distribusi resmi, tanpa memasukkan private key/password ke Git. Menghapus aplikasi lama untuk mengganti signature akan menghapus data lokalnya.
