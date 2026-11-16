class Campaign {
  const Campaign({
    required this.id,
    required this.institutionId,
    required this.sessionId,
    required this.title,
    required this.description,
    required this.status,
    required this.feedbackMode,
    required this.startsAt,
    required this.endsAt,
    required this.minResponseThreshold,
    required this.autoPublishComments,
    required this.createdAt,
  });

  final String id;
  final String institutionId;
  final String sessionId;
  final String title;
  final String? description;
  final String status;
  final String feedbackMode;
  final DateTime startsAt;
  final DateTime endsAt;
  final int minResponseThreshold;
  final bool autoPublishComments;
  final DateTime createdAt;

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      sessionId: map['session_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: (map['status'] as String?) ?? 'draft',
      feedbackMode: (map['feedback_mode'] as String?) ?? 'anonymous',
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: DateTime.parse(map['ends_at'] as String),
      minResponseThreshold: (map['min_response_threshold'] as int?) ?? 5,
      autoPublishComments: (map['auto_publish_comments'] as bool?) ?? false,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  bool get isOpen => status == 'open';

  String get timeRange => '${startsAt.toLocal().toString().split(' ')[0]} → ${endsAt.toLocal().toString().split(' ')[0]}';
}
