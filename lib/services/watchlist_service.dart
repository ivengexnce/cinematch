import 'package:flutter/foundation.dart';
import '../models/movie.dart';

class WatchlistService extends ChangeNotifier {
  static final WatchlistService _instance = WatchlistService._internal();
  factory WatchlistService() => _instance;
  WatchlistService._internal();

  final Map<String, Movie> _watchlist = {};

  List<Movie> get items => _watchlist.values.toList();
  int get count => _watchlist.length;

  bool isBookmarked(String movieId) {
    return _watchlist.containsKey(movieId);
  }

  void toggleBookmark(Movie movie) {
    if (_watchlist.containsKey(movie.id)) {
      _watchlist.remove(movie.id);
    } else {
      _watchlist[movie.id] = movie;
    }
    notifyListeners();
  }

  void add(Movie movie) {
    _watchlist[movie.id] = movie;
    notifyListeners();
  }

  void remove(String movieId) {
    _watchlist.remove(movieId);
    notifyListeners();
  }
}
