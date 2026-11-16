import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared/models/student_registration_option.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';

class StudentVerificationScreen extends ConsumerStatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  ConsumerState<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState
    extends ConsumerState<StudentVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _studentNumber = TextEditingController();
  String? _departmentId;
  String? _programId;
  String? _semesterId;
  var _loading = false;

  @override
  void dispose() {
    _fullName.dispose();
    _studentNumber.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_departmentId == null || _programId == null || _semesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select your department, program, and semester.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateFullName(_fullName.text.trim());
      await ref.read(verificationRepositoryProvider).requestVerification(
            departmentId: _departmentId!,
            programId: _programId!,
            semesterId: _semesterId!,
            studentNumber: _studentNumber.text,
          );
      invalidateAccount(ref);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration submitted. VC/Admin must verify your student details.',
          ),
        ),
      );
      context.go(AppRoutes.onboarding);
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(uotStudentRegistrationOptionsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    if (_fullName.text.isEmpty && (profile?.fullName.isNotEmpty ?? false)) {
      _fullName.text = profile!.fullName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('University of Turbat student registration'),
      ),
      body: options.when(
        loading: () => const LoadingState(
          message: 'Loading UOT academic programs…',
        ),
        error: (error, _) => ErrorState(
          message: error is AppException
              ? error.message
              : 'Could not load University of Turbat academic programs.',
          onRetry: () => ref.invalidate(uotStudentRegistrationOptionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'Academic choices are not configured',
              message: 'VC/Admin must configure active UOT departments, degree '
                  'programs, semesters, and a current academic session.',
            );
          }

          final departments = {
            for (final item in items) item.departmentId: item.departmentName,
          };
          final programs = items
              .where((item) => item.departmentId == _departmentId)
              .toList();
          final programNames = {
            for (final item in programs) item.programId: item.programName,
          };
          final semesters =
              programs.where((item) => item.programId == _programId).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Your account remains pending until VC/Admin verifies '
                      'your registration number. This does not depend on an '
                      'institution approval workflow.',
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Full name',
                      controller: _fullName,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      key: const ValueKey('uot-department'),
                      initialSelection: _departmentId,
                      label: const Text('Department'),
                      expandedInsets: EdgeInsets.zero,
                      dropdownMenuEntries: departments.entries
                          .map(
                            (entry) => DropdownMenuEntry(
                              value: entry.key,
                              label: entry.value,
                            ),
                          )
                          .toList(),
                      onSelected: (value) {
                        setState(() {
                          _departmentId = value;
                          _programId = null;
                          _semesterId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      key: ValueKey('uot-program-$_departmentId'),
                      initialSelection: _programId,
                      label: const Text('Degree program'),
                      expandedInsets: EdgeInsets.zero,
                      dropdownMenuEntries: programNames.entries
                          .map(
                            (entry) => DropdownMenuEntry(
                              value: entry.key,
                              label: entry.value,
                            ),
                          )
                          .toList(),
                      onSelected: (value) {
                        setState(() {
                          _programId = value;
                          _semesterId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownMenu<String>(
                      key: ValueKey('uot-semester-$_programId'),
                      initialSelection: _semesterId,
                      label: const Text('Current semester'),
                      expandedInsets: EdgeInsets.zero,
                      dropdownMenuEntries: semesters
                          .map(
                            (StudentRegistrationOption item) =>
                                DropdownMenuEntry(
                              value: item.semesterId,
                              label:
                                  '${item.semesterName} (${item.semesterNumber})',
                            ),
                          )
                          .toList(),
                      onSelected: (value) =>
                          setState(() => _semesterId = value),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Student registration number',
                      controller: _studentNumber,
                      helperText: 'VC/Admin will verify this number manually.',
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Enter your student registration number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Submit for verification',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
