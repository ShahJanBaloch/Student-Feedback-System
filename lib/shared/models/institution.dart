import '../../core/constants/institution_enums.dart';

class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.institutionType,
    required this.status,
    required this.province,
    required this.minResponseThreshold,
    this.district,
    this.city,
    this.address,
    this.contactEmail,
    this.createdBy,
  });

  final String id;
  final String name;
  final String shortCode;
  final InstitutionType institutionType;
  final InstitutionStatus status;
  final String province;
  final int minResponseThreshold;
  final String? district;
  final String? city;
  final String? address;
  final String? contactEmail;
  final String? createdBy;

  factory Institution.fromMap(Map<String, dynamic> map) {
    return Institution(
      id: map['id'] as String,
      name: map['name'] as String,
      shortCode: map['short_code'] as String,
      institutionType: InstitutionType.parse(map['institution_type'] as String),
      status: InstitutionStatus.parse(map['status'] as String),
      province: (map['province'] as String?) ?? 'Balochistan',
      minResponseThreshold: (map['min_response_threshold'] as int?) ?? 5,
      district: map['district'] as String?,
      city: map['city'] as String?,
      address: map['address'] as String?,
      contactEmail: map['contact_email'] as String?,
      createdBy: map['created_by'] as String?,
    );
  }
}
