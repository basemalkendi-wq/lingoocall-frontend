class ChatMessage {
  final String id;
  final String senderId;
  final String originalText;
  final String translatedText;
  final String senderLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  final bool isAudio;
  final String? audioDuration;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.originalText,
    required this.translatedText,
    required this.senderLanguage,
    required this.targetLanguage,
    required this.timestamp,
    this.isAudio = false,
    this.audioDuration,
  });
}