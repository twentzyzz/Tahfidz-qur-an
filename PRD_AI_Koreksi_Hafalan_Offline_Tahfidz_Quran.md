# PRD — AI Koreksi Hafalan Al-Qur'an Offline

**Proyek:** Tahfidz Quran (Flutter Android)  
**Repository:** `twentzyzz/Tahfidz-qur-an`  
**Dokumen:** Product Requirements Document (PRD)  
**Versi:** 1.1 — 13 November 2026  
**Status:** Rencana implementasi; kemampuan AI belum dianggap selesai atau tervalidasi.

## 1. Ringkasan produk
Menambahkan fitur *latihan hafalan dengan bantuan pengenalan suara offline* pada aplikasi Flutter Tahfidz Quran yang sudah ada. Pengguna memilih surah dan rentang ayat, merekam bacaan, lalu mendapat indikasi kemungkinan kata terlewat/berbeda dan bagian untuk diulang. Seluruh inferensi AI dan perbandingan teks dilakukan pada perangkat Android, tanpa layanan AI cloud, tanpa akun API berbayar, dan tanpa keharusan hosting backend.

**Batasan utama:** hasil AI hanya umpan balik latihan, bukan penilaian tajwid atau makhraj yang pasti, bukan pengganti guru tahfidz. Bila keyakinan rendah atau model tak bisa memproses audio, tampilkan “Belum dapat dinilai”, bukan memvonis salah.

## 2. Tujuan dan metrik
- Pengguna dapat melakukan sesi hafalan, merekam, memproses, dan meninjau hasil tanpa internet setelah seluruh aset model terpasang.
- Aplikasi tidak mengirim rekaman, transkrip, atau ayat ke server eksternal untuk inferensi.
- UI tetap responsif; sesi dapat dibatalkan dan kesalahan input tertangani.
- Keberhasilan teknis diverifikasi pada emulator dan setidaknya satu HP Android fisik.
- Akurasi harus diukur pada kumpulan uji bacaan yang sah dan beragam; ambang kualitas ditentukan dari pengujian, tidak diklaim sebelum ada bukti.

## 3. Pengguna dan skenario
**Pengguna:** pelajar tahfidz dan pengguna mandiri yang ingin mengulang hafalan.  
**Alur utama:** pilih surah dan ayat → mulai sesi → beri izin mikrofon → rekam → hentikan → proses di perangkat → lihat kata/ayat yang diduga berbeda → dengarkan ulang/ulang rekaman → simpan ringkasan progres secara lokal.

## 4. Lingkup MVP
1. Tombol “Latihan dengan AI Offline” dari halaman hafalan/surah yang sudah tersedia.
2. Pemilihan surah serta rentang ayat dari data Al-Qur'an lokal yang sudah dipakai aplikasi.
3. Rekaman mikrofon, indikator sedang merekam, durasi, tombol stop/batal, dan penanganan izin.
4. Pipeline audio Android → preprocessing yang sesuai model → inferensi ASR di perangkat → normalisasi transkrip Arab → penyelarasan ke ayat yang dipilih.
5. Hasil berupa status **Sesuai terdeteksi**, **Perlu diulang**, dan **Belum dapat dinilai**, beserta alasan sederhana dan penanda kata bila andal.
6. Opsi rekam ulang dan menyimpan ringkasan hasil di penyimpanan lokal.
7. Penjelasan eksplisit bahwa deteksi model bisa keliru dan tidak menguji semua hukum tajwid/makhraj.

**Di luar MVP:** penilaian tajwid/makhraj tingkat ahli, sertifikat kelulusan, pelatihan model dari nol, sinkronisasi cloud, leaderboard online, pembayaran, login wajib, dan jaminan 100% akurat.

