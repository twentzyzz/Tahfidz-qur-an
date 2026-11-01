# Validasi versi 1.1.0+2

Tanggal: 1 November 2026. Proyek melanjutkan branch main setelah PR tahap pertama digabungkan; identitas aplikasi dan workflow `blank.yml` dipertahankan.

## Hasil yang dijalankan

- `flutter pub get --enforce-lockfile`: lulus.
- `flutter analyze`: bersih, tidak ada issue.
- `flutter test`: **11 tes lulus**. Cakupan: seluruh 114 surah/6.236 ayat dan enam URL qari per ayat; 30 juz tanpa ayat hilang/duplikat; urutan pengulangan rentang; kontrol audio menggunakan fake engine; bookmark/progres/pengaturan setelah reload penyimpanan; checklist tanggal baru; WIB/WITA/WIT dan batas tengah malam; validasi kota/tanggal API serta cache ketika offline; penjadwalan/pembatalan notifikasi melalui platform channel Android yang dimock; navigasi pembaca, teks Arab, bookmark, progres, bahasa/tema, sembunyikan Arab, dan pilihan qari.
- `flutter build web`: lulus. Build Web tidak membuktikan notifikasi/GPS native bekerja pada HP.
- Data Quran: semua 114 jumlah ayat EQuran.id dicocokkan dengan metadata AlQuran Cloud. Batas 30 juz mencakup seluruh 6.236 ayat tepat sekali dalam urutan Quran.
- Audio nyata: 18 sampel HTTP dari enam qari pada surah 1, 55, dan 114 berhasil diterima dengan tipe konten audio. Semua 37.416 URL tidak diunduh/didengarkan satu per satu. Lihat provenance.
- Jadwal nyata: respons MyQuran untuk Jakarta (WIB), Badung (WITA), dan Asmat (WIT) pada 2026-11-01 berhasil diverifikasi. Percobaan Python sebelumnya menerima 403; permintaan dengan user-agent Dart berhasil.
- Ikon mushaf diperiksa secara visual. Resource launcher raster/adaptive dan splash Android menunjuk ikon baru; tidak memakai logo Flutter.

## Batas validasi

Android SDK belum tersedia di Codex Cloud; build APK versi ini dijalankan melalui GitHub Actions pada PR. Status run dan artifact versi ini dicatat di deskripsi PR setelah selesai. Hasil APK tahap pertama tidak dianggap sebagai bukti build versi 1.1.0.

Belum dilakukan pada perangkat fisik: instalasi/upgrade APK, mendengarkan seluruh qari, izin GPS saat ditolak/ditolak permanen, pengiriman notifikasi saat layar terkunci/Doze/reboot, serta tampilan ikon pada launcher vendor. Tes notifikasi membuktikan permintaan penjadwalan dikirim melalui plugin, bukan bahwa sistem operasi telah menampilkan notifikasi pada waktu yang tepat.

Enam qari aktif; empat belas qari tambahan belum diintegrasikan karena sumber per ayat dan izin penggunaannya belum terverifikasi. Tidak ada audio URL buatan. Notifikasi hanya dijadwalkan tujuh hari ke depan, memerlukan aplikasi dibuka berkala, dan memakai mode inexact sesuai pembatasan Android. Penyimpanan tidak disinkronkan ke cloud.
