import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/campaign_target_report.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../../../shared/providers/session_provider.dart';

final teacherReportsProvider =
    FutureProvider<List<CampaignTargetReport>>((ref) async {
  final institution = ref.watch(activeInstitutionProvider);
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (institution == null || userId == null) {
    return const [];
  }

  return ref.watch(teacherAnalyticsRepositoryProvider).fetchReports(
        institutionId: institution.id,
        userId: userId,
      );
});

final teacherAssignmentCountProvider = FutureProvider<int>((ref) async {
  final institution = ref.watch(activeInstitutionProvider);
  final userId = ref.watch(currentSessionProvider)?.user.id;
  if (institution == null || userId == null) {
    return 0;
  }

  return ref.watch(teacherAnalyticsRepositoryProvider).fetchAssignmentCount(
        institutionId: institution.id,
        userId: userId,
      );
});
