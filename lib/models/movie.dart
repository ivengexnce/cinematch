class Movie {
  final String id;
  final int? rank;
  final String title;
  final String genre;
  final String mood;
  final String director;
  final String actors;
  final int year;
  final int runtime;
  final double rating;
  final String votes;
  final int metascore;
  final String synopsis;
  final String posterUrl;
  final double recommendedScore;
  final double? calculatedScore;
  final Map<String, dynamic>? scoreBreakdown;
  final int userRecommendationsCount;
  final List<String> recommendedByUsers;
  final double? userRatingAverage;
  final int userRatingsCount;

  const Movie({
    required this.id,
    this.rank,
    required this.title,
    required this.genre,
    this.mood = 'Curious',
    this.director = 'Unknown',
    this.actors = 'Unknown',
    this.year = 2024,
    this.runtime = 120,
    this.rating = 7.5,
    this.votes = '0',
    this.metascore = 70,
    required this.synopsis,
    required this.posterUrl,
    this.recommendedScore = 80.0,
    this.calculatedScore,
    this.scoreBreakdown,
    this.userRecommendationsCount = 42,
    this.recommendedByUsers = const [],
    this.userRatingAverage,
    this.userRatingsCount = 0,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      rank: json['rank'] != null ? int.tryParse(json['rank'].toString()) : null,
      title: json['title']?.toString() ?? 'Untitled',
      genre: json['genre']?.toString() ?? 'General',
      mood: json['mood']?.toString() ?? 'Curious',
      director: json['director']?.toString() ?? 'Unknown',
      actors: json['actors']?.toString() ?? 'Unknown',
      year: int.tryParse(json['year']?.toString() ?? '2024') ?? 2024,
      runtime: int.tryParse(json['runtime']?.toString() ?? '120') ?? 120,
      rating: double.tryParse(json['rating']?.toString() ?? '7.0') ?? 7.0,
      votes: json['votes']?.toString() ?? '0',
      metascore: int.tryParse(json['metascore']?.toString() ?? '70') ?? 70,
      synopsis: json['synopsis']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString() ??
          'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&q=80',
      recommendedScore:
          double.tryParse(json['recommended_score']?.toString() ?? '80.0') ??
              80.0,
      calculatedScore: json['calculated_score'] != null
          ? double.tryParse(json['calculated_score'].toString())
          : null,
      scoreBreakdown: json['score_breakdown'] as Map<String, dynamic>?,
      userRecommendationsCount: int.tryParse(json['user_recommendations_count']?.toString() ?? '') ??
          (((int.tryParse(json['votes']?.toString() ?? '1000') ?? 1000) ~/ 3000) +
                  ((double.tryParse(json['rating']?.toString() ?? '7.0') ?? 7.0) * 8).toInt())
              .clamp(12, 999),
      recommendedByUsers: (json['recommended_by_users'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      userRatingAverage: json['user_rating_average'] != null
          ? double.tryParse(json['user_rating_average'].toString())
          : null,
      userRatingsCount: int.tryParse(json['user_ratings_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (rank != null) 'rank': rank,
      'title': title,
      'genre': genre,
      'mood': mood,
      'director': director,
      'actors': actors,
      'year': year,
      'runtime': runtime,
      'rating': rating,
      'votes': votes,
      'metascore': metascore,
      'synopsis': synopsis,
      'poster_url': posterUrl,
      'recommended_score': recommendedScore,
      if (calculatedScore != null) 'calculated_score': calculatedScore,
      if (scoreBreakdown != null) 'score_breakdown': scoreBreakdown,
      'user_recommendations_count': userRecommendationsCount,
      'recommended_by_users': recommendedByUsers,
      if (userRatingAverage != null) 'user_rating_average': userRatingAverage,
      'user_ratings_count': userRatingsCount,
    };
  }

  Movie copyWith({
    String? id,
    int? rank,
    String? title,
    String? genre,
    String? mood,
    String? director,
    String? actors,
    int? year,
    int? runtime,
    double? rating,
    String? votes,
    int? metascore,
    String? synopsis,
    String? posterUrl,
    double? recommendedScore,
    double? calculatedScore,
    Map<String, dynamic>? scoreBreakdown,
    int? userRecommendationsCount,
    List<String>? recommendedByUsers,
    double? userRatingAverage,
    int? userRatingsCount,
  }) {
    return Movie(
      id: id ?? this.id,
      rank: rank ?? this.rank,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      mood: mood ?? this.mood,
      director: director ?? this.director,
      actors: actors ?? this.actors,
      year: year ?? this.year,
      runtime: runtime ?? this.runtime,
      rating: rating ?? this.rating,
      votes: votes ?? this.votes,
      metascore: metascore ?? this.metascore,
      synopsis: synopsis ?? this.synopsis,
      posterUrl: posterUrl ?? this.posterUrl,
      recommendedScore: recommendedScore ?? this.recommendedScore,
      calculatedScore: calculatedScore ?? this.calculatedScore,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
      userRecommendationsCount: userRecommendationsCount ?? this.userRecommendationsCount,
      recommendedByUsers: recommendedByUsers ?? this.recommendedByUsers,
      userRatingAverage: userRatingAverage ?? this.userRatingAverage,
      userRatingsCount: userRatingsCount ?? this.userRatingsCount,
    );
  }

  List<String> get genresList {
    return genre.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList();
  }

  int get matchPercentage {
    if (calculatedScore == null) return 85;
    final score = calculatedScore!;
    if (score > 100.0) {
      return ((score / 142.0) * 100.0).round().clamp(72, 99);
    }
    return score.round().clamp(72, 99);
  }

  double get compositeTopRating {
    final imdbPart = rating * 0.60;
    final communityPart = (userRatingAverage ?? rating) * 0.25;
    final recBonus = (6.0 + (userRecommendationsCount / 50.0).clamp(0.0, 4.0)) * 0.15;
    final total = imdbPart + communityPart + recBonus;
    return double.parse(total.clamp(1.0, 10.0).toStringAsFixed(1));
  }

  bool isRecommendedBy(String userId) => recommendedByUsers.contains(userId);

  String get formattedRuntime {
    final hours = runtime ~/ 60;
    final mins = runtime % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}
