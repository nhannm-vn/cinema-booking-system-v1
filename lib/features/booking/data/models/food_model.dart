/// Food model mapping from PostgreSQL `foods` table.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 9
class FoodModel {
  final String id;
  final String cinemaId;
  final String name;
  final String category; // 'combo', 'popcorn', 'drink', 'snack'
  final int price;
  final bool isAvailable;
  final String? imageUrl;
  final String? description;
  final int quantity; // Selected count in cart

  const FoodModel({
    required this.id,
    required this.cinemaId,
    required this.name,
    required this.category,
    required this.price,
    this.isAvailable = true,
    this.imageUrl,
    this.description,
    this.quantity = 0,
  });

  FoodModel copyWith({
    String? id,
    String? cinemaId,
    String? name,
    String? category,
    int? price,
    bool? isAvailable,
    String? imageUrl,
    String? description,
    int? quantity,
  }) {
    return FoodModel(
      id: id ?? this.id,
      cinemaId: cinemaId ?? this.cinemaId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

  factory FoodModel.fromMap(Map<String, dynamic> map, {int quantity = 0}) {
    return FoodModel(
      id: map['id'] as String,
      cinemaId: map['cinema_id'] as String,
      name: map['name'] as String,
      category: (map['category'] as String?) ?? 'combo',
      price: map['price'] as int,
      isAvailable: (map['is_available'] as bool?) ?? true,
      imageUrl: map['image_url'] as String?,
      description: map['description'] as String?,
      quantity: quantity,
    );
  }

  Map<String, dynamic> toBookingJson() {
    return {
      'food_id': id,
      'name': name,
      'qty': quantity,
      'unit_price': price,
    };
  }
}
