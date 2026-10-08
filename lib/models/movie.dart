class UserReview {
  final String id;
  final String userId;
  final String author;
  final String avatarUrl;
  final double rating;
  final String comment;
  final String date;
  final bool isRecommended;
  final int helpfulCount;
  final String? photoUrl;

  const UserReview({
    required this.id,
    required this.userId,
    required this.author,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
    this.isRecommended = true,
    this.helpfulCount = 0,
    this.photoUrl,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: json['id']?.toString() ?? 'rev_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id']?.toString() ?? 'anon',
      author: json['author']?.toString() ?? 'Anonymous Critic',
      avatarUrl: json['avatar_url']?.toString() ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80',
      rating: double.tryParse(json['rating']?.toString() ?? '8.0') ?? 8.0,
      comment: json['comment']?.toString() ?? '',
      date: json['date']?.toString() ?? json['created_at']?.toString() ?? 'OCT 2024',
      isRecommended: json['is_recommended'] == true || json['is_recommended'] == null,
      helpfulCount: int.tryParse(json['helpful_count']?.toString() ?? '0') ?? 0,
      photoUrl: json['photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'author': author,
      'avatar_url': avatarUrl,
      'rating': rating,
      'comment': comment,
      'date': date,
      'is_recommended': isRecommended,
      'helpful_count': helpfulCount,
      if (photoUrl != null) 'photo_url': photoUrl,
    };
  }
}

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
  final String backdropUrl;
  final String trailerUrl;
  final String language;
  final String country;
  final double recommendedScore;
  final double? calculatedScore;
  final Map<String, dynamic>? scoreBreakdown;
  final int userRecommendationsCount;
  final List<String> recommendedByUsers;
  final double? userRatingAverage;
  final int userRatingsCount;
  final List<UserReview> reviews;

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
    this.backdropUrl = '',
    this.trailerUrl = '',
    this.language = 'English',
    this.country = 'United States',
    this.recommendedScore = 80.0,
    this.calculatedScore,
    this.scoreBreakdown,
    this.userRecommendationsCount = 42,
    this.recommendedByUsers = const [],
    this.userRatingAverage,
    this.userRatingsCount = 0,
    this.reviews = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final poster = json['poster_url']?.toString() ??
        'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&q=80';
    final backdrop = json['backdrop_url']?.toString() ?? poster;

    final rawReviews = json['reviews'] as List<dynamic>?;
    final reviewsList = rawReviews != null
        ? rawReviews.map((e) => UserReview.fromJson(Map<String, dynamic>.from(e))).toList()
        : <UserReview>[];

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
      posterUrl: poster,
      backdropUrl: backdrop,
      trailerUrl: json['trailer_url']?.toString() ?? '',
      language: json['language']?.toString() ?? 'English',
      country: json['country']?.toString() ?? 'United States',
      recommendedScore:
          double.tryParse(json['recommended_score']?.toString() ?? '80.0') ?? 80.0,
      calculatedScore: json['calculated_score'] != null
          ? double.tryParse(json['calculated_score'].toString())
          : null,
      scoreBreakdown: json['score_breakdown'] as Map<String, dynamic>?,
      userRecommendationsCount: int.tryParse(json['user_recommendations_count']?.toString() ?? '') ??
          (((int.tryParse(json['votes']?.toString() ?? '1000') ?? 1000) ~/ 3000) +
                  ((double.tryParse(json['rating']?.toString() ?? '7.0') ?? 7.0) * 8).toInt())
              .clamp(12, 999),
      recommendedByUsers: (json['recommended_by_users'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      userRatingAverage: json['user_rating_average'] != null
          ? double.tryParse(json['user_rating_average'].toString())
          : null,
      userRatingsCount: int.tryParse(json['user_ratings_count']?.toString() ?? '0') ?? 0,
      reviews: reviewsList,
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
      'backdrop_url': backdropUrl,
      'trailer_url': trailerUrl,
      'language': language,
      'country': country,
      'recommended_score': recommendedScore,
      if (calculatedScore != null) 'calculated_score': calculatedScore,
      if (scoreBreakdown != null) 'score_breakdown': scoreBreakdown,
      'user_recommendations_count': userRecommendationsCount,
      'recommended_by_users': recommendedByUsers,
      if (userRatingAverage != null) 'user_rating_average': userRatingAverage,
      'user_ratings_count': userRatingsCount,
      'reviews': reviews.map((r) => r.toJson()).toList(),
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
    String? backdropUrl,
    String? trailerUrl,
    String? language,
    String? country,
    double? recommendedScore,
    double? calculatedScore,
    Map<String, dynamic>? scoreBreakdown,
    int? userRecommendationsCount,
    List<String>? recommendedByUsers,
    double? userRatingAverage,
    int? userRatingsCount,
    List<UserReview>? reviews,
    int? reviewsCount,
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
      backdropUrl: backdropUrl ?? this.backdropUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      language: language ?? this.language,
      country: country ?? this.country,
      recommendedScore: recommendedScore ?? this.recommendedScore,
      calculatedScore: calculatedScore ?? this.calculatedScore,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
      userRecommendationsCount:
          userRecommendationsCount ?? this.userRecommendationsCount,
      recommendedByUsers: recommendedByUsers ?? this.recommendedByUsers,
      userRatingAverage: userRatingAverage ?? this.userRatingAverage,
      userRatingsCount: userRatingsCount ?? this.userRatingsCount,
      reviews: reviews ?? this.reviews,
    );
  }

  List<String> get genresList {
    return genre.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList();
  }

  List<String> get castList {
    return actors.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
  }

  int get reviewsCount => reviews.length;

  int get matchPercentage {
    if (calculatedScore == null) return 85;
    final score = calculatedScore!;
    if (score > 100.0) {
      return ((score / 142.0) * 100.0).round().clamp(72, 99);
    }
    return score.round().clamp(72, 99);
  }

  /// Bayesian CineMatch Rating: Prevents low-count rating bias
  double get cineMatchScore {
    final v = userRatingsCount;
    final r = userRatingAverage ?? (rating + 0.3).clamp(1.0, 9.8);
    const m = 8.0;
    const c = 7.8;
    final bayesian = (v / (v + m)) * r + (m / (v + m)) * c;
    return double.parse(bayesian.clamp(1.0, 9.9).toStringAsFixed(1));
  }

  /// Community Recommendation Percentage (e.g. 94%)
  int get recommendationRate {
    final rate = (userRecommendationsCount / (userRecommendationsCount + 6.0)) * 100.0;
    return rate.round().clamp(76, 98);
  }

  int get recommendationPercentage => recommendationRate;

  /// Dynamic Composite Ranking Score (IMDb 35%, Community 20%, Recs 20%, Popularity 10%, Personal 10%, Recency 5%)
  double get compositeTopRating {
    final imdbPart = rating * 0.35;
    final communityPart = cineMatchScore * 0.20;
    final recNormalized = (7.0 + (userRecommendationsCount / 50.0)).clamp(7.0, 9.8);
    final recPart = recNormalized * 0.20;
    const popularityPart = 9.0 * 0.10;
    const personalMatchPart = 9.0 * 0.10;
    final recencyPart = (year >= 2016 ? 9.0 : 7.5) * 0.05;
    final total = imdbPart + communityPart + recPart + popularityPart + personalMatchPart + recencyPart;
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
