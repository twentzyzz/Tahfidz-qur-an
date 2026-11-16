// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'audio_offline_models.dart';
import 'quran_repository.dart';

class _Cancelled implements Exception {
  const _Cancelled();
}

/// Personal on-device cache. A file appears only after its full download.
class AudioOfflineService extends ChangeNotifier {
  AudioOfflineService({
    http.Client? client,
    Future<Directory> Function()? directoryProvider,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const maxVerseBytes = 25 * 1024 * 1024;
  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _directoryProvider;

  bool _busy = false;
  bool _cancel = false;
  String? _voice;
  int? _surah;
  int _completed = 0;
  int _total = 0;
  String? _error;

  bool get supported => true;
  bool get isDownloading => _busy;
  bool get cancelRequested => _cancel;
  String? get activeVoice => _voice;
  int? get activeSurah => _surah;
  int get completed => _completed;
  int get total => _total;
  String? get error => _error;

  void _validateVoice(String voice) {
    if (!RegExp(r'^0[1-6]$').hasMatch(voice)) {
      throw ArgumentError.value(voice, 'voice', 'Unknown reciter');
    }
  }

  Future<Directory> _folder(String voice, {bool create = false}) async {
    _validateVoice(voice);
    final root = await _directoryProvider();
    final dir = Directory(root.path + Platform.pathSeparator +
        'murottal_offline' + Platform.pathSeparator + voice);
    if (create && !await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _file(Directory folder, Verse verse) => File(
    folder.path + Platform.pathSeparator +
    verse.surah.toString() + '_' + verse.number.toString() + '.mp3',
  );

  Future<Uri?> cachedUri(Verse verse, String voice) async {
    try {
      final file = _file(await _folder(voice), verse);
      return await file.exists() && await file.length() > 0 ? file.uri : null;
    } catch (_) {
      // Missing file or filesystem support must not break online playback.
      return null;
    }
  }

  Future<OfflineAudioSnapshot> snapshot(String voice) async {
    final dir = await _folder(voice);
    final counts = <int, int>{};
    var bytes = 0;
    if (!await dir.exists()) return OfflineAudioSnapshot(counts, bytes);
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final match = RegExp(r'^(\d{1,3})_(\d{1,3})\.mp3$')
          .firstMatch(entity.uri.pathSegments.last);
      if (match == null) continue;
      final surah = int.parse(match.group(1)!);
      if (surah < 1 || surah > 114) continue;
      final size = await entity.length();
      if (size <= 0) continue;
      counts[surah] = (counts[surah] ?? 0) + 1;
      bytes += size;
    }
    return OfflineAudioSnapshot(counts, bytes);
  }

  Future<void> downloadSurah(List<Verse> verses, String voice) async {
    if (_busy) throw StateError('A download is already running');
    if (verses.isEmpty) throw ArgumentError('No verses to download');
    _validateVoice(voice);
    final surah = verses.first.surah;
    if (surah < 1 || surah > 114 ||
        verses.any((v) => v.surah != surah || !v.audio.containsKey(voice))) {
      throw ArgumentError('Invalid chapter or source');
    }
    _busy = true;
    _cancel = false;
    _voice = voice;
    _surah = surah;
    _completed = 0;
    _total = verses.length;
    _error = null;
    notifyListeners();
    try {
      final dir = await _folder(voice, create: true);
      for (final verse in verses) {
        if (_cancel) break;
        final destination = _file(dir, verse);
        if (!await destination.exists() || await destination.length() == 0) {
          await _downloadOne(verse, voice, destination);
        }
        _completed++;
        notifyListeners();
      }
    } on _Cancelled {
      // Already completed verses remain available.
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      _voice = null;
      _surah = null;
      notifyListeners();
    }
  }

  Future<void> _downloadOne(Verse verse, String voice, File target) async {
    final uri = Uri.parse(verse.audio[voice]!);
    if (uri.scheme != 'https' || uri.host != 'cdn.equran.id') {
      throw const FormatException('Untrusted audio URL');
    }
    final temp = File(target.path + '.part');
    if (await temp.exists()) await temp.delete();
    final response = await _client.send(http.Request('GET', uri))
        .timeout(const Duration(seconds: 40));
    if (response.statusCode != 200) {
      throw HttpException('Audio HTTP ' + response.statusCode.toString(),
          uri: uri);
    }
    final type = response.headers['content-type']?.toLowerCase() ?? '';
    if (type.isNotEmpty && !type.startsWith('audio/') &&
        !type.startsWith('application/octet-stream') &&
        !type.startsWith('binary/octet-stream')) {
      throw const FormatException('Response is not audio');
    }
    if (response.contentLength != null &&
        response.contentLength! > maxVerseBytes) {
      throw const FormatException('Audio exceeds 25 MB');
    }
    final sink = temp.openWrite();
    var size = 0;
    try {
      await for (final chunk in response.stream.timeout(
          const Duration(seconds: 40))) {
        if (_cancel) throw const _Cancelled();
        size += chunk.length;
        if (size > maxVerseBytes) {
          throw const FormatException('Audio exceeds 25 MB');
        }
        sink.add(chunk);
      }
      if (_cancel) throw const _Cancelled();
      await sink.flush();
      await sink.close();
      if (size == 0) throw const FormatException('Empty audio response');
      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
    } catch (_) {
      await sink.close();
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
  }

  void cancel() {
    if (!_busy) return;
    _cancel = true;
    notifyListeners();
  }

  Future<void> deleteSurah(int surah, String voice) async {
    if (_busy) throw StateError('Finish the current download first');
    if (surah < 1 || surah > 114) throw ArgumentError.value(surah, 'surah');
    final dir = await _folder(voice);
    if (!await dir.exists()) return;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith(surah.toString() + '_') &&
          name.endsWith('.mp3')) {
        await entity.delete();
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
    super.dispose();
  }
}
