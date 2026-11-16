import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../shared/models/academic_entities.dart';
import '../../../shared/models/student_registration_option.dart';

class AcademicRepository {
  const AcademicRepository(this._client);

  final SupabaseClient _client;

  static List<RosterImportRow> parseCsvRows(String csvText) {
    final lines = csvText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const [];
    }

    final header = _splitCsvLine(lines.first)
        .map((value) => value.trim().toLowerCase())
        .toList();
    final rows = <RosterImportRow>[];

    for (var i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      if (values.length < 2) {
        continue;
      }

      final map = <String, String>{};
      for (var index = 0;
          index < header.length && index < values.length;
          index++) {
        map[header[index]] = values[index].trim();
      }

      final studentNumber = map['student_number'] ?? values[0].trim();
      final fullName = map['full_name'] ?? values[1].trim();
      if (studentNumber.isEmpty || fullName.isEmpty) {
        continue;
      }

      rows.add(
        RosterImportRow(
          studentNumber: studentNumber,
          fullName: fullName,
          programName: map['program_name'] ?? map['program'],
          className: map['class_name'] ?? map['class'] ?? map['section'],
          sessionName:
              map['session_name'] ?? map['session'] ?? map['academic_session'],
        ),
      );
    }

    return rows;
  }

  Future<AcademicOverview> fetchOverview(String institutionId) async {
    try {
      final results = await Future.wait([
        _client
            .from('departments')
            .select()
            .eq('institution_id', institutionId)
            .order('name'),
        _client
            .from('academic_sessions')
            .select()
            .eq('institution_id', institutionId)
            .order('starts_on', ascending: false),
        _client
            .from('academic_programs')
            .select()
            .eq('institution_id', institutionId)
            .order('name'),
        _client
            .from('academic_classes')
            .select()
            .eq('institution_id', institutionId)
            .order('name'),
        _client
            .from('subjects')
            .select()
            .eq('institution_id', institutionId)
            .order('name'),
        _client
            .from('teacher_profiles')
            .select()
            .eq('institution_id', institutionId)
            .order('created_at', ascending: false),
        _client
            .from('teacher_assignments')
            .select()
            .eq('institution_id', institutionId)
            .order('created_at', ascending: false),
        _client
            .from('student_roster_entries')
            .select()
            .eq('institution_id', institutionId)
            .order('created_at', ascending: false),
        _client
            .from('academic_semesters')
            .select()
            .eq('institution_id', institutionId)
            .order('semester_number'),
      ]);

      return AcademicOverview(
        departments: (results[0] as List<dynamic>)
            .map((row) => Department.fromMap(row as Map<String, dynamic>))
            .toList(),
        sessions: (results[1] as List<dynamic>)
            .map((row) => AcademicSession.fromMap(row as Map<String, dynamic>))
            .toList(),
        programs: (results[2] as List<dynamic>)
            .map((row) => AcademicProgram.fromMap(row as Map<String, dynamic>))
            .toList(),
        semesters: (results[8] as List<dynamic>)
            .map((row) => AcademicSemester.fromMap(row as Map<String, dynamic>))
            .toList(),
        classes: (results[3] as List<dynamic>)
            .map((row) => AcademicClass.fromMap(row as Map<String, dynamic>))
            .toList(),
        subjects: (results[4] as List<dynamic>)
            .map((row) => Subject.fromMap(row as Map<String, dynamic>))
            .toList(),
        teacherProfiles: (results[5] as List<dynamic>)
            .map((row) => TeacherProfile.fromMap(row as Map<String, dynamic>))
            .toList(),
        teacherAssignments: (results[6] as List<dynamic>)
            .map(
              (row) => TeacherAssignment.fromMap(
                row as Map<String, dynamic>,
              ),
            )
            .toList(),
        rosterEntries: (results[7] as List<dynamic>)
            .map((row) => RosterEntry.fromMap(row as Map<String, dynamic>))
            .toList(),
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<StudentRegistrationOption>>
      fetchUotStudentRegistrationOptions() async {
    try {
      final rows = await _client.rpc('uot_student_registration_options');
      return (rows as List<dynamic>)
          .map(
            (row) => StudentRegistrationOption.fromMap(
              row as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<Department> createDepartment({
    required String institutionId,
    required String name,
    String? code,
  }) async {
    if (name.trim().isEmpty) {
      throw const AppException('Department name is required.');
    }

    try {
      final row = await _client
          .from('departments')
          .insert({
            'institution_id': institutionId,
            'name': name.trim(),
            'code': _emptyToNull(code)?.toUpperCase(),
          })
          .select()
          .single();
      return Department.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AcademicSession> createSession({
    required String institutionId,
    required String name,
    required DateTime startsOn,
    required DateTime endsOn,
    bool isCurrent = false,
  }) async {
    if (institutionId.isEmpty || name.trim().isEmpty) {
      throw const AppException('Academic session name is required.');
    }
    if (endsOn.isBefore(startsOn)) {
      throw const AppException(
        'Session end date must be on or after the start date.',
      );
    }

    try {
      final sessionId = await _client.rpc(
        'create_uot_academic_session',
        params: {
          'p_name': name.trim(),
          'p_starts_on': startsOn.toIso8601String().split('T').first,
          'p_ends_on': endsOn.toIso8601String().split('T').first,
          'p_is_current': isCurrent,
        },
      );
      final row = await _client
          .from('academic_sessions')
          .select()
          .eq('id', sessionId as String)
          .single();
      return AcademicSession.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AcademicProgram> createProgram({
    required String institutionId,
    required String departmentId,
    required String name,
    String? level,
  }) async {
    if (departmentId.isEmpty || name.trim().isEmpty) {
      throw const AppException('Choose a department and enter a program name.');
    }

    try {
      final row = await _client
          .from('academic_programs')
          .insert({
            'institution_id': institutionId,
            'department_id': departmentId,
            'name': name.trim(),
            'level': _emptyToNull(level),
          })
          .select()
          .single();
      return AcademicProgram.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AcademicSemester> createSemester({
    required String institutionId,
    required String departmentId,
    required String programId,
    required int semesterNumber,
    required String name,
  }) async {
    if (departmentId.isEmpty || programId.isEmpty || name.trim().isEmpty) {
      throw const AppException(
        'Choose a department and program, and enter a semester name.',
      );
    }
    if (semesterNumber < 1 || semesterNumber > 16) {
      throw const AppException('Semester number must be between 1 and 16.');
    }

    try {
      final row = await _client
          .from('academic_semesters')
          .insert({
            'institution_id': institutionId,
            'department_id': departmentId,
            'program_id': programId,
            'semester_number': semesterNumber,
            'name': name.trim(),
          })
          .select()
          .single();
      return AcademicSemester.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AcademicClass> createClass({
    required String institutionId,
    required String programId,
    required String sessionId,
    required String semesterId,
    required String name,
    String? section,
  }) async {
    if (programId.isEmpty ||
        sessionId.isEmpty ||
        semesterId.isEmpty ||
        name.trim().isEmpty) {
      throw const AppException(
        'Semester, session, and class name are required.',
      );
    }

    try {
      final row = await _client
          .from('academic_classes')
          .insert({
            'institution_id': institutionId,
            'program_id': programId,
            'session_id': sessionId,
            'semester_id': semesterId,
            'name': name.trim(),
            'section': _emptyToNull(section),
          })
          .select()
          .single();
      return AcademicClass.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<Subject> createSubject({
    required String institutionId,
    required String departmentId,
    required String code,
    required String name,
  }) async {
    if (code.trim().isEmpty || name.trim().isEmpty) {
      throw const AppException('Subject code and name are required.');
    }

    try {
      final row = await _client
          .from('subjects')
          .insert({
            'institution_id': institutionId,
            'department_id': departmentId,
            'code': code.trim().toUpperCase(),
            'name': name.trim(),
          })
          .select()
          .single();
      return Subject.fromMap(row);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<int> importRosterCsv({
    required String institutionId,
    required String csvText,
  }) async {
    final rows = parseCsvRows(csvText);
    if (rows.isEmpty) {
      return 0;
    }

    final overview = await fetchOverview(institutionId);
    final sessionMap = {
      for (final session in overview.sessions)
        session.name.toLowerCase(): session,
    };
    final programMap = {
      for (final program in overview.programs)
        program.name.toLowerCase(): program,
    };
    final classMap = {
      for (final academicClass in overview.classes)
        academicClass.name.toLowerCase(): academicClass,
    };

    var inserted = 0;
    for (final row in rows) {
      final trimmedStudentNumber = row.studentNumber.trim();
      final trimmedFullName = row.fullName.trim();
      if (trimmedStudentNumber.isEmpty || trimmedFullName.isEmpty) {
        continue;
      }

      final sessionName = row.sessionName?.trim();
      final sessionId = sessionName == null || sessionName.isEmpty
          ? null
          : sessionMap[sessionName.toLowerCase()]?.id;
      if (sessionId == null) {
        throw AppException(
          'Roster import failed: session "${row.sessionName}" was not found. Create it first.',
        );
      }

      final programName = row.programName?.trim();
      final programId = programName == null || programName.isEmpty
          ? null
          : programMap[programName.toLowerCase()]?.id;
      final className = row.className?.trim();
      final classId = className == null || className.isEmpty
          ? null
          : classMap[className.toLowerCase()]?.id;

      await _client.from('student_roster_entries').insert({
        'institution_id': institutionId,
        'student_number': trimmedStudentNumber,
        'full_name': trimmedFullName,
        'program_id': programId,
        'class_id': classId,
        'session_id': sessionId,
        'is_active': true,
      });
      inserted += 1;
    }

    return inserted;
  }

  static List<String> _splitCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    values.add(buffer.toString());
    return values;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
