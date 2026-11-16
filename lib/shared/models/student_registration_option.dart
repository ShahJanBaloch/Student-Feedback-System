class StudentRegistrationOption {
  const StudentRegistrationOption({
    required this.departmentId,
    required this.departmentName,
    required this.programId,
    required this.programName,
    required this.semesterId,
    required this.semesterNumber,
    required this.semesterName,
  });

  final String departmentId;
  final String departmentName;
  final String programId;
  final String programName;
  final String semesterId;
  final int semesterNumber;
  final String semesterName;

  factory StudentRegistrationOption.fromMap(Map<String, dynamic> map) {
    return StudentRegistrationOption(
      departmentId: map['department_id'] as String,
      departmentName: map['department_name'] as String,
      programId: map['program_id'] as String,
      programName: map['program_name'] as String,
      semesterId: map['semester_id'] as String,
      semesterNumber: map['semester_number'] as int,
      semesterName: map['semester_name'] as String,
    );
  }
}
