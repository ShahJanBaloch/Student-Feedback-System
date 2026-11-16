/// Matches `public.app_role` in Phase 2 SQL.
enum AppRole {
  student,
  teacher,
  hod,
  vcAdmin;

  String get storageValue {
    return switch (this) {
      AppRole.student => 'student',
      AppRole.teacher => 'teacher',
      AppRole.hod => 'hod',
      AppRole.vcAdmin => 'institution_admin',
    };
  }

  String get label {
    return switch (this) {
      AppRole.student => 'Student',
      AppRole.teacher => 'Teacher',
      AppRole.hod => 'HOD',
      AppRole.vcAdmin => 'VC / Admin',
    };
  }

  static AppRole? tryParse(String? value) {
    return switch (value) {
      'student' => AppRole.student,
      'teacher' => AppRole.teacher,
      'hod' => AppRole.hod,
      'institution_admin' => AppRole.vcAdmin,
      _ => null,
    };
  }
}
