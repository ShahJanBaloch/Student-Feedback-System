import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_notification.dart';
import '../../../shared/providers/repositories.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).fetchNotifications();
});
