import '../models/memorization_progress.dart';

/// Sambungkan ke penyimpanan lokal (misalnya SQLite) di tahap berikutnya.
/// Tahap pertama belum menulis atau membaca progres pengguna.
abstract class ProgressService {
  Future<List<MemorizationProgress>> load();
  Future<void> save(MemorizationProgress progress);
}