## 5. Persyaratan model AI offline
- Audit kandidat model pengenalan bacaan Al-Qur'an atau Arabic ASR yang *benar-benar* dapat dijalankan di Android (misalnya ONNX Runtime atau TensorFlow Lite), bukan hanya skrip Python server.
- Verifikasi sumber, lisensi model, izin redistribusi bobot, ukuran unduhan, RAM/CPU, format audio, tokenizer, dukungan bahasa, dan kemampuan mengenali bacaan tilawah.
- Jangan mengambil bobot model dari sumber tidak jelas. Cantumkan URL, versi, lisensi, dan checksum bila tersedia dalam dokumentasi.
- Jika model terlalu besar atau tak cocok untuk Android, ajukan alternatif yang realistis; **jangan membuat hasil koreksi palsu** atau placeholder yang disajikan sebagai AI aktif.
- Aset model boleh dibundel atau diunduh sekali secara opsional; jika diunduh, beri penjelasan ukuran dan simpan permanen untuk penggunaan offline setelahnya. Jika syaratnya *langsung offline sejak instalasi*, bundel seluruh aset.

## 6. Arsitektur yang disarankan
- **Presentation:** layar latihan, perekam, status pemrosesan, layar hasil.
- **Domain:** `RecitationSession`, `RecognitionResult`, `AlignmentResult`, status ketidakpastian, dan layanan validasi.
- **Data:** referensi ayat lokal, penyimpanan sesi/progres lokal yang kompatibel dengan struktur aplikasi.
- **Inference:** interface `OfflineRecitationRecognizer` dengan implementasi Android on-device yang diuji; pemrosesan audio/transkrip tidak lewat HTTP.
- **Alignment:** pencocokan transkrip hasil ASR terhadap teks ayat pilihan, dengan normalisasi Arab yang didokumentasikan; jangan mengabaikan perbedaan yang berpengaruh pada bacaan secara sembarang.
- Semua operasi berat dilakukan di luar thread UI jika memungkinkan; hindari kebocoran resource mikrofon/model.

## 7. Desain UI/UX
- Pertahankan struktur navigasi dan tema Flutter yang berlaku; desain konsisten dengan UI/UX Tahfidz Quran, bukan aplikasi terpisah.
- Sediakan layar persiapan (pilih ayat), rekam (timer + status + stop), proses (loading + batal), hasil (ayat referensi, penanda yang diduga perlu diperiksa, keyakinan/keterbatasan, ulang).
- Gunakan kontras terbaca untuk teks Arab; tanda warna harus disertai label teks (aksesibilitas).
- Beri konfirmasi bila sesi belum disimpan akan ditinggalkan.
- Jangan mengklaim “tajwid benar/salah” kecuali ada model khusus yang terbukti melalui evaluasi.

## 8. Privasi, keamanan, dan biaya
- Default: rekaman dihapus setelah diproses kecuali pengguna memilih menyimpannya; bila disimpan, beri kontrol hapus.
- Tidak mengirim rekaman dan transkrip ke cloud, analytics, crash-reporting, atau endpoint pihak ketiga.
- Mintalah izin mikrofon hanya saat dibutuhkan; jelaskan kegunaannya.
- Tidak menambahkan langganan hosting, API AI berbayar, atau secret/token dalam repository.
- Pemeriksaan terhadap dependency dan koneksi jaringan harus membuktikan mode offline berfungsi (aktifkan mode pesawat ketika uji).

## 9. Integrasi dengan fitur lama
- Gunakan repository Flutter yang sudah ada; jangan buat proyek baru.
- Jangan menghilangkan daftar surah, halaman ayat, pemutar audio qari, pengaturan pengulangan, bookmark, progres, pengingat salat, maupun pengaturan aplikasi.
- Jika perlu migrasi penyimpanan lokal, buat kompatibilitas mundur dan pengujian data lama.
- Jangan mengubah API/konfigurasi Gradle tanpa alasan serta bukti kompatibilitas.

## 10. Kriteria penerimaan
- Build debug dan release APK berhasil, `flutter analyze` dan `flutter test` lulus atau kegagalan yang ada dijelaskan terpisah.
- Rekam, stop, batal, izin ditolak, audio hening, suara bising, ayat tidak cocok, dan kondisi memori terbatas ditangani tanpa crash.
- Sesudah aset siap, sesi berjalan dalam mode pesawat tanpa panggilan AI ke internet.
- Hasil bukan angka acak/dummy: rekaman nyata menghasilkan keluaran model nyata dan proses pencocokan terdokumentasi.
- Jika prediksi tidak andal, UI menampilkan ketidakpastian, bukan kesalahan pasti.
- UI tampil dan dapat dinavigasi di emulator Android Studio; uji mikrofon dan inferensi nyata juga dilakukan di HP Android fisik.

