import 'domain.dart';

RecitationDevice createRecitationDevice() => UnsupportedRecitationDevice();

class UnsupportedRecitationDevice implements RecitationDevice {
  @override
  bool get supported => false;
  @override
  Future<void> prepare() async => throw const RecitationFailure('unsupported');
  @override
  Future<void> startRecording() async =>
      throw const RecitationFailure('unsupported');
  @override
  Future<String?> stopRecording() async => null;
  @override
  Future<void> playRecording(String path) async {}
  @override
  Future<void> stopPlayback() async {}
  @override
  Future<void> removeRecording(String path) async {}
  @override
  Future<void> dispose() async {}
  @override
  Future<RecognitionResult> recognize(String path) async =>
      throw const RecitationFailure('unsupported');
}
