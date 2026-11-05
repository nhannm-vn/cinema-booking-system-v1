import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_model.dart';

/// Repository for Food items query.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 9
class FoodRepository {
  final SupabaseClient _supabase;

  FoodRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch foods available for a given cinema: món của rạp + món toàn hệ thống (cinema_id null).
  Future<List<FoodModel>> getFoodsByCinema(String cinemaId) async {
    final response = await _supabase
        .from('foods')
        .select()
        .or('cinema_id.eq.$cinemaId,cinema_id.is.null')
        .order('price');

    return (response as List).map((f) => FoodModel.fromMap(f)).toList();
  }
}
