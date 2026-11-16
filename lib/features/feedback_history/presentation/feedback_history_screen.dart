import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/empty_state.dart';

class FeedbackHistoryScreen extends StatelessWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Feedback')),
      body: const EmptyState(
        icon: Icons.history,
        title: 'No submissions yet',
        message: 'After you submit feedback, this list will show receipts from '
            'eligibility records — not other students’ responses.',
      ),
    );
  }
}
