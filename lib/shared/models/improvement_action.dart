class ImprovementAction {
  const ImprovementAction({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueOn,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueOn;
  final DateTime createdAt;

  factory ImprovementAction.fromMap(Map<String, dynamic> map) {
    return ImprovementAction(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'planned',
      dueOn: DateTime.tryParse(map['due_on'] as String? ?? ''),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
