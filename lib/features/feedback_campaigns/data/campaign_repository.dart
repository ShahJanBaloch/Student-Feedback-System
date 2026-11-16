import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/campaign.dart';

class CampaignRepository {
  const CampaignRepository(this._client);

  final SupabaseClient _client;

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
