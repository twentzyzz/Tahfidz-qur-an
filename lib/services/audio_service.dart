/// Kontrak untuk pemutar murottal per ayat di tahap berikutnya.
/// Implementasi harus memvalidasi URL dari API dan melepas player saat selesai.
abstract class AudioService {
  Future<void> play(Uri source, {required String qariId, int repeatCount = 1});
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}
