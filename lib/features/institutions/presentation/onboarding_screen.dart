import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../../../shared/providers/supabase_provider.dart';

String _roleLabel(String role) {
  return switch (role) {
    'teacher' => 'Teacher',
    'hod' => 'HOD',
    'institution_admin' => 'VC / Admin',
    _ => 'Staff',
  };
}

final hodDepartmentSelectionProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final requests = ref.watch(myVerificationRequestsProvider);
    final memberships = ref.watch(membershipsProvider);
    final departments = ref.watch(uotDepartmentsProvider);
    final selectedDepartmentId =
        ref.watch(hodDepartmentSelectionProvider);
    final requestedRole = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.userMetadata?['requested_role'] as String?;
    final hasActiveStudentMembership = memberships.valueOrNull?.any(
          (membership) =>
              membership.isActive && membership.role == AppRole.student,
        ) ??
        false;
    final staffRequestedRole = hasActiveStudentMembership ||
            requestedRole == null ||
            requestedRole == 'student'
        ? null
        : requestedRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get started'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              invalidateAccount(ref);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const LoadingState(message: 'Loading your profile…'),
        error: (error, _) => ErrorState(
          message: error is AppException
              ? error.message
              : 'Could not load your profile. Apply Phase 2 SQL if this is a new database.',
          onRetry: () => invalidateAccount(ref),
        ),
        data: (user) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Set up your TaleemVoice access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: user?.fullName.isNotEmpty == true
                    ? 'Hello, ${user!.fullName}'
                    : 'Welcome to TaleemVoice',
                subtitle: user?.email,
                child: const Text(
                  'Student access is enabled after University of Turbat '
                  'verification. Teacher, HOD, and VC/Admin accounts are '
                  'created by an authorized administrator.',
                ),
              ),
              const SizedBox(height: 12),
              if (staffRequestedRole != null)
                SectionCard(
                  title: 'Account type request',
                  subtitle: _roleLabel(staffRequestedRole),
                  child: Text(
                    'Your ${_roleLabel(staffRequestedRole)} account type requires '
                    'approval by an existing VC/Admin. The request status '
                    'will appear below.',
                  ),
                ),
              if (staffRequestedRole != null)
                const SizedBox(height: 12),
              if (staffRequestedRole != null)
                SectionCard(
                  title: 'Complete staff details',
                  subtitle: 'Approval is handled inside the app',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (staffRequestedRole == 'hod')
                        departments.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (error, _) => Text(
                            'Departments unavailable: $error',
                          ),
                          data: (items) => DropdownMenu<String>(
                            label: const Text('HOD department'),
                            expandedInsets: EdgeInsets.zero,
                            initialSelection: selectedDepartmentId,
                            dropdownMenuEntries: items
                                .map(
                                  (department) => DropdownMenuEntry(
                                    value: department.id,
                                    label: department.name,
                                  ),
                                )
                                .toList(),
                            onSelected: (value) => ref
                                .read(
                                  hodDepartmentSelectionProvider.notifier,
                                )
                                .state = value,
                          ),
                        ),
                      if (staffRequestedRole == 'hod')
                        const SizedBox(height: 12),
                      if (staffRequestedRole == 'teacher')
                        AppButton(
                          label: 'Request Teacher access',
                          onPressed: () => _requestTeacher(context, ref),
                        ),
                      if (requestedRole == 'hod')
                        AppButton(
                          label: 'Request HOD access',
                          onPressed: selectedDepartmentId != null
                              ? () => _requestRole(
                                  context,
                                  ref,
                                  AppRole.hod,
                                  departmentId: selectedDepartmentId,
                                )
                              : null,
                        ),
                      if (staffRequestedRole == 'institution_admin')
                        AppButton(
                          label: 'Request VC / Admin access',
                          onPressed: () => _requestRole(
                            context,
                            ref,
                            AppRole.vcAdmin,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'I am a student',
                subtitle: 'Complete University of Turbat registration',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provide your department, degree program, current '
                      'semester, and University of Turbat registration number. '
                      'Your account remains pending until verified.',
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Complete student registration',
                      onPressed: () =>
                          context.go(AppRoutes.studentVerification),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              requests.when(
                data: (items) {
                  final visibleItems = staffRequestedRole == null
                      ? items
                          .where((item) => item.requestType != 'role_access')
                          .toList()
                      : items;
                  if (visibleItems.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SectionCard(
                    title: 'Verification requests',
                    child: Column(
                      children: visibleItems
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.requestType == 'role_access'
                                    ? '${item.requestedRoleLabel} access request'
                                    : item.studentNumber.isEmpty
                                        ? item.requestType
                                        : 'Student no. ${item.studentNumber}',
                              ),
                              subtitle: Text(
                                item.decisionReason?.isNotEmpty == true
                                    ? '${item.status.label} · '
                                        '${item.decisionReason}'
                                    : item.status.label,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, _) => Text('$error'),
              ),
              memberships.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SectionCard(
                    title: 'Memberships',
                    child: Column(
                      children: items
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.role?.label ?? 'Legacy role'),
                              subtitle: Text(
                                '${item.institution?.name ?? 'Platform'} · ${item.status.label}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _requestRole(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
    {
    String? departmentId,
    String? employeeCode,
    String? designation,
  }
  ) {
    ref
        .read(verificationRepositoryProvider)
        .requestRoleAccessForUot(
          role: role,
          departmentId: departmentId,
          employeeCode: employeeCode,
          designation: designation,
        )
        .then((_) {
      invalidateAccount(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${role.label} request submitted.')),
        );
      }
    }).catchError((Object error) {
      if (context.mounted) {
        final message = error is AppException
            ? error.message
            : 'Could not submit the role request.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  Future<void> _requestTeacher(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final employeeCode = TextEditingController();
    final designation = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Teacher access request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: employeeCode,
              decoration: const InputDecoration(
                labelText: 'Employee code (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: designation,
              decoration: const InputDecoration(
                labelText: 'Designation (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              (employeeCode.text.trim(), designation.text.trim()),
            ),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );
    employeeCode.dispose();
    designation.dispose();
    if (result == null || !context.mounted) {
      return;
    }
    _requestRole(
      context,
      ref,
      AppRole.teacher,
      employeeCode: result.$1,
      designation: result.$2,
    );
  }
}
