import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final String handle;
  final String email;
  final String avatarUrl;
  final String bio;

  const UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.email,
    required this.avatarUrl,
    required this.bio,
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

  UserProfile get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  Set<String> get recommendedMovieIds => Set.unmodifiable(_recommendedMovieIds);
  Map<String, double> get userRatings => Map.unmodifiable(_userRatings);
  int get recommendationsCount => _recommendedMovieIds.length;
  int get ratingsCount => _userRatings.length;

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null && userStr.isNotEmpty) {
        _currentUser = UserProfile.fromJson(json.decode(userStr));
      }

      final recsList = prefs.getStringList(_recsKey);
      if (recsList != null) {
        _recommendedMovieIds.addAll(recsList);
      }

      final ratingsStr = prefs.getString(_ratingsKey);
      if (ratingsStr != null && ratingsStr.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(ratingsStr);
        decoded.forEach((key, value) {
          _userRatings[key] = double.tryParse(value.toString()) ?? 0.0;
        });
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
      await prefs.setString(_ratingsKey, json.encode(_userRatings));
    } catch (e) {
      debugPrint('AuthService save error: $e');
    }
  }

  bool hasRecommended(String movieId) {
    return _recommendedMovieIds.contains(movieId);
  }

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

  double? getUserRating(String movieId) {
    return _userRatings[movieId];
  }

  void login({required String name, required String handle, required String email}) {
    _currentUser = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isNotEmpty ? name.trim() : 'Cinema Enthusiast',
      handle: handle.startsWith('@') ? handle : '@$handle',
      email: email.trim().isNotEmpty ? email.trim() : 'user@cinematch.io',
      avatarUrl: _currentUser.avatarUrl,
      bio: 'Verified CineMatch community reviewer.',
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
