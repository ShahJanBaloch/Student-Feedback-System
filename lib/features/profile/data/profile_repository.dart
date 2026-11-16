import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/profile.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> fetchCurrent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Sign in required.');
    }
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        throw const AppException(
          'Your profile row is missing. The Auth trigger may not have run. '
          'Apply Phase 2 SQL, then register a new user.',
        );
      }
      return Profile.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<Profile> updateFullName(String fullName) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Sign in required.');
    }
    try {
      final row = await _client
          .from('profiles')
          .update({'full_name': fullName.trim()})
          .eq('id', userId)
          .select()
          .single();
      return Profile.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
