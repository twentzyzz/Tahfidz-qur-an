# Latihan pengenalan bacaan offline — prototipe Android

Fitur ini melanjutkan aplikasi yang ada dan fondasi P0. Model menghasilkan transkrip nyata secara lokal. **Kualitas tilawah, confidence, dan koreksi kata belum tervalidasi.** Karena itu implementasi produksi menampilkan **Belum dapat dinilai**, bahkan ketika transkrip kebetulan sama dengan referensi. Tidak ada skor acak, simulasi hasil AI, atau klaim tajwid/makhraj benar/salah.

## Keputusan model dan sumber

| Kandidat | Bukti dan keputusan |
| --- | --- |
| Whisper Tiny multilingual, int8, sherpa-onnx | Dipilih untuk prototipe: bahasa Arab (`ar`), 39 juta parameter menurut OpenAI, decoder transcribe, ONNX Runtime di Android melalui sherpa_onnx 2.0.1. Tiga aset yang dipilih berjumlah **103.609.903 byte**. Inferensi native Linux sudah dijalankan, bukan bukti akurasi Quran atau performa HP. |
| Whisper Base multilingual | OpenAI mendokumentasikan 74 juta parameter. Lisensi MIT juga berlaku, tetapi model ini tidak diunduh/diuji pada tugas ini. Kandidat evaluasi berikutnya jika Tiny tidak memadai; tidak diasumsikan lebih akurat pada Quran tanpa dataset. |
| Model khusus Quran | Belum dipilih: harus tersedia bobot berlisensi redistribusi, tokenizer, preprocessing, dan ekspor Android yang dapat diuji. Model Python/cloud saja tidak memenuhi kebutuhan. |

- Model asal dan lisensi kode/bobot MIT: https://github.com/openai/whisper dan https://github.com/openai/whisper/blob/main/LICENSE
- Export/runtime sherpa-onnx, Apache-2.0: https://github.com/k2-fsa/sherpa-onnx dan https://github.com/k2-fsa/sherpa-onnx/tree/master/scripts/whisper
- Flutter FFI: https://pub.dev/packages/sherpa_onnx/versions/2.0.1
- Arsip resmi konversi, rilis `asr-models`, aset bertanggal 13 Juli 2024: https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-tiny.tar.bz2
- SHA-256 arsip: `c46116994e539aa165266d96b325252728429c12535eb9d8b6a2b10f129e66b1`.

Checksum dipatok dari unduhan HTTPS resmi yang diverifikasi TLS dalam audit ini; bukan klaim signature kriptografis dari penerbit. Checksum per berkas ada di `tool/prepare_offline_model.py` dan pemeriksa runtime. Arsip upstream dapat berubah: jika checksum berbeda, hentikan setup dan audit perubahan sumber; jangan menonaktifkan pemeriksaan atau mengganti hash tanpa audit.

Lisensi Whisper dan sherpa disertakan dalam `assets/models/whisper_tiny/`. Kebutuhan VRAM yang disebut README OpenAI adalah pengukuran lingkungan mereka, **bukan RAM Android**. Pada satu smoke test Linux di mesin ini, proses native selesai sekitar 1,6–2,2 detik dengan maximum child RSS 465.684 KiB. Angka tersebut bukan jaminan latensi/RAM di HP.

## Aset dan build

Aset model dibundel ke APK, sehingga pengguna tidak perlu mengunduh model setelah instalasi. Pada penggunaan pertama, aset disalin ke direktori aplikasi untuk runtime native dan checksum diperiksa. Sediakan tambahan sekitar 100 MB untuk salinan privat di luar ukuran APK. Bobot tidak dimasukkan ke Git; script dan CI mengambil aset resmi dengan checksum.

