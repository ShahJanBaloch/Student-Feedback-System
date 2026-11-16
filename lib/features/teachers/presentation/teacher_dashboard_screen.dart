import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/models/campaign_target_report.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/widgets/role_app_bar.dart';
import '../providers/teacher_analytics_provider.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institution = ref.watch(activeInstitutionProvider);
    final reports = ref.watch(teacherReportsProvider);

    return Scaffold(
      appBar: const RoleAppBar(title: 'Teacher'),
      body: reports.when(
        loading: () => const LoadingState(message: 'Loading feedback reports…'),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load reports',
          message: error is AppException
              ? error.message
              : 'Please try again. ${error.toString()}',
          action: TextButton(
            onPressed: () => ref.invalidate(teacherReportsProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(teacherReportsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: institution?.name ?? 'Assigned institution',
                subtitle: 'Feedback reports',
                child: Text(
                  'Reports include aggregate student ratings only. '
                  'Student identities are never shown.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.analytics_outlined,
                  title: 'No campaign reports yet',
                  message:
                      'Reports appear here after an institution runs a campaign for your assigned classes.',
                )
              else
                ...items.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReportCard(report: report),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final CampaignTargetReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: report.subjectName,
      subtitle: '${report.campaignTitle} · ${report.className}',
      child: report.isBelowThreshold
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Results are hidden until the response threshold is met.',
                ),
                const SizedBox(height: 8),
                Text('Minimum required: ${report.threshold} responses'),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Responses: ${report.responseCount ?? '—'}'),
                const SizedBox(height: 12),
                ...report.criteria.map<Widget>(
                  (criterion) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CriterionRow(criterion: criterion),
                  ),
                ),
                if (report.publishedComments.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Published comments',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...report.publishedComments.map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('“$comment”'),
                    ),
                  ),
                ],
                if (report.disclaimer.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    report.disclaimer,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion});

  final CampaignCriterionReport criterion;

  @override
  Widget build(BuildContext context) {
    final rating = criterion.meanRating;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(criterion.title)),
            Text(
              rating == null
                  ? 'No numeric ratings'
                  : '${rating.toStringAsFixed(2)} / 5',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: rating == null ? 0 : (rating / 5).clamp(0, 1).toDouble(),
        ),
        const SizedBox(height: 4),
        Text(
          '${criterion.numericResponses} ratings'
          '${criterion.notApplicableCount > 0 ? ' · ${criterion.notApplicableCount} N/A' : ''}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
