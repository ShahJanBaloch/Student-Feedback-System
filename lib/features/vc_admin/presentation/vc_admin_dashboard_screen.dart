import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/widgets/role_app_bar.dart';

class VcAdminDashboardScreen extends ConsumerWidget {
  const VcAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingVerificationsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: const RoleAppBar(title: 'VC / Admin'),
      body: ListView(
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
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                  size: 30,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'University administration',
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
          const SectionCard(
            title: 'University of Turbat',
            subtitle: 'VC / Admin access · University of Turbat',
            child: Text(
              'Manage UOT academic structure, student verification, reports, '
              'and improvement actions.',
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Access requests',
            subtitle: '${pending.length} pending request(s) visible to you',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review student verification and staff-role requests. '
                  'Approved roles are activated automatically.',
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open verification queue',
                  onPressed: () =>
                      context.go(AppRoutes.vcAdminVerifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Academic structure',
            subtitle: 'Phase 5',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage UOT departments, programs, semesters, courses, and academic sessions.',
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open academic admin',
                  onPressed: () =>
                      context.go(AppRoutes.vcAdminAcademics),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Comment moderation',
            subtitle: 'Phase 8',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review anonymous comments before publication. Moderation decisions are recorded in the database.',
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open moderation queue',
                  onPressed: () =>
                      context.go(AppRoutes.vcAdminModeration),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Improvement actions',
            subtitle: 'Phase 8',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Turn departmental feedback into trackable university actions.',
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Manage improvement actions',
                  onPressed: () =>
                      context.go(AppRoutes.vcAdminImprovements),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
