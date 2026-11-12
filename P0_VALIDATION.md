# P0 — Target harian, murajaah, dan ujian manual

Implementasi melanjutkan commit `337e057` pada branch `feat/tahfidz-p0`.

## Alur pengguna

- **Progres → Kalender & hasil latihan**: pilih tanggal untuk melihat jumlah ayat unik, target, status pencapaian, dan hasil latihan manual.
- Target tetap 1/3/5/10/20 ayat. Perubahan target berlaku mulai hari perubahan; target pada hari sebelumnya dipertahankan. Penggantian target beberapa kali pada hari yang sama memakai nilai terakhir.
- Aktivitas kalender tidak hilang saat ayat direset. Grafik tujuh hari yang sudah ada tetap memakai definisi sebelumnya: ayat yang masih berstatus hafal. Keterangan masing-masing menjelaskan perbedaannya.
- **Hafalan → Murajaah terjadwal**: ayat baru yang ditandai hafal dijadwalkan besok. Hafalan lama tanpa jadwal ditampilkan sebagai perlu diulang hari ini. Reset atau perubahan menjadi sedang dihafal menghapus jadwal ayat tersebut.
- Hasil manual menentukan interval: perlu diulang 1 hari, dengan bantuan 3 hari, lancar 7 hari. Interval dihitung berdasarkan tanggal lokal perangkat, termasuk perpindahan bulan/tahun.
- **Hafalan → pilih surah → pilih ayat awal/akhir → Ujian rentang**: mode sembunyikan teks atau sambung ayat. Ujian hanya mencakup rentang yang dipilih. Pada sambung ayat, ayat kedua dan seterusnya mendapat petunjuk ayat sebelumnya dalam rentang; ayat pertama dibaca dari ingatan.
- Pengguna membuka jawaban dan menilai kelancaran sendiri. Contoh qari tersedia setelah jawaban dibuka dan membutuhkan internet. Ujian manual dan teks lokal tidak membutuhkan koneksi.
- Ringkasan disimpan hanya saat **Simpan hasil** ditekan. Keluar sebelum menyimpan meminta konfirmasi. Penyimpanan memperbarui jadwal untuk ayat yang sudah berstatus hafal, tanpa otomatis mengubah status hafalan.
- Dukungan Indonesia/English dan tema aplikasi dipertahankan. Setoran suara/AI tidak termasuk perubahan P0 ini.

## Penyimpanan

Tetap menggunakan SharedPreferences `user.v2`. Field baru: `dailyRecords`, `goalHistory`, `reviews`, `practiceSessions`. Bookmark, riwayat, progres, pengaturan, dan data lain dipertahankan. Riwayat lama digunakan sebagai aktivitas, tetapi target historis yang tidak diketahui tidak ditebak. Riwayat target mulai dicatat ketika versi ini pertama kali dibuka.

Penulisan seluruh dokumen diserialkan; state diterbitkan setelah penyimpanan berhasil. Progres dan riwayat ditulis bersama, begitu juga hasil latihan dan jadwal. ID sesi membuat pengulangan simpan idempoten. Tidak ada perekaman suara, secret baru, atau layanan AI.

## Validasi setelah lingkungan dipublikasikan

- Flutter 3.47.9 / Dart 3.13.7 berhasil diaktifkan. Akses `storage.googleapis.com` sudah diterapkan pada runtime.
- `flutter pub get --enforce-lockfile`: lulus; lockfile tetap sama.
- Formatter Dart dijalankan pada berkas implementasi dan tes yang berubah.
- `flutter analyze --no-pub`: lulus, tidak ada issue.
- `flutter test --no-pub`: **28 tes lulus**, termasuk 11 tes baru.
- `flutter build web --no-pub`: lulus.
- `flutter build web --no-pub --no-web-resources-cdn`: lulus; mesin CanvasKit disertakan lokal untuk pengujian tanpa akses CDN `www.gstatic.com`.
- Diperbaiki selama validasi: parameter tombol audio (`label` pada `OutlinedButton.icon`) serta langkah gulir tes agar tombol simpan terlihat sepenuhnya sebelum diklik.
- `git diff --check`: lulus. Lockfile, workflow CI dan konfigurasi applicationId tidak berubah.
- Build APK dan instalasi Android belum diuji; Android SDK belum tersedia. CI remote belum dijalankan dan perubahan belum dikirim ke GitHub.

## Perintah pengembangan pada lingkungan ini

```sh
export PATH="/workspace/tools/flutter/bin:$PATH"
export PUB_CACHE=/workspace/tools/pub-cache
export XDG_CONFIG_HOME=/workspace/tools/config
export ANALYZER_STATE_LOCATION_OVERRIDE=/workspace/tools/analyzer-state
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
export CI=true
cd /workspace/Tahfidz-qur-an
flutter pub get --enforce-lockfile
dart format lib test
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
# Setelah Java 17 dan Android SDK tersedia:
flutter build apk --release
```

Periksa UI manual pada layar sempit dengan pembesaran teks, tema gelap dan English; uji penolakan penyimpanan dan pergantian hari pada perangkat. Workflow GitHub Actions yang ada tetap menjalankan analyze, test, dan build APK ketika perubahan diajukan melalui PR.
