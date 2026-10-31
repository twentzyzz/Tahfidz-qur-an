class Surah {
  const Surah({
    required this.number,
    required this.name,
    required this.verseCount,
  });
  final int number;
  final String name;
  final int verseCount;

  factory Surah.fromEquranJson(Map<String, dynamic> json) => Surah(
    number: json['nomor'] as int,
    name: json['namaLatin'] as String,
    verseCount: json['jumlahAyat'] as int,
  );
}
