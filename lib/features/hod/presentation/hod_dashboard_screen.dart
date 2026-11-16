import 'package:material_ui/material_ui.dart';

class HodDashboardScreen extends StatelessWidget {
  const HodDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HOD dashboard')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your HOD role is active. Department feedback review is not '
            'available yet.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
