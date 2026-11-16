import '../../core/constants/app_roles.dart';
import '../../core/constants/institution_enums.dart';
import 'institution.dart';

class Membership {
  const Membership({
    required this.id,
    required this.userId,
    required this.role,
    required this.status,
    this.institutionId,
    this.institution,
  });

  final String id;
  final String userId;
  final String? institutionId;
  final AppRole? role;
  final MembershipStatus status;
  final Institution? institution;

  bool get isActive => status == MembershipStatus.active;

  factory Membership.fromMap(Map<String, dynamic> map) {
    final institutionMap = map['institutions'];
    return Membership(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      institutionId: map['institution_id'] as String?,
      role: AppRole.tryParse(map['role'] as String?),
      status: MembershipStatus.parse(map['status'] as String),
      institution: institutionMap is Map<String, dynamic>
          ? Institution.fromMap(institutionMap)
          : null,
    );
  }
}
