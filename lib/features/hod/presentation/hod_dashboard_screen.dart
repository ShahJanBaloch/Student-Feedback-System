import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../../shared/widgets/role_app_bar.dart';

final hodDepartmentSummaryProvider =
    FutureProvider.autoDispose<HodDepartmentSummary>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    throw const AppException('Please sign in again to view this dashboard.');
  }

  final assignments = await client
      .from('hod_department_assignments')
      .select('department_id, institution_id')
      .eq('user_id', userId)
      .eq('is_active', true);
  if (assignments.isEmpty) {
    throw const AppException(
      'No active department is assigned to this HOD account.',
    );
  }

  final assignment = assignments.first;
  final departmentId = assignment['department_id'] as String;
  final departmentRows = await client
      .from('departments')
      .select('name, code')
      .eq('id', departmentId)
      .eq('institution_id', assignment['institution_id'] as String)
      .eq('is_active', true)
      .limit(1);
  if (departmentRows.isEmpty) {
    throw const AppException(
      'The assigned department could not be found or is inactive.',
    );
  }
  final department = departmentRows.first;

  final programs = await client
      .from('academic_programs')
      .select('id')
      .eq('department_id', departmentId)
      .eq('is_active', true);
  final subjects = await client
      .from('subjects')
      .select('id')
      .eq('department_id', departmentId)
      .eq('is_active', true);
  final subjectIds = subjects.map((row) => row['id'] as String).toList();
  final teacherAssignments = subjectIds.isEmpty
      ? const <dynamic>[]
      : await client
          .from('teacher_assignments')
          .select('teacher_profile_id')
          .eq('institution_id', assignment['institution_id'] as String)
          .inFilter('subject_id', subjectIds);
  final teacherIds = teacherAssignments
      .map((row) => row['teacher_profile_id'] as String)
      .toSet();
  final programIds = programs.map((row) => row['id'] as String);
  final classes = programIds.isEmpty
      ? const <dynamic>[]
      : await client
          .from('academic_classes')
          .select('id')
          .inFilter('program_id', programIds.toList());
  final campaigns = await client
      .from('feedback_campaigns')
      .select('id')
      .eq('institution_id', assignment['institution_id'] as String)
      .inFilter('status', ['open', 'closed', 'archived']);

  return HodDepartmentSummary(
    name: department['name'] as String? ?? 'Assigned department',
    code: department['code'] as String?,
    programCount: programs.length,
    subjectCount: subjects.length,
    classCount: classes.length,
    teacherCount: teacherIds.length,
    campaignCount: campaigns.length,
  );
});

class HodDepartmentSummary {
  const HodDepartmentSummary({
    required this.name,
    required this.code,
    required this.programCount,
    required this.subjectCount,
    required this.classCount,
    required this.teacherCount,
    required this.campaignCount,
  });

  final String name;
  final String? code;
  final int programCount;
  final int subjectCount;
  final int classCount;
  final int teacherCount;
  final int campaignCount;
}

class HodDashboardScreen extends ConsumerWidget {
  const HodDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(hodDepartmentSummaryProvider);
    return Scaffold(
      appBar: const RoleAppBar(title: 'HOD'),
      body: summary.when(
        loading: () => const LoadingState(
          message: 'Loading department dashboard…',
        ),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load department',
          message: error is AppException
              ? error.message
              : 'Please try again. ${error.toString()}',
          action: TextButton(
            onPressed: () => ref.invalidate(hodDepartmentSummaryProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(hodDepartmentSummaryProvider.future),
          child: ListView(
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
                      Icons.account_tree_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Department overview',
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
                title: data.name,
                subtitle: data.code == null
                    ? 'Assigned department'
                    : 'Department code: ${data.code}',
                child: const Text(
                  'This dashboard is limited to your assigned department.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CountCard(
                      label: 'Programs',
                      count: data.programCount,
                      icon: Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountCard(
                      label: 'Subjects',
                      count: data.subjectCount,
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountCard(
                      label: 'Classes',
                      count: data.classCount,
                      icon: Icons.groups_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CountCard(
                      label: 'Teachers',
                      count: data.teacherCount,
                      icon: Icons.co_present_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountCard(
                      label: 'Campaigns',
                      count: data.campaignCount,
                      icon: Icons.poll_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Feedback review',
                subtitle: data.campaignCount == 0
                    ? 'No campaigns are available yet'
                    : '${data.campaignCount} campaign(s) available',
                child: const Text(
                  'Department feedback analytics are protected by '
                  'anonymous response thresholds.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '$count',
      subtitle: label,
      child: Icon(icon),
    );
  }
}
