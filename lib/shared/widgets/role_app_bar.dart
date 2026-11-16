import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_roles.dart';
import '../../core/router/app_routes.dart';
import '../providers/account_provider.dart';
import '../providers/active_role_provider.dart';
import '../providers/repositories.dart';
import '../providers/session_provider.dart';

class RoleAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const RoleAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(availableRolesProvider);
    final current = ref.watch(resolvedRoleProvider);

    return AppBar(
      title: Text(title),
      actions: [
        if (roles.length > 1)
          PopupMenuButton<AppRole>(
            tooltip: 'Switch role layout',
            onSelected: (role) {
              ref.read(activeRoleProvider.notifier).state = role;
              context.go(_homeFor(role));
            },
            itemBuilder: (context) {
              return roles
                  .map(
                    (role) => PopupMenuItem(
                      value: role,
                      child: Text(
                        role == current
                            ? '${role.label} (current)'
                            : role.label,
                      ),
                    ),
                  )
                  .toList();
            },
            icon: const Icon(Icons.swap_horiz),
          ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () async {
            if (ref.read(currentSessionProvider) != null) {
              await ref.read(authRepositoryProvider).signOut();
            }
            invalidateAccount(ref);
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }
}

String _homeFor(AppRole role) {
  return switch (role) {
    AppRole.student => AppRoutes.studentHome,
    AppRole.teacher => AppRoutes.teacher,
    AppRole.hod => AppRoutes.hod,
    AppRole.vcAdmin => AppRoutes.vcAdmin,
  };
}
