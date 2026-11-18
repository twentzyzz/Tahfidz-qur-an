# Tahfidz Quran

Aplikasi Flutter/Dart untuk membaca Al-Qur'an, mengulang audio hafalan, mencatat progres, dan mengikuti jadwal salat Indonesia. Android dan Web tersedia. Versi **1.1.0+2**, application ID tetap `id.tahfidz.tahfidz_quran`.

## Fitur

- **114 surah / 6.236 ayat**, teks Arab berharakat, nama Arab/Latin, terjemahan Indonesia, pencarian nama/nomor, dan pembacaan **30 juz**.
- Dataset asli EQuran.id diambil melalui API v2 pada 1 November 2026 dan disertakan sebagai aset agar bacaan tersedia offline. Batas juz berasal dari metadata AlQuran Cloud. Tidak ada ayat atau terjemahan buatan. Pembaruan dataset dilakukan melalui pembaruan aplikasi; versi ini belum menyinkronkan teks Quran otomatis dari server.
- **Tab Al-Qur'an:** pembaca bergaya mushaf dengan teks Arab mengalir dan penanda nomor ayat, beberapa ayat dalam satu lembar, serta navigasi geser antarlembar. Ketuk ayat atau tombol **Detail ayat** untuk membuka terjemahan, bookmark, audio ayat, salin, dan status hafalan; audio surah dan pilihan qari tetap tersedia. Pembagian lembar adalah tata letak aplikasi berdasarkan panjang teks, **bukan** nomor halaman maupun susunan baris mushaf cetak standar; teks ayat bersumber dari EQuran.id dan tidak diubah. **Tab 30 Juz:** tetap **scroll vertikal berkesinambungan** per ayat dengan teks Arab terbuka tanpa kotak besar, penanda nomor ayat bernuansa emas, pemisah tipis, terjemahan langsung di bawah ayat, dan kontrol hafalan ringkas dalam menu; tersedia tombol pilih qari, putar satu juz, audio per ayat, bookmark, salin, dan penanda bacaan terakhir. Ayat dibangun seperlunya agar ringan. Pembaca hafalan juga tetap scroll vertikal dengan latihan rentang dan AI offline. Bacaan terakhir, bookmark, ukuran Arab dan terjemahan tetap tersimpan secara lokal.
- **Enam qari**: Abdullah Al-Juhany, Abdul Muhsin Al-Qasim, Abdurrahman As-Sudais, Ibrahim Al-Dossari, Mishary Rashid Alafasy, Yasser Al-Dosari. Semua URL audio berasal dari respons EQuran.id. Tidak ada URL audio hasil tebakan.
- Audio streaming per ayat, play/pause/stop, sebelumnya/berikutnya, seluruh surah atau juz, pengulangan rentang **1/3/5/10 kali**, serta mini player. Pilihan qari terakhir disimpan; mengganti qari saat audio aktif memulai ulang rentang dengan suara baru. **Audio murottal offline** bisa diunduh atas tindakan pengguna untuk surah dan qari tertentu; file lengkap diputar otomatis dari penyimpanan privat perangkat, sementara ayat yang belum diunduh tetap streaming. Background audio kini mendukung kontrol media di notifikasi dan layar terkunci Android selama murottal diputar.
- Mode hafalan: pilih surah, ayat awal/akhir, sembunyikan/tampilkan teks Arab, ulangi rentang, tandai **Sedang dihafal / Sudah hafal / Reset**. Target harian, progres per surah, persentase dan riwayat disimpan lokal.
- Pengingat murajaah dapat diaktifkan terpisah dari notifikasi salat. **Jam pengingat bisa dipilih sendiri** melalui Pengaturan → Pengingat ibadah → Jam pengingat murajaah; default **08.00 waktu lokal perangkat**. Saat jam diganti, notifikasi murajaah terjadwal akan diperbarui tanpa mengubah notifikasi salat. Jam pilihan ikut tersimpan dalam backup. Notifikasi hanya dijadwalkan jika ada ayat yang jatuh tempo; Android dapat menunda notifikasi demi penghematan baterai.
- Navigasi bawah: **Beranda, Al-Qur'an, 30 Juz, Hafalan, Progres**. Jadwal salat dan pengaturan dapat dibuka dari ikon bagian atas.
- Bahasa Indonesia (default) dan English melalui sistem `LocalizationsDelegate` resmi Flutter beserta `flutter_localizations`. Bahasa antarmuka berubah; terjemahan Quran tetap bahasa Indonesia dari sumbernya. Tema terang/gelap dan ukuran teks dapat diubah.
- Jadwal MyQuran API sesuai kota, tanggal, serta WIB/WITA/WIT, salat berikutnya, hitung mundur, checklist harian dan riwayat. Checklist hanya berubah melalui tindakan pengguna, menggunakan kunci tanggal setempat; hari baru tidak mewarisi centang kemarin.
- Pilihan kota manual tetap tersedia tanpa izin lokasi. GPS meminta izin saat tombol ditekan, menggunakan reverse geocoding sistem operasi, kemudian menampilkan pencarian kota untuk dikonfirmasi pengguna. Koordinat GPS tidak disimpan.
- Notifikasi salat dan pengingat 5/10/15 menit sebelumnya. Izin Android diminta saat diaktifkan. Jadwal valid dicache, dan mode cache ditandai jika server tidak dapat dihubungi.
- Ikon mushaf emerald/emas, adaptive launcher icon Android, dan splash screen khusus. Nama launcher **Tahfidz Quran**.

