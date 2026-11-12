class RecognitionResult {
  const RecognitionResult({
    required this.text,
    required this.model,
    this.reason,
    this.qualityValidated = false,
  });
  final String text, model;
  final String? reason;
  // Production Whisper Tiny has no calibrated Quran confidence profile.
  final bool qualityValidated;
}