```sh
python tool/prepare_offline_model.py
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

Python 3.10+ diperlukan hanya untuk menyiapkan aset saat pengembangan/build, bukan ketika aplikasi dipakai. Script tidak mengekstrak jalur arbitrer dari arsip, hanya tiga berkas yang sudah ditentukan. Mengulang script memeriksa aset yang ada dan melewati unduhan jika checksum cocok.

Saat berpindah antara debug, integration test, dan release, gunakan perintah Flutter standar di atas tanpa `--no-pub`. Flutter 3.47.9 perlu memperbarui registrasi plugin sesuai mode; melewati langkah itu setelah build debug dapat meninggalkan referensi `integration_test` yang tidak disertakan dalam release. Jangan mengedit `GeneratedPluginRegistrant.java` secara manual.

Toolchain proyek: Flutter **3.47.9**, Dart **3.13.7**, JDK **17**, Gradle **9.3.1**, AGP **9.1.0**, Kotlin **2.4.0**, NDK **28.2.13676358**, CMake **3.22.1**, compile SDK aplikasi **36**. Plugin yang terkunci juga membutuhkan platform SDK **34/35**, di samping **36**. Pasang lewat SDK Manager Android Studio. Application ID tetap `id.tahfidz.tahfidz_quran`; konfigurasi Gradle/signing aplikasi tidak sengaja diganti. Release masih menggunakan debug signing proyek untuk pengujian pribadi, bukan distribusi Play Store.

## Arsitektur dan privasi

- `RecitationController` mengelola persiapan, rekam, rekaman siap, proses, pembatalan, hasil, dan pemulihan error.
- `RecitationDevice` memisahkan perekam/perangkat dari UI; `OfflineRecitationRecognizer` adalah kontrak ASR.
- `record` merekam WAV PCM16 mono 16 kHz, maksimum 20 detik. Izin mikrofon baru diminta setelah tombol Mulai rekam ditekan.
- `recognizeWhisper` menjalankan sherpa-onnx di isolate, dua thread CPU, `language=ar`, `task=transcribe`, debug logging nonaktif. Tidak ada HTTP pada jalur inferensi.
- Rekaman dapat diputar sebelum pemrosesan. Setelah proses, pembatalan, atau keluar, rekaman dihapus; rekaman sisa crash dibersihkan pada persiapan berikutnya. Rekaman tidak disimpan permanen.
- Pembatalan native bersifat kooperatif: UI menandai pembatalan dan membuang hasil, lalu menunggu decode selesai agar stream/model dapat dibebaskan dengan aman. Tidak membunuh isolate saat C/C++ sedang memakai resource. Tidak menjalankan decode kedua selama pembersihan.
- Saat aplikasi masuk background selama merekam, rekaman dibatalkan.
- Ringkasan hanya disimpan setelah persetujuan tombol Simpan ringkasan. Isinya ID, waktu, referensi ayat, status, alasan, dan model; **tanpa audio atau transkrip**. Ringkasan dapat dilihat/dihapus melalui Progres → Kalender & hasil latihan. Status hafalan lama tidak diubah otomatis.
- Field `offlineRecitationSessions` ditambahkan pada `user.v2`; data sebelumnya dipertahankan.
- Audio qari dan jadwal salat tetap memiliki fungsi jaringan yang sudah ada. Fitur tersebut tidak dipakai untuk inferensi AI. Jalur AI tidak memerlukan API key, backend, login, atau layanan berbayar.

## Normalisasi dan batas hasil

Normalisasi membuang tatweel, harakat, tanda waqaf, dan alif kecil; alif wasla dinormalkan ke alif. Bentuk hamza gabungan dikomposisi secara eksplisit, tetapi perbedaan hamza, ta marbuta/ha, dan alif maqsura/ya tidak disamakan. Perbedaan rasm Uthmani dan ejaan transkrip tetap dapat memunculkan perbedaan leksikal. Normalisasi ini **tidak** mengukur tajwid, panjang vokal, makhraj, atau kualitas qiraah.

Alignment memakai edit distance kata dengan operasi terlewat, tambahan, dan berbeda, serta referensi ayat/posisi kata. Jalur status Sesuai terdeteksi/Perlu diulang hanya digunakan untuk recognizer dengan quality profile yang telah divalidasi. Whisper Tiny produksi tidak memiliki profile tersebut: `qualityValidated=false`; penanda kata tidak ditampilkan sebagai tuduhan kesalahan. Unit test memakai hasil terkontrol untuk menguji alignment dan gate, bukan hasil AI yang ditampilkan ke pengguna.

Perekam menghasilkan mono 16 kHz. Precheck memeriksa sample rate, batas ukuran 1 MiB, durasi terlalu pendek/panjang, RMS sangat rendah, dan saturasi berlebihan. Ambang ini adalah filter input teknis; bukan confidence ASR. Noise, salah surah, suara berbeda, atau halusinasi model tetap harus ditangani sebagai hasil tidak pasti.

## Evaluasi lokal yang dapat diulang

Smoke test native Linux memakai `test_wavs/0.wav` dari arsip resmi sherpa (sampel bahasa Inggris) sebagai **negative control**, tanpa mendistribusikan ulang audio. Memaksa bahasa Arab menghasilkan transkrip Arab yang keliru: bukti penting bahwa model tidak boleh dijadikan hakim bacaan. Berkas hening dan saturasi yang dihasilkan secara sintetis ditolak sebagai `silence`/`clipped`. Trace syscall `connect/sendto` pada smoke test tidak menunjukkan koneksi IP; ini belum menggantikan uji mode pesawat Android.

Untuk kumpulan bacaan Quran yang memiliki izin, buat JSONL lokal:

```json
{"id":"sample-001","audio":"sample-001.wav","reference":"بسم الله الرحمن الرحيم","license":"izin pemilik rekaman / sumber dan lisensi yang dapat diverifikasi"}
```

```sh
dart run tool/evaluate_offline_recognizer.dart assets/models/whisper_tiny samples/dataset.jsonl
```

Runner memakai model sungguhan, mencatat WER, CER, durasi, kegagalan input, dan abstention. WER/CER dihitung setelah normalisasi yang dijelaskan di atas; WER dapat melebihi 1 jika banyak penambahan. Tidak menulis audio atau transkrip mentah. False-positive rate tetap `null` selama tidak ada verdict tervalidasi—bukan 0%. Belum tersedia dataset Quran berizin dan anotasi pengajar pada tugas ini; belum ada klaim akurasi Quran. Siapkan bacaan benar, penghilangan/pengulangan kata, salah ayat, noise, serta beberapa penutur sebelum membuka quality gate.

## Android Studio Windows setelah PR digabung

1. Simpan perubahan lokal terlebih dahulu: tinjau diff lalu commit/stash seperlunya. Jangan menimpa konfigurasi lokal secara otomatis.
2. Buka proyek Flutter yang sama, pilih branch `main`, lalu **Git → Pull**.
3. Pastikan JDK 17 serta SDK/NDK di atas tersedia. Jalankan `flutter doctor`, `python tool/prepare_offline_model.py`, `flutter pub get --enforce-lockfile`, dan `flutter devices`.
4. Pilih emulator Android yang berjalan, kemudian `flutter run`.
5. Buka **Hafalan → pilih surah → rentang pendek → Latihan dengan AI Offline**. Tunggu persiapan model, mulai rekam, izinkan mikrofon, hentikan, dengarkan ulang, proses, lalu simpan ringkasan bila diinginkan.
6. Ulangi di HP fisik dengan mode pesawat, termasuk izin ditolak, hening, noise, batal saat merekam/proses, background, hapus ringkasan, dan beberapa sesi berulang. Periksa penggunaan RAM dan keberadaan rekaman sisa.
7. Model dapat keliru; jangan menggunakan hasil prototipe sebagai bukti benar/salahnya tajwid atau makhraj.

## Status bukti

### Tes integrasi Android yang dapat diulang

Jalankan emulator, pilih ID dari `flutter devices`, lalu ganti `<device-id>` di bawah. `adb` tersedia di folder `platform-tools` Android SDK; tambahkan folder itu ke PATH Terminal Android Studio bila diperlukan.

```sh
flutter build apk --debug
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <device-id> shell cmd connectivity airplane-mode enable
adb -s <device-id> shell svc wifi disable
adb -s <device-id> shell svc data disable
flutter test integration_test/offline_native_test.dart -d <device-id>
adb -s <device-id> shell pm grant id.tahfidz.tahfidz_quran android.permission.RECORD_AUDIO
flutter test integration_test/offline_microphone_test.dart -d <device-id>
```

Tes native menjalankan decoder model bundel pada sinyal sintetis dan menavigasi layar AI. Tes mikrofon memakai plugin Android sungguhan untuk rekam, stop, putar, proses, serta hapus audio. Pemberian izin via ADB hanya untuk tes otomatis; aplikasi tetap meminta izin saat pengguna menekan Mulai rekam. Uji penolakan izin secara manual dengan mencabut izin terlebih dahulu. Suara emulator, terutama jika audio host dimatikan, tidak membuktikan mikrofon HP atau akurasi tilawah.

Hasil akhir analyze/test/build/emulator dicatat dalam `OFFLINE_VALIDATION.md`. Pengujian mikrofon nyata, dataset Quran berizin, dan setidaknya satu HP fisik tetap wajib sebelum menyatakan kriteria penerimaan produk terpenuhi. Tidak ada perangkat fisik tersambung pada sesi cloud ini.
