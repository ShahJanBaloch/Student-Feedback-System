import '../../core/constants/institution_enums.dart';

class AccessRequest {
  const AccessRequest({
    required this.id,
    required this.requesterId,
    required this.requestType,
    required this.status,
    required this.payload,
    this.institutionId,
    this.decisionReason,
    this.createdAt,
  });

  final String id;
  final String requesterId;
  final String? institutionId;
  final String requestType;
  final AccessRequestStatus status;
  final Map<String, dynamic> payload;
  final String? decisionReason;
  final DateTime? createdAt;

  String get studentNumber => '${payload['student_number'] ?? ''}';
  String get submittedName => '${payload['full_name'] ?? ''}';
  String get requestedRole => '${payload['requested_role'] ?? ''}';
  String get requestedRoleLabel {
    return switch (requestedRole) {
      'institution_admin' => 'VC / Admin',
      'hod' => 'HOD',
      'teacher' => 'Teacher',
      _ => 'Staff',
    };
  }

  factory AccessRequest.fromMap(Map<String, dynamic> map) {
    return AccessRequest(
      id: map['id'] as String,
      requesterId: map['requester_id'] as String,
      institutionId: map['institution_id'] as String?,
      requestType: map['request_type'] as String,
      status: AccessRequestStatus.parse(map['status'] as String),
      payload: Map<String, dynamic>.from(
        (map['payload'] as Map?) ?? const <String, dynamic>{},
      ),
      decisionReason: map['decision_reason'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
    );
  }
}
