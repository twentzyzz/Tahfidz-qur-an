/// Hanya diisi dari sumber Al-Qur'an tepercaya; jangan gunakan teks buatan.
class Ayah {
  const Ayah({
    required this.number,
    required this.arabic,
    required this.translation,
    this.audioByQari = const {},
  });
  final int number;
  final String arabic;
  final String translation;
  final Map<String, String> audioByQari;

  factory Ayah.fromEquranJson(Map<String, dynamic> json) => Ayah(
    number: json['nomorAyat'] as int,
    arabic: json['teksArab'] as String,
    translation: json['teksIndonesia'] as String,
    audioByQari: Map<String, String>.from(json['audio'] as Map? ?? {}),
  );
}
