import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'audio_offline_models.dart';
import 'quran_repository.dart';

class AudioOfflineService extends ChangeNotifier {
  AudioOfflineService({
    http.Client? client,
    Future<dynamic> Function()? directoryProvider,
  });

  bool get supported => false;
  bool get isDownloading => false;
  bool get cancelRequested => false;
  String? get activeVoice => null;
  int? get activeSurah => null;
  int get completed => 0;
  int get total => 0;
  String? get error => null;

  Future<Uri?> cachedUri(Verse verse, String voice) async => null;
  Future<OfflineAudioSnapshot> snapshot(String voice) async =>
      const OfflineAudioSnapshot({}, 0);
  Future<void> downloadSurah(List<Verse> verses, String voice) async =>
      throw UnsupportedError('Offline audio requires a supported device');
  Future<void> deleteSurah(int surah, String voice) async =>
      throw UnsupportedError('Offline audio requires a supported device');
  void cancel() {}
}
