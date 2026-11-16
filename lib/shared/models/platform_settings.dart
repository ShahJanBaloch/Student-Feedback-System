class PlatformSettings {
  const PlatformSettings({
    required this.studentSelfRegistration,
    required this.institutionSelfOnboarding,
    required this.defaultMinResponseThreshold,
    required this.allowConfidentialMode,
    this.maintenanceMessage,
  });

  final bool studentSelfRegistration;
  final bool institutionSelfOnboarding;
  final int defaultMinResponseThreshold;
  final bool allowConfidentialMode;
  final String? maintenanceMessage;

  factory PlatformSettings.fromMap(Map<String, dynamic> map) {
    return PlatformSettings(
      studentSelfRegistration: map['student_self_registration'] as bool? ?? true,
      institutionSelfOnboarding:
          map['institution_self_onboarding'] as bool? ?? true,
      defaultMinResponseThreshold:
          map['default_min_response_threshold'] as int? ?? 5,
      allowConfidentialMode: map['allow_confidential_mode'] as bool? ?? true,
      maintenanceMessage: map['maintenance_message'] as String?,
    );
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.createdAt,
    this.institutionId,
    this.actorId,
  });

  final String id;
  final String action;
  final String entityType;
  final String? institutionId;
  final String? actorId;
  final DateTime createdAt;

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] as String,
      action: map['action'] as String,
      entityType: map['entity_type'] as String,
      institutionId: map['institution_id'] as String?,
      actorId: map['actor_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