## 11. Pengujian dan evaluasi
- **Unit test:** normalisasi teks Arab, pencocokan kata/ayat, perhitungan status, penanganan error.
- **Widget test:** transisi layar, tombol rekam, loading, hasil, izin mikrofon ditolak.
- **Integration test:** rekaman → inferensi offline → hasil, jika perangkat dan model tersedia.
- **Evaluasi model:** gunakan dataset bacaan dengan izin yang sesuai, uji pengucapan benar, penghilangan kata, pengulangan, noise, suara berbeda; catat WER/CER dan false positive secara terpisah.
- Perbedaan hasil emulator/HP fisik dan keterbatasan perangkat didokumentasikan.

## 12. Tahapan pekerjaan Codex dan deliverable
**Tahap A — Audit & riset:** baca kode, cek model/lisensi/kemampuan offline, berikan keputusan kelayakan dan risiko.  
**Tahap B — Fondasi:** interface recognizer, pengelolaan aset, izin, rekaman, penyimpanan lokal, unit test.  
**Tahap C — Integrasi AI:** inferensi model sungguhan, normalisasi, alignment, penanganan ketidakpastian.  
**Tahap D — UI & QA:** layar latihan, uji Flutter, dokumentasi emulator dan perangkat fisik, build APK.  
**Tahap E — Review:** branch baru dan Pull Request, changelog, instruksi testing, daftar keterbatasan.

Codex wajib melaporkan yang *sudah terbukti*, yang *baru direncanakan*, dan yang *belum bisa diuji* secara terpisah.

## 13. Android Studio Windows dan emulator
Proyek dijalankan di Android Studio pada Windows; target utama Flutter Android. Jangan mengubahnya menjadi aplikasi web atau proyek Python-only.

**Langkah setelah Pull Request digabung:**
1. Buka folder proyek Flutter di Android Studio; pastikan berada di branch `main`.
2. Jika ada perubahan lokal yang belum disimpan (termasuk konfigurasi Gradle), commit/stash atau tinjau perbedaan sebelum melakukan Git Pull; jangan overwrite otomatis.
3. Lakukan **Git → Pull** untuk mengambil perubahan terbaru dari GitHub.
4. Jalankan `flutter doctor`, `flutter pub get`, lalu `flutter devices` di Terminal Android Studio.
5. Pilih emulator Android yang berjalan, lalu jalankan `flutter run`.
6. Buka menu Tahfidz → AI Koreksi Hafalan Offline; cek layout, navigasi, izin, dan status hasil.
7. Uji di HP Android fisik untuk mikrofon, performa, penggunaan RAM, dan hasil ASR; emulator tidak selalu representatif untuk audio.

**Instruksi bagi Codex:** dokumentasikan versi Flutter/Dart/Gradle/AGP/NDK yang diperlukan secara minimal, langkah menyiapkan aset model, dan cara membangun `flutter build apk --release`. Jangan menyatakan emulator atau mikrofon telah diuji jika pengujian tidak benar-benar dilakukan.

## 14. Prompt implementasi untuk Codex
> Baca PRD ini dan audit repository `twentzyzz/Tahfidz-qur-an`. Tambahkan AI Koreksi Hafalan **100% offline** pada proyek Flutter Android yang ada, tanpa hosting dan tanpa API AI berbayar. Mulai dengan kajian kelayakan model yang dapat dijalankan di Android, termasuk lisensi dan ukuran. Jangan menghapus fitur lama dan jangan membuat UI hasil AI palsu. Implementasikan bertahap, sertakan pengujian, panduan Git Pull + `flutter run` di Android Studio Windows, dan instruksi uji di HP fisik. Kerjakan pada branch baru lalu buat Pull Request. Jika inferensi nyata belum layak atau belum teruji, nyatakan hambatannya dengan jelas.
