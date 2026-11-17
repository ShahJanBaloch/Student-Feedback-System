import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../shared/providers/repositories.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  AppRole _requestedRole = AppRole.student;
  var _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!Env.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Env.configurationError ?? 'Missing .env.example',
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(authRepositoryProvider).signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            requestedRole: _requestedRole,
          );
      if (!mounted) {
        return;
      }
      if (result.needsEmailConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Confirm the email Supabase sent, then sign in. '
              'Feedback is still blocked until institutional verification.',
            ),
          ),
        );
        context.go(AppRoutes.login);
      }
    } on AppException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Create your TaleemVoice account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start with your email',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'After confirming your email, complete your '
                          'student or approved staff onboarding flow.',
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Choose account type',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AppRole.student,
                            AppRole.teacher,
                            AppRole.hod,
                            AppRole.vcAdmin,
                          ]
                              .map(
                                (role) => ChoiceChip(
                                  avatar: Icon(
                                    switch (role) {
                                      AppRole.student => Icons.school_outlined,
                                      AppRole.teacher =>
                                        Icons.co_present_outlined,
                                      AppRole.hod =>
                                        Icons.account_tree_outlined,
                                      AppRole.vcAdmin =>
                                        Icons.admin_panel_settings_outlined,
                                    },
                                  ),
                                  label: Text(role.label),
                                  selected: _requestedRole == role,
                                  onSelected: _loading
                                      ? null
                                      : (selected) {
                                          if (selected) {
                                            setState(
                                              () => _requestedRole = role,
                                            );
                                          }
                                        },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _requestedRole == AppRole.student
                              ? 'Student accounts continue to academic verification.'
                              : 'This account type requires approval by an existing VC/Admin.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Full name',
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Email',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (!text.contains('@') || !text.contains('.')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Password',
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null ||
                                value.length < AppConstants.minPasswordLength) {
                              return 'Use at least ${AppConstants.minPasswordLength} characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Confirm password',
                          controller: _confirm,
                          obscureText: true,
                          validator: (value) {
                            if (value != _password.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Create account',
                          loading: _loading,
                          onPressed: _register,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Already have an account? Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
