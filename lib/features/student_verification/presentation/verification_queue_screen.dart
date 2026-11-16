import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../../../shared/widgets/role_app_bar.dart';

class VerificationQueueScreen extends ConsumerWidget {
  const VerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingVerificationsProvider);

    return Scaffold(
      appBar: const RoleAppBar(title: 'Student verification queue'),
      body: pending.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: error is AppException ? error.message : 'Could not load queue',
          onRetry: () => ref.invalidate(pendingVerificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No pending requests',
              message:
                  'Students appear here after they submit verification. '
                  'VC/Admin reviews the submitted registration number and academic choices.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      title: item.submittedName.isEmpty
                          ? 'Student ${item.studentNumber}'
                          : item.submittedName,
                      subtitle:
                          '${item.payload['department_name'] ?? 'Department'} · '
                          '${item.payload['program_name'] ?? 'Program'} · '
                          '${item.payload['semester_name'] ?? 'Semester'} · '
                          'No. ${item.studentNumber} · ${item.status.label}',
                      child: Row(
                        children: [
                          FilledButton(
                            onPressed: () => _decide(
                              context,
                              ref,
                              requestId: item.id,
                              approve: true,
                            ),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _decide(
                              context,
                              ref,
                              requestId: item.id,
                              approve: false,
                            ),
                            child: const Text('Reject'),
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
    required bool approve,
  }) async {
    try {
      await ref.read(verificationRepositoryProvider).decide(
            requestId: requestId,
            approve: approve,
            reason: approve ? 'admin_approved' : 'admin_rejected',
          );
      invalidateAccount(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Approved in PostgreSQL.' : 'Rejected.'),
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
