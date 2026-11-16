import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared/models/campaign.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutionId = ref.watch(activeInstitutionProvider)?.id ?? '';
    final campaigns = ref.watch(openCampaignsProvider(institutionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Give Feedback')),
      body: campaigns.when(
        loading: () => const LoadingState(message: 'Loading open campaigns…'),
        error: (error, stack) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load campaigns',
          message: 'Check the University of Turbat campaign data and Supabase connection.',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No campaigns to show',
              message: 'Open campaigns appear here once VC/Admin starts one.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final campaign = items[index];
              return _CampaignTile(campaign: campaign);
            },
          );
        },
      ),
    );
  }
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(campaign.status.toUpperCase()),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (campaign.description != null && campaign.description!.trim().isNotEmpty)
              Text(campaign.description!),
            const SizedBox(height: 8),
            Text('Open: ${campaign.timeRange}'),
            const SizedBox(height: 4),
            Text('Threshold: ${campaign.minResponseThreshold} responses'),
            const SizedBox(height: 4),
            Text('Mode: ${campaign.feedbackMode}'),
          ],
        ),
      ),
    );
  }
}
