import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final requests = ref.watch(myVerificationRequestsProvider);
    final memberships = ref.watch(membershipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get started'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              invalidateAccount(ref);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const LoadingState(message: 'Loading your profile…'),
        error: (error, _) => ErrorState(
          message: error is AppException
              ? error.message
              : 'Could not load your profile. Apply Phase 2 SQL if this is a new database.',
          onRetry: () => invalidateAccount(ref),
        ),
        data: (user) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: user?.fullName.isNotEmpty == true
                    ? 'Hello, ${user!.fullName}'
                    : 'Welcome to TaleemVoice',
                subtitle: user?.email,
                child: const Text(
                  'Student access is enabled after University of Turbat '
                  'verification. Teacher, HOD, and VC/Admin accounts are '
                  'created by an authorized administrator.',
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'I am a student',
                subtitle: 'Complete University of Turbat registration',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provide your department, degree program, current '
                      'semester, and University of Turbat registration number. '
                      'Your account remains pending until verified.',
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Complete student registration',
                      onPressed: () =>
                          context.go(AppRoutes.studentVerification),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              requests.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SectionCard(
                    title: 'Verification requests',
                    child: Column(
                      children: items
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.studentNumber.isEmpty
                                    ? item.requestType
                                    : 'Student no. ${item.studentNumber}',
                              ),
                              subtitle: Text(item.status.label),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, _) => Text('$error'),
              ),
              memberships.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SectionCard(
                    title: 'Memberships',
                    child: Column(
                      children: items
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.role?.label ?? 'Legacy role'),
                              subtitle: Text(
                                '${item.institution?.name ?? 'Platform'} · ${item.status.label}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}
