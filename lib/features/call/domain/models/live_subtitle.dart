class LiveSubtitle {
  final String speakerName;
  final String originalSentence;
  final String translatedSentence;
  final String originalLang;
  final String targetLang;

  LiveSubtitle({
    required this.speakerName,
    required this.originalSentence,
    required this.translatedSentence,
    required this.originalLang,
    required this.targetLang,
  });
}