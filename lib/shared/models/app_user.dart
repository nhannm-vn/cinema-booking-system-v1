/// User role in the cinema booking system.
/// References: BUSINESS_RULES.md Section 2 & TECH_STACK.md Section 4
enum UserRole {
  customer,
  staff,
  manager,
  admin;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String get dbValue => name;
}

/// Profile model mapped from PostgreSQL `profiles` table.
/// References: PROJECT_STRUCTURE.md Section 3 & TECH_STACK.md Section 4
class AppUser {
  final String id; // uuid matches auth.users.id
  final String fullName;
  final String? phone;
  final UserRole role;
  final String? cinemaId; // e.g. "cn_q1" for staff/manager
  final bool isLocked;
  final String? email;

  const AppUser({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.cinemaId,
    this.isLocked = false,
    this.email,
  });

  bool get isCustomer => role == UserRole.customer;
  bool get isStaff => role == UserRole.staff;
  bool get isManager => role == UserRole.manager;
  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(Map<String, dynamic> map, {String? email}) {
    return AppUser(
      id: map['id'] as String,
      fullName: (map['full_name'] as String?) ?? '',
      phone: map['phone'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      cinemaId: map['cinema_id'] as String?,
      isLocked: (map['is_locked'] as bool?) ?? false,
      email: email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role.dbValue,
      'cinema_id': cinemaId,
      'is_locked': isLocked,
    };
  }

  AppUser copyWith({
    String? id,
    String? fullName,
    String? phone,
    UserRole? role,
    String? cinemaId,
    bool? isLocked,
    String? email,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      cinemaId: cinemaId ?? this.cinemaId,
      isLocked: isLocked ?? this.isLocked,
      email: email ?? this.email,
    );
  }
}
