class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const passwordReset = '/reset-password';
  static const configError = '/config';

  static const onboarding = '/onboarding';
  static const studentVerification = '/onboarding/verify';

  static const student = '/student';
  static const studentHome = '/student/home';
  static const studentFeedback = '/student/feedback';
  static const studentHistory = '/student/history';
  static const studentNotifications = '/student/notifications';
  static const studentProfile = '/student/profile';

  static const teacher = '/teacher';
  static const hod = '/hod';
  static const vcAdmin = '/vc-admin';
  static const vcAdminAcademics = '/vc-admin/academics';
  static const vcAdminVerifications = '/vc-admin/verifications';
  static const vcAdminModeration = '/vc-admin/moderation';
  static const vcAdminImprovements = '/vc-admin/improvements';
}
