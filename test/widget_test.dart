import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taleemvoice/app.dart';
import 'package:taleemvoice/core/config/env.dart';
import 'package:taleemvoice/core/constants/app_constants.dart';
import 'package:taleemvoice/core/constants/app_roles.dart';
import 'package:taleemvoice/core/router/app_routes.dart';
import 'package:taleemvoice/core/widgets/empty_state.dart';
import 'package:taleemvoice/shared/models/app_notification.dart';
import 'package:taleemvoice/shared/models/campaign_target_report.dart';
import 'package:taleemvoice/shared/models/improvement_action.dart';
import 'package:taleemvoice/shared/models/institution.dart';

void main() {
  testWidgets('login screen offers the four credential-based role choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: TaleemVoiceApp()),
    );
    await tester.pump();
    expect(find.text(AppConstants.appName), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('UI preview (debug only — not a login)'), findsNothing);
    expect(find.text('Sign in as'), findsOneWidget);
    for (final role in [
      AppRole.student,
      AppRole.teacher,
      AppRole.hod,
      AppRole.vcAdmin,
    ]) {
      expect(find.widgetWithText(ChoiceChip, role.label), findsOneWidget);
    }

    await tester.tap(find.widgetWithText(ChoiceChip, AppRole.hod.label));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(
            find.widgetWithText(ChoiceChip, AppRole.hod.label),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('unauthenticated navigation cannot open a protected dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TaleemVoiceApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final context = tester.element(find.text(AppConstants.appName));
    final router = GoRouter.of(context);
    for (final route in [
      AppRoutes.teacher,
      AppRoutes.hod,
      AppRoutes.vcAdmin,
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(find.text('Sign in'), findsOneWidget);
    }
  });

  testWidgets('password recovery route is available without a session', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TaleemVoiceApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final context = tester.element(find.text(AppConstants.appName));
    GoRouter.of(context).go(AppRoutes.passwordReset);
    await tester.pumpAndSettle();

    expect(find.text('Set a new password'), findsOneWidget);
    expect(find.text('Update password'), findsOneWidget);
  });

  test('HOD role parses from the database value', () {
    expect(AppRole.tryParse('hod'), AppRole.hod);
    expect(AppRole.hod.storageValue, 'hod');
    expect(AppRole.vcAdmin.label, 'VC / Admin');
  });

  testWidgets('empty state renders title and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(
          title: 'No campaigns',
          message: 'None yet',
        ),
      ),
    );
    expect(find.text('No campaigns'), findsOneWidget);
    expect(find.text('None yet'), findsOneWidget);
  });

  test('environment defaults stay unset until provided by dart-define', () {
    expect(Env.supabaseUrl, isEmpty);
    expect(Env.supabaseAnonKey, isEmpty);
    expect(Env.isConfigured, isFalse);
    expect(Env.configurationError, contains('SUPABASE_URL'));
  });

  test('institution map parses enums', () {
    final institution = Institution.fromMap({
      'id': '11111111-1111-1111-1111-111111111111',
      'name': 'University of Turbat',
      'short_code': 'UOT',
      'institution_type': 'university',
      'status': 'pending',
      'province': 'Balochistan',
      'min_response_threshold': 5,
    });
    expect(institution.name, 'University of Turbat');
    expect(institution.shortCode, 'UOT');
    expect(institution.institutionType.label, 'University');
    expect(institution.status.label, 'Pending approval');
  });

  test('campaign target report keeps below-threshold data private', () {
    final report = CampaignTargetReport.fromMap(
      targetId: 'target-id',
      campaignTitle: 'Term feedback',
      subjectName: 'Mathematics',
      className: 'Grade 10 (A)',
      map: {
        'status': 'below_threshold',
        'threshold': 5,
        'response_count': null,
        'disclaimer': 'Results are hidden.',
      },
    );

    expect(report.isBelowThreshold, isTrue);
    expect(report.responseCount, isNull);
    expect(report.criteria, isEmpty);
    expect(report.publishedComments, isEmpty);
  });

  test('campaign target report parses released category results', () {
    final report = CampaignTargetReport.fromMap(
      targetId: 'target-id',
      campaignTitle: 'Term feedback',
      subjectName: 'Mathematics',
      className: 'Grade 10 (A)',
      map: {
        'status': 'ok',
        'threshold': 5,
        'response_count': 7,
        'criteria': [
          {
            'category': 'teaching_clarity',
            'title': 'Explains concepts clearly',
            'mean_rating': 4.25,
            'numeric_responses': 7,
            'na_count': 0,
          },
        ],
        'published_comments': [
          {'id': 'comment-id', 'body': 'Helpful explanations.'},
        ],
        'disclaimer': 'Aggregate perceptions only.',
      },
    );

    expect(report.isBelowThreshold, isFalse);
    expect(report.responseCount, 7);
    expect(report.criteria.single.meanRating, 4.25);
    expect(report.publishedComments, ['Helpful explanations.']);
  });

  test('notification maps its read state and type', () {
    final notification = AppNotification.fromMap({
      'id': 'notification-id',
      'notification_type': 'submission',
      'title': 'Feedback submitted',
      'body': 'Thank you.',
      'is_read': false,
      'created_at': '2026-11-16T08:00:00Z',
    });

    expect(notification.type, 'submission');
    expect(notification.isRead, isFalse);
    expect(notification.title, 'Feedback submitted');
  });

  test('improvement action parses status and optional due date', () {
    final action = ImprovementAction.fromMap({
      'id': 'action-id',
      'title': 'Review course materials',
      'description': 'Refresh the lesson resources.',
      'status': 'in_progress',
      'due_on': '2026-12-01',
      'created_at': '2026-11-16T08:00:00Z',
    });

    expect(action.title, 'Review course materials');
    expect(action.status, 'in_progress');
    expect(action.dueOn, DateTime(2026, 12, 1));
  });
}
