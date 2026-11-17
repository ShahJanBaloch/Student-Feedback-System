import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final destinations = const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Give Feedback',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'My Feedback',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        void selectDestination(int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        }

        if (constraints.maxWidth >= 900) {
          return Scaffold(
            body: Column(
              children: [
                _PortalHeader(
                  onProfile: () => navigationShell.goBranch(4),
                  onNotifications: () => navigationShell.goBranch(3),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 88,
                        color: Theme.of(context).colorScheme.surface,
                        child: NavigationRail(
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: selectDestination,
                          labelType: NavigationRailLabelType.all,
                          destinations: destinations
                              .map(
                                (destination) => NavigationRailDestination(
                                  icon: destination.icon,
                                  selectedIcon: destination.selectedIcon,
                                  label: Text(destination.label),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: navigationShell),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              _PortalHeader(
                onProfile: () => navigationShell.goBranch(4),
                onNotifications: () => navigationShell.goBranch(3),
              ),
              Expanded(child: navigationShell),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: selectDestination,
            destinations: destinations,
          ),
        );
      },
    );
  }
}

class _PortalHeader extends StatelessWidget {
  const _PortalHeader({
    required this.onProfile,
    required this.onNotifications,
  });

  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.forum_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'TaleemVoice',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 28,
            width: 1,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Text(
            'University of Turbat',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(24),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: theme.colorScheme.secondary,
              child: Text(
                'S',
                style: TextStyle(color: theme.colorScheme.onSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
