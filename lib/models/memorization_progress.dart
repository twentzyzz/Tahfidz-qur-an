class MemorizationProgress {
  const MemorizationProgress({
    required this.surahNumber,
    required this.completedAyahs,
    required this.updatedAt,
  });
  final int surahNumber;
  final Set<int> completedAyahs;
  final DateTime updatedAt;
}
