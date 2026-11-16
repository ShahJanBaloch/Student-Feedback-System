import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/app_notification.dart';

class NotificationRepository {
  const NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      return (rows as List<dynamic>)
          .map(
            (row) => AppNotification.fromMap(row as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> markRead(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Sign in to update notifications.');
    }

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> markAllRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppAuthException('Sign in to update notifications.');
    }

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
