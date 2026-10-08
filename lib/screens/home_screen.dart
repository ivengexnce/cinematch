import 'dart:math';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../widgets/poster_image.dart';
import '../widgets/recommendation_chips.dart';
import 'add_movie_screen.dart';
import 'movie_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final WatchlistService _watchlist = WatchlistService();
  final AuthService _auth = AuthService();

  int _currentNavigationIndex = 0;

  // Home Tab State
  List<Movie> _trendingMovies = [];
  List<Movie> _topRatedMovies = [];
  String _topRatedFilter = 'all'; // 'all', 'cinematch', 'imdb', 'most_recommended'

  // Recommendations Tab State
  String _selectedMood = 'Adrenaline';
  String _selectedGenre = 'Action';
  List<Movie> _recommendations = [];
  bool _isLoadingRecs = false;

  // Catalog / Explore Tab State
  List<Movie> _catalogMovies = [];
  bool _isLoadingCatalog = false;
  String _catalogSearch = '';
  String _catalogGenre = 'All';
  String _catalogSort = 'top_rating';
  double _minRating = 0.0;
  final TextEditingController _searchController = TextEditingController();

  // Watchlist & History Tab State
  int _watchlistSegment = 0; // 0 = Watchlist, 1 = Watch History

  // System & Connection State
  bool _isServerOnline = false;
  int? _serverLatencyMs;

  static const List<String> _catalogGenres = [
    'All', 'Action', 'Adventure', 'Sci-Fi', 'Drama', 'Comedy', 'Thriller', 'Crime', 'Horror', 'Mystery'
  ];

  static const List<String> _allGenresList = [
    'Action', 'Adventure', 'Animation', 'Comedy', 'Crime', 'Drama', 'Fantasy', 'Horror', 'Mystery', 'Romance', 'Sci-Fi', 'Thriller'
  ];

  static const List<String> _allMoodsList = [
    'Adrenaline', 'Mind-Bending', 'Suspense', 'Romantic', 'Feel-Good', 'Emotional', 'Scary', 'Sci-Fi', 'Mystery', 'Chill', 'Thought-Provoking'
  ];

  @override
  void initState() {
    super.initState();

    // 1. Instant synchronous preview from in-memory cache
    _recommendations = _apiService.getImmediateRecommendations(
      mood: _selectedMood,
      genre: _selectedGenre,
      limit: 12,
    );
    _catalogMovies = _apiService.getImmediateCatalog(limit: 50);
    _trendingMovies = _catalogMovies.take(10).toList();
    _topRatedMovies = _catalogMovies.take(10).toList();

    // 2. Fresh background network fetch
    _fetchAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchAllData() {
    _fetchHomeData();
    _fetchRecommendations();
    _fetchCatalog();
    _apiService.checkHealth().then((health) {
      if (mounted) {
        setState(() {
          _isServerOnline = health['is_remote'] == true;
          _serverLatencyMs = health['latency_ms'] as int?;
        });
      }
    });
  }

  Future<void> _fetchHomeData() async {
    try {
      final trending = await _apiService.getTrendingMovies(limit: 10);
      final topRated = await _apiService.getTopRatedMovies(filter: _topRatedFilter, limit: 10);
      if (mounted) {
        setState(() {
          _trendingMovies = trending;
          _topRatedMovies = topRated;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRecommendations() async {
    if (_recommendations.isEmpty) setState(() => _isLoadingRecs = true);
    try {
      final recs = await _apiService.getRecommendations(
        mood: _selectedMood,
        genre: _selectedGenre,
        limit: 12,
      );
      if (mounted) setState(() { _recommendations = recs; _isLoadingRecs = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRecs = false);
    }
  }

  Future<void> _fetchCatalog() async {
    if (_catalogMovies.isEmpty) setState(() => _isLoadingCatalog = true);
    try {
      final movies = await _apiService.getMovies(
        search: _catalogSearch,
        genre: _catalogGenre,
        minRating: _minRating > 0 ? _minRating : null,
        sortBy: _catalogSort,
        limit: 50,
      );
      if (mounted) setState(() { _catalogMovies = movies; _isLoadingCatalog = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  void _openMovie(Movie movie) async {
    _auth.addToWatchHistory(movie.id);
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
    if (refreshed == true) _fetchAllData();
  }

  void _triggerSurpriseMe() {
    final pool = _recommendations.isNotEmpty ? _recommendations : _catalogMovies;
    if (pool.isEmpty) return;
    final randomMovie = pool[Random().nextInt(pool.length)];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.borderLight),
        ),
        title: const Text('Surprise Movie Pick', style: TextStyle(fontFamily: AppTheme.fontDisplay)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: PosterImage(url: randomMovie.posterUrl, title: randomMovie.title, genre: randomMovie.genre, year: randomMovie.year),
            ),
            const SizedBox(height: 12),
            Text(randomMovie.title, style: const TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${randomMovie.year} • ${randomMovie.genre.toUpperCase()} • ★ ${randomMovie.rating.toStringAsFixed(1)}', style: AppTheme.monoTag),
            const SizedBox(height: 8),
            Text(randomMovie.synopsis, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTheme.bodyRegular),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openMovie(randomMovie);
            },
            child: const Text('Explore Film'),
          ),
        ],
      ),
    );
  }

  void _showTrailerDialog(Movie movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.borderLight),
        ),
        title: Text('Trailer Preview — ${movie.title}', style: const TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppTheme.borderLight)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PosterImage(url: movie.posterUrl, title: movie.title, genre: movie.genre, year: movie.year, fit: BoxFit.cover),
                  Container(color: Colors.black54),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 48, color: AppTheme.accentVermilion),
                      SizedBox(height: 8),
                      Text('Streaming Official Trailer', style: AppTheme.monoTag),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Trailer preview for "${movie.title}" (${movie.year}). Directed by ${movie.director}.', style: AppTheme.bodyRegular),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showScoreBreakdownSheet(Movie movie) {
    final breakdown = _apiService.calculateScoreBreakdown(
      movie,
      userFavoriteGenres: _auth.currentUser.favoriteGenres,
      userFavoriteMoods: _auth.currentUser.favoriteMoods,
      watchHistory: _auth.currentUser.watchHistory,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: AppTheme.accentVermilion, size: 20),
                const SizedBox(width: 8),
                const Text('TRANSPARENT CINEMATCH SCORE', style: AppTheme.monoTag),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentVermilion.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.accentVermilion),
                  ),
                  child: Text(
                    '🎯 ${breakdown['final_match']}% MATCH',
                    style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(movie.title, style: const TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('Multi-signal algorithm breakdown explaining why this title is recommended for you:', style: AppTheme.bodyRegular.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            _buildBreakdownRow('Genre Match', '+${breakdown['genre_match']}', 'Matches your active preferred genres'),
            _buildBreakdownRow('IMDb Rating Quality', '+${breakdown['imdb_rating']}', 'Normalized critic & audience rating score'),
            _buildBreakdownRow('Community Upvotes', '+${breakdown['community_rating']}', 'CineMatch user recommendations & consensus'),
            _buildBreakdownRow('Your Watch History Affinity', '+${breakdown['user_history']}', 'Taste correlation with previously saved & watched films'),
            _buildBreakdownRow('Mood Affinity (${movie.mood})', '+${breakdown['mood_match']}', 'Direct match to selected discovery mood'),
            const Divider(color: AppTheme.borderLight, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL MATCH SCORE', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text('${breakdown['final_match']}%', style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.cyberAmber)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String bonus, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(description, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Text(bonus, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentVermilion)),
          ),
        ],
      ),
    );
  }

  void _showNotificationCenter() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: AppTheme.accentVermilion, size: 20),
            SizedBox(width: 8),
            Text('NOTIFICATIONS', style: AppTheme.monoTag),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationItem('🎬 Trending Movie', 'Interstellar entered the top 5 community recommendations.'),
            _buildNotificationItem('🔥 Community Impact', '3 users discovered Dune after your recommendation!'),
            _buildNotificationItem('⭐ New Review Liked', 'Your review on Blade Runner 2049 was marked helpful.'),
            _buildNotificationItem('🍿 Fresh Picks Available', 'New Mind-Bending titles matching your taste were indexed.'),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('DISMISS')),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: const BoxDecoration(color: AppTheme.accentVermilion, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(message, style: AppTheme.bodyRegular.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPreferenceQuizDialog() {
    final user = _auth.currentUser;
    final selectedGenres = List<String>.from(user.favoriteGenres);
    final selectedMoods = List<String>.from(user.favoriteMoods);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
          title: const Text('DISCOVERY TASTE PROFILE', style: AppTheme.monoTag),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select favorite genres to calibrate CineMatch recommendations:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allGenresList.map((g) {
                    final isSel = selectedGenres.contains(g);
                    return FilterChip(
                      label: Text(g, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : AppTheme.textPrimary)),
                      selected: isSel,
                      selectedColor: AppTheme.accentVermilion,
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(color: isSel ? AppTheme.accentVermilion : AppTheme.borderLight),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedGenres.add(g);
                          } else {
                            selectedGenres.remove(g);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Preferred Discovery Moods:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allMoodsList.map((m) {
                    final isSel = selectedMoods.contains(m);
                    return FilterChip(
                      label: Text(m, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : AppTheme.textPrimary)),
                      selected: isSel,
                      selectedColor: AppTheme.cyberAmber.withValues(alpha: 0.8),
                      backgroundColor: AppTheme.surface,
                      side: BorderSide(color: isSel ? AppTheme.cyberAmber : AppTheme.borderLight),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedMoods.add(m);
                          } else {
                            selectedMoods.remove(m);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                _auth.updatePreferences(favoriteGenres: selectedGenres, favoriteMoods: selectedMoods);
                Navigator.pop(ctx);
                _fetchRecommendations();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Taste profile updated! Recs recalibrated.', style: AppTheme.monoTag)),
                );
              },
              child: const Text('SAVE PREFERENCES'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 720;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            toolbarHeight: 56,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.movie_filter, color: AppTheme.accentVermilion, size: 20),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'CINEMATCH',
                      style: TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _isServerOnline ? AppTheme.accentVermilion : AppTheme.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWideScreen ? 260 : 120),
                      child: Text(
                        _isServerOnline
                            ? (_serverLatencyMs != null ? 'FASTAPI ONLINE (${_serverLatencyMs}ms)' : 'FASTAPI ONLINE')
                            : 'OFFLINE ENGINE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.monoTag.copyWith(fontSize: 8.5, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_outlined, size: 20),
                onPressed: _showNotificationCenter,
              ),
              IconButton(
                tooltip: 'Surprise Pick',
                icon: const Icon(Icons.shuffle, size: 20),
                onPressed: _triggerSurpriseMe,
              ),
              // On narrow screens collapse to icon; on wide keep label
              if (isWideScreen)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    onPressed: () async {
                      final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddMovieScreen()));
                      if (added == true) _fetchAllData();
                    },
                    child: const Text('+ ADD MOVIE'),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Add Movie',
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () async {
                    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddMovieScreen()));
                    if (added == true) _fetchAllData();
                  },
                ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.tune, size: 20),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  _fetchAllData();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: isWideScreen
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentNavigationIndex,
                      onDestinationSelected: (idx) => setState(() => _currentNavigationIndex = idx),
                      backgroundColor: AppTheme.surface,
                      indicatorColor: AppTheme.accentVermilion.withValues(alpha: 0.2),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.accentVermilion), label: Text('Home')),
                        NavigationRailDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore, color: AppTheme.accentVermilion), label: Text('Explore')),
                        NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: AppTheme.accentVermilion), label: Text('For You')),
                        NavigationRailDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark, color: AppTheme.accentVermilion), label: Text('Watchlist')),
                        NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppTheme.accentVermilion), label: Text('Profile')),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: AppTheme.borderLight),
                    Expanded(child: _buildSelectedTab()),
                  ],
                )
              : _buildSelectedTab(),
          bottomNavigationBar: isWideScreen
              ? null
              : Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentNavigationIndex,
                    onTap: (idx) => setState(() => _currentNavigationIndex = idx),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: AppTheme.surface,
                    selectedItemColor: AppTheme.accentVermilion,
                    unselectedItemColor: AppTheme.textMuted,
                    selectedLabelStyle: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10),
                    items: [
                      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                      const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Explore'),
                      const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'For You'),
                      BottomNavigationBarItem(
                        icon: AnimatedBuilder(
                          animation: _watchlist,
                          builder: (ctx, _) => Badge(
                            label: Text('${_watchlist.count}'),
                            isLabelVisible: _watchlist.count > 0,
                            backgroundColor: AppTheme.accentVermilion,
                            child: const Icon(Icons.bookmark_outline),
                          ),
                        ),
                        activeIcon: const Icon(Icons.bookmark),
                        label: 'Watchlist',
                      ),
                      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSelectedTab() {
    switch (_currentNavigationIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildCatalogTab();
      case 2:
        return _buildRecommendationsTab();
      case 3:
        return _buildWatchlistAndHistoryTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ==========================================
  // TAB 0: HOME SCREEN (Hero, Trending, Top-Rated, Because You Liked)
  // ==========================================
  Widget _buildHomeTab() {
    final heroMovie = _trendingMovies.isNotEmpty ? _trendingMovies.first : (_catalogMovies.isNotEmpty ? _catalogMovies.first : null);

    return RefreshIndicator(
      color: AppTheme.accentVermilion,
      backgroundColor: AppTheme.surface,
      onRefresh: _fetchHomeData,
      child: CustomScrollView(
        slivers: [
          // 1. Cinematic Hero Section
          if (heroMovie != null)
            SliverToBoxAdapter(
              child: _buildCinematicHeroSection(heroMovie),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // 2. Trending Now Section (Leaderboard Rail)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🔥 TRENDING NOW', style: AppTheme.monoTag),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.accentVermilion.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
                        child: const Text('LIVE', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 8.5, fontWeight: FontWeight.w700, color: AppTheme.accentVermilion)),
                      ),
                    ],
                  ),
                  Text('TOP 10', style: AppTheme.monoTag.copyWith(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 254,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: min(_trendingMovies.length, 10),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, idx) {
                  final movie = _trendingMovies[idx];
                  return SizedBox(
                    width: 150,
                    child: MovieCard(
                      movie: movie,
                      rankNumber: idx + 1,
                      onTap: () => _openMovie(movie),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // 3. Community Favorites & Top Rated Filter Strip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏆 COMMUNITY FAVORITES', style: AppTheme.monoTag),
                  const SizedBox(height: 8),
                  // Filter Pills — wrapped so they never overflow on narrow screens
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildTopRatedFilterChip('All', 'all'),
                      _buildTopRatedFilterChip('CineMatch', 'cinematch'),
                      _buildTopRatedFilterChip('IMDb', 'imdb'),
                      _buildTopRatedFilterChip('Most Recs', 'most_recommended'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          _buildMovieGrid(_topRatedMovies),

          // 4. "Because you liked [X]" Personalized Strip
          if (_recommendations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BECAUSE YOU LIKED ${_selectedMood.toUpperCase()}', style: AppTheme.monoTag),
                    InkWell(
                      onTap: () => setState(() => _currentNavigationIndex = 2),
                      child: const Text('SEE ALL →', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: min(_recommendations.length, 6),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, idx) {
                    final movie = _recommendations[idx];
                    return SizedBox(
                      width: 146,
                      child: MovieCard(
                        movie: movie,
                        showScore: true,
                        onTap: () => _openMovie(movie),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
          ],
        ],
      ),
    );
  }

  Widget _buildTopRatedFilterChip(String label, String value) {
    final isSelected = _topRatedFilter == value;
    return InkWell(
      onTap: () async {
        setState(() => _topRatedFilter = value);
        final list = await _apiService.getTopRatedMovies(filter: value, limit: 10);
        if (mounted) setState(() => _topRatedMovies = list);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentVermilion : AppTheme.surface,
          border: Border.all(color: isSelected ? AppTheme.accentVermilion : AppTheme.borderLight),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.fontMono,
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCinematicHeroSection(Movie movie) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Stack(
        children: [
          // Large Backdrop Scrim
          SizedBox(
            height: 380,
            width: double.infinity,
            child: PosterImage(
              url: movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.posterUrl,
              title: movie.title,
              genre: movie.genre,
              year: movie.year,
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.black87,
                    AppTheme.background,
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentVermilion,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text('CINEMATIC HIGHLIGHT', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showScoreBreakdownSheet(movie),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.cyberAmber.withValues(alpha: 0.15),
                          border: Border.all(color: AppTheme.cyberAmber, width: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎯 ', style: TextStyle(fontSize: 9)),
                            Text('${movie.matchPercentage}% CINEMATCH MATCH', style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 8.5, fontWeight: FontWeight.w700, color: AppTheme.cyberAmber)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(movie.title, style: AppTheme.displayTitle.copyWith(fontSize: 28, height: 1.1)),
                const SizedBox(height: 6),
                Text(
                  '${movie.year}  •  ${movie.formattedRuntime}  •  ${movie.genre.toUpperCase()}  •  IMDb ★ ${movie.rating.toStringAsFixed(1)}  •  👍 ${movie.recommendationPercentage}% REC',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10.5, color: AppTheme.textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),
                Text(movie.synopsis, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.bodyRegular.copyWith(fontSize: 13, height: 1.4)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('WATCH TRAILER'),
                      onPressed: () => _showTrailerDialog(movie),
                    ),
                    AnimatedBuilder(
                      animation: _watchlist,
                      builder: (ctx, _) {
                        final saved = _watchlist.isBookmarked(movie.id);
                        return OutlinedButton.icon(
                          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, size: 16, color: saved ? AppTheme.accentVermilion : AppTheme.textPrimary),
                          label: Text(saved ? 'IN WATCHLIST' : '+ WATCHLIST'),
                          onPressed: () => _watchlist.toggleBookmark(movie),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _auth,
                      builder: (ctx, _) {
                        final recommended = _auth.hasRecommended(movie.id);
                        return OutlinedButton.icon(
                          icon: Icon(recommended ? Icons.thumb_up : Icons.thumb_up_alt_outlined, size: 15, color: recommended ? AppTheme.cyberAmber : AppTheme.textPrimary),
                          label: Text(recommended ? 'RECOMMENDED' : 'RECOMMEND', style: TextStyle(color: recommended ? AppTheme.cyberAmber : AppTheme.textPrimary)),
                          onPressed: () async {
                            final nowRec = _auth.toggleRecommendation(movie.id);
                            _apiService.toggleRecommendation(movie.id, _auth.currentUser.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.surfaceElevated,
                                content: Text(nowRec ? '👍 Recommended "${movie.title}"!' : 'Removed recommendation.', style: AppTheme.monoTag),
                              ),
                            );
                            _fetchAllData();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: EXPLORE & INSTANT SEARCH
  // ==========================================
  Widget _buildCatalogTab() {
    return RefreshIndicator(
      color: AppTheme.accentVermilion,
      backgroundColor: AppTheme.surface,
      onRefresh: _fetchCatalog,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _catalogGenres.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final g = _catalogGenres[index];
                        final isSelected = _catalogGenre.toLowerCase() == g.toLowerCase();
                        return InkWell(
                          onTap: () {
                            setState(() => _catalogGenre = g);
                            _fetchCatalog();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.accentVermilion : AppTheme.surface,
                              border: Border.all(color: isSelected ? AppTheme.accentVermilion : AppTheme.borderLight),
                            ),
                            child: Text(
                              g.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppTheme.fontMono,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by title, director, cast, or genre...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _catalogSearch = '');
                                _fetchCatalog();
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() => _catalogSearch = val);
                      _fetchCatalog();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
                        child: DropdownButton<String>(
                          value: _catalogSort,
                          dropdownColor: AppTheme.surface,
                          underline: const SizedBox(),
                          style: AppTheme.monoTag.copyWith(color: AppTheme.textPrimary),
                          items: const [
                            DropdownMenuItem(value: 'top_rating', child: Text('★ Top Rated (Community + IMDb)')),
                            DropdownMenuItem(value: 'recommendations', child: Text('🔥 Most Recommended')),
                            DropdownMenuItem(value: 'rating', child: Text('IMDb: Highest')),
                            DropdownMenuItem(value: 'year', child: Text('Release Year')),
                            DropdownMenuItem(value: 'title', child: Text('Title: A–Z')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _catalogSort = val);
                              _fetchCatalog();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.accentVermilion,
                            thumbColor: AppTheme.accentVermilion,
                            inactiveTrackColor: AppTheme.borderLight,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _minRating,
                            min: 0.0,
                            max: 9.0,
                            divisions: 9,
                            onChanged: (val) {
                              setState(() => _minRating = val);
                              _fetchCatalog();
                            },
                          ),
                        ),
                      ),
                      Text(
                        _minRating == 0.0 ? 'ALL' : '≥ ${_minRating.toStringAsFixed(1)} ★',
                        style: AppTheme.monoTag.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingCatalog)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentVermilion)),
            )
          else if (_catalogMovies.isEmpty)
            _buildEmptySliver('No movies found matching your search.')
          else
            _buildMovieGrid(_catalogMovies),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: RECOMMENDATIONS & MOOD DISCOVERY
  // ==========================================
  Widget _buildRecommendationsTab() {
    return RefreshIndicator(
      color: AppTheme.accentVermilion,
      backgroundColor: AppTheme.surface,
      onRefresh: _fetchRecommendations,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: RecommendationChips(
              selectedMood: _selectedMood,
              selectedGenre: _selectedGenre,
              onMoodChanged: (mood) {
                setState(() => _selectedMood = mood);
                _fetchRecommendations();
              },
              onGenreChanged: (genre) {
                setState(() => _selectedGenre = genre);
                _fetchRecommendations();
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Top 10 Rail with Transparent Score Info
          if (_recommendations.length >= 3) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOP RECOMMENDATIONS', style: AppTheme.monoTag),
                    InkWell(
                      onTap: () {
                        if (_recommendations.isNotEmpty) _showScoreBreakdownSheet(_recommendations.first);
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 12, color: AppTheme.cyberAmber),
                          SizedBox(width: 4),
                          Text('HOW SCORE IS COMPUTED', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9.5, color: AppTheme.cyberAmber, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: min(_recommendations.length, 10),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final m = _recommendations[index];
                    return SizedBox(
                      width: 146,
                      child: MovieCard(
                        movie: m,
                        showScore: true,
                        rankNumber: index + 1,
                        onTap: () => _openMovie(m),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RECOMMENDED FOR YOU', style: AppTheme.monoTag),
                  Text('${_recommendations.length} FILMS', style: AppTheme.monoTag.copyWith(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          if (_isLoadingRecs)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentVermilion)),
            )
          else if (_recommendations.isEmpty)
            _buildEmptySliver('No movies found for this mood and genre.', onReset: () {
              setState(() { _selectedMood = 'Adrenaline'; _selectedGenre = 'Action'; });
              _fetchRecommendations();
            })
          else
            _buildMovieGrid(_recommendations, showScore: true),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: WATCHLIST & WATCH HISTORY
  // ==========================================
  Widget _buildWatchlistAndHistoryTab() {
    return Column(
      children: [
        // Segmented Switcher
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _watchlistSegment = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _watchlistSegment == 0 ? AppTheme.accentVermilion : Colors.transparent,
                      border: Border.all(color: _watchlistSegment == 0 ? AppTheme.accentVermilion : AppTheme.borderLight),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _watchlist,
                        builder: (ctx, _) => Text(
                          'SAVED WATCHLIST (${_watchlist.count})',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _watchlistSegment == 0 ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _watchlistSegment = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _watchlistSegment == 1 ? AppTheme.accentVermilion : Colors.transparent,
                      border: Border.all(color: _watchlistSegment == 1 ? AppTheme.accentVermilion : AppTheme.borderLight),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _auth,
                        builder: (ctx, _) => Text(
                          'WATCH HISTORY (${_auth.currentUser.watchHistory.length})',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _watchlistSegment == 1 ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _watchlistSegment == 0 ? _buildWatchlistSubView() : _buildHistorySubView(),
        ),
      ],
    );
  }

  Widget _buildWatchlistSubView() {
    return AnimatedBuilder(
      animation: _watchlist,
      builder: (context, _) {
        final items = _watchlist.items;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Your Watchlist is Empty', style: TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Tap "+ Watchlist" on any movie card to save it here.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => setState(() => _currentNavigationIndex = 0),
                  child: const Text('Browse Recommended Movies'),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MY SAVED MOVIES', style: AppTheme.monoTag),
                    Row(
                      children: [
                        Text('${items.length} MOVIES', style: AppTheme.monoTag.copyWith(color: AppTheme.textMuted)),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surfaceElevated,
                                title: const Text('CLEAR WATCHLIST?', style: AppTheme.monoTag),
                                content: const Text('Remove all saved movies from your watchlist?', style: AppTheme.bodyRegular),
                                actions: [
                                  OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentVermilion),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('CLEAR ALL'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) _watchlist.clear();
                          },
                          child: const Text('CLEAR ALL', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildMovieGrid(items),
          ],
        );
      },
    );
  }

  Widget _buildHistorySubView() {
    return AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        final historyIds = _auth.currentUser.watchHistory;
        final historyMovies = _catalogMovies.where((m) => historyIds.contains(m.id)).toList();

        if (historyMovies.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: AppTheme.textMuted),
                SizedBox(height: 12),
                Text('No Watch History Yet', style: TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 20, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('Movies you explore or mark as watched will appear here.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECENTLY WATCHED & EXPLORED', style: AppTheme.monoTag),
                    InkWell(
                      onTap: () {
                        _auth.clearWatchHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Watch history cleared.', style: AppTheme.monoTag)),
                        );
                      },
                      child: const Text('CLEAR HISTORY', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            _buildMovieGrid(historyMovies),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 4: USER PROFILE & COMMUNITY STATS
  // ==========================================
  Widget _buildProfileTab() {
    return AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        final user = _auth.currentUser;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.accentVermilion,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          Text(user.handle, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 12, color: AppTheme.accentVermilion)),
                          Text(user.email, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Profile',
                      onPressed: () {
                        _showEditProfileDialog();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Activity Stats Counter Grid
              Row(
                children: [
                  Expanded(child: _buildStatCard('WATCHED', '👁️ ${user.watchedMovieIds.length} films', AppTheme.textPrimary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('RECOMMENDED', '👍 ${user.recommendedMovieIds.length} recs', AppTheme.cyberAmber)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('RATINGS', '★ ${user.ratedMovies.length} scores', AppTheme.ratingStar)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('WATCHLIST', '♡ ${_watchlist.count} saved', AppTheme.accentVermilion)),
                ],
              ),

              const SizedBox(height: 24),

              // Taste Profile & Preference Calibrator Button
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DISCOVERY PREFERENCES', style: AppTheme.monoTag),
                        OutlinedButton(
                          onPressed: _showPreferenceQuizDialog,
                          child: const Text('CALIBRATE TASTE'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('FAVORITE GENRES:', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: user.favoriteGenres.map((g) => Chip(
                        label: Text(g, style: const TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: AppTheme.accentVermilion.withValues(alpha: 0.8),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                    const SizedBox(height: 10),
                    const Text('FAVORITE MOODS:', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: user.favoriteMoods.map((m) => Chip(
                        label: Text(m, style: const TextStyle(fontSize: 10, color: AppTheme.cyberAmber)),
                        backgroundColor: AppTheme.surfaceElevated,
                        side: const BorderSide(color: AppTheme.borderLight),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Anti-Abuse & Community Trust Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppTheme.cyberAmber, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('COMMUNITY TRUST LEVEL: VERIFIED CRITIC', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.cyberAmber)),
                          const SizedBox(height: 2),
                          Text('Your upvotes contribute directly to the Bayesian CineMatch recommendation ranking score with full 1-vote-per-user anti-abuse protection.', style: AppTheme.monoTag.copyWith(fontSize: 9, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('RESET CATALOG SEED & REFRESH'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                onPressed: () async {
                  await _apiService.resetCatalog();
                  _fetchAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Catalog seed reset to pristine state.', style: AppTheme.monoTag)),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('SWITCH USER PROFILE'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                onPressed: () {
                  _showEditProfileDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _auth.currentUser.name);
    final handleCtrl = TextEditingController(text: _auth.currentUser.handle.replaceAll('@', ''));
    final emailCtrl = TextEditingController(text: _auth.currentUser.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
        title: const Text('EDIT USER PROFILE', style: AppTheme.monoTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 8),
            TextField(controller: handleCtrl, decoration: const InputDecoration(labelText: 'Handle (e.g. cinelover)')),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              _auth.login(
                name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Film Critic',
                handle: handleCtrl.text.trim().isNotEmpty ? handleCtrl.text.trim() : 'critic',
                email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : 'critic@cinematch.app',
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Profile saved & synchronized!', style: AppTheme.monoTag)),
              );
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  // Reusable responsive Movie Grid
  Widget _buildMovieGrid(List<Movie> movies, {bool showScore = false}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.61,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final movie = movies[index];
            return MovieCard(
              movie: movie,
              showScore: showScore,
              onTap: () => _openMovie(movie),
            );
          },
          childCount: movies.length,
        ),
      ),
    );
  }

  Widget _buildEmptySliver(String message, {VoidCallback? onReset}) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: const TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 16, color: AppTheme.textSecondary)),
            if (onReset != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onReset, child: const Text('Reset Filters')),
            ],
          ],
        ),
      ),
    );
  }
}
