import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/models/academic_entities.dart';
import '../../../shared/providers/account_provider.dart';
import '../../../shared/providers/repositories.dart';

class AcademicAdminScreen extends ConsumerStatefulWidget {
  const AcademicAdminScreen({super.key});

  @override
  ConsumerState<AcademicAdminScreen> createState() =>
      _AcademicAdminScreenState();
}

class _AcademicAdminScreenState extends ConsumerState<AcademicAdminScreen> {
  final _departmentController = TextEditingController();
  final _departmentCodeController = TextEditingController();
  final _sessionNameController = TextEditingController();
  final _programNameController = TextEditingController();
  final _programLevelController = TextEditingController();
  final _semesterNameController = TextEditingController();
  final _semesterNumberController = TextEditingController();
  final _classNameController = TextEditingController();
  final _classSectionController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _rosterCsvController = TextEditingController();
  DateTime? _sessionStartsOn;
  DateTime? _sessionEndsOn;
  var _sessionIsCurrent = false;
  String? _selectedProgramDepartmentId;
  String? _selectedSubjectDepartmentId;
  String? _selectedSemesterProgramId;
  String? _selectedSemesterId;
  String? _selectedSessionId;
  var _loading = false;

  @override
  void dispose() {
    _departmentController.dispose();
    _departmentCodeController.dispose();
    _sessionNameController.dispose();
    _programNameController.dispose();
    _programLevelController.dispose();
    _semesterNameController.dispose();
    _semesterNumberController.dispose();
    _classNameController.dispose();
    _classSectionController.dispose();
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _rosterCsvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final institutionId = ref.watch(activeInstitutionProvider)?.id ?? '';
    final overview = ref.watch(academicOverviewProvider(institutionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic structure'),
        actions: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ],
      ),
      body: overview.when(
        loading: () =>
            const LoadingState(message: 'Loading academic settings…'),
        error: (error, _) => ErrorState(
          message: error is AppException
              ? error.message
              : 'Unable to load academic records.',
          onRetry: () =>
              ref.invalidate(academicOverviewProvider(institutionId)),
        ),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Institution structure',
                subtitle:
                    'Departments, sessions, programs, semesters, classes, and subjects.',
                child: Text(
                  'Departments: ${data.departments.length} · Sessions: ${data.sessions.length} · Programs: ${data.programs.length} · Semesters: ${data.semesters.length} · Classes: ${data.classes.length}',
                ),
              ),
              const SizedBox(height: 12),
              _BuildDepartmentForm(
                departmentController: _departmentController,
                codeController: _departmentCodeController,
                onSubmit: () => _createDepartment(institutionId),
                loading: _loading,
              ),
              const SizedBox(height: 12),
              _BuildSessionForm(
                nameController: _sessionNameController,
                startsOn: _sessionStartsOn,
                endsOn: _sessionEndsOn,
                isCurrent: _sessionIsCurrent,
                onCurrentChanged: (value) =>
                    setState(() => _sessionIsCurrent = value),
                onPickStart: () async {
                  final date =
                      await _pickDate(_sessionStartsOn ?? DateTime.now());
                  if (date != null) {
                    setState(() => _sessionStartsOn = date);
                  }
                },
                onPickEnd: () async {
                  final date =
                      await _pickDate(_sessionEndsOn ?? DateTime.now());
                  if (date != null) {
                    setState(() => _sessionEndsOn = date);
                  }
                },
                onSubmit: () => _createSession(institutionId),
                loading: _loading,
              ),
              const SizedBox(height: 12),
              _BuildProgramForm(
                nameController: _programNameController,
                levelController: _programLevelController,
                departments: data.departments,
                selectedDepartmentId: _selectedProgramDepartmentId,
                onChanged: (value) =>
                    setState(() => _selectedProgramDepartmentId = value),
                onSubmit: () => _createProgram(institutionId),
                loading: _loading,
              ),
              const SizedBox(height: 12),
              _BuildSemesterForm(
                nameController: _semesterNameController,
                numberController: _semesterNumberController,
                programs: data.programs,
                selectedProgramId: _selectedSemesterProgramId,
                onProgramChanged: (value) =>
                    setState(() => _selectedSemesterProgramId = value),
                onSubmit: () => _createSemester(institutionId, data.programs),
                loading: _loading,
              ),
              const SizedBox(height: 12),
              _BuildClassForm(
                nameController: _classNameController,
                sectionController: _classSectionController,
                semesters: data.semesters,
                programs: data.programs,
                sessions: data.sessions,
                selectedSemesterId: _selectedSemesterId,
                selectedSessionId: _selectedSessionId,
                onSemesterChanged: (value) =>
                    setState(() => _selectedSemesterId = value),
                onSessionChanged: (value) =>
                    setState(() => _selectedSessionId = value),
                onSubmit: () => _createClass(institutionId, data.semesters),
                loading: _loading,
              ),
              const SizedBox(height: 12),
              _BuildSubjectForm(
                codeController: _subjectCodeController,
                nameController: _subjectNameController,
                departments: data.departments,
                selectedDepartmentId: _selectedSubjectDepartmentId,
                onChanged: (value) =>
                    setState(() => _selectedSubjectDepartmentId = value),
                onSubmit: () => _createSubject(institutionId),
                loading: _loading,
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Roster import',
                subtitle:
                    'CSV format: student_number, full_name, program_name, class_name, session_name',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _rosterCsvController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '2025-101,Ali Khan,BSCS,BSCS-1,2025 Fall',
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Import roster',
                      loading: _loading,
                      onPressed: () => _importRoster(institutionId),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Current academic data',
                child: Column(
                  children: [
                    if (data.departments.isEmpty)
                      const Text('No departments yet.')
                    else
                      ..._departmentTiles(data.departments),
                    if (data.sessions.isEmpty)
                      const Text('No sessions yet.')
                    else
                      ..._sessionTiles(data.sessions),
                    if (data.programs.isEmpty)
                      const Text('No programs yet.')
                    else
                      ..._programTiles(data.programs),
                    if (data.semesters.isEmpty)
                      const Text('No semesters yet.')
                    else
                      ..._semesterTiles(data.semesters, data.programs),
                    if (data.classes.isEmpty)
                      const Text('No classes yet.')
                    else
                      ..._classTiles(data.classes),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createDepartment(String institutionId) async {
    if (institutionId.isEmpty) {
      _showMessage('Select an institution first.');
      return;
    }

    try {
      setState(() => _loading = true);
      await ref.read(academicRepositoryProvider).createDepartment(
            institutionId: institutionId,
            name: _departmentController.text,
            code: _departmentCodeController.text,
          );
      _departmentController.clear();
      _departmentCodeController.clear();
      ref.invalidate(academicOverviewProvider(institutionId));
      _showMessage('Department created.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSession(String institutionId) async {
    if (institutionId.isEmpty) {
      _showMessage('Select an institution first.');
      return;
    }
    if (_sessionStartsOn == null || _sessionEndsOn == null) {
      _showMessage('Set both the session start and end dates.');
      return;
    }

    try {
      setState(() => _loading = true);
      await ref.read(academicRepositoryProvider).createSession(
            institutionId: institutionId,
            name: _sessionNameController.text,
            startsOn: _sessionStartsOn!,
            endsOn: _sessionEndsOn!,
            isCurrent: _sessionIsCurrent,
          );
      _sessionNameController.clear();
      _sessionStartsOn = null;
      _sessionEndsOn = null;
      _sessionIsCurrent = false;
      ref.invalidate(academicOverviewProvider(institutionId));
      _showMessage('Academic session created.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createProgram(String institutionId) async {
    if (institutionId.isEmpty || _selectedProgramDepartmentId == null) {
      _showMessage('Choose a department first.');
      return;
    }

    try {
      setState(() => _loading = true);
      await ref.read(academicRepositoryProvider).createProgram(
            institutionId: institutionId,
            departmentId: _selectedProgramDepartmentId!,
            name: _programNameController.text,
            level: _programLevelController.text,
          );
      _programNameController.clear();
      _programLevelController.clear();
      _selectedProgramDepartmentId = null;
      ref.invalidate(academicOverviewProvider(institutionId));
      _showMessage('Program created.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClass(
    String institutionId,
    List<AcademicSemester> semesters,
  ) async {
    AcademicSemester? semester;
    for (final item in semesters) {
      if (item.id == _selectedSemesterId) {
        semester = item;
        break;
      }
    }

    if (institutionId.isEmpty ||
        semester == null ||
        _selectedSessionId == null) {
      _showMessage('Choose a semester and session.');
      return;
    }

    try {
      setState(() => _loading = true);
      await ref.read(academicRepositoryProvider).createClass(
            institutionId: institutionId,
            programId: semester.programId,
            sessionId: _selectedSessionId!,
            semesterId: semester.id,
            name: _classNameController.text,
            section: _classSectionController.text,
          );
      _classNameController.clear();
      _classSectionController.clear();
      ref.invalidate(academicOverviewProvider(institutionId));
      _showMessage('Class created.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSemester(
    String institutionId,
    List<AcademicProgram> programs,
  ) async {
    AcademicProgram? program;
    for (final item in programs) {
      if (item.id == _selectedSemesterProgramId) {
        program = item;
        break;
      }
    }
    final semesterNumber = int.tryParse(_semesterNumberController.text);
    if (institutionId.isEmpty || program == null || semesterNumber == null) {
      _showMessage('Choose a program and enter a valid semester number.');
      return;
    }

    try {
      setState(() => _loading = true);
      await ref.read(academicRepositoryProvider).createSemester(
            institutionId: institutionId,
            departmentId: program.departmentId,
            programId: program.id,
            semesterNumber: semesterNumber,
            name: _semesterNameController.text,
          );
      _semesterNameController.clear();
      _semesterNumberController.clear();
      _selectedSemesterProgramId = null;
      ref.invalidate(academicOverviewProvider(institutionId));
      ref.invalidate(uotStudentRegistrationOptionsProvider);
      _showMessage('Semester created.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSubject(String institutionId) async {
    if (institutionId.isEmpty || _selectedSubjectDepartmentId == null) {
      _showMessage('Choose a department first.');
      return;
    }

    try {
      setState(() => _loading = true);
      await ref.read(academicRepositoryProvider).createSubject(
            institutionId: institutionId,
            departmentId: _selectedSubjectDepartmentId!,
            code: _subjectCodeController.text,
            name: _subjectNameController.text,
          );
      _subjectCodeController.clear();
      _subjectNameController.clear();
      _selectedSubjectDepartmentId = null;
      ref.invalidate(academicOverviewProvider(institutionId));
      _showMessage('Subject created.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importRoster(String institutionId) async {
    if (institutionId.isEmpty) {
      _showMessage('Select an institution first.');
      return;
    }

    try {
      setState(() => _loading = true);
      final count = await ref.read(academicRepositoryProvider).importRosterCsv(
            institutionId: institutionId,
            csvText: _rosterCsvController.text,
          );
      _rosterCsvController.clear();
      ref.invalidate(academicOverviewProvider(institutionId));
      _showMessage('Imported $count roster rows.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<DateTime?> _pickDate(DateTime initialDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    return picked;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Widget> _departmentTiles(List<Department> departments) {
    return departments
        .map(
          (department) => ListTile(
            dense: true,
            title: Text(department.name),
            subtitle: department.code == null ? null : Text(department.code!),
          ),
        )
        .toList();
  }

  List<Widget> _sessionTiles(List<AcademicSession> sessions) {
    return sessions
        .map(
          (session) => ListTile(
            dense: true,
            title: Text(session.name),
            subtitle: Text(session.displayRange),
            trailing: session.isCurrent
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        )
        .toList();
  }

  List<Widget> _programTiles(List<AcademicProgram> programs) {
    return programs
        .map(
          (program) => ListTile(
            dense: true,
            title: Text(program.name),
            subtitle: program.level == null ? null : Text(program.level!),
          ),
        )
        .toList();
  }

  List<Widget> _semesterTiles(
    List<AcademicSemester> semesters,
    List<AcademicProgram> programs,
  ) {
    return semesters.map(
      (semester) {
        String programName = 'Program';
        for (final program in programs) {
          if (program.id == semester.programId) {
            programName = program.name;
            break;
          }
        }
        return ListTile(
          dense: true,
          title: Text(
            'Semester ${semester.semesterNumber}: ${semester.name}',
          ),
          subtitle: Text(programName),
        );
      },
    ).toList();
  }

  List<Widget> _classTiles(List<AcademicClass> classes) {
    return classes
        .map(
          (academicClass) => ListTile(
            dense: true,
            title: Text(academicClass.label),
          ),
        )
        .toList();
  }
}

class _BuildDepartmentForm extends StatelessWidget {
  const _BuildDepartmentForm({
    required this.departmentController,
    required this.codeController,
    required this.onSubmit,
    required this.loading,
  });

  final TextEditingController departmentController;
  final TextEditingController codeController;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create department',
      child: Column(
        children: [
          AppTextField(
            label: 'Department name',
            controller: departmentController,
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Code (optional)', controller: codeController),
          const SizedBox(height: 12),
          AppButton(
            label: 'Save department',
            loading: loading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _BuildSessionForm extends StatelessWidget {
  const _BuildSessionForm({
    required this.nameController,
    required this.startsOn,
    required this.endsOn,
    required this.isCurrent,
    required this.onCurrentChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onSubmit,
    required this.loading,
  });

  final TextEditingController nameController;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final bool isCurrent;
  final ValueChanged<bool> onCurrentChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create academic session',
      child: Column(
        children: [
          AppTextField(label: 'Session name', controller: nameController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickStart,
                  child: Text(
                    startsOn == null
                        ? 'Start date'
                        : 'Start: ${startsOn!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickEnd,
                  child: Text(
                    endsOn == null
                        ? 'End date'
                        : 'End: ${endsOn!.toLocal().toString().split(' ')[0]}',
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as current academic session'),
            value: isCurrent,
            onChanged: loading ? null : onCurrentChanged,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Save session',
            loading: loading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _BuildProgramForm extends StatelessWidget {
  const _BuildProgramForm({
    required this.nameController,
    required this.levelController,
    required this.departments,
    required this.selectedDepartmentId,
    required this.onChanged,
    required this.onSubmit,
    required this.loading,
  });

  final TextEditingController nameController;
  final TextEditingController levelController;
  final List<Department> departments;
  final String? selectedDepartmentId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create program',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedDepartmentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Department'),
            items: departments.map((department) {
              return DropdownMenuItem<String>(
                value: department.id,
                child: Text(department.name),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Program name', controller: nameController),
          const SizedBox(height: 12),
          AppTextField(label: 'Level (optional)', controller: levelController),
          const SizedBox(height: 12),
          AppButton(
            label: 'Save program',
            loading: loading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _BuildSemesterForm extends StatelessWidget {
  const _BuildSemesterForm({
    required this.nameController,
    required this.numberController,
    required this.programs,
    required this.selectedProgramId,
    required this.onProgramChanged,
    required this.onSubmit,
    required this.loading,
  });

  final TextEditingController nameController;
  final TextEditingController numberController;
  final List<AcademicProgram> programs;
  final String? selectedProgramId;
  final ValueChanged<String?> onProgramChanged;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create semester',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedProgramId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Program'),
            items: programs.map((program) {
              return DropdownMenuItem<String>(
                value: program.id,
                child: Text(program.name),
              );
            }).toList(),
            onChanged: onProgramChanged,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Semester number (1-16)',
            controller: numberController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Semester name', controller: nameController),
          const SizedBox(height: 12),
          AppButton(
            label: 'Save semester',
            loading: loading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _BuildClassForm extends StatelessWidget {
  const _BuildClassForm({
    required this.nameController,
    required this.sectionController,
    required this.semesters,
    required this.programs,
    required this.sessions,
    required this.selectedSemesterId,
    required this.selectedSessionId,
    required this.onSemesterChanged,
    required this.onSessionChanged,
    required this.onSubmit,
    required this.loading,
  });

  final TextEditingController nameController;
  final TextEditingController sectionController;
  final List<AcademicSemester> semesters;
  final List<AcademicProgram> programs;
  final List<AcademicSession> sessions;
  final String? selectedSemesterId;
  final String? selectedSessionId;
  final ValueChanged<String?> onSemesterChanged;
  final ValueChanged<String?> onSessionChanged;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create class',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedSemesterId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Semester'),
            items: semesters.map((semester) {
              String programName = 'Program';
              for (final program in programs) {
                if (program.id == semester.programId) {
                  programName = program.name;
                  break;
                }
              }
              return DropdownMenuItem<String>(
                value: semester.id,
                child: Text(
                  '$programName · Semester ${semester.semesterNumber}',
                ),
              );
            }).toList(),
            onChanged: onSemesterChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedSessionId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Session'),
            items: sessions.map((session) {
              return DropdownMenuItem<String>(
                value: session.id,
                child: Text(session.name),
              );
            }).toList(),
            onChanged: onSessionChanged,
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Class name', controller: nameController),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Section (optional)',
            controller: sectionController,
          ),
          const SizedBox(height: 12),
          AppButton(label: 'Save class', loading: loading, onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _BuildSubjectForm extends StatelessWidget {
  const _BuildSubjectForm({
    required this.codeController,
    required this.nameController,
    required this.departments,
    required this.selectedDepartmentId,
    required this.onChanged,
    required this.onSubmit,
    required this.loading,
  });

  final TextEditingController codeController;
  final TextEditingController nameController;
  final List<Department> departments;
  final String? selectedDepartmentId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Create subject',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedDepartmentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Department'),
            items: departments.map((department) {
              return DropdownMenuItem<String>(
                value: department.id,
                child: Text(department.name),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Subject code', controller: codeController),
          const SizedBox(height: 12),
          AppTextField(label: 'Subject name', controller: nameController),
          const SizedBox(height: 12),
          AppButton(
            label: 'Save subject',
            loading: loading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
