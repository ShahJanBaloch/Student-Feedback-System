import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/providers/repositories.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed:
                notifications.valueOrNull?.any((item) => !item.isRead) == true
                    ? () => _markAllRead(context, ref)
                    : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const LoadingState(message: 'Loading notifications…'),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load notifications',
          message: error is AppException
              ? error.message
              : 'Please try again. ${error.toString()}',
          action: TextButton(
            onPressed: () => ref.invalidate(notificationsProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'Inbox is empty',
              message: 'New account and feedback updates will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _NotificationTile(
                notification: items[index],
                onTap: items[index].isRead
                    ? null
                    : () => _markRead(context, ref, items[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    try {
      await ref.read(notificationRepositoryProvider).markRead(notification.id);
      ref.invalidate(notificationsProvider);
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none
              : Icons.notifications_active_outlined,
          color: notification.isRead
              ? theme.disabledColor
              : theme.colorScheme.primary,
        ),
        title: Text(
          notification.title,
          style: notification.isRead
              ? null
              : const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 6),
              Text(
                '${notification.type} · ${DateFormat.yMMMd().add_jm().format(notification.createdAt.toLocal())}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing: notification.isRead
            ? const Icon(Icons.check, size: 18)
            : const Icon(Icons.circle, size: 10),
      ),
    );
  }
}
