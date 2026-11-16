import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_roles.dart';

/// Client-side selected role. PostgreSQL RLS is the real permission check.
final activeRoleProvider = StateProvider<AppRole>((ref) => AppRole.student);
