import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/improvement_action.dart';
import '../../../shared/providers/repositories.dart';

final improvementActionsProvider =
    FutureProvider.family<List<ImprovementAction>, String>(
  (ref, institutionId) {
    return ref.watch(improvementRepositoryProvider).fetchActions(institutionId);
  },
);
