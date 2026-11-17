import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../../../shared/widgets/role_app_bar.dart';

class VerificationQueueScreen extends ConsumerWidget {
  const VerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingVerificationsProvider);

    return Scaffold(
      appBar: const RoleAppBar(title: 'Access requests'),
      body: pending.when(
        loading: () => const LoadingState(
          message: 'Loading pending student requests…',
        ),
        error: (error, _) => ErrorState(
          message: error is AppException
              ? error.message
              : 'Could not load the verification queue. Check your admin '
                  'membership and Supabase RLS policies.',
          onRetry: () => ref.invalidate(pendingVerificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No pending requests',
              message:
                  'Student verification and staff-role requests will appear '
                  'here for review.',
            );
          }
          return ListView(
              padding: const EdgeInsets.all(16),
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.requestType == 'role_access'
                                  ? '${item.requestedRoleLabel} access request'
                                  : item.submittedName.isEmpty
                                      ? 'Student ${item.studentNumber}'
                                      : item.submittedName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                item.requestType == 'role_access'
                                    ? 'Staff access'
                                    : 'Student verification',
                              ),
                              avatar: Icon(
                                item.requestType == 'role_access'
                                    ? Icons.badge_outlined
                                    : Icons.school_outlined,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (item.requestType == 'role_access')
                              Text(
                                'Requested role: ${item.requestedRoleLabel}',
                              )
                            else ...[
                              Text(
                                '${item.payload['department_name'] ?? 'Department'} · '
                                '${item.payload['program_name'] ?? 'Program'} · '
                                '${item.payload['semester_name'] ?? 'Semester'}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Registration no. ${item.studentNumber} · '
                                '${item.status.label}',
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton(
                                  onPressed: () => _decide(
                                    context,
                                    ref,
                                    requestId: item.id,
                                      requestType: item.requestType,
                                    approve: true,
                                  ),
                                  child: const Text('Approve'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _decide(
                                    context,
                                    ref,
                                    requestId: item.id,
                                      requestType: item.requestType,
                                    approve: false,
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
          );
        },
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref, {
    required String requestId,
    required String requestType,
    required bool approve,
  }) async {
    String? reason;
    if (!approve) {
      reason = await _rejectionReason(context);
      if (reason == null) {
        return;
      }
    }
    try {
      await ref.read(verificationRepositoryProvider).decide(
            requestId: requestId,
            requestType: requestType,
            approve: approve,
            reason: approve ? 'Approved by VC/Admin.' : reason,
          );
      invalidateAccount(ref);
      ref.invalidate(pendingVerificationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Request approved.' : 'Request rejected.'),
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

  Future<String?> _rejectionReason(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Explain what the requester should correct.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return reason;
  }
}
