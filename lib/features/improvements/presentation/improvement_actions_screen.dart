import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared/models/improvement_action.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../../../shared/widgets/role_app_bar.dart';
import '../providers/improvement_provider.dart';

class ImprovementActionsScreen extends ConsumerWidget {
  const ImprovementActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutionId = ref.watch(activeInstitutionProvider)?.id ?? '';
    final actions = ref.watch(improvementActionsProvider(institutionId));
    return Scaffold(
      appBar: const RoleAppBar(title: 'Improvement actions'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: institutionId.isEmpty
            ? null
            : () => _createAction(context, ref, institutionId),
        icon: const Icon(Icons.add),
        label: const Text('Add action'),
      ),
      body: actions.when(
        loading: () =>
            const LoadingState(message: 'Loading improvement actions…'),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load actions',
          message: error is AppException
              ? error.message
              : 'Please try again. ${error.toString()}',
          action: TextButton(
            onPressed: () =>
                ref.invalidate(improvementActionsProvider(institutionId)),
            child: const Text('Try again'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.task_alt,
              title: 'No improvement actions yet',
              message:
                  'Create a concrete follow-up action from campaign feedback.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(improvementActionsProvider(institutionId).future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ActionCard(
                action: items[index],
                onStatusChanged: (status) => _updateStatus(
                  context,
                  ref,
                  institutionId,
                  items[index],
                  status,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createAction(
    BuildContext context,
    WidgetRef ref,
    String institutionId,
  ) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New improvement action'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Action title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != true) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    try {
      await ref.read(improvementRepositoryProvider).createAction(
            institutionId: institutionId,
            title: titleController.text,
            description: descriptionController.text,
          );
      ref.invalidate(improvementActionsProvider(institutionId));
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String institutionId,
    ImprovementAction action,
    String status,
  ) async {
    try {
      await ref.read(improvementRepositoryProvider).updateStatus(
            actionId: action.id,
            status: status,
          );
      ref.invalidate(improvementActionsProvider(institutionId));
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onStatusChanged});

  final ImprovementAction action;
  final ValueChanged<String> onStatusChanged;

  static const _statuses = {
    'planned': 'Planned',
    'in_progress': 'In progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(action.title, style: Theme.of(context).textTheme.titleMedium),
            if (action.description != null &&
                action.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(action.description!),
            ],
            const SizedBox(height: 8),
            Text(
              'Created ${DateFormat.yMMMd().format(action.createdAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: action.status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: _statuses.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status != null && status != action.status) {
                  onStatusChanged(status);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