## Unduhan audio offline (Android / perangkat dengan filesystem)

Buka **Pengaturan → Qari & audio → Kelola audio offline**, lalu pilih qari dan tekan ikon unduh pada surah yang diinginkan. Progres unduh dihitung per ayat. Bisa dibatalkan; ayat yang selesai tetap tersimpan dan proses berikutnya melanjutkan dari file yang belum ada. Ikon hapus menghapus hanya audio surah dan qari terkait setelah konfirmasi. Audio tidak otomatis diunduh atau dimasukkan ke APK; lokasi file adalah direktori privat aplikasi. Uninstall/menghapus data aplikasi menghilangkan cache ini.

Unduh saat terhubung Wi-Fi dan pastikan ruang perangkat mencukupi. Saat audio diputar, file lokal yang lengkap diprioritaskan; sisanya perlu Internet. Perubahan unduhan saat pemutaran sedang aktif berlaku setelah pemutaran dimulai ulang. Sumber tetap EQuran.id dan hak penggunaannya mengikuti ketentuan penyedia; implementasi ini tidak memberikan izin redistribusi audio. Web belum menyediakan penyimpanan audio offline.

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

## Latihan AI offline (eksperimental)

Halaman Hafalan menyediakan **Latihan dengan AI Offline** untuk rentang ayat yang dipilih. Rekaman diproses oleh Whisper Tiny multilingual int8 melalui sherpa-onnx di perangkat Android, tanpa API AI atau backend. Rekaman dihapus setelah proses; ringkasan lokal hanya disimpan atas persetujuan pengguna.

**Kualitas tilawah belum tervalidasi.** Versi ini menampilkan transkrip nyata dengan status **Belum dapat dinilai**, bukan skor atau koreksi tajwid yang pasti. Lihat [panduan model, privasi, dan Android Studio Windows](docs/OFFLINE_RECITATION.md) serta [hasil validasi dan keterbatasan](OFFLINE_VALIDATION.md).

Sebelum build, siapkan aset model terverifikasi (Python 3.10+; sekitar 100 MB aset dibundel ke APK):

```sh
python tool/prepare_offline_model.py
```

GitHub Actions menjalankan persiapan ini secara otomatis. Bobot tidak disimpan dalam Git. Target harian, kalender, murajaah 1/3/7 hari, dan ujian manual tetap tersedia tanpa AI; detailnya ada di [P0_VALIDATION.md](P0_VALIDATION.md).

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
