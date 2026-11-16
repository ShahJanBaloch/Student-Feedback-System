import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/improvement_action.dart';

class ImprovementRepository {
  const ImprovementRepository(this._client);

  final SupabaseClient _client;

  Future<List<ImprovementAction>> fetchActions(String institutionId) async {
    if (institutionId.trim().isEmpty) {
      return const [];
    }

    try {
      final rows = await _client
          .from('improvement_actions')
          .select()
          .eq('institution_id', institutionId)
          .order('created_at', ascending: false);
      return (rows as List<dynamic>)
          .map(
            (row) => ImprovementAction.fromMap(row as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> createAction({
    required String institutionId,
    required String title,
    String? description,
  }) async {
    if (title.trim().isEmpty) {
      throw const AppException('Action title is required.');
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('Sign in to create an improvement action.');
    }

    try {
      await _client.from('improvement_actions').insert({
        'institution_id': institutionId,
        'title': title.trim(),
        'description': _emptyToNull(description),
        'created_by': userId,
      });
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> updateStatus({
    required String actionId,
    required String status,
  }) async {
    if (!const {'planned', 'in_progress', 'completed', 'cancelled'}
        .contains(status)) {
      throw const AppException('Choose a valid improvement status.');
    }

    try {
      await _client.rpc(
        'update_improvement_action_status',
        params: {
          'p_action_id': actionId,
          'p_status': status,
        },
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
