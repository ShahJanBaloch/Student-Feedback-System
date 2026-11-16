import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/access_request.dart';

class VerificationRepository {
  const VerificationRepository(this._client);

  final SupabaseClient _client;

  Future<String> requestVerification({
    required String departmentId,
    required String programId,
    required String semesterId,
    required String studentNumber,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const AppAuthException('Sign in required.');
    }
    try {
      final result = await _client.rpc(
        'request_uot_student_verification',
        params: {
          'p_department_id': departmentId,
          'p_program_id': programId,
          'p_semester_id': semesterId,
          'p_student_number': studentNumber.trim(),
        },
      );
      return result as String;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<AccessRequest>> myVerificationRequests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }
    try {
      final rows = await _client
          .from('access_requests')
          .select()
          .eq('requester_id', userId)
          .eq('request_type', 'student_verification')
          .order('created_at', ascending: false);
      return (rows as List<dynamic>)
          .map((row) => AccessRequest.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<AccessRequest>> pendingForAdmin() async {
    try {
      final rows = await _client
          .from('access_requests')
          .select()
          .eq('request_type', 'student_verification')
          .eq('status', 'pending')
          .order('created_at');
      return (rows as List<dynamic>)
          .map((row) => AccessRequest.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> decide({
    required String requestId,
    required bool approve,
    String? reason,
  }) async {
    try {
      await _client.rpc(
        'decide_student_verification',
        params: {
          'p_request_id': requestId,
          'p_approve': approve,
          'p_reason': reason,
        },
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
