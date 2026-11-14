# Changelog

## Unreleased

- Header beranda tetap stabil jika decoder gambar Android gagal: ukuran decode logo dibatasi dan ikon cadangan tersedia.
- Build debug/release dan dua tes integrasi Android offline tervalidasi; panduan tes mikrofon menjelaskan izin dan `--no-uninstall`.

- Kalender target hafalan harian dengan riwayat pencapaian yang tetap ada setelah reset ayat.
- Murajaah terjadwal berdasarkan penilaian manual dengan interval 1/3/7 hari.
- Ujian manual pada rentang ayat: sembunyikan teks dan sambung ayat, ringkasan hasil, serta pembatalan.
- Prototipe Android pengenalan bacaan offline: perekaman WAV 16 kHz mono, pemutaran rekaman lokal, inferensi Whisper Tiny int8 dalam isolate, pembersihan rekaman, dan ringkasan atas persetujuan.
- Model dibundel melalui script dengan checksum dan lisensi; tidak ada backend, API AI berbayar, atau kunci API.
- Normalisasi Arab, alignment leksikal, dan alat evaluasi WER/CER. Quality gate tetap tertutup: hasil produksi selalu tidak pasti sampai pengujian Quran memadai.
- Tes regresi dan panduan Android Studio Windows. Data pengguna, applicationId, fitur lama, dan workflow APK dipertahankan; CI menambahkan persiapan model.

Batas rilis dan hasil pemeriksaan tercatat di `OFFLINE_VALIDATION.md`. Fitur ini belum boleh dipromosikan sebagai koreksi tajwid/makhraj tervalidasi.
