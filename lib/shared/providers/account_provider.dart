import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_roles.dart';
import '../models/access_request.dart';
import '../models/institution.dart';
import '../models/membership.dart';
import '../models/platform_settings.dart';
import '../models/profile.dart';
import 'active_role_provider.dart';
import 'repositories.dart';
import 'session_provider.dart';

final profileProvider = FutureProvider<Profile?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return null;
  }
  return ref.watch(profileRepositoryProvider).fetchCurrent();
});

final membershipsProvider = FutureProvider<List<Membership>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const [];
  }
  return ref.watch(institutionRepositoryProvider).myMemberships();
});

final platformSettingsProvider = FutureProvider<PlatformSettings?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return null;
  }
  return ref.watch(institutionRepositoryProvider).fetchSettings();
});

final myVerificationRequestsProvider =
    FutureProvider<List<AccessRequest>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const [];
  }
  return ref.watch(verificationRepositoryProvider).myVerificationRequests();
});

final pendingVerificationsProvider =
    FutureProvider<List<AccessRequest>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const [];
  }
  return ref.watch(verificationRepositoryProvider).pendingForAdmin();
});

final auditLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return const [];
  }
  return ref.watch(institutionRepositoryProvider).recentAuditLogs();
});

final activeMembershipsProvider = Provider<List<Membership>>((ref) {
  final memberships = ref.watch(membershipsProvider).valueOrNull ?? const [];
  return memberships.where((item) => item.isActive).toList();
});

final availableRolesProvider = Provider<List<AppRole>>((ref) {
  final roles = ref
      .watch(activeMembershipsProvider)
      .map((item) => item.role)
      .whereType<AppRole>()
      .toSet()
      .toList();
  roles.sort((a, b) => a.index.compareTo(b.index));
  return roles;
});

final resolvedRoleProvider = Provider<AppRole>((ref) {
  final selected = ref.watch(activeRoleProvider);
  final roles = ref.watch(availableRolesProvider);
  if (roles.contains(selected)) {
    return selected;
  }
  if (roles.contains(AppRole.vcAdmin)) {
    return AppRole.vcAdmin;
  }
  if (roles.contains(AppRole.hod)) {
    return AppRole.hod;
  }
  if (roles.contains(AppRole.teacher)) {
    return AppRole.teacher;
  }
  if (roles.contains(AppRole.student)) {
    return AppRole.student;
  }
  return AppRole.student;
});

final activeInstitutionProvider = Provider<Institution?>((ref) {
  final role = ref.watch(resolvedRoleProvider);
  final memberships = ref.watch(activeMembershipsProvider);
  for (final membership in memberships) {
    if (membership.role == role && membership.institution != null) {
      return membership.institution;
    }
  }
  return memberships
      .map((item) => item.institution)
      .whereType<Institution>()
      .cast<Institution?>()
      .firstWhere((item) => item != null, orElse: () => null);
});

void invalidateAccount(WidgetRef ref) {
  Future<void>.microtask(() {
    ref.invalidate(profileProvider);
    ref.invalidate(membershipsProvider);
    ref.invalidate(platformSettingsProvider);
    ref.invalidate(myVerificationRequestsProvider);
    ref.invalidate(pendingVerificationsProvider);
    ref.invalidate(auditLogsProvider);
  });
}

final hasActiveMembershipProvider = Provider<bool>((ref) {
  return ref.watch(activeMembershipsProvider).isNotEmpty;
});

final accountReadyProvider = Provider<bool>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) {
    return true;
  }
  return !ref.watch(membershipsProvider).isLoading;
});
