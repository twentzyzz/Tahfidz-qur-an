# Bukti validasi AI offline

Branch: `feat/offline-recitation`, dibangun di atas commit P0 `3f7b08f` dan main `337e057`. Tanggal laporan: 13 November 2026 (Asia/Bangkok).

## Sudah terbukti

- Flutter 3.47.9 / Dart 3.13.7; `flutter analyze --no-pub` bersih.
- **41 tes unit/widget lulus**, mencakup regresi fitur lama, P0, normalisasi, alignment, quality gate, izin ditolak, pembersihan audio, pembatalan inferensi/izin yang masih menunggu, checksum model, pembatasan ukuran input, serta penyimpanan ringkasan tanpa transkrip/audio. Tes perangkat memakai fake adapter dan tidak dianggap sebagai pengujian mikrofon Android.
- `flutter build web --no-pub --no-web-resources-cdn`: lulus untuk menjaga target Web lama; ini tidak memvalidasi plugin ASR Android.
- Arsip dan tiga berkas model resmi diverifikasi checksum. Persiapan model diulang dan mengenali aset yang sudah valid tanpa mengunduh lagi.
- Inferensi native Linux memakai worker yang sama dengan implementasi Android berhasil menghasilkan keluaran model nyata. Sampel Inggris bawaan arsip sherpa dipakai sebagai negative control dengan bahasa `ar`; keluarannya keliru, sehingga tidak menjadi bukti akurasi Quran. Tidak mendistribusikan ulang sampel tersebut.
- Pada smoke test native: sekitar 1,6–2,2 detik untuk satu sampel, maximum child RSS 465.684 KiB. Angka ini tidak memprediksi performa HP.
- Trace syscall `connect/sendto` pada smoke test tidak berisi koneksi IP. Audio hening dan saturasi sintetis menghasilkan alasan `silence` dan `clipped`.
- Model produksi tidak mengaktifkan `qualityValidated`. Tidak ada hasil AI palsu, skor acak, atau penanda kata pasti salah. Status hasil tetap **Belum dapat dinilai** hingga ada kalibrasi dan dataset Quran yang memadai.

## Belum selesai / hambatan yang diamati

- Build APK debug telah dicoba. JDK 17, SDK 34/35/36, build-tools, serta NDK 28.2 telah disiapkan. Build berikutnya terhenti pada dependency native `jni` karena **CMake 3.22.1 belum terpasang**.
- Unduhan CMake dari Android SDK maupun distribusi resmi Kitware gagal **HTTP 503**; koneksi metadata paket lain juga gagal 503. Ini merupakan hambatan unduhan pada sesi tersebut, bukan bukti kesalahan kode Dart. TLS/sertifikat/checksum tidak dinonaktifkan. Build APK debug dan release belum dapat diklaim lulus.
- Emulator Android API 35 x86_64 berhasil diluncurkan dengan software emulation (KVM tidak tersedia), ADB mendeteksi perangkat. APK fitur baru belum dipasang, sehingga UI Android dan inferensi Android belum diklaim teruji.
- `integration_test/offline_native_test.dart` disiapkan untuk memuat model sungguhan dan melakukan decode input sintetis pada Android, lalu memeriksa pembersihan resource. Belum dijalankan karena build APK terblokir. Input sintetis tidak membuktikan kualitas bacaan manusia.
- Tidak ada HP fisik terhubung. Mikrofon nyata, mode pesawat Android, performa HP, noise dunia nyata, dan tekanan memori belum diuji.
- Dataset Quran berizin dan anotasi pengajar belum tersedia. WER/CER, false-positive rate, dan ambang confidence untuk Quran belum diukur. Evaluator lokal tersedia; nilai yang tidak memiliki denominator atau verdict valid ditampilkan `null`, bukan 0%.
- Push branch ke GitHub juga telah dicoba dan gagal HTTP 503 (`upstream connect error`); commit masih lokal dan PR belum dibuat.
- GitHub API ditolak kebijakan jaringan saat percobaan read-only. Penambahan `api.github.com` disimpan dalam draf pengaturan, belum dianggap diterapkan. Status PR harus dikonfirmasi dari hasil pembuatan PR, bukan dari adanya branch lokal.

## Melanjutkan validasi

1. Setelah layanan unduhan kembali tersedia, instal **CMake 3.22.1** melalui SDK Manager Android Studio (atau `sdkmanager 'cmake;3.22.1'`).
2. Jalankan `python tool/prepare_offline_model.py`, `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, dan `flutter build apk --release`.
3. Jalankan emulator, lalu `flutter test integration_test/offline_native_test.dart -d <device-id>`. Uji navigasi normal dengan `flutter run` secara terpisah.
4. Uji di HP fisik dan mode pesawat mengikuti `docs/OFFLINE_RECITATION.md`. Lakukan evaluasi dataset sebelum mengubah quality gate.

Konfigurasi cache khusus mesin cloud memakai `PUB_CACHE`, `XDG_CONFIG_HOME`, dan `ANALYZER_STATE_LOCATION_OVERRIDE` di `/workspace/tools`; Java menggunakan truststore CA sistem. Tidak diperlukan perubahan tersebut pada Windows dengan home directory yang dapat ditulis dan sertifikat jaringan normal. Skrip setup lingkungan lama tidak diubah/dipublikasikan ulang.
