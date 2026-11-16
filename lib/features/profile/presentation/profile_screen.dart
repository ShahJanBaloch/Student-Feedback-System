import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/active_role_provider.dart';
import '../../../shared/providers/repositories.dart';
import '../../../shared/providers/session_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateFullName(_name.text);
      invalidateAccount(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final roles = ref.watch(availableRolesProvider);
    final role = ref.watch(resolvedRoleProvider);
    final memberships = ref.watch(membershipsProvider).valueOrNull ?? [];

    if (_name.text.isEmpty && (profile?.fullName.isNotEmpty ?? false)) {
      _name.text = profile!.fullName;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Account',
            subtitle: profile?.email ?? 'Signed in',
            child: Column(
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Save name',
                  loading: _saving,
                  onPressed: _saveName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Roles',
            subtitle:
                'Switching layout never grants extra SQL permissions. RLS still applies.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((value) {
                final selected = value == role;
                return ChoiceChip(
                  label: Text(value.label),
                  selected: selected,
                  onSelected: (_) {
                    ref.read(activeRoleProvider.notifier).state = value;
                    context.go(_homeFor(value));
                  },
                );
              }).toList(),
            ),
          ),
          if (memberships.isNotEmpty) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Memberships',
              child: Column(
                children: memberships
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.role?.label ?? 'Legacy role'),
                        subtitle: Text(
                          '${item.institution?.name ?? 'Platform'} · ${item.status.label}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'Sign out',
            onPressed: () async {
              ref.read(activeRoleProvider.notifier).state = AppRole.student;
              if (ref.read(currentSessionProvider) != null) {
                await ref.read(authRepositoryProvider).signOut();
              }
              invalidateAccount(ref);
            },
          ),
        ],
      ),
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
