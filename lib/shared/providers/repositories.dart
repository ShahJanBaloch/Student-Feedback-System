import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/academics/data/academic_repository.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/institutions/data/institution_repository.dart';
import '../../features/improvements/data/improvement_repository.dart';
import '../../features/moderation/data/moderation_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/teachers/data/teacher_analytics_repository.dart';
import '../../features/feedback_campaigns/data/campaign_repository.dart';
import '../../features/student_verification/data/verification_repository.dart';
import '../models/academic_entities.dart';
import '../models/campaign.dart';
import '../models/student_registration_option.dart';
import 'supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final institutionRepositoryProvider = Provider<InstitutionRepository>((ref) {
  return InstitutionRepository(ref.watch(supabaseClientProvider));
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository(ref.watch(supabaseClientProvider));
});


final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepository(ref.watch(supabaseClientProvider));
});

final teacherAnalyticsRepositoryProvider =
    Provider<TeacherAnalyticsRepository>((ref) {
  return TeacherAnalyticsRepository(ref.watch(supabaseClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(ref.watch(supabaseClientProvider));
});

final improvementRepositoryProvider = Provider<ImprovementRepository>((ref) {
  return ImprovementRepository(ref.watch(supabaseClientProvider));
});

final openCampaignsProvider = FutureProvider.family<List<Campaign>, String>(
  (ref, institutionId) async {
    if (institutionId.trim().isEmpty) {
      return const [];
    }
    return ref
        .watch(campaignRepositoryProvider)
        .fetchOpenCampaignsForInstitution(institutionId);
  },
);

final institutionCampaignsProvider =
    FutureProvider.family<List<Campaign>, String>((ref, institutionId) async {
  if (institutionId.trim().isEmpty) {
    return const [];
  }
  return ref.watch(campaignRepositoryProvider).fetchCampaigns(institutionId);
});

final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  return CampaignRepository(ref.watch(supabaseClientProvider));
});

final academicOverviewProvider =
    FutureProvider.family<AcademicOverview, String>(
  (ref, institutionId) async {
    if (institutionId.trim().isEmpty) {
      return const AcademicOverview(
        departments: [],
        sessions: [],
        programs: [],
        semesters: [],
        classes: [],
        subjects: [],
        teacherProfiles: [],
        teacherAssignments: [],
        rosterEntries: [],
      );
    }
    return ref.watch(academicRepositoryProvider).fetchOverview(institutionId);
  },
);

final uotStudentRegistrationOptionsProvider =
    FutureProvider<List<StudentRegistrationOption>>((ref) async {
  return ref
      .watch(academicRepositoryProvider)
      .fetchUotStudentRegistrationOptions();
});

final uotDepartmentsProvider = FutureProvider<List<Department>>((ref) async {
  return ref.watch(verificationRepositoryProvider).fetchUotDepartments();
});
