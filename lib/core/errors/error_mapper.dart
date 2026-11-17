import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'app_exception.dart';

class ErrorMapper {
  const ErrorMapper._();

  static AppException map(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is supabase.AuthException) {
      return AppAuthException(_authMessage(error.message), code: error.code);
    }

    if (error is supabase.PostgrestException) {
      return AppException(
        _postgrestMessage(error),
        code: error.code,
      );
    }

    if (error is supabase.FunctionException) {
      return AppException(
        error.details?.toString() ?? error.reasonPhrase ?? 'Request failed.',
        code: '${error.status}',
      );
    }

    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return const NetworkException(
        'No internet connection. TaleemVoice needs the network to reach Supabase.',
      );
    }

    return AppException(
      'Something went wrong. Check your connection and try again.',
      code: error.runtimeType.toString(),
    );
  }

  static String _authMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login')) {
      return 'Email or password is not correct.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirm your email from the message Supabase sent, then sign in.';
    }
    if (lower.contains('already registered') || lower.contains('already been registered')) {
      return 'This email already has an account. Sign in instead.';
    }
    if (lower.contains('password')) {
      return 'Password does not meet the project rules. Use at least 8 characters.';
    }
    return message;
  }

  static String _postgrestMessage(supabase.PostgrestException error) {
    final code = error.code ?? '';
    final message = error.message;
    if (message.contains('uot_student_registration_options') &&
        message.contains('schema cache')) {
      return 'Student registration is not enabled in Supabase yet. Apply '
          'migration 20261116000015_uot_student_verification.sql, then retry.';
    }
    if (code == '42501' || message.contains('not authorized')) {
      return 'You are not allowed to do this. Permissions are enforced in PostgreSQL.';
    }
    if (code == '28000') {
      return 'Your session expired. Sign in again.';
    }
    if (code == 'P0001' && message.contains('not approved')) {
      return 'That institution is not approved yet.';
    }
    if (code == 'P0002') {
      if (message.contains('roster entry missing')) {
        return 'The older verification workflow is still active in Supabase. '
            'Apply the UOT verification function from migration 15.';
      }
      if (message.contains('pending student enrollment')) {
        return 'The student registration record is incomplete. Submit the '
            'student registration again, then approve it.';
      }
      return 'The record was not found or cannot be processed yet.';
    }
    if (code == '23505') {
      return 'This value is already used. Choose a different code or student number.';
    }
    if (message.contains('current academic session')) {
      return 'VC/Admin must configure a current UOT academic session before student registration.';
    }
    if (message.isNotEmpty) {
      return message;
    }
    return 'The database rejected this request.';
  }
}
