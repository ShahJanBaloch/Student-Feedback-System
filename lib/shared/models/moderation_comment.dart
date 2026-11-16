class ModerationComment {
  const ModerationComment({
    required this.id,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String body;
  final DateTime createdAt;

  factory ModerationComment.fromMap(Map<String, dynamic> map) {
    return ModerationComment(
      id: map['id'] as String,
      body: map['body'] as String,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
