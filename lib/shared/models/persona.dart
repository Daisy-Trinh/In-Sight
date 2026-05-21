/// Persona enum — 3 AI personas của In-Sight
enum Persona {
  lay('lay', 'Lầy'),
  mentor('mentor', 'Mentor'),
  soul('soul', 'Soul');

  final String id;
  final String displayName;

  const Persona(this.id, this.displayName);

  static Persona fromId(String id) {
    return Persona.values.firstWhere(
      (p) => p.id == id,
      orElse: () => Persona.lay,
    );
  }
}

/// Mood tags cho Journey log
enum MoodTag {
  happy('😊', 'Vui'),
  calm('😌', 'Bình yên'),
  thoughtful('🤔', 'Suy nghĩ'),
  sad('😔', 'Buồn'),
  anxious('😰', 'Lo lắng'),
  angry('😤', 'Tức'),
  grateful('🙏', 'Biết ơn'),
  loved('🥰', 'Được yêu');

  final String emoji;
  final String label;

  const MoodTag(this.emoji, this.label);
}

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;
  final int? hapticType; // 1=light, 2=medium, 3=heavy

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.hapticType,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    int? hapticType,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      hapticType: hapticType ?? this.hapticType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'hapticType': hapticType,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        isUser: json['isUser'] as bool,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        hapticType: json['hapticType'] as int?,
      );
}

/// Journey session model
class JourneySession {
  final String id;
  final Persona persona;
  final DateTime date;
  final List<ChatMessage> messages;
  final MoodTag? mood;
  final String? summary;

  const JourneySession({
    required this.id,
    required this.persona,
    required this.date,
    required this.messages,
    this.mood,
    this.summary,
  });

  int get messageCount => messages.length;

  String get previewText {
    final userMessages = messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) return '';
    return userMessages.first.content.length > 50
        ? '${userMessages.first.content.substring(0, 50)}...'
        : userMessages.first.content;
  }
}

/// Quota model
class QuotaStatus {
  final int tokensRemaining;
  final int tokensGranted;
  final int adGrants;
  final bool isPremium;
  final DateTime? resetsAt;
  final String quotaDate;

  const QuotaStatus({
    required this.tokensRemaining,
    required this.tokensGranted,
    required this.adGrants,
    required this.isPremium,
    this.resetsAt,
    required this.quotaDate,
  });

  bool get isEmpty => tokensRemaining <= 0;
  bool get isLow => tokensRemaining <= 5 && tokensRemaining > 0;

  double get percentRemaining => tokensGranted > 0
      ? (tokensRemaining / tokensGranted).clamp(0.0, 1.0)
      : 0.0;

  Map<String, dynamic> toJson() => {
        'tokensRemaining': tokensRemaining,
        'tokensGranted': tokensGranted,
        'adGrants': adGrants,
        'isPremium': isPremium,
        'resetsAt': resetsAt?.millisecondsSinceEpoch,
        'quotaDate': quotaDate,
      };

  factory QuotaStatus.fromJson(Map<String, dynamic> json) => QuotaStatus(
        tokensRemaining: json['tokensRemaining'] as int,
        tokensGranted: json['tokensGranted'] as int,
        adGrants: json['adGrants'] as int? ?? 0,
        isPremium: json['isPremium'] as bool? ?? false,
        resetsAt: json['resetsAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['resetsAt'] as int)
            : null,
        quotaDate: json['quotaDate'] as String? ?? '',
      );

  /// Default free-tier quota
  factory QuotaStatus.defaultFree() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return QuotaStatus(
      tokensRemaining: 20,
      tokensGranted: 20,
      adGrants: 0,
      isPremium: false,
      quotaDate: dateStr,
    );
  }
}
