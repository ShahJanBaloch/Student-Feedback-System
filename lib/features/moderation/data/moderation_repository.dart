import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/moderation_comment.dart';

class ModerationRepository {
  const ModerationRepository(this._client);

  final SupabaseClient _client;

  Future<List<ModerationComment>> fetchPendingComments(
    String institutionId,
  ) async {
    if (institutionId.trim().isEmpty) {
      return const [];
    }

    try {
      final rows = await _client
          .from('feedback_comments')
          .select('id, body, created_at')
          .eq('institution_id', institutionId)
          .eq('moderation_status', 'pending')
          .order('created_at');
      return (rows as List<dynamic>)
          .map(
            (row) => ModerationComment.fromMap(row as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> decide({
    required String commentId,
    required String decision,
    String? reason,
  }) async {
    if (!const {'published', 'rejected', 'hidden'}.contains(decision)) {
      throw const AppException('Choose a valid moderation decision.');
    }

    try {
      await _client.rpc(
        'moderate_feedback_comment',
        params: {
          'p_comment_id': commentId,
          'p_decision': decision,
          'p_reason': reason,
        },
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
