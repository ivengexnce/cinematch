import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../widgets/poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  final ApiService _apiService = ApiService();
  final WatchlistService _watchlistService = WatchlistService();
  final AuthService _authService = AuthService();
  bool _isActionInProgress = false;
  List<Movie> _similarMovies = [];

  final List<Map<String, dynamic>> _userReviews = [
    {'author': 'Alex M.', 'rating': 9.0, 'date': 'OCT 2024', 'comment': 'Sensational direction and pacing. A must-watch masterpiece.'},
    {'author': 'CinemaBuff99', 'rating': 8.5, 'date': 'SEP 2024', 'comment': 'Incredible cinematography and sound design throughout the film.'},
  ];

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _fetchSimilarMovies();
  }

  Future<void> _fetchSimilarMovies() async {
    try {
      final list = await _apiService.getSimilarMovies(_currentMovie.id, limit: 8);
      if (mounted && list.isNotEmpty) {
        setState(() => _similarMovies = list);
        return;
      }
    } catch (_) {}

    try {
      final genre = _currentMovie.genresList.isNotEmpty ? _currentMovie.genresList.first : 'Action';
      final list = await _apiService.getMovies(genre: genre, limit: 8);
      if (mounted) setState(() => _similarMovies = list.where((m) => m.id != _currentMovie.id).toList());
    } catch (_) {}
  }

  void _showTrailerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
        title: const Text('TRAILER PREVIEW', style: AppTheme.monoTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(color: Colors.black, border: Border.all(color: AppTheme.borderLight)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PosterImage(url: _currentMovie.posterUrl, title: _currentMovie.title, genre: _currentMovie.genre, year: _currentMovie.year),
                  Container(color: Colors.black.withValues(alpha: 0.65)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.accentVermilion, width: 1.5)),
                        child: const Icon(Icons.play_arrow_rounded, size: 30, color: AppTheme.accentVermilion),
                      ),
                      const SizedBox(height: 8),
                      const Text('STREAMING TRAILER', style: TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 11, letterSpacing: 0.8)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Official trailer preview for "${_currentMovie.title}" (${_currentMovie.year}).', style: AppTheme.bodyRegular.copyWith(fontSize: 12)),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _showAddReviewDialog() {
    final commentCtrl = TextEditingController();
    double rating = 8.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
          title: const Text('WRITE A REVIEW', style: AppTheme.monoTag),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('RATING:', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, color: AppTheme.textSecondary)),
                  Text('★ ${rating.toStringAsFixed(1)} / 10', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              Slider(
                value: rating,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AppTheme.accentVermilion,
                onChanged: (val) => setDialogState(() => rating = val),
              ),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                style: AppTheme.bodyRegular.copyWith(fontSize: 13),
                decoration: const InputDecoration(hintText: 'Share your thoughts on this movie...'),
              ),
            ],
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                if (commentCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _userReviews.insert(0, {'author': 'You', 'rating': rating, 'date': 'JUST NOW', 'comment': commentCtrl.text.trim()});
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Review added!', style: AppTheme.monoTag)));
                }
              },
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserRecommendation() async {
    final user = _authService.currentUser;
    final nowRecommended = _authService.toggleRecommendation(_currentMovie.id);

    final currentRecs = _currentMovie.userRecommendationsCount;
    final newCount = nowRecommended ? currentRecs + 1 : (currentRecs > 0 ? currentRecs - 1 : 0);
    final updatedUsers = List<String>.from(_currentMovie.recommendedByUsers);
    if (nowRecommended) {
      if (!updatedUsers.contains(user.id)) updatedUsers.add(user.id);
    } else {
      updatedUsers.remove(user.id);
    }

    setState(() {
      _currentMovie = _currentMovie.copyWith(
        userRecommendationsCount: newCount,
        recommendedByUsers: updatedUsers,
      );
    });

    try {
      final res = await _apiService.toggleRecommendation(_currentMovie.id, user.id);
      if (res['movie'] != null && mounted) {
        setState(() {
          _currentMovie = Movie.fromJson(res['movie']);
        });
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceElevated,
          content: Text(
            nowRecommended
                ? '👍 Recommended "${_currentMovie.title}" to the CineMatch community!'
                : 'Removed recommendation for "${_currentMovie.title}".',
            style: AppTheme.monoTag,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showRateFilmDialog() {
    final currentRating = _authService.getUserRating(_currentMovie.id) ?? (_currentMovie.userRatingAverage ?? 8.0);
    double selectedRating = currentRating;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
          title: Row(
            children: [
              const Icon(Icons.star, color: AppTheme.cyberAmber, size: 18),
              const SizedBox(width: 8),
              Text('RATE THIS FILM', style: AppTheme.monoTag.copyWith(color: AppTheme.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate "${_currentMovie.title}" (${_currentMovie.year})',
                style: AppTheme.bodyRegular.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('YOUR SCORE:', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, color: AppTheme.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberAmber.withValues(alpha: 0.15),
                      border: Border.all(color: AppTheme.cyberAmber),
                    ),
                    child: Text(
                      '★ ${selectedRating.toStringAsFixed(1)} / 10',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        color: AppTheme.cyberAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: selectedRating,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AppTheme.cyberAmber,
                inactiveColor: AppTheme.borderLight,
                onChanged: (val) => setDialogState(() => selectedRating = val),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1.0 Poor', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textMuted)),
                  Text('10.0 Masterpiece', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _authService.setUserRating(_currentMovie.id, selectedRating);
                final res = await _apiService.submitUserRating(_currentMovie.id, _authService.currentUser.id, selectedRating);
                if (res['movie'] != null && mounted) {
                  setState(() {
                    _currentMovie = Movie.fromJson(res['movie']);
                  });
                } else if (mounted) {
                  final curCount = _currentMovie.userRatingsCount + 1;
                  final curAvg = double.parse(((((_currentMovie.userRatingAverage ?? _currentMovie.rating) * _currentMovie.userRatingsCount) + selectedRating) / curCount).toStringAsFixed(1));
                  setState(() {
                    _currentMovie = _currentMovie.copyWith(userRatingAverage: curAvg, userRatingsCount: curCount);
                  });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceElevated,
                      content: Text(
                        '★ Rated ${selectedRating.toStringAsFixed(1)}/10! Top community rating refreshed.',
                        style: AppTheme.monoTag,
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('SUBMIT RATING'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final ratingCtrl = TextEditingController(text: _currentMovie.rating.toString());
    final synCtrl = TextEditingController(text: _currentMovie.synopsis);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
        title: const Text('EDIT MOVIE DETAILS', style: AppTheme.monoTag),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RATING (0.0 - 10.0)', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              TextField(controller: ratingCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary)),
              const SizedBox(height: 14),
              const Text('SYNOPSIS & DESCRIPTION', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              TextField(controller: synCtrl, maxLines: 4, style: AppTheme.bodyRegular.copyWith(fontSize: 13), decoration: const InputDecoration(hintText: 'Enter updated synopsis...')),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE (PUT)')),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isActionInProgress = true);
      try {
        final res = await _apiService.updateMovie(
          _currentMovie.id,
          rating: double.tryParse(ratingCtrl.text.trim()) ?? _currentMovie.rating,
          synopsis: synCtrl.text.trim(),
        );
        if (mounted) {
          setState(() {
            _currentMovie = res;
            _isActionInProgress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Movie updated successfully!', style: AppTheme.monoTag)));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isActionInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.accentVermilion, content: Text('Update failed: $e')));
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
        title: Text('DELETE MOVIE?', style: AppTheme.monoTag.copyWith(color: AppTheme.accentVermilion)),
        content: Text('Delete "${_currentMovie.title}" (${_currentMovie.year}) from the database?', style: AppTheme.bodyRegular),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentVermilion), onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isActionInProgress = true);
      try {
        await _apiService.deleteMovie(_currentMovie.id);
        _watchlistService.remove(_currentMovie.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Movie deleted from database.', style: AppTheme.monoTag)));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isActionInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.accentVermilion, content: Text('Delete failed: $e')));
        }
      }
    }
  }

  Widget _actionBtn({required IconData icon, required VoidCallback onTap, Color? color, String? tooltip}) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppTheme.background.withValues(alpha: 0.8),
          border: Border.all(color: color != null && color != AppTheme.textPrimary ? color : AppTheme.borderLight),
        ),
        child: Icon(icon, color: color ?? AppTheme.textPrimary, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isActionInProgress
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentVermilion, strokeWidth: 1.5))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 360,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  leading: _actionBtn(icon: Icons.arrow_back, onTap: () => Navigator.pop(context, true)),
                  actions: [
                    AnimatedBuilder(
                      animation: _watchlistService,
                      builder: (context, _) {
                        final bookmarked = _watchlistService.isBookmarked(_currentMovie.id);
                        return _actionBtn(
                          icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: bookmarked ? AppTheme.accentVermilion : AppTheme.textPrimary,
                          tooltip: bookmarked ? 'Remove from Watchlist' : 'Add to Watchlist',
                          onTap: () => _watchlistService.toggleBookmark(_currentMovie),
                        );
                      },
                    ),
                    _actionBtn(
                      icon: Icons.share_outlined,
                      tooltip: 'Copy Info to Clipboard',
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text: '${_currentMovie.title} (${_currentMovie.year})\nRating: ${_currentMovie.rating}/10 ★\nDirector: ${_currentMovie.director}\nGenre: ${_currentMovie.genre}\n\n${_currentMovie.synopsis}',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.surfaceElevated,
                            content: Text('Movie details copied to clipboard.', style: AppTheme.monoTag),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _actionBtn(icon: Icons.edit_outlined, tooltip: 'Edit Movie (PUT)', onTap: _showEditDialog),
                    _actionBtn(icon: Icons.delete_outline, color: AppTheme.accentVermilion, tooltip: 'Delete Movie (DELETE)', onTap: _confirmDelete),
                    const SizedBox(width: 10),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PosterImage(url: _currentMovie.posterUrl, title: _currentMovie.title, genre: _currentMovie.genre, year: _currentMovie.year),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black45, Colors.transparent, AppTheme.background.withValues(alpha: 0.85), AppTheme.background],
                              stops: const [0.0, 0.45, 0.85, 1.0],
                            ),
                          ),
                        ),
                        Center(
                          child: InkWell(
                            onTap: _showTrailerDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: AppTheme.background.withValues(alpha: 0.85), border: Border.all(color: AppTheme.accentVermilion)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow_outlined, color: AppTheme.accentVermilion, size: 18),
                                  SizedBox(width: 8),
                                  Text('WATCH TRAILER', style: TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 0.8, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('ID: ${_currentMovie.id.toUpperCase()}', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontSize: 11, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(border: Border.all(color: AppTheme.accentVermilion)),
                              child: Text('★ ${_currentMovie.rating.toStringAsFixed(1)} / 10', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_currentMovie.title, style: AppTheme.displayTitle.copyWith(fontSize: 32, height: 1.1)),
                        const SizedBox(height: 8),
                        Text(
                          '${_currentMovie.year}  •  ${_currentMovie.formattedRuntime}  •  MOOD: ${_currentMovie.mood.toUpperCase()}${_currentMovie.metascore > 0 ? "  •  METASCORE: ${_currentMovie.metascore}" : ""}',
                          style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, color: AppTheme.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _currentMovie.genresList.map((g) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(border: Border.all(color: AppTheme.borderLight)),
                              child: Text(g.toUpperCase(), style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 10, letterSpacing: 0.6)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        _buildCommunityRatingCard(),

                        if (_currentMovie.scoreBreakdown != null) _buildMatchBreakdown(),

                        const SizedBox(height: 20),
                        const Text('STORYLINE & OVERVIEW', style: AppTheme.monoTag),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.only(left: 14),
                          decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppTheme.accentVermilion, width: 2))),
                          child: Text(_currentMovie.synopsis.isNotEmpty ? _currentMovie.synopsis : 'No synopsis available for this movie.', style: AppTheme.bodyRegular.copyWith(fontSize: 14, height: 1.6)),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.borderLight, height: 1),
                        const SizedBox(height: 16),

                        _buildCrewRow('DIRECTOR', _currentMovie.director),
                        const SizedBox(height: 10),
                        _buildCrewRow('STARRING', _currentMovie.actors),
                        const SizedBox(height: 10),
                        _buildCrewRow('VOTES', '${_currentMovie.votes} verified IMDb ratings'),

                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.borderLight, height: 1),
                        const SizedBox(height: 24),

                        if (_similarMovies.isNotEmpty) ...[
                          const Text('MORE MOVIES LIKE THIS', style: AppTheme.monoTag),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 220,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _similarMovies.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 14),
                              itemBuilder: (ctx, idx) {
                                final sim = _similarMovies[idx];
                                return SizedBox(
                                  width: 140,
                                  child: MovieCard(
                                    movie: sim,
                                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: sim))),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('USER REVIEWS', style: AppTheme.monoTag),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 14, color: AppTheme.accentVermilion),
                              label: const Text('+ WRITE A REVIEW', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11)),
                              onPressed: _showAddReviewDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        ..._userReviews.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final r = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('REVIEW #0$idx  •  ${(r['author'] as String).toUpperCase()}', style: const TextStyle(fontFamily: AppTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textSecondary)),
                                    Text('★ ${r['rating']}  [${r['date']}]', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r['comment'] as String, style: AppTheme.bodyRegular.copyWith(fontSize: 13, height: 1.4)),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCrewRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700))),
        Expanded(child: Text(value, style: AppTheme.bodyRegular.copyWith(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildMatchBreakdown() {
    final bd = _currentMovie.scoreBreakdown!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 14, color: AppTheme.accentVermilion),
              const SizedBox(width: 8),
              const Text('MATCH SCORE BREAKDOWN', style: TextStyle(fontFamily: AppTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textPrimary)),
              const Spacer(),
              Text('MATCH: ${_currentMovie.calculatedScore?.toStringAsFixed(1) ?? "--"}%', style: const TextStyle(fontFamily: AppTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.accentVermilion)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderLight, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreCol('BASE SCORE', '${bd['base_score']}'),
              _buildScoreCol('MOOD MATCH', '+${bd['mood_bonus']}'),
              _buildScoreCol('GENRE MATCH', '+${bd['genre_bonus']}'),
              _buildScoreCol('RATING BONUS', '+${bd['rating_bonus']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textSecondary, fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildCommunityRatingCard() {
    return AnimatedBuilder(
      animation: _authService,
      builder: (context, _) {
        final isUserRecommended = _authService.hasRecommended(_currentMovie.id);
        final userPersonalRating = _authService.getUserRating(_currentMovie.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isUserRecommended
                  ? AppTheme.accentVermilion.withValues(alpha: 0.8)
                  : AppTheme.borderLight,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16, color: AppTheme.cyberAmber),
                  const SizedBox(width: 8),
                  const Text(
                    'COMMUNITY CONSENSUS & TOP RATING',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMono,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'TOP: ${_currentMovie.compositeTopRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: AppTheme.cyberAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppTheme.borderLight, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricTile(
                    label: 'COMPOSITE TOP',
                    value: '★ ${_currentMovie.compositeTopRating.toStringAsFixed(1)}',
                    subtext: 'IMDb 60% + User 25% + Recs',
                    valueColor: AppTheme.cyberAmber,
                  ),
                  _buildMetricTile(
                    label: 'IMDb RATING',
                    value: '★ ${_currentMovie.rating.toStringAsFixed(1)}',
                    subtext: '${_currentMovie.votes} votes',
                    valueColor: AppTheme.ratingStar,
                  ),
                  _buildMetricTile(
                    label: 'USER RATINGS',
                    value: '★ ${(_currentMovie.userRatingAverage ?? _currentMovie.rating).toStringAsFixed(1)}',
                    subtext: '${_currentMovie.userRatingsCount} submissions',
                    valueColor: AppTheme.accentVermilion,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up_alt, size: 14, color: AppTheme.cyberAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_currentMovie.userRecommendationsCount} users recommend this movie to watch',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 10,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isUserRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.accentVermilion.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'YOU RECOMMENDED',
                          style: TextStyle(
                            fontFamily: AppTheme.fontMono,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentVermilion,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isUserRecommended
                            ? AppTheme.accentVermilion.withValues(alpha: 0.12)
                            : Colors.transparent,
                        side: BorderSide(
                          color: isUserRecommended
                              ? AppTheme.accentVermilion
                              : AppTheme.borderLight,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _toggleUserRecommendation,
                      icon: Icon(
                        isUserRecommended ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 15,
                        color: isUserRecommended ? AppTheme.accentVermilion : AppTheme.textPrimary,
                      ),
                      label: Text(
                        isUserRecommended ? 'RECOMMENDED' : 'RECOMMEND FILM',
                        style: TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isUserRecommended ? AppTheme.accentVermilion : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userPersonalRating != null
                            ? AppTheme.cyberAmber
                            : AppTheme.accentVermilion,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _showRateFilmDialog,
                      icon: const Icon(Icons.star, size: 15, color: Colors.black),
                      label: Text(
                        userPersonalRating != null
                            ? 'RATED: ${userPersonalRating.toStringAsFixed(1)} ★'
                            : 'RATE FILM',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontMono,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontMono,
            fontSize: 9,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.fontMono,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: const TextStyle(
            fontFamily: AppTheme.fontMono,
            fontSize: 8.5,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
