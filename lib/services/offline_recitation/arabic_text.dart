/// Lexical comparison only. Harakat/recitation signs are removed, so this
/// cannot evaluate tajwid, vowel length or makhraj. Hamza, ta marbuta, and
/// alif maqsura are preserved; Uthmani spelling differences remain uncertain.
String normalizeArabic(String value) => value
    .replaceAll('ا\u0654', 'أ')
    .replaceAll('ا\u0655', 'إ')
    .replaceAll('و\u0654', 'ؤ')
    .replaceAll('ي\u0654', 'ئ')
    .replaceAll('ا\u0653', 'آ')
    .replaceAll('ٱ', 'ا')
    .replaceAll(
      RegExp(
        '[\u0610-\u061A\u064B-\u0653\u0656-\u065F\u0670\u06D6-\u06ED\u0640]',
      ),
      '',
    )
    .replaceAll(
      RegExp(
        '[^\u0621-\u063A\u0641-\u064A\u0654\u0655\u066E\u066F\u0671-\u06D3]+',
      ),
      ' ',
    )
    .trim();

List<String> arabicWords(String value) =>
    normalizeArabic(value)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
