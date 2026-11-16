import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/constants/institution_enums.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/providers/account_provider.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final institution = ref.watch(activeInstitutionProvider);
    final memberships = ref.watch(activeMembershipsProvider);
    final requests = ref.watch(myVerificationRequestsProvider).valueOrNull ?? [];
    final verified = memberships.any((item) => item.role == AppRole.student);
    final latestRequest = requests.isEmpty ? null : requests.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: profile?.fullName.isNotEmpty == true
                ? profile!.fullName
                : AppConstants.appName,
            subtitle: AppConstants.tagline,
            child: Text(
              institution == null
                  ? 'No active institution membership yet.'
                  : '${institution.name} · ${institution.institutionType.label}',
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Verification',
            subtitle: verified
                ? 'Active student membership'
                : latestRequest?.status.label ?? 'Not verified',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified
                      ? 'You may see eligible campaigns once an admin opens one (Phase 6).'
                      : latestRequest?.status == AccessRequestStatus.pending
                          ? 'Your request is waiting. Auto-approve needs a roster match with a session.'
                          : 'Complete University of Turbat student verification before giving feedback.',
                ),
                if (!verified) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Verify now',
                    onPressed: () => context.go(AppRoutes.studentVerification),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Open campaigns',
            child: Text(
              'Campaigns, eligibility, and questionnaires are Phase 6. This '
              'home screen only shows who you are and whether PostgreSQL has '
              'marked you as a verified student.',
            ),
          ),
        ],
      ),
    );
  }
}
