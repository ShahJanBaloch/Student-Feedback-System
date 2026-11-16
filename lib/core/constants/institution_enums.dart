enum InstitutionType {
  school,
  college,
  university;

  String get storageValue => name;

  String get label => switch (this) {
        InstitutionType.school => 'School',
        InstitutionType.college => 'College',
        InstitutionType.university => 'University',
      };

  static InstitutionType parse(String value) {
    return InstitutionType.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => InstitutionType.school,
    );
  }
}

enum InstitutionStatus {
  pending,
  approved,
  suspended;

  String get storageValue => name;

  String get label => switch (this) {
        InstitutionStatus.pending => 'Pending approval',
        InstitutionStatus.approved => 'Approved',
        InstitutionStatus.suspended => 'Suspended',
      };

  static InstitutionStatus parse(String value) {
    return InstitutionStatus.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => InstitutionStatus.pending,
    );
  }
}

enum MembershipStatus {
  pending,
  active,
  suspended,
  rejected;

  String get storageValue => name;

  String get label => switch (this) {
        MembershipStatus.pending => 'Pending',
        MembershipStatus.active => 'Active',
        MembershipStatus.suspended => 'Suspended',
        MembershipStatus.rejected => 'Rejected',
      };

  static MembershipStatus parse(String value) {
    return MembershipStatus.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => MembershipStatus.pending,
    );
  }
}

enum AccessRequestStatus {
  pending,
  approved,
  rejected,
  cancelled;

  String get storageValue => name;

  String get label => switch (this) {
        AccessRequestStatus.pending => 'Pending',
        AccessRequestStatus.approved => 'Approved',
        AccessRequestStatus.rejected => 'Rejected',
        AccessRequestStatus.cancelled => 'Cancelled',
      };

  static AccessRequestStatus parse(String value) {
    return AccessRequestStatus.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => AccessRequestStatus.pending,
    );
  }
}
