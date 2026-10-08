import 'dart:math';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _apiService = ApiService();
  final WatchlistService _watchlist = WatchlistService();

  // Recommendations State
  String _selectedMood = 'Adrenaline';
  String _selectedGenre = 'Action';
  List<Movie> _recommendations = [];
  bool _isLoadingRecs = false;

  // Catalog State
  List<Movie> _catalogMovies = [];
  bool _isLoadingCatalog = false;
  String _catalogSearch = '';
  String _catalogSort = 'rating';
  double _minRating = 0.0;
  final TextEditingController _searchController = TextEditingController();

  bool _isServerOnline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)..addListener(() {
      if (mounted) setState(() {});
    });

    // 1. Immediately populate from in-memory cache if available (0ms delay)
    _recommendations = _apiService.getImmediateRecommendations(
      mood: _selectedMood,
      genre: _selectedGenre,
      limit: 12,
    );
    _catalogMovies = _apiService.getImmediateCatalog(limit: 50);

    // 2. Fetch fresh data concurrently in background
    _fetchConcurrently();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchConcurrently() {
    _fetchRecommendations();
    _fetchCatalog();
    _apiService.checkHealth().then((health) {
      if (mounted) setState(() => _isServerOnline = health['is_remote'] == true);
    });
  }

  Future<void> _fetchRecommendations() async {
    if (_recommendations.isEmpty) {
      setState(() => _isLoadingRecs = true);
    }
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
    if (_catalogMovies.isEmpty) {
      setState(() => _isLoadingCatalog = true);
    }
    try {
      final movies = await _apiService.getMovies(
        search: _catalogSearch,
        genre: 'All',
        minRating: _minRating > 0 ? _minRating : null,
        limit: 50,
      );
      if (mounted) {
        final sorted = List<Movie>.from(movies);
        if (_catalogSort == 'rating') sorted.sort((a, b) => b.rating.compareTo(a.rating));
        if (_catalogSort == 'year') sorted.sort((a, b) => b.year.compareTo(a.year));
        if (_catalogSort == 'title') sorted.sort((a, b) => a.title.compareTo(b.title));
        setState(() { _catalogMovies = sorted; _isLoadingCatalog = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  void _openMovie(Movie movie) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
    if (refreshed == true) _fetchConcurrently();
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
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: PosterImage(
                url: randomMovie.posterUrl,
                title: randomMovie.title,
                genre: randomMovie.genre,
                year: randomMovie.year,
                width: 140,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(randomMovie.title, style: AppTheme.displayTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text('${randomMovie.year}  /  ★ ${randomMovie.rating}  /  ${randomMovie.genre.toUpperCase()}',
                style: AppTheme.monoTag),
            const SizedBox(height: 8),
            Text(randomMovie.synopsis, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTheme.bodyRegular),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openMovie(randomMovie);
            },
            child: const Text('View Movie'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('CINEMATCH', style: TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('• MOVIE RECOMMENDATIONS', style: AppTheme.monoTag.copyWith(color: AppTheme.textSecondary.withValues(alpha: 0.8))),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _isServerOnline ? AppTheme.accentVermilion : AppTheme.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isServerOnline ? 'FASTAPI BACKEND ONLINE' : 'OFFLINE MODE (IN-APP ENGINE)',
                  style: AppTheme.monoTag.copyWith(fontSize: 9, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            onPressed: () async {
              final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddMovieScreen()));
              if (added == true) _fetchConcurrently();
            },
            child: const Text('+ ADD MOVIE'),
          ),
          const SizedBox(width: 8),
          IconButton(tooltip: 'Surprise Pick', icon: const Icon(Icons.shuffle, size: 18), onPressed: _triggerSurpriseMe),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune, size: 18),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _fetchConcurrently();
            },
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentVermilion,
          indicatorWeight: 2,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: AppTheme.monoTag.copyWith(fontSize: 11),
          unselectedLabelStyle: AppTheme.monoTag.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
          tabs: [
            const Tab(text: 'RECOMMENDED'),
            const Tab(text: 'ALL MOVIES'),
            AnimatedBuilder(
              animation: _watchlist,
              builder: (context, _) => Tab(text: 'WATCHLIST (${_watchlist.count})'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecommendationsTab(),
          _buildCatalogTab(),
          _buildWatchlistTab(),
        ],
      ),
    );
  }

  // --- TAB 1: Recommendations ---
  Widget _buildRecommendationsTab() {
    final heroMovie = _recommendations.isNotEmpty ? _recommendations.first : null;
    final otherRecs = _recommendations.length > 1 ? _recommendations.sublist(1) : <Movie>[];

    return RefreshIndicator(
      color: AppTheme.accentVermilion,
      backgroundColor: AppTheme.surface,
      onRefresh: _fetchRecommendations,
      child: CustomScrollView(
        slivers: [
          if (heroMovie != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _buildLeadFeature(heroMovie),
              ),
            ),
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

          // Top 10 Rail
          if (_recommendations.length >= 3) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOP RECOMMENDATIONS', style: AppTheme.monoTag),
                    Text('TOP 10', style: AppTheme.monoTag.copyWith(color: AppTheme.textMuted)),
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
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
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

          // Grid Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MORE MOVIES FOR YOU', style: AppTheme.monoTag),
                  Text('${otherRecs.length} MOVIES', style: AppTheme.monoTag.copyWith(color: AppTheme.textMuted)),
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
            _buildMovieGrid(otherRecs, showScore: true),
        ],
      ),
    );
  }

  // --- TAB 2: Catalog ---
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
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search movies by title, director, cast, or genre...',
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
                            DropdownMenuItem(value: 'rating', child: Text('Rating: Highest')),
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

  // --- TAB 3: Watchlist ---
  Widget _buildWatchlistTab() {
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
                  onPressed: () => _tabController.animateTo(0),
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
                    Text('${items.length} MOVIES', style: AppTheme.monoTag.copyWith(color: AppTheme.textMuted)),
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

  // Reusable Movie Grid Sliver (Eliminates duplication across all 3 tabs)
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

  // Responsive Lead Feature Monograph
  Widget _buildLeadFeature(Movie movie) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 580;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('FEATURED PICK', style: AppTheme.monoTag),
                      const SizedBox(width: 8),
                      Text('//  TOP RECOMMENDATION', style: AppTheme.monoTag.copyWith(color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(movie.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTheme.displayTitle.copyWith(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text('${movie.year}  /  ${movie.formattedRuntime}  /  ${movie.genre.toUpperCase()}', style: AppTheme.monoTag),
                  const SizedBox(height: 10),
                  Text(movie.synopsis, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTheme.bodyRegular),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(onPressed: () => _openMovie(movie), child: const Text('View Details')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _watchlist.toggleBookmark(movie)),
                    child: Text(_watchlist.isBookmarked(movie.id) ? 'Saved' : '+ Watchlist'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showTrailerDialog(movie),
                    child: Text('Watch Trailer', style: AppTheme.monoTag.copyWith(color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ],
          );

          if (isWide) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 200,
                    child: PosterImage(url: movie.posterUrl, title: movie.title, genre: movie.genre, year: movie.year, fit: BoxFit.cover, borderRadius: BorderRadius.zero),
                  ),
                  Expanded(child: Padding(padding: const EdgeInsets.all(20), child: content)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: PosterImage(url: movie.posterUrl, title: movie.title, genre: movie.genre, year: movie.year, fit: BoxFit.cover, borderRadius: BorderRadius.zero),
              ),
              Padding(padding: const EdgeInsets.all(16), child: content),
            ],
          );
        },
      ),
    );
  }
}
