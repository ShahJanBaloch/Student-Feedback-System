import 'package:material_ui/material_ui.dart';

import '../../../core/config/env.dart';
import '../../../core/widgets/error_state.dart';

class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ErrorState(
        message: Env.configurationError ??
            'Configuration is incomplete. See README for dart-define setup.',
      ),
    );
  }
}
