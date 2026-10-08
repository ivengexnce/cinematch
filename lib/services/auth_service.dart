import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class UserProfile {
  final String id;
  final String name;
  final String handle;
  final String email;
  final String avatarUrl;
  final String bio;
  final List<String> favoriteGenres;
  final List<String> favoriteMoods;
  final List<String> watchHistory;
  final Set<String> watchedMovieIds;
  final Set<String> recommendedMovieIds;
  final Map<String, double> ratedMovies;

  const UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    this.favoriteGenres = const ['Action', 'Sci-Fi', 'Drama', 'Thriller'],
    this.favoriteMoods = const ['Mind-Bending', 'Adrenaline'],
    this.watchHistory = const [],
    this.watchedMovieIds = const {},
    this.recommendedMovieIds = const {},
    this.ratedMovies = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'handle': handle,
        'email': email,
        'avatar_url': avatarUrl,
        'bio': bio,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] ?? 'user_alex',
        name: json['name'] ?? 'Alex Rivers',
        handle: json['handle'] ?? '@alex_cine',
        email: json['email'] ?? 'alex@cinematch.io',
        avatarUrl: json['avatar_url'] ??
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&q=80',
        bio: json['bio'] ?? 'Film buff, cinephile & IMDB Top 250 explorer.',
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _loadState();
  }

  static const String _userKey = 'cinematch_user_profile_v1';
  static const String _recsKey = 'cinematch_user_recs_v1';
  static const String _ratingsKey = 'cinematch_user_ratings_v1';
  static const String _watchedKey = 'cinematch_user_watched_v1';
  static const String _historyKey = 'cinematch_user_history_v1';
  static const String _genresKey = 'cinematch_user_genres_v1';
  static const String _moodsKey = 'cinematch_user_moods_v1';
  static const String _reviewsKey = 'cinematch_user_reviews_v1';

  UserProfile _currentUser = const UserProfile(
    id: 'user_alex',
    name: 'Alex Rivers',
    handle: '@alex_cine',
    email: 'alex@cinematch.io',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&q=80',
    bio: 'Film buff, cinephile & IMDB Top 250 explorer.',
  );

  bool _isLoggedIn = true;
  final Set<String> _recommendedMovieIds = {};
  final Map<String, double> _userRatings = {};
  final Set<String> _watchedMovieIds = {};
  final List<String> _watchHistory = [];
  final Set<String> _favoriteGenres = {'Action', 'Sci-Fi', 'Drama', 'Thriller'};
  final Set<String> _favoriteMoods = {'Mind-Bending', 'Adrenaline'};
  final List<UserReview> _userReviews = [];

  UserProfile get currentUser => UserProfile(
    id: _currentUser.id,
    name: _currentUser.name,
    handle: _currentUser.handle,
    email: _currentUser.email,
    avatarUrl: _currentUser.avatarUrl,
    bio: _currentUser.bio,
    favoriteGenres: _favoriteGenres.toList(),
    favoriteMoods: _favoriteMoods.toList(),
    watchHistory: List.unmodifiable(_watchHistory),
    watchedMovieIds: Set.unmodifiable(_watchedMovieIds),
    recommendedMovieIds: Set.unmodifiable(_recommendedMovieIds),
    ratedMovies: Map.unmodifiable(_userRatings),
  );

  bool get isLoggedIn => _isLoggedIn;
  Set<String> get recommendedMovieIds => Set.unmodifiable(_recommendedMovieIds);
  Map<String, double> get userRatings => Map.unmodifiable(_userRatings);
  Set<String> get watchedMovieIds => Set.unmodifiable(_watchedMovieIds);
  List<String> get watchHistory => List.unmodifiable(_watchHistory);
  Set<String> get favoriteGenres => Set.unmodifiable(_favoriteGenres);
  Set<String> get favoriteMoods => Set.unmodifiable(_favoriteMoods);
  List<UserReview> get userReviews => List.unmodifiable(_userReviews);

  int get recommendationsCount => _recommendedMovieIds.length;
  int get ratingsCount => _userRatings.length;
  int get watchedCount => _watchedMovieIds.length;
  int get reviewsCount => _userReviews.length;

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null && userStr.isNotEmpty) {
        _currentUser = UserProfile.fromJson(json.decode(userStr));
      }

      final recsList = prefs.getStringList(_recsKey);
      if (recsList != null) _recommendedMovieIds.addAll(recsList);

      final watchedList = prefs.getStringList(_watchedKey);
      if (watchedList != null) _watchedMovieIds.addAll(watchedList);

      final historyList = prefs.getStringList(_historyKey);
      if (historyList != null) {
        _watchHistory.clear();
        _watchHistory.addAll(historyList);
      }

      final genresList = prefs.getStringList(_genresKey);
      if (genresList != null && genresList.isNotEmpty) {
        _favoriteGenres.clear();
        _favoriteGenres.addAll(genresList);
      }

      final moodsList = prefs.getStringList(_moodsKey);
      if (moodsList != null && moodsList.isNotEmpty) {
        _favoriteMoods.clear();
        _favoriteMoods.addAll(moodsList);
      }

      final ratingsStr = prefs.getString(_ratingsKey);
      if (ratingsStr != null && ratingsStr.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(ratingsStr);
        decoded.forEach((key, value) {
          _userRatings[key] = double.tryParse(value.toString()) ?? 0.0;
        });
      }

      final reviewsStr = prefs.getString(_reviewsKey);
      if (reviewsStr != null && reviewsStr.isNotEmpty) {
        final List<dynamic> decoded = json.decode(reviewsStr);
        _userReviews.clear();
        _userReviews.addAll(decoded.map((e) => UserReview.fromJson(Map<String, dynamic>.from(e))));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AuthService load error: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(_currentUser.toJson()));
      await prefs.setStringList(_recsKey, _recommendedMovieIds.toList());
      await prefs.setStringList(_watchedKey, _watchedMovieIds.toList());
      await prefs.setStringList(_historyKey, _watchHistory);
      await prefs.setStringList(_genresKey, _favoriteGenres.toList());
      await prefs.setStringList(_moodsKey, _favoriteMoods.toList());
      await prefs.setString(_ratingsKey, json.encode(_userRatings));
      await prefs.setString(_reviewsKey, json.encode(_userReviews.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('AuthService save error: $e');
    }
  }

  bool hasRecommended(String movieId) => _recommendedMovieIds.contains(movieId);

  bool toggleRecommendation(String movieId) {
    final nowRecommended = !_recommendedMovieIds.contains(movieId);
    if (nowRecommended) {
      _recommendedMovieIds.add(movieId);
    } else {
      _recommendedMovieIds.remove(movieId);
    }
    _saveState();
    notifyListeners();
    return nowRecommended;
  }

  void setUserRating(String movieId, double rating) {
    _userRatings[movieId] = rating;
    _saveState();
    notifyListeners();
  }

  double? getUserRating(String movieId) => _userRatings[movieId];

  bool isWatched(String movieId) => _watchedMovieIds.contains(movieId);

  bool toggleWatched(String movieId) {
    final isNowWatched = !_watchedMovieIds.contains(movieId);
    if (isNowWatched) {
      _watchedMovieIds.add(movieId);
      addToWatchHistory(movieId);
    } else {
      _watchedMovieIds.remove(movieId);
    }
    _saveState();
    notifyListeners();
    return isNowWatched;
  }

  void addToWatchHistory(String movieId) {
    _watchHistory.remove(movieId);
    _watchHistory.insert(0, movieId);
    if (_watchHistory.length > 50) _watchHistory.removeLast();
    _saveState();
    notifyListeners();
  }

  void clearWatchHistory() {
    _watchHistory.clear();
    _saveState();
    notifyListeners();
  }

  void updatePreferences({
    Iterable<String>? favoriteGenres,
    Iterable<String>? favoriteMoods,
    Iterable<String>? genres,
    Iterable<String>? moods,
  }) {
    final g = favoriteGenres ?? genres;
    final m = favoriteMoods ?? moods;
    if (g != null) {
      _favoriteGenres.clear();
      _favoriteGenres.addAll(g);
    }
    if (m != null) {
      _favoriteMoods.clear();
      _favoriteMoods.addAll(m);
    }
    _saveState();
    notifyListeners();
  }

  void addReview(UserReview review) {
    _userReviews.removeWhere((r) => r.id == review.id);
    _userReviews.insert(0, review);
    _saveState();
    notifyListeners();
  }

  void login({required String name, required String handle, required String email}) {
    _currentUser = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isNotEmpty ? name.trim() : 'Alex Rivers',
      handle: handle.startsWith('@') ? handle : '@$handle',
      email: email.trim().isNotEmpty ? email.trim() : 'alex@cinematch.io',
      avatarUrl: _currentUser.avatarUrl,
      bio: 'Verified CineMatch community reviewer & movie explorer.',
    );
    _isLoggedIn = true;
    _saveState();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
