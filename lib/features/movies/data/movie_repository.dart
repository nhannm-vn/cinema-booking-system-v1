import 'package:supabase_flutter/supabase_flutter.dart';
import 'movie_model.dart';

/// Repository for Movies operations.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 3.1
class MovieRepository {
  final SupabaseClient _supabase;

  MovieRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetch all active movies.
  Future<List<MovieModel>> getActiveMovies() async {
    final response = await _supabase
        .from('movies')
        .select()
        .eq('is_active', true)
        .order('release_date', ascending: true);

    return (response as List).map((m) => MovieModel.fromMap(m)).toList();
  }

  /// Get movie by ID.
  Future<MovieModel?> getMovieById(String id) async {
    final response = await _supabase
        .from('movies')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return MovieModel.fromMap(response);
  }
}
