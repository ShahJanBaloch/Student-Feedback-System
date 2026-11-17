import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';

class SignUpResult {
  const SignUpResult({required this.needsEmailConfirmation});

  final bool needsEmailConfirmation;
}

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> signIn({
    required String email,
    required String password,
    required AppRole role,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      await signOut();
      throw const AppAuthException(
        'Sign-in did not return an authenticated user.',
      );
    }

    bool hasRole;
    try {
      final memberships = await _client
          .from('institution_memberships')
          .select('institution_id')
          .eq('user_id', userId)
          .eq('role', role.storageValue)
          .eq('status', 'active');
      hasRole = memberships.isNotEmpty;

      if (hasRole && role == AppRole.hod) {
        final assignments = await _client
            .from('hod_department_assignments')
            .select('institution_id')
            .eq('user_id', userId)
            .eq('is_active', true);
        final assignedInstitutionIds = assignments
            .map((assignment) => assignment['institution_id'] as String)
            .toSet();
        hasRole = memberships.any(
          (membership) =>
              assignedInstitutionIds.contains(membership['institution_id']),
        );
      }
    } catch (error) {
      await signOut();
      throw ErrorMapper.map(error);
    }

    final requestedRole = _requestedRoleForUser();
    final pendingRequestedRole = !hasRole &&
        role != AppRole.student &&
        requestedRole == role.storageValue;
    if (!hasRole && !pendingRequestedRole && role != AppRole.student) {
      await signOut();
      throw AppAuthException(
        'This account does not have an active ${role.label} role.',
      );
    }
    // Unverified students must be able to reach roster verification; RLS
    // continues to block feedback access until an active student membership exists.
  }

  String? _requestedRoleForUser() {
    final value = _client.auth.currentUser?.userMetadata?['requested_role'];
    return value is String ? value : null;
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> updatePassword({required String password}) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: password),
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required AppRole requestedRole,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'requested_role': requestedRole.storageValue,
        },
      );
      return SignUpResult(
        needsEmailConfirmation: response.session == null,
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
