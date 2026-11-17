import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/constants/app_roles.dart';
import '../../../shared/models/access_request.dart';
import '../../../shared/models/academic_entities.dart';

class VerificationRepository {
  const VerificationRepository(this._client);

  final SupabaseClient _client;

  Future<String> requestRoleAccessForUot({
    required AppRole role,
    String? departmentId,
    String? employeeCode,
    String? designation,
  }) async {
    try {
      final institutions = await _client
          .from('institutions')
          .select('id')
          .eq('short_code', 'UOT')
          .limit(1);
      if (institutions.isEmpty) {
        throw const AppException('University of Turbat is not configured.');
      }
      final payload = <String, dynamic>{
        if (departmentId != null) 'department_id': departmentId,
        if (employeeCode != null) 'employee_code': employeeCode,
        if (designation != null) 'designation': designation,
      };
      return await requestRoleAccess(
        institutionId: institutions.first['id'] as String,
        role: role,
        payload: payload.isEmpty ? null : payload,
      );
    } catch (error) {
      if (error is AppException) {
        rethrow;
      }
      throw ErrorMapper.map(error);
    }
  }

  Future<String> requestRoleAccess({
    required String institutionId,
    required AppRole role,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final result = await _client.rpc(
        'request_role_access',
        params: {
          'p_institution_id': institutionId,
          'p_role': role.storageValue,
          'p_payload': payload,
        },
      );
      return result as String;
    } catch (error) {
      throw ErrorMapper.map(error);
    }

  }

  Future<List<Department>> fetchUotDepartments() async {
    try {
      final institutions = await _client
          .from('institutions')
          .select('id')
          .eq('short_code', 'UOT')
          .limit(1);
      if (institutions.isEmpty) {
        return const [];
      }
      final rows = await _client
          .from('departments')
          .select('id, institution_id, name, code, is_active, created_at')
          .eq('institution_id', institutions.first['id'] as String)
          .eq('is_active', true)
          .order('name');
      return rows.map((row) => Department.fromMap(row)).toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

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
          .inFilter('request_type', ['student_verification', 'role_access'])
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
          .select(
            'id, requester_id, institution_id, request_type, status, payload, '
            'decision_reason, created_at',
          )
          .inFilter('request_type', ['student_verification', 'role_access'])
          .eq('status', 'pending')
          .order('created_at')
          .limit(100)
          .timeout(const Duration(seconds: 15));
      return (rows as List<dynamic>)
          .map((row) => AccessRequest.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> decide({
    required String requestId,
    required String requestType,
    required bool approve,
    String? reason,
  }) async {
    try {
      await _client.rpc(
        requestType == 'role_access'
            ? 'decide_role_access'
            : 'decide_student_verification',
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
