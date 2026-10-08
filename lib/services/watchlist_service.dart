import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class WatchlistService extends ChangeNotifier {
  static final WatchlistService _instance = WatchlistService._internal();
  factory WatchlistService() => _instance;
  WatchlistService._internal() {
    _loadFromStorage();
  }

  static const String _storageKey = 'cinematch_watchlist_v1';
  final Map<String, Movie> _watchlist = {};

  List<Movie> get items => _watchlist.values.toList();
  int get count => _watchlist.length;

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonStr);
        for (final item in decoded) {
          final m = Movie.fromJson(item as Map<String, dynamic>);
          _watchlist[m.id] = m;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WatchlistService load error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _watchlist.values.map((m) => m.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(list));
    } catch (e) {
      debugPrint('WatchlistService save error: $e');
    }
  }

  bool isBookmarked(String movieId) {
    return _watchlist.containsKey(movieId);
  }

  void toggleBookmark(Movie movie) {
    if (_watchlist.containsKey(movie.id)) {
      _watchlist.remove(movie.id);
    } else {
      _watchlist[movie.id] = movie;
    }
    _saveToStorage();
    notifyListeners();
  }

  void add(Movie movie) {
    _watchlist[movie.id] = movie;
    _saveToStorage();
    notifyListeners();
  }

  void remove(String movieId) {
    _watchlist.remove(movieId);
    _saveToStorage();
    notifyListeners();
  }

  void clear() {
    _watchlist.clear();
    _saveToStorage();
    notifyListeners();
  }
}

