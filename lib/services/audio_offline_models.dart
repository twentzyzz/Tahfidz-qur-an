class OfflineAudioSnapshot {
  const OfflineAudioSnapshot(this.counts, this.bytes);

  final Map<int, int> counts;
  final int bytes;

  int countFor(int surah) => counts[surah] ?? 0;
}
