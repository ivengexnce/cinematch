import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _ensureLocalLoaded();
  }

  String _baseUrl = 'http://127.0.0.1:8000';
  bool forceOffline = false;
  bool isUsingOfflineFallback = false;

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    _baseUrl = trimmed;
  }

  // Local in-memory cache populated from asset seed
  List<Movie> _localCatalog = [];
  bool _localLoaded = false;
  final Map<String, List<Movie>> _recsCache = {};

  Future<void> _ensureLocalLoaded() async {
    if (_localLoaded && _localCatalog.isNotEmpty) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/movies_seed.json');
      final List<dynamic> decoded = json.decode(jsonStr);
      _localCatalog = decoded.map((e) => Movie.fromJson(e)).toList();
      _localLoaded = true;
      debugPrint('Loaded ${_localCatalog.length} seed movies into memory.');
    } catch (e) {
      debugPrint('Error loading seed movies: $e');
      _localCatalog = [];
    }
  }

  // Synchronous immediate recommendations from memory (0ms delay)
  List<Movie> getImmediateRecommendations({String? mood, String? genre, int limit = 12}) {
    final key = '$mood-$genre-$limit';
    if (_recsCache.containsKey(key)) return _recsCache[key]!;
    if (_localCatalog.isEmpty) return [];

    final targetMood = mood?.toLowerCase().trim();
    final targetGenre = genre?.toLowerCase().trim();

    final scored = _localCatalog.map((m) {
      final baseScore = m.recommendedScore;
      var deltaMood = 0.0;
      var deltaGenre = 0.0;
      final movieMood = m.mood.toLowerCase();
      final movieGenre = m.genre.toLowerCase();

      if (targetMood != null && targetMood != 'all' && (targetMood.contains(movieMood) || movieMood.contains(targetMood))) {
        deltaMood = 15.0;
      }
      if (targetGenre != null && targetGenre != 'all' && movieGenre.contains(targetGenre)) {
        deltaGenre = 10.0;
      }

      final ratingBonus = m.rating * 2.0;
      final rawScore = baseScore + deltaMood + deltaGenre + ratingBonus;
      final normScore = ((rawScore / 142.0) * 100.0).clamp(72.0, 99.0);

      return m.copyWith(
        calculatedScore: double.parse(normScore.toStringAsFixed(1)),
        scoreBreakdown: {
          'base_score': baseScore,
          'mood_bonus': deltaMood,
          'genre_bonus': deltaGenre,
          'rating_bonus': double.parse(ratingBonus.toStringAsFixed(1)),
          'raw_total': double.parse(rawScore.toStringAsFixed(1)),
        },
      );
    }).toList();

    scored.sort((a, b) => (b.calculatedScore ?? 0).compareTo(a.calculatedScore ?? 0));
    final result = scored.take(limit).toList();
    _recsCache[key] = result;
    return result;
  }

  // Synchronous immediate catalog from memory (0ms delay)
  List<Movie> getImmediateCatalog({int limit = 50}) {
    if (_localCatalog.isEmpty) return [];
    final list = List<Movie>.from(_localCatalog);
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(limit).toList();
  }

  // --- Health Check ---
  Future<Map<String, dynamic>> checkHealth() async {
    if (forceOffline) {
      await _ensureLocalLoaded();
      return {
        'status': 'offline_mode',
        'service': 'CineMatch Local Seed',
        'total_movies': _localCatalog.length,
        'is_remote': false,
        'latency_ms': 0,
      };
    }
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(milliseconds: 1200));
      stopwatch.stop();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        isUsingOfflineFallback = false;
        return {
          ...data,
          'is_remote': true,
          'latency_ms': stopwatch.elapsedMilliseconds,
        };
      }
    } catch (_) {}

    await _ensureLocalLoaded();
    isUsingOfflineFallback = true;
    return {
      'status': 'fallback_offline',
      'service': 'CineMatch Offline Engine',
      'total_movies': _localCatalog.length,
      'is_remote': false,
      'latency_ms': stopwatch.elapsedMilliseconds,
    };
  }

  // --- Get Catalog Movies ---
  Future<List<Movie>> getMovies({
    String? genre,
    String? search,
    double? minRating,
    String? sortBy,
    int skip = 0,
    int limit = 50,
  }) async {
    if (!forceOffline) {
      try {
        final queryParams = <String, String>{'skip': skip.toString(), 'limit': limit.toString()};
        if (genre != null && genre.isNotEmpty && genre.toLowerCase() != 'all') queryParams['genre'] = genre;
        if (search != null && search.isNotEmpty) queryParams['search'] = search;
        if (minRating != null) queryParams['min_rating'] = minRating.toString();
        if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;

        final uri = Uri.parse('$_baseUrl/api/movies').replace(queryParameters: queryParams);
        final response = await http.get(uri).timeout(const Duration(milliseconds: 1500));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> list = data['movies'] ?? [];
          isUsingOfflineFallback = false;
          final mapped = list.map((e) => Movie.fromJson(e)).toList();
          if (search == null && (genre == null || genre.toLowerCase() == 'all') && skip == 0 && mapped.isNotEmpty) {
            _localCatalog = mapped;
          }
          return mapped;
        }
      } catch (_) {}
    }

    isUsingOfflineFallback = true;
    await _ensureLocalLoaded();
    var results = List<Movie>.from(_localCatalog);

    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase().trim();
      results = results.where((m) {
        return m.title.toLowerCase().contains(s) || m.director.toLowerCase().contains(s) || m.actors.toLowerCase().contains(s) || m.genre.toLowerCase().contains(s);
      }).toList();
    }
    if (genre != null && genre.isNotEmpty && genre.toLowerCase() != 'all') {
      final g = genre.toLowerCase().trim();
      results = results.where((m) => m.genre.toLowerCase().contains(g)).toList();
    }
    if (minRating != null) {
      results = results.where((m) => m.rating >= minRating).toList();
    }

    if (sortBy == 'top_rating') {
      results.sort((a, b) => b.compositeTopRating.compareTo(a.compositeTopRating));
    } else if (sortBy == 'recommendations') {
      results.sort((a, b) => b.userRecommendationsCount.compareTo(a.userRecommendationsCount));
    } else if (sortBy == 'year') {
      results.sort((a, b) => b.year.compareTo(a.year));
    } else if (sortBy == 'title') {
      results.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      results.sort((a, b) => b.rating.compareTo(a.rating));
    }

    final end = (skip + limit) > results.length ? results.length : (skip + limit);
    if (skip >= results.length) return [];
    return results.sublist(skip, end);
  }

  // --- Get Movie by ID ---
  Future<Movie?> getMovieById(String id) async {
    if (!forceOffline) {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/api/movies/$id')).timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) return Movie.fromJson(json.decode(response.body));
      } catch (_) {}
    }
    await _ensureLocalLoaded();
    try {
      return _localCatalog.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Recommendation Engine ---
  Future<List<Movie>> getRecommendations({String? mood, String? genre, int limit = 12}) async {
    final cacheKey = '$mood-$genre-$limit';

    if (!forceOffline) {
      try {
        final queryParams = <String, String>{'limit': limit.toString()};
        if (mood != null && mood.isNotEmpty && mood.toLowerCase() != 'all') queryParams['mood'] = mood;
        if (genre != null && genre.isNotEmpty && genre.toLowerCase() != 'all') queryParams['genre'] = genre;

        final uri = Uri.parse('$_baseUrl/api/recommendations').replace(queryParameters: queryParams);
        final response = await http.get(uri).timeout(const Duration(milliseconds: 1500));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> recs = data['recommendations'] ?? [];
          isUsingOfflineFallback = false;
          final list = recs.map((e) => Movie.fromJson(e)).toList();
          _recsCache[cacheKey] = list;
          return list;
        }
      } catch (_) {}
    }

    isUsingOfflineFallback = true;
    await _ensureLocalLoaded();
    final localRecs = getImmediateRecommendations(mood: mood, genre: genre, limit: limit);
    return localRecs;
  }

  // --- Create Movie (POST) ---
  Future<Movie> createMovie(Movie movie) async {
    if (!forceOffline) {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/api/movies'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'title': movie.title,
                'genre': movie.genre,
                'mood': movie.mood,
                'director': movie.director,
                'actors': movie.actors,
                'year': movie.year,
                'runtime': movie.runtime,
                'rating': movie.rating,
                'votes': movie.votes,
                'metascore': movie.metascore,
                'synopsis': movie.synopsis,
                'poster_url': movie.posterUrl,
              }),
            )
            .timeout(const Duration(milliseconds: 2000));

        if (response.statusCode == 201 || response.statusCode == 200) {
          final created = Movie.fromJson(json.decode(response.body));
          _localCatalog.insert(0, created);
          _recsCache.clear();
          return created;
        }
      } catch (_) {}
    }

    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final created = movie.copyWith(id: localId, rank: 1, recommendedScore: 80.0 + (movie.rating * 2.0));
    _localCatalog.insert(0, created);
    _recsCache.clear();
    return created;
  }

  // --- Update Movie (PUT) ---
  Future<Movie> updateMovie(String id, {double? rating, String? synopsis}) async {
    if (!forceOffline) {
      try {
        final body = <String, dynamic>{};
        if (rating != null) body['rating'] = rating;
        if (synopsis != null) body['synopsis'] = synopsis;

        final response = await http
            .put(Uri.parse('$_baseUrl/api/movies/$id'), headers: {'Content-Type': 'application/json'}, body: json.encode(body))
            .timeout(const Duration(milliseconds: 2000));

        if (response.statusCode == 200) {
          final updated = Movie.fromJson(json.decode(response.body));
          _updateLocalItem(updated);
          _recsCache.clear();
          return updated;
        }
      } catch (_) {}
    }

    await _ensureLocalLoaded();
    final index = _localCatalog.indexWhere((m) => m.id == id);
    if (index != -1) {
      final current = _localCatalog[index];
      final updated = current.copyWith(
        rating: rating ?? current.rating,
        synopsis: synopsis ?? current.synopsis,
        recommendedScore: rating != null ? (80.0 + (rating * 2.0)) : current.recommendedScore,
      );
      _localCatalog[index] = updated;
      _recsCache.clear();
      return updated;
    }
    throw Exception('Movie with id $id not found');
  }

  // --- Delete Movie (DELETE) ---
  Future<bool> deleteMovie(String id) async {
    if (!forceOffline) {
      try {
        final response = await http.delete(Uri.parse('$_baseUrl/api/movies/$id')).timeout(const Duration(milliseconds: 2000));
        if (response.statusCode == 200) {
          _localCatalog.removeWhere((m) => m.id == id);
          _recsCache.clear();
          return true;
        }
      } catch (_) {}
    }

    await _ensureLocalLoaded();
    _localCatalog.removeWhere((m) => m.id == id);
    _recsCache.clear();
    return true;
  }

  // --- Reset Catalog ---
  Future<void> resetCatalog() async {
    if (!forceOffline) {
      try {
        await http.post(Uri.parse('$_baseUrl/api/movies/reset')).timeout(const Duration(milliseconds: 2000));
      } catch (_) {}
    }
    _localLoaded = false;
    _recsCache.clear();
    await _ensureLocalLoaded();
  }

  // --- Multi-Attribute Similar Movies ---
  Future<List<Movie>> getSimilarMovies(String movieId, {int limit = 6}) async {
    if (!forceOffline) {
      try {
        final uri = Uri.parse('$_baseUrl/api/movies/$movieId/similar?limit=$limit');
        final response = await http.get(uri).timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> list = data['similar_movies'] ?? [];
          return list.map((e) => Movie.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    await _ensureLocalLoaded();
    Movie? target;
    for (final m in _localCatalog) {
      if (m.id == movieId) {
        target = m;
        break;
      }
    }
    if (target == null) return [];

    final targetGenres = target.genresList.map((g) => g.toLowerCase()).toSet();
    final targetDirector = target.director.toLowerCase();
    final targetMood = target.mood.toLowerCase();
    final targetYear = target.year;
    final targetRating = target.rating;

    final scored = <Map<String, dynamic>>[];
    for (final m in _localCatalog) {
      if (m.id == movieId) continue;

      final itemGenres = m.genresList.map((g) => g.toLowerCase()).toSet();
      final intersection = targetGenres.intersection(itemGenres).length;
      final union = targetGenres.union(itemGenres).length;
      final jaccard = union > 0 ? (intersection / union) : 0.0;

      final directorMatch = (targetDirector.isNotEmpty && targetDirector != 'unknown' && targetDirector == m.director.toLowerCase()) ? 1.0 : 0.0;
      final moodMatch = (targetMood == m.mood.toLowerCase()) ? 1.0 : 0.0;
      final eraSim = (1.0 - ((targetYear - m.year).abs() / 40.0)).clamp(0.0, 1.0);
      final ratingSim = (1.0 - ((targetRating - m.rating).abs() / 5.0)).clamp(0.0, 1.0);

      final similarityScore = (jaccard * 45.0) + (directorMatch * 20.0) + (moodMatch * 15.0) + (eraSim * 10.0) + (ratingSim * 10.0);
      scored.add({'movie': m, 'score': similarityScore});
    }

    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return scored.take(limit).map((e) => e['movie'] as Movie).toList();
  }

  // --- Catalog Analytics & Stats ---
  Future<Map<String, dynamic>> getCatalogStats() async {
    if (!forceOffline) {
      try {
        final response = await http.get(Uri.parse('$_baseUrl/api/stats')).timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      } catch (_) {}
    }

    await _ensureLocalLoaded();
    final total = _localCatalog.length;
    if (total == 0) return {'total_movies': 0, 'avg_rating': 0.0, 'genres': {}, 'moods': {}};

    final sumRating = _localCatalog.fold<double>(0.0, (acc, m) => acc + m.rating);
    final avgRating = double.parse((sumRating / total).toStringAsFixed(2));

    final genreMap = <String, int>{};
    final moodMap = <String, int>{};
    final decadeMap = <String, int>{};

    for (final m in _localCatalog) {
      for (final g in m.genresList) {
        genreMap[g] = (genreMap[g] ?? 0) + 1;
      }
      moodMap[m.mood] = (moodMap[m.mood] ?? 0) + 1;
      final decade = '${(m.year ~/ 10) * 10}s';
      decadeMap[decade] = (decadeMap[decade] ?? 0) + 1;
    }

    final sortedGenres = Map.fromEntries(
      genreMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return {
      'total_movies': total,
      'avg_rating': avgRating,
      'genres': sortedGenres,
      'moods': moodMap,
      'decades': decadeMap,
    };
  }

  // --- Available Genres ---
  Future<List<String>> getAvailableGenres() async {
    await _ensureLocalLoaded();
    final set = <String>{'All'};
    for (final m in _localCatalog) {
      set.addAll(m.genresList);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  // --- Toggle Community Recommendation ---
  Future<Map<String, dynamic>> toggleRecommendation(String movieId, String userId) async {
    if (!forceOffline) {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/api/movies/$movieId/recommend'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'user_id': userId}),
            )
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['movie'] != null) {
            final updatedMovie = Movie.fromJson(data['movie']);
            _updateLocalItem(updatedMovie);
          }
          return data;
        }
      } catch (_) {}
    }

    await _ensureLocalLoaded();
    final idx = _localCatalog.indexWhere((m) => m.id == movieId);
    if (idx != -1) {
      final m = _localCatalog[idx];
      final users = List<String>.from(m.recommendedByUsers);
      final isNowRecommended = !users.contains(userId);
      if (isNowRecommended) {
        users.add(userId);
      } else {
        users.remove(userId);
      }
      final newCount = isNowRecommended
          ? m.userRecommendationsCount + 1
          : (m.userRecommendationsCount > 0 ? m.userRecommendationsCount - 1 : 0);
      final updated = m.copyWith(
        recommendedByUsers: users,
        userRecommendationsCount: newCount,
      );
      _localCatalog[idx] = updated;
      return {
        'message': 'Recommendation updated locally',
        'movie_id': movieId,
        'is_recommended': isNowRecommended,
        'user_recommendations_count': newCount,
        'movie': updated.toJson(),
      };
    }
    return {'is_recommended': false, 'user_recommendations_count': 0};
  }

  // --- Submit User Rating ---
  Future<Map<String, dynamic>> submitUserRating(String movieId, String userId, double rating) async {
    if (!forceOffline) {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/api/movies/$movieId/rate'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'movie_id': movieId, 'user_id': userId, 'rating': rating}),
            )
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['movie'] != null) {
            final updatedMovie = Movie.fromJson(data['movie']);
            _updateLocalItem(updatedMovie);
          }
          return data;
        }
      } catch (_) {}
    }

    await _ensureLocalLoaded();
    final idx = _localCatalog.indexWhere((m) => m.id == movieId);
    if (idx != -1) {
      final m = _localCatalog[idx];
      final currentAvg = m.userRatingAverage ?? m.rating;
      final currentCount = m.userRatingsCount;
      final newCount = currentCount + 1;
      final newAvg = double.parse((((currentAvg * currentCount) + rating) / newCount).toStringAsFixed(1));
      final updated = m.copyWith(
        userRatingAverage: newAvg,
        userRatingsCount: newCount,
      );
      _localCatalog[idx] = updated;
      return {
        'message': 'Rating submitted locally',
        'movie_id': movieId,
        'user_rating_average': newAvg,
        'user_ratings_count': newCount,
        'movie': updated.toJson(),
      };
    }
    return {'user_rating_average': rating, 'user_ratings_count': 1};
  }

  void _updateLocalItem(Movie movie) {
    final idx = _localCatalog.indexWhere((m) => m.id == movie.id);
    if (idx != -1) _localCatalog[idx] = movie;
  }
}

