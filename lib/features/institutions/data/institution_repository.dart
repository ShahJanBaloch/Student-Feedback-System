import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/institution_enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/institution.dart';
import '../../../shared/models/membership.dart';
import '../../../shared/models/platform_settings.dart';

class InstitutionRepository {
  const InstitutionRepository(this._client);

  final SupabaseClient _client;

  Future<List<Membership>> myMemberships() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }
    try {
      final rows = await _client
          .from('institution_memberships')
          .select('*, institutions(*)')
          .eq('user_id', userId)
          .order('created_at');
      return (rows as List<dynamic>)
          .map((row) => Membership.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<Institution>> listVisibleInstitutions() async {
    try {
      final rows = await _client.from('institutions').select().order('name');
      return (rows as List<dynamic>)
          .map((row) => Institution.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<Institution>> listApprovedInstitutions() async {
    final all = await listVisibleInstitutions();
    return all
        .where((item) => item.status == InstitutionStatus.approved)
        .toList();
  }

  Future<List<Institution>> listCreatedByMe() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }
    try {
      final rows = await _client
          .from('institutions')
          .select()
          .eq('created_by', userId)
          .order('created_at');
      return (rows as List<dynamic>)
          .map((row) => Institution.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<Institution> createPending({
    required String name,
    required String shortCode,
    required InstitutionType type,
    String? district,
    String? city,
    String? contactEmail,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Sign in required.');
    }
    try {
      final row = await _client
          .from('institutions')
          .insert({
            'name': name.trim(),
            'short_code': shortCode.trim().toUpperCase(),
            'institution_type': type.storageValue,
            'status': 'pending',
            'district': _emptyToNull(district),
            'city': _emptyToNull(city),
            'contact_email': _emptyToNull(contactEmail),
            'province': 'Balochistan',
            'created_by': userId,
          })
          .select()
          .single();
      return Institution.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> approve({
    required String institutionId,
    required String adminUserId,
  }) async {
    try {
      await _client.rpc(
        'approve_institution',
        params: {
          'p_institution_id': institutionId,
          'p_admin_user_id': adminUserId,
        },
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> setStatus({
    required String institutionId,
    required InstitutionStatus status,
  }) async {
    try {
      await _client
          .from('institutions')
          .update({'status': status.storageValue}).eq('id', institutionId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<PlatformSettings> fetchSettings() async {
    try {
      final row = await _client
          .from('platform_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) {
        return const PlatformSettings(
          studentSelfRegistration: true,
          institutionSelfOnboarding: true,
          defaultMinResponseThreshold: 5,
          allowConfidentialMode: true,
        );
      }
      return PlatformSettings.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<AuditLogEntry>> recentAuditLogs({int limit = 20}) async {
    try {
      final rows = await _client
          .from('audit_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List<dynamic>)
          .map((row) => AuditLogEntry.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
