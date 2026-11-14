# Bukti validasi AI offline

Branch: `feat/offline-recitation-prd`, dibangun di atas main `012df22`, dengan fondasi P0 pada commit `d32b32f`. Tanggal laporan: 14 November 2026 (Asia/Bangkok).

## Sudah terbukti

- Flutter 3.47.9 / Dart 3.13.7; `flutter analyze --no-pub` bersih.
- `flutter build apk --debug --no-pub`: **lulus**. APK dengan aset model bundel berukuran sekitar 302 MiB. JDK 17, SDK 34/35/36, build-tools 35/36, NDK 28.2.13676358, dan CMake 3.22.1 terpasang. Konfigurasi Gradle proyek tidak diubah.
- `flutter build apk --release`: **lulus**, ukuran yang dilaporkan Flutter 201,4 MB. Masih menggunakan debug signing bawaan proyek untuk pengujian, bukan signing distribusi.
- **41 tes unit/widget lulus**, mencakup regresi fitur lama, P0, normalisasi, alignment, quality gate, izin ditolak, pembersihan audio, pembatalan inferensi/izin yang masih menunggu, checksum model, pembatasan ukuran input, serta penyimpanan ringkasan tanpa transkrip/audio. Tes perangkat memakai fake adapter dan tidak dianggap sebagai pengujian mikrofon Android.
- `flutter build web --no-pub --no-web-resources-cdn`: lulus untuk menjaga target Web lama; ini tidak memvalidasi plugin ASR Android.
- Arsip dan tiga berkas model resmi diverifikasi checksum. Persiapan model diulang dan mengenali aset yang sudah valid tanpa mengunduh lagi.
- Inferensi native Linux memakai worker yang sama dengan implementasi Android berhasil menghasilkan keluaran model nyata. Sampel Inggris bawaan arsip sherpa dipakai sebagai negative control dengan bahasa `ar`; keluarannya keliru, sehingga tidak menjadi bukti akurasi Quran. Tidak mendistribusikan ulang sampel tersebut.
- Pada smoke test native: sekitar 1,6–2,2 detik untuk satu sampel, maximum child RSS 465.684 KiB. Angka ini tidak memprediksi performa HP.
- Trace syscall `connect/sendto` pada smoke test tidak berisi koneksi IP. Audio hening dan saturasi sintetis menghasilkan alasan `silence` dan `clipped`.
- **Tes integrasi native Android lulus** pada emulator API 35 x86_64, software emulation tanpa KVM, RAM AVD 2 GB. Mode pesawat aktif, Wi-Fi mati, dan `dumpsys connectivity` menunjukkan `Active default network: none`. Model nyata memproses sinyal sintetis, berkas sementara dihapus, layar AI dibuka dari Hafalan/Al-Fatihah, dan navigasi kembali berhasil tanpa exception.
- Pada percobaan emulator tersebut, verifikasi model sekitar 19,8 detik dan decode sintetis sekitar 195,5 detik; total tes sekitar 5 menit 29 detik. Ini bukti fungsi, bukan klaim performa HP atau akurasi tilawah.
- Percobaan Android pertama menemukan kegagalan decode logo dan overflow header beranda. Logo tetap dipertahankan, ukuran decode dibatasi sesuai layar, dan ikon cadangan ditampilkan bila decoder gagal. Setelah perbaikan, 41 tes unit/widget dan pengulangan integrasi native lulus.
- Model produksi tidak mengaktifkan `qualityValidated`. Tidak ada hasil AI palsu, skor acak, atau penanda kata pasti salah. Status hasil tetap **Belum dapat dinilai** hingga ada kalibrasi dan dataset Quran yang memadai.

## Belum selesai / hambatan yang diamati

- Hambatan unduhan CMake telah teratasi. Koneksi Maven pada mesin cloud memakai cache Gradle dengan `systemProp.org.gradle.internal.http.idleConnectionTimeout=1` untuk menghindari kegagalan penggunaan ulang koneksi proxy. TLS/sertifikat/checksum tidak dinonaktifkan; pengaturan khusus cloud ini tidak masuk konfigurasi Gradle proyek.
- Percobaan release dengan `--no-pub` setelah debug gagal karena registrasi `integration_test` yang tertinggal. Perintah release standar memperbarui registrasi plugin otomatis dan berhasil; tidak ada edit manual pada registrant atau perubahan Gradle aplikasi.
- `integration_test/offline_microphone_test.dart` sedang divalidasi untuk rekam/putar/proses/hapus menggunakan plugin Android. Belum diklaim lulus. Tes native yang sudah lulus menggunakan input sintetis, bukan bacaan manusia.
- Tidak ada HP fisik terhubung. Mikrofon fisik, performa HP, noise dunia nyata, dan pengujian tekanan memori belum dilakukan. Mode pesawat sudah diuji pada emulator.
- Dataset Quran berizin dan anotasi pengajar belum tersedia. WER/CER, false-positive rate, dan ambang confidence untuk Quran belum diukur. Evaluator lokal tersedia; nilai yang tidak memiliki denominator atau verdict valid ditampilkan `null`, bukan 0%.
- Branch `feat/offline-recitation-prd` sudah berhasil di-push ke GitHub. PR belum dibuat.
- GitHub API ditolak kebijakan jaringan saat percobaan read-only. Penambahan `api.github.com` disimpan dalam draf pengaturan, belum dianggap diterapkan. Status PR harus dikonfirmasi dari hasil pembuatan PR, bukan dari adanya branch lokal.

## Melanjutkan validasi

1. Pastikan toolchain pada `docs/OFFLINE_RECITATION.md`, termasuk **CMake 3.22.1**, tersedia di SDK Manager Android Studio.
2. Jalankan `python tool/prepare_offline_model.py`, `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, dan `flutter build apk --release`.
3. Jalankan tes native dan mikrofon di emulator dalam mode pesawat menggunakan perintah pada `docs/OFFLINE_RECITATION.md`. Uji navigasi normal dengan `flutter run` secara terpisah.
4. Uji di HP fisik dan mode pesawat mengikuti `docs/OFFLINE_RECITATION.md`. Lakukan evaluasi dataset sebelum mengubah quality gate.

Konfigurasi cache khusus mesin cloud memakai `PUB_CACHE`, `XDG_CONFIG_HOME`, dan `ANALYZER_STATE_LOCATION_OVERRIDE` di `/workspace/tools`; Java menggunakan truststore CA sistem. Tidak diperlukan perubahan tersebut pada Windows dengan home directory yang dapat ditulis dan sertifikat jaringan normal. Skrip setup lingkungan lama tidak diubah/dipublikasikan ulang.
