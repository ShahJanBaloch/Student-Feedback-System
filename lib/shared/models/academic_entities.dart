import 'package:intl/intl.dart';

class Department {
  const Department({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.code,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String institutionId;
  final String name;
  final String? code;
  final bool isActive;
  final DateTime createdAt;

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class AcademicSession {
  const AcademicSession({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.startsOn,
    required this.endsOn,
    required this.isCurrent,
  });

  final String id;
  final String institutionId;
  final String name;
  final DateTime startsOn;
  final DateTime endsOn;
  final bool isCurrent;

  factory AcademicSession.fromMap(Map<String, dynamic> map) {
    return AcademicSession(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      name: map['name'] as String,
      startsOn: DateTime.parse(map['starts_on'] as String),
      endsOn: DateTime.parse(map['ends_on'] as String),
      isCurrent: (map['is_current'] as bool?) ?? false,
    );
  }

  String get displayRange => '${DateFormat('MMM d, yyyy').format(startsOn)} - ${DateFormat('MMM d, yyyy').format(endsOn)}';
}

class AcademicProgram {
  const AcademicProgram({
    required this.id,
    required this.institutionId,
    required this.departmentId,
    required this.name,
    required this.level,
    required this.isActive,
  });

  final String id;
  final String institutionId;
  final String departmentId;
  final String name;
  final String? level;
  final bool isActive;

  factory AcademicProgram.fromMap(Map<String, dynamic> map) {
    return AcademicProgram(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      departmentId: map['department_id'] as String,
      name: map['name'] as String,
      level: map['level'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

class AcademicSemester {
  const AcademicSemester({
    required this.id,
    required this.institutionId,
    required this.departmentId,
    required this.programId,
    required this.semesterNumber,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String institutionId;
  final String departmentId;
  final String programId;
  final int semesterNumber;
  final String name;
  final bool isActive;

  factory AcademicSemester.fromMap(Map<String, dynamic> map) {
    return AcademicSemester(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      departmentId: map['department_id'] as String,
      programId: map['program_id'] as String,
      semesterNumber: map['semester_number'] as int,
      name: map['name'] as String,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

class AcademicClass {
  const AcademicClass({
    required this.id,
    required this.institutionId,
    required this.programId,
    required this.sessionId,
    required this.name,
    required this.section,
  });

  final String id;
  final String institutionId;
  final String programId;
  final String sessionId;
  final String name;
  final String? section;

  factory AcademicClass.fromMap(Map<String, dynamic> map) {
    return AcademicClass(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      programId: map['program_id'] as String,
      sessionId: map['session_id'] as String,
      name: map['name'] as String,
      section: map['section'] as String?,
    );
  }

  String get label => section == null || section!.trim().isEmpty ? name : '$name (${section!})';
}

class Subject {
  const Subject({
    required this.id,
    required this.institutionId,
    required this.departmentId,
    required this.code,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String institutionId;
  final String departmentId;
  final String code;
  final String name;
  final bool isActive;

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      departmentId: map['department_id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

class TeacherProfile {
  const TeacherProfile({
    required this.id,
    required this.institutionId,
    required this.userId,
    required this.employeeCode,
    required this.designation,
    required this.isActive,
  });

  final String id;
  final String institutionId;
  final String userId;
  final String? employeeCode;
  final String? designation;
  final bool isActive;

  factory TeacherProfile.fromMap(Map<String, dynamic> map) {
    return TeacherProfile(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      userId: map['user_id'] as String,
      employeeCode: map['employee_code'] as String?,
      designation: map['designation'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

class TeacherAssignment {
  const TeacherAssignment({
    required this.id,
    required this.institutionId,
    required this.teacherProfileId,
    required this.subjectId,
    required this.classId,
    required this.sessionId,
  });

  final String id;
  final String institutionId;
  final String teacherProfileId;
  final String subjectId;
  final String classId;
  final String sessionId;

  factory TeacherAssignment.fromMap(Map<String, dynamic> map) {
    return TeacherAssignment(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      teacherProfileId: map['teacher_profile_id'] as String,
      subjectId: map['subject_id'] as String,
      classId: map['class_id'] as String,
      sessionId: map['session_id'] as String,
    );
  }
}

class RosterEntry {
  const RosterEntry({
    required this.id,
    required this.institutionId,
    required this.studentNumber,
    required this.fullName,
    this.classId,
    this.programId,
    this.sessionId,
    this.matchedUserId,
    required this.isActive,
  });

  final String id;
  final String institutionId;
  final String studentNumber;
  final String fullName;
  final String? classId;
  final String? programId;
  final String? sessionId;
  final String? matchedUserId;
  final bool isActive;

  factory RosterEntry.fromMap(Map<String, dynamic> map) {
    return RosterEntry(
      id: map['id'] as String,
      institutionId: map['institution_id'] as String,
      studentNumber: map['student_number'] as String,
      fullName: map['full_name'] as String,
      classId: map['class_id'] as String?,
      programId: map['program_id'] as String?,
      sessionId: map['session_id'] as String?,
      matchedUserId: map['matched_user_id'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

class AcademicOverview {
  const AcademicOverview({
    required this.departments,
    required this.sessions,
    required this.programs,
    required this.semesters,
    required this.classes,
    required this.subjects,
    required this.teacherProfiles,
    required this.teacherAssignments,
    required this.rosterEntries,
  });

  final List<Department> departments;
  final List<AcademicSession> sessions;
  final List<AcademicProgram> programs;
  final List<AcademicSemester> semesters;
  final List<AcademicClass> classes;
  final List<Subject> subjects;
  final List<TeacherProfile> teacherProfiles;
  final List<TeacherAssignment> teacherAssignments;
  final List<RosterEntry> rosterEntries;
}

class RosterImportRow {
  const RosterImportRow({
    required this.studentNumber,
    required this.fullName,
    this.programName,
    this.className,
    this.sessionName,
  });

  final String studentNumber;
  final String fullName;
  final String? programName;
  final String? className;
  final String? sessionName;
}
