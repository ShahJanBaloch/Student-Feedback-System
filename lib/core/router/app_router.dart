import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/constants/app_roles.dart';
import '../../features/academics/presentation/academic_admin_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/password_reset_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/feedback_campaigns/presentation/campaigns_screen.dart';
import '../../features/feedback_history/presentation/feedback_history_screen.dart';
import '../../features/vc_admin/presentation/vc_admin_dashboard_screen.dart';
import '../../features/institutions/presentation/onboarding_screen.dart';
import '../../features/improvements/presentation/improvement_actions_screen.dart';
import '../../features/moderation/presentation/moderation_queue_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/hod/presentation/hod_dashboard_screen.dart';
import '../../features/splash/presentation/config_error_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/student_home/presentation/student_home_screen.dart';
import '../../features/student_verification/presentation/student_verification_screen.dart';
import '../../features/student_verification/presentation/verification_queue_screen.dart';
import '../../features/teachers/presentation/teacher_dashboard_screen.dart';
import '../../shared/providers/account_provider.dart';
import '../../shared/providers/session_provider.dart';
import '../../shared/widgets/student_shell.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  void scheduleRefresh() {
    Future<void>.microtask(() => refresh.value++);
  }

  ref.listen(currentSessionProvider, (_, __) => scheduleRefresh());
  ref.listen(resolvedRoleProvider, (_, __) => scheduleRefresh());
  ref.listen(membershipsProvider, (_, __) => scheduleRefresh());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Env.isConfigured ? AppRoutes.splash : AppRoutes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (!Env.isConfigured && path != AppRoutes.configError) {
        // Keep auth screens reachable until Supabase configuration is provided.
        if (path == AppRoutes.login ||
            path == AppRoutes.register ||
            path == AppRoutes.passwordReset) {
          return null;
        }
        if (path == AppRoutes.splash) {
          return AppRoutes.login;
        }
      }

      final session = ref.read(currentSessionProvider);
      final signedIn = session != null;
      final role = ref.read(resolvedRoleProvider);
      final accountReady = ref.read(accountReadyProvider);
      final hasMembership = ref.read(hasActiveMembershipProvider);

      final isSplash = path == AppRoutes.splash;
      final isAuthRoute = path == AppRoutes.login || path == AppRoutes.register;
      final isPasswordReset = path == AppRoutes.passwordReset;
      final isOnboardingPath = path.startsWith(AppRoutes.onboarding);

      if (!signedIn) {
        if (isSplash) {
          return AppRoutes.login;
        }
        if (isAuthRoute || isPasswordReset || path == AppRoutes.configError) {
          return null;
        }
        return AppRoutes.login;
      }

      if (!accountReady && !isPasswordReset) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (isSplash || isAuthRoute) {
        if (!hasMembership) {
          return AppRoutes.onboarding;
        }
        return _homeForRole(role);
      }

      if (!hasMembership &&
          !isOnboardingPath &&
          !isPasswordReset &&
          path != AppRoutes.studentProfile) {
        return AppRoutes.onboarding;
      }

      if (_isStudentPath(path) && role != AppRole.student && hasMembership) {
        return _homeForRole(role);
      }
      if (path == AppRoutes.teacher && role != AppRole.teacher) {
        return _homeForRole(role);
      }
      if (path == AppRoutes.hod && role != AppRole.hod) {
        return _homeForRole(role);
      }
      if (path.startsWith(AppRoutes.vcAdmin) && role != AppRole.vcAdmin) {
        return _homeForRole(role);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.configError,
        builder: (context, state) => const ConfigErrorScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordReset,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentVerification,
        builder: (context, state) => const StudentVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.teacher,
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.hod,
        builder: (context, state) => const HodDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.vcAdmin,
        builder: (context, state) => const VcAdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.vcAdminAcademics,
        builder: (context, state) => const AcademicAdminScreen(),
      ),
      GoRoute(
        path: AppRoutes.vcAdminVerifications,
        builder: (context, state) => const VerificationQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.vcAdminModeration,
        builder: (context, state) => const ModerationQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.vcAdminImprovements,
        builder: (context, state) => const ImprovementActionsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentHome,
                builder: (context, state) => const StudentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentFeedback,
                builder: (context, state) => const CampaignsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentHistory,
                builder: (context, state) => const FeedbackHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentNotifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentProfile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

String _homeForRole(AppRole role) {
  return switch (role) {
    AppRole.student => AppRoutes.studentHome,
    AppRole.teacher => AppRoutes.teacher,
    AppRole.hod => AppRoutes.hod,
    AppRole.vcAdmin => AppRoutes.vcAdmin,
  };
}

bool _isStudentPath(String path) => path.startsWith('/student');
