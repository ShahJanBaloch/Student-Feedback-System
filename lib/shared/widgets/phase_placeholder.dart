import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class PhasePlaceholder extends StatelessWidget {
  const PhasePlaceholder({
    super.key,
    required this.title,
    required this.phase,
    required this.summary,
    this.icon = Icons.construction_outlined,
    this.trailing,
  });

  final String title;
  final String phase;
  final String summary;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: icon,
        title: '$title is not live yet',
        message: '$summary\n\nPlanned in $phase.',
        action: trailing,
      ),
    );
  }
}
