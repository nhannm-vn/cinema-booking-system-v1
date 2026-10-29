import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cinema_model.dart';
import 'location_service.dart';

/// Repository for Cinemas.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 3.2
class CinemaRepository {
  final SupabaseClient _supabase;

  CinemaRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch all active cinemas with calculated distances if user position is provided.
  Future<List<CinemaModel>> getActiveCinemas({Position? userPosition}) async {
    final response = await _supabase
        .from('cinemas')
        .select()
        .eq('is_active', true)
        .order('name');

    final cinemas = (response as List).map((c) {
      double? distance;
      if (userPosition != null) {
        distance = LocationService.calculateDistanceKm(
          startLatitude: userPosition.latitude,
          startLongitude: userPosition.longitude,
          endLatitude: (c['lat'] as num).toDouble(),
          endLongitude: (c['lng'] as num).toDouble(),
        );
      }
      return CinemaModel.fromMap(c, distanceKm: distance);
    }).toList();

    if (userPosition != null) {
      cinemas.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    }

    return cinemas;
  }

  /// Get cinema by ID.
  Future<CinemaModel?> getCinemaById(String id) async {
    final response = await _supabase
        .from('cinemas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return CinemaModel.fromMap(response);
  }
}
