/// Movie model mapping from PostgreSQL `movies` table.
/// References: TECH_STACK.md Section 4 & BUSINESS_RULES.md Section 3.1
class MovieModel {
  final String id;
  final String title;
  final List<String> genres;
  final int durationMin;
  final String ageRating; // P, T13, T16, T18
  final DateTime releaseDate;
  final bool isActive;
  final String? description;
  final String? director;
  final List<String> castMembers;
  final String? posterUrl;
  final String? backdropUrl;
  final String? trailerUrl;

  const MovieModel({
    required this.id,
    required this.title,
    required this.genres,
    required this.durationMin,
    required this.ageRating,
    required this.releaseDate,
    this.isActive = true,
    this.description,
    this.director,
    this.castMembers = const [],
    this.posterUrl,
    this.backdropUrl,
    this.trailerUrl,
  });

  /// Đang chiếu: isActive == true và releaseDate <= now
  bool get isNowShowing => isActive && !releaseDate.isAfter(DateTime.now());

  /// Sắp chiếu: isActive == true và releaseDate > now
  bool get isUpcoming => isActive && releaseDate.isAfter(DateTime.now());

  String get genresText => genres.join(', ');

  factory MovieModel.fromMap(Map<String, dynamic> map) {
    return MovieModel(
      id: map['id'] as String,
      title: map['title'] as String,
      genres: List<String>.from(map['genres'] ?? []),
      durationMin: map['duration_min'] as int,
      ageRating: (map['age_rating'] as String?) ?? 'P',
      releaseDate: DateTime.parse(map['release_date'] as String),
      isActive: (map['is_active'] as bool?) ?? true,
      description: map['description'] as String?,
      director: map['director'] as String?,
      castMembers: List<String>.from(map['cast_members'] ?? []),
      posterUrl: map['poster_url'] as String?,
      backdropUrl: map['backdrop_url'] as String?,
      trailerUrl: map['trailer_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'genres': genres,
      'duration_min': durationMin,
      'age_rating': ageRating,
      'release_date': releaseDate.toIso8601String().split('T').first,
      'is_active': isActive,
      'description': description,
      'director': director,
      'cast_members': castMembers,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'trailer_url': trailerUrl,
    };
  }
}
