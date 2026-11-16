import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared/models/moderation_comment.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../../../shared/widgets/role_app_bar.dart';
import '../providers/moderation_provider.dart';

class ModerationQueueScreen extends ConsumerWidget {
  const ModerationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutionId = ref.watch(activeInstitutionProvider)?.id ?? '';
    final comments = ref.watch(pendingCommentsProvider(institutionId));
    return Scaffold(
      appBar: const RoleAppBar(title: 'Comment moderation'),
      body: comments.when(
        loading: () => const LoadingState(message: 'Loading pending comments…'),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load comments',
          message: error is AppException
              ? error.message
              : 'Please try again. ${error.toString()}',
          action: TextButton(
            onPressed: () =>
                ref.invalidate(pendingCommentsProvider(institutionId)),
            child: const Text('Try again'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_outlined,
              title: 'Moderation queue is clear',
              message: 'Comments awaiting review will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(pendingCommentsProvider(institutionId).future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _CommentCard(
                comment: items[index],
                onDecision: (decision) => _decide(
                  context,
                  ref,
                  institutionId,
                  items[index],
                  decision,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    String institutionId,
    ModerationComment comment,
    String decision,
  ) async {
    String? reason;
    if (decision != 'published') {
      reason = await showDialog<String>(
        context: context,
        builder: (context) => _ModerationReasonDialog(
          title: decision == 'rejected' ? 'Reject comment' : 'Hide comment',
        ),
      );
      if (reason == null) {
        return;
      }
    }

    try {
      await ref.read(moderationRepositoryProvider).decide(
            commentId: comment.id,
            decision: decision,
            reason: reason,
          );
      ref.invalidate(pendingCommentsProvider(institutionId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              decision == 'published'
                  ? 'Comment published.'
                  : 'Comment ${decision == 'rejected' ? 'rejected' : 'hidden'}.',
            ),
          ),
        );
      }
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.onDecision});

  final ModerationComment comment;
  final ValueChanged<String> onDecision;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.body),
            const SizedBox(height: 8),
            Text(
              'Submitted ${DateFormat.yMMMd().add_jm().format(comment.createdAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => onDecision('published'),
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish'),
                ),
                OutlinedButton(
                  onPressed: () => onDecision('rejected'),
                  child: const Text('Reject'),
                ),
                TextButton(
                  onPressed: () => onDecision('hidden'),
                  child: const Text('Hide'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationReasonDialog extends StatefulWidget {
  const _ModerationReasonDialog({required this.title});

  final String title;

  @override
  State<_ModerationReasonDialog> createState() =>
      _ModerationReasonDialogState();
}

class _ModerationReasonDialogState extends State<_ModerationReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Briefly explain this moderation decision',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
