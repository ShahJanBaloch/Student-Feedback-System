import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
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
            title: 'Student verification',
            subtitle: '${pending.length} pending request(s) visible to you',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review student registration details and verify eligibility. '
                  'Anonymous feedback does not reveal student identities.',
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
