/// Cinema model mapping from PostgreSQL `cinemas` table.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 3.2
class CinemaModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final double lat;
  final double lng;
  final String? openingHours;
  final bool isActive;
  final double? distanceKm;

  const CinemaModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    required this.lat,
    required this.lng,
    this.openingHours,
    this.isActive = true,
    this.distanceKm,
  });

  CinemaModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    double? lat,
    double? lng,
    String? openingHours,
    bool? isActive,
    double? distanceKm,
  }) {
    return CinemaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      openingHours: openingHours ?? this.openingHours,
      isActive: isActive ?? this.isActive,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  factory CinemaModel.fromMap(Map<String, dynamic> map, {double? distanceKm}) {
    return CinemaModel(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String?,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      openingHours: map['opening_hours'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      distanceKm: distanceKm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'opening_hours': openingHours,
      'is_active': isActive,
    };
  }
}
