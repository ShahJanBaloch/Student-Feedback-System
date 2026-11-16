class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
    this.phone,
    this.locale = 'en',
  });

  final String id;
  final String? email;
  final String fullName;
  final String? phone;
  final String locale;
  final bool isActive;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: (map['full_name'] as String?) ?? '',
      phone: map['phone'] as String?,
      locale: (map['locale'] as String?) ?? 'en',
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}
