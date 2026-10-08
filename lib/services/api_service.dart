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
      return {'status': 'offline_mode', 'service': 'CineMatch Local Seed', 'total_movies': _localCatalog.length, 'is_remote': false};
    }
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/health')).timeout(const Duration(milliseconds: 1200));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        isUsingOfflineFallback = false;
        return {...data, 'is_remote': true};
      }
    } catch (_) {}

    await _ensureLocalLoaded();
    isUsingOfflineFallback = true;
    return {'status': 'fallback_offline', 'service': 'CineMatch Offline Engine', 'total_movies': _localCatalog.length, 'is_remote': false};
  }

  // --- Get Catalog Movies ---
  Future<List<Movie>> getMovies({
    String? genre,
    String? search,
    double? minRating,
    int skip = 0,
    int limit = 50,
  }) async {
    if (!forceOffline) {
      try {
        final queryParams = <String, String>{'skip': skip.toString(), 'limit': limit.toString()};
        if (genre != null && genre.isNotEmpty && genre.toLowerCase() != 'all') queryParams['genre'] = genre;
        if (search != null && search.isNotEmpty) queryParams['search'] = search;
        if (minRating != null) queryParams['min_rating'] = minRating.toString();

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

  void _updateLocalItem(Movie movie) {
    final idx = _localCatalog.indexWhere((m) => m.id == movie.id);
    if (idx != -1) _localCatalog[idx] = movie;
  }
}
