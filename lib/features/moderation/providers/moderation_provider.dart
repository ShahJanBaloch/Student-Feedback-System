import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/moderation_comment.dart';
import '../../../shared/providers/repositories.dart';

final pendingCommentsProvider =
    FutureProvider.family<List<ModerationComment>, String>(
  (ref, institutionId) {
    return ref
        .watch(moderationRepositoryProvider)
        .fetchPendingComments(institutionId);
  },
);
