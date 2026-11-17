import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/campaign.dart';

class CampaignRepository {
  const CampaignRepository(this._client);

  final SupabaseClient _client;

  Future<List<Campaign>> fetchCampaigns(String institutionId) async {
    try {
      final rows = await _client
          .from('feedback_campaigns')
          .select()
          .eq('institution_id', institutionId)
          .order('starts_at', ascending: false);
      return rows.map((row) => Campaign.fromMap(row)).toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> closeCampaign(String campaignId) async {
    try {
      await _client
          .from('feedback_campaigns')
          .update({'status': 'closed'})
          .eq('id', campaignId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> createOpenCampaign({
    required String institutionId,
    required String sessionId,
    required String title,
    String? description,
    required DateTime endsAt,
  }) async {
    try {
      await _client.rpc(
        'create_feedback_campaign',
        params: {
          'p_institution_id': institutionId,
          'p_session_id': sessionId,
          'p_title': title,
          'p_description': description,
          'p_ends_at': endsAt.toUtc().toIso8601String(),
        },
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<CampaignCriterion>> fetchCriteria(String campaignId) async {
    try {
      final rows = await _client
          .from('campaign_criteria')
          .select('id, title, description, display_order')
          .eq('campaign_id', campaignId)
          .order('display_order');
      return rows.map((row) => CampaignCriterion.fromMap(row)).toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<String>> fetchTargets(String campaignId) async {
    try {
      final rows = await _client
          .from('campaign_targets')
          .select('id')
          .eq('campaign_id', campaignId);
      return rows.map((row) => row['id'] as String).toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }

  }

  Future<List<String>> fetchEligibleTargets(String campaignId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }
    try {
      final rows = await _client
          .from('feedback_eligibility')
          .select('campaign_target_id')
          .eq('campaign_id', campaignId)
          .eq('student_user_id', userId)
          .isFilter('used_at', null)
          .isFilter('revoked_at', null);
      return rows.map((row) => row['campaign_target_id'] as String).toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> submitFeedback({
    required String campaignId,
    required String targetId,
    required List<Map<String, dynamic>> ratings,
    String? comment,
  }) async {
    try {
      await _client.rpc(
        'submit_feedback',
        params: {
          'p_campaign_id': campaignId,
          'p_campaign_target_id': targetId,
          'p_ratings': ratings,
          'p_comment': comment,
        },
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<Campaign>> fetchOpenCampaignsForInstitution(String institutionId) async {
    if (institutionId.trim().isEmpty) {
      return const [];
    }

    try {
      final rows = await _client
          .from('feedback_campaigns')
          .select()
          .eq('institution_id', institutionId)
          .eq('status', 'open')
          .order('starts_at', ascending: false);

      return (rows as List<dynamic>)
          .map((row) => Campaign.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

}

class CampaignCriterion {
  const CampaignCriterion({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  factory CampaignCriterion.fromMap(Map<String, dynamic> map) {
    return CampaignCriterion(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
    );
  }
}
