import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared/models/campaign.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../data/campaign_repository.dart';

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
          message:
              'Check the University of Turbat campaign data and Supabase connection.',
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
              return _CampaignTile(
                campaign: campaign,
                onStart: () => _startCampaign(context, ref, campaign),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startCampaign(
    BuildContext context,
    WidgetRef ref,
    Campaign campaign,
  ) async {
    try {
      final repository = ref.read(campaignRepositoryProvider);
      final criteria = await repository.fetchCriteria(campaign.id);
      final targets = await repository.fetchEligibleTargets(campaign.id);
      if (!context.mounted) {
        return;
      }
      if (criteria.isEmpty || targets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              criteria.isEmpty
                  ? 'This campaign has no questions configured yet.'
                  : 'You are not currently eligible for this campaign.',
            ),
          ),
        );
        return;
      }
      final targetId = targets.length == 1
          ? targets.first
          : await showDialog<String>(
              context: context,
              builder: (_) => _TargetPicker(targets: targets),
            );
      if (!context.mounted || targetId == null) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _FeedbackDialog(
          campaign: campaign,
          criteria: criteria,
          targetId: targetId,
          repository: repository,
        ),
      );
    } on AppException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _TargetPicker extends StatelessWidget {
  const _TargetPicker({required this.targets});

  final List<String> targets;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose feedback target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This campaign includes more than one eligible class or teacher. '
            'Choose which one you want to review.',
          ),
          const SizedBox(height: 12),
          ...List.generate(
            targets.length,
            (index) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text('${index + 1}'),
              ),
              title: Text('Eligible target ${index + 1}'),
              subtitle: Text(
                'Target reference ${targets[index].substring(0, 8)}',
              ),
              onTap: () => Navigator.pop(context, targets[index]),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({
    required this.campaign,
    required this.onStart,
  });

  final Campaign campaign;
  final VoidCallback onStart;

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
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (campaign.description != null &&
                campaign.description!.trim().isNotEmpty)
              Text(campaign.description!),
            const SizedBox(height: 8),
            Text('Open: ${campaign.timeRange}'),
            const SizedBox(height: 4),
            Text('Threshold: ${campaign.minResponseThreshold} responses'),
            const SizedBox(height: 4),
            Text('Mode: ${campaign.feedbackMode}'),
            const SizedBox(height: 16),
            AppButton(
              label: 'Start feedback',
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({
    required this.campaign,
    required this.criteria,
    required this.targetId,
    required this.repository,
  });

  final Campaign campaign;
  final List<CampaignCriterion> criteria;
  final String targetId;
  final CampaignRepository repository;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _comment = TextEditingController();
  final _ratings = <String, int>{};
  var _loading = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ratings.length != widget.criteria.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rate every criterion before submitting.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.repository.submitFeedback(
        campaignId: widget.campaign.id,
        targetId: widget.targetId,
        ratings: widget.criteria
            .map(
              (criterion) => {
                'criterion_id': criterion.id,
                'rating_value': _ratings[criterion.id],
                'is_not_applicable': false,
              },
            )
            .toList(),
        comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted anonymously.')),
        );
      }
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.campaign.title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your response is anonymous. Select one rating for each item.',
              ),
              const SizedBox(height: 16),
              ...widget.criteria.map(
                (criterion) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        criterion.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (criterion.description.isNotEmpty)
                        Text(criterion.description),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: List.generate(
                          5,
                          (index) => ChoiceChip(
                            label: Text('${index + 1}'),
                            selected: _ratings[criterion.id] == index + 1,
                            onSelected: (_) => setState(
                              () => _ratings[criterion.id] = index + 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextField(
                controller: _comment,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Optional comment',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const CircularProgressIndicator()
              : const Text('Submit feedback'),
        ),
      ],
    );
  }
}
