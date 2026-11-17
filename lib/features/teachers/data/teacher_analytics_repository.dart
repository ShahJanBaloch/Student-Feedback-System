import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/campaign_target_report.dart';

class TeacherAnalyticsRepository {
  const TeacherAnalyticsRepository(this._client);

  final SupabaseClient _client;

  Future<int> fetchAssignmentCount({
    required String institutionId,
    required String userId,
  }) async {
    try {
      final teacherRows = await _client
          .from('teacher_profiles')
          .select('id')
          .eq('institution_id', institutionId)
          .eq('user_id', userId)
          .eq('is_active', true);
      final teacherIds = teacherRows.map((row) => row['id'] as String).toList();
      if (teacherIds.isEmpty) {
        return 0;
      }
      final assignments = await _client
          .from('teacher_assignments')
          .select('id')
          .eq('institution_id', institutionId)
          .inFilter('teacher_profile_id', teacherIds);
      return assignments.length;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<CampaignTargetReport>> fetchReports({
    required String institutionId,
    required String userId,
  }) async {
    if (institutionId.trim().isEmpty || userId.trim().isEmpty) {
      return const [];
    }

    try {
      final teacherRows = await _client
          .from('teacher_profiles')
          .select('id')
          .eq('institution_id', institutionId)
          .eq('user_id', userId);
      final teacherIds = (teacherRows as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['id'] as String)
          .toList();
      if (teacherIds.isEmpty) {
        return const [];
      }

      final assignmentRows = await _client
          .from('teacher_assignments')
          .select(
            'id, teacher_profile_id, subjects(name), academic_classes(name, section)',
          )
          .eq('institution_id', institutionId)
          .inFilter('teacher_profile_id', teacherIds);
      if (assignmentRows.isEmpty) {
        return const [];
      }

      final assignments = <String, Map<String, dynamic>>{
        for (final row in assignmentRows)
          row['id'] as String: row,
      };
      final campaignRows = await _client
          .from('feedback_campaigns')
          .select('id, title')
          .eq('institution_id', institutionId)
          .inFilter('status', ['open', 'closed', 'archived']);
      if (campaignRows.isEmpty) {
        return const [];
      }

      final campaigns = <String, String>{
        for (final row in campaignRows)
          row['id'] as String: (row['title'] as String?) ?? 'Feedback campaign',
      };
      final targetRows = await _client
          .from('campaign_targets')
          .select('id, campaign_id, teacher_assignment_id')
          .eq('institution_id', institutionId)
          .inFilter('campaign_id', campaigns.keys.toList())
          .inFilter('teacher_assignment_id', assignments.keys.toList());

      return await Future.wait(
        (targetRows as List<dynamic>).map((row) async {
          final target = row as Map<String, dynamic>;
          final assignment = assignments[target['teacher_assignment_id']];
          if (assignment == null) {
            return null;
          }

          final reportData = await _client.rpc(
            'get_campaign_target_report',
            params: {'p_campaign_target_id': target['id']},
          );
          final subject = assignment['subjects'] as Map<String, dynamic>?;
          final academicClass =
              assignment['academic_classes'] as Map<String, dynamic>?;
          final section = academicClass?['section'] as String?;
          final className = academicClass?['name'] as String? ?? 'Class';
          return CampaignTargetReport.fromMap(
            targetId: target['id'] as String,
            campaignTitle:
                campaigns[target['campaign_id']] ?? 'Feedback campaign',
            subjectName: subject?['name'] as String? ?? 'Subject',
            className: section == null || section.trim().isEmpty
                ? className
                : '$className ($section)',
            map: reportData as Map<String, dynamic>,
          );
        }),
      ).then((reports) => reports.whereType<CampaignTargetReport>().toList());
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
