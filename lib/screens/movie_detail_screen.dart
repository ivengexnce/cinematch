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

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _authService.addToWatchHistory(_currentMovie.id);
    _fetchSimilarMovies();
    _fetchFreshReviews();
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

  Future<void> _fetchFreshReviews() async {
    try {
      final reviews = await _apiService.getMovieReviews(_currentMovie.id);
      if (mounted && reviews.isNotEmpty) {
        setState(() {
          _currentMovie = _currentMovie.copyWith(reviews: reviews, reviewsCount: reviews.length);
        });
      }
    } catch (_) {}
  }

  void _showScoreBreakdownModal() {
    final breakdown = _apiService.calculateScoreBreakdown(
      _currentMovie,
      userFavoriteGenres: _authService.favoriteGenres.toList(),
      userFavoriteMoods: _authService.favoriteMoods.toList(),
      watchHistory: _authService.watchHistory,
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
            Text(_currentMovie.title, style: const TextStyle(fontFamily: AppTheme.fontDisplay, fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('Why CineMatch recommends this movie for your taste:', style: AppTheme.bodyRegular.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            _buildScoreBreakdownItem('Genre Affinity Match', '+${breakdown['genre_match']}', 'Matches your preferred genres'),
            _buildScoreBreakdownItem('IMDb Rating Quality', '+${breakdown['imdb_rating']}', 'Normalized global critic & fan score'),
            _buildScoreBreakdownItem('CineMatch Community Upvotes', '+${breakdown['community_rating']}', 'Bayesian smoothed community recommendations'),
            _buildScoreBreakdownItem('Watch History Taste Affinity', '+${breakdown['user_history']}', 'Correlated with your saved & watched movies'),
            _buildScoreBreakdownItem('Mood Match (${_currentMovie.mood})', '+${breakdown['mood_match']}', 'Aligns with your mood discovery target'),
            const Divider(color: AppTheme.borderLight, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('FINAL CINEMATCH SCORE', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text('${breakdown['final_match']}%', style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.cyberAmber)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdownItem(String title, String bonus, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Text(desc, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
            child: Text(bonus, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentVermilion)),
          ),
        ],
      ),
    );
  }

  void _showTrailerBottomSheet() {
    bool isPlaying = true;
    double progress = 0.25;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'OFFICIAL TRAILER — ${_currentMovie.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PosterImage(
                      url: _currentMovie.backdropUrl.isNotEmpty ? _currentMovie.backdropUrl : _currentMovie.posterUrl,
                      title: _currentMovie.title,
                      genre: _currentMovie.genre,
                      year: _currentMovie.year,
                      fit: BoxFit.cover,
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.4)),
                    Center(
                      child: IconButton(
                        iconSize: 56,
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: AppTheme.accentVermilion),
                        onPressed: () => setSheetState(() => isPlaying = !isPlaying),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Text('0:${(progress * 140).round().toString().padLeft(2, '0')}', style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: progress,
                              min: 0.0,
                              max: 1.0,
                              activeColor: AppTheme.accentVermilion,
                              inactiveColor: Colors.white30,
                              onChanged: (val) => setSheetState(() => progress = val),
                            ),
                          ),
                          const Text('2:20', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Streaming trailer for "${_currentMovie.title}" (${_currentMovie.year}). Directed by ${_currentMovie.director}. Language: ${_currentMovie.language.isNotEmpty ? _currentMovie.language : "English"}.',
                style: AppTheme.monoTag.copyWith(fontSize: 10, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    final commentCtrl = TextEditingController();
    final photoUrlCtrl = TextEditingController();
    double rating = 8.5;
    bool isRecommended = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
          title: const Text('SUBMIT CRITIC REVIEW', style: AppTheme.monoTag),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RATING:', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, color: AppTheme.textSecondary)),
                    Text('★ ${rating.toStringAsFixed(1)} / 10', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.cyberAmber, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                Slider(
                  value: rating,
                  min: 1.0,
                  max: 10.0,
                  divisions: 18,
                  activeColor: AppTheme.cyberAmber,
                  onChanged: (val) => setDialogState(() => rating = val),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isRecommended,
                  title: const Text('👍 I recommend this movie to the community', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                  activeColor: AppTheme.accentVermilion,
                  onChanged: (val) => setDialogState(() => isRecommended = val ?? true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commentCtrl,
                  maxLines: 4,
                  style: AppTheme.bodyRegular.copyWith(fontSize: 13),
                  decoration: const InputDecoration(hintText: 'Share your thoughtful review, analysis, or impressions...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: photoUrlCtrl,
                  style: const TextStyle(fontSize: 12, fontFamily: AppTheme.fontMono),
                  decoration: const InputDecoration(
                    hintText: 'Optional review photo URL (or poster snapshot)...',
                    prefixIcon: Icon(Icons.add_photo_alternate_outlined, size: 16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (commentCtrl.text.trim().isNotEmpty) {
                  final newRev = UserReview(
                    id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                    userId: _authService.currentUser.id,
                    author: _authService.currentUser.name,
                    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120&q=80',
                    rating: rating,
                    comment: commentCtrl.text.trim(),
                    date: 'TODAY',
                    isRecommended: isRecommended,
                    photoUrl: photoUrlCtrl.text.trim().isNotEmpty ? photoUrlCtrl.text.trim() : null,
                  );

                  Navigator.pop(ctx);
                  _authService.addReview(newRev);
                  await _apiService.submitReview(_currentMovie.id, newRev);

                  if (mounted) {
                    final updatedReviews = List<UserReview>.from(_currentMovie.reviews);
                    updatedReviews.insert(0, newRev);
                    setState(() {
                      _currentMovie = _currentMovie.copyWith(
                        reviews: updatedReviews,
                        reviewsCount: updatedReviews.length,
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('✓ Review published & synced with CineMatch!', style: AppTheme.monoTag)),
                    );
                  }
                }
              },
              child: const Text('PUBLISH REVIEW'),
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
                ? '👍 Recommended "${_currentMovie.title}" to CineMatch! Count incremented.'
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
              Text('Rate "${_currentMovie.title}" (${_currentMovie.year})', style: AppTheme.bodyRegular.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('YOUR SCORE:', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11, color: AppTheme.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.cyberAmber.withValues(alpha: 0.15), border: Border.all(color: AppTheme.cyberAmber)),
                    child: Text('★ ${selectedRating.toStringAsFixed(1)} / 10', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.cyberAmber, fontWeight: FontWeight.w700, fontSize: 13)),
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
                  setState(() => _currentMovie = Movie.fromJson(res['movie']));
                } else if (mounted) {
                  final curCount = _currentMovie.userRatingsCount + 1;
                  final curAvg = double.parse(((((_currentMovie.userRatingAverage ?? _currentMovie.rating) * _currentMovie.userRatingsCount) + selectedRating) / curCount).toStringAsFixed(1));
                  setState(() => _currentMovie = _currentMovie.copyWith(userRatingAverage: curAvg, userRatingsCount: curCount));
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.surfaceElevated,
                      content: Text('★ Rated ${selectedRating.toStringAsFixed(1)}/10! CineMatch rating refreshed.', style: AppTheme.monoTag),
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
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
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
                      tooltip: 'Share Film',
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                          text: '🎬 ${_currentMovie.title} (${_currentMovie.year})\n⭐ IMDb: ${_currentMovie.rating}/10\n🎬 CineMatch: ${_currentMovie.cineMatchScore.toStringAsFixed(1)}/10\n👍 ${_currentMovie.recommendationPercentage}% Recommend\n\n"${_currentMovie.synopsis}"\n\nDiscover on CineMatch App.',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.surfaceElevated,
                            content: Text('✓ Movie summary copied to clipboard for sharing!', style: AppTheme.monoTag),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _actionBtn(icon: Icons.edit_outlined, tooltip: 'Edit Movie', onTap: _showEditDialog),
                    _actionBtn(icon: Icons.delete_outline, color: AppTheme.accentVermilion, tooltip: 'Delete Movie', onTap: _confirmDelete),
                    const SizedBox(width: 10),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PosterImage(
                          url: _currentMovie.backdropUrl.isNotEmpty ? _currentMovie.backdropUrl : _currentMovie.posterUrl,
                          title: _currentMovie.title,
                          genre: _currentMovie.genre,
                          year: _currentMovie.year,
                          fit: BoxFit.cover,
                        ),
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
                            onTap: _showTrailerBottomSheet,
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
                        // ID Pill & Match Percent
                        Row(
                          children: [
                            Text('ID: ${_currentMovie.id.toUpperCase()}', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontSize: 11, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            InkWell(
                              onTap: _showScoreBreakdownModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyberAmber.withValues(alpha: 0.15),
                                  border: Border.all(color: AppTheme.cyberAmber),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🎯 ', style: TextStyle(fontSize: 10)),
                                    Text('${_currentMovie.matchPercentage}% CINEMATCH SCORE', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.cyberAmber, fontWeight: FontWeight.w700, fontSize: 11)),
                                  ],
                                ),
                              ),
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

                        // Quick Action Buttons (Trailer, Recommend, Rate, Watched)
                        _buildQuickActionBar(),

                        const SizedBox(height: 20),

                        // Section 4: Dual Ratings & Community Display Card
                        _buildDualRatingsCard(),

                        const SizedBox(height: 20),

                        // Section 52: Movie Statistics Grid
                        _buildMovieStatisticsGrid(),

                        const SizedBox(height: 24),
                        const Text('STORYLINE & OVERVIEW', style: AppTheme.monoTag),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.only(left: 14),
                          decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppTheme.accentVermilion, width: 2))),
                          child: Text(_currentMovie.synopsis.isNotEmpty ? _currentMovie.synopsis : 'No synopsis available for this movie.', style: AppTheme.bodyRegular.copyWith(fontSize: 14, height: 1.6)),
                        ),

                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.borderLight, height: 1),
                        const SizedBox(height: 20),

                        // Cast Horizontal Cards
                        if (_currentMovie.castList.isNotEmpty) ...[
                          const Text('FEATURED CAST', style: AppTheme.monoTag),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _currentMovie.castList.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (ctx, idx) {
                                final actor = _currentMovie.castList[idx];
                                return Container(
                                  width: 110,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    border: Border.all(color: AppTheme.borderLight),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppTheme.surfaceElevated,
                                        child: Text(actor.isNotEmpty ? actor[0] : 'A', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.cyberAmber, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        actor,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: AppTheme.borderLight, height: 1),
                          const SizedBox(height: 20),
                        ],

                        // Metadata Information Rows
                        _buildCrewRow('DIRECTOR', _currentMovie.director),
                        const SizedBox(height: 8),
                        _buildCrewRow('LANGUAGE', _currentMovie.language.isNotEmpty ? _currentMovie.language : 'English'),
                        const SizedBox(height: 8),
                        _buildCrewRow('COUNTRY', _currentMovie.country.isNotEmpty ? _currentMovie.country : 'United States'),
                        const SizedBox(height: 8),
                        _buildCrewRow('RUNTIME', '${_currentMovie.runtime} minutes'),

                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.borderLight, height: 1),
                        const SizedBox(height: 24),

                        // Section 25: Similar Movies
                        if (_similarMovies.isNotEmpty) ...[
                          const Text('YOU MAY ALSO LIKE (SIMILAR MOVIES)', style: AppTheme.monoTag),
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

                        // Reviews Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('COMMUNITY REVIEWS (${_currentMovie.reviews.length})', style: AppTheme.monoTag),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 14, color: AppTheme.accentVermilion),
                              label: const Text('+ WRITE A REVIEW', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11)),
                              onPressed: _showAddReviewDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        ..._currentMovie.reviews.map((r) => _buildReviewCard(r)),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActionBar() {
    return AnimatedBuilder(
      animation: _authService,
      builder: (ctx, _) {
        final isWatched = _authService.isWatched(_currentMovie.id);
        final isRecommended = _authService.hasRecommended(_currentMovie.id);
        final userRating = _authService.getUserRating(_currentMovie.id);

        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(isRecommended ? Icons.thumb_up : Icons.thumb_up_alt_outlined, size: 15, color: isRecommended ? AppTheme.cyberAmber : AppTheme.textPrimary),
                label: Text(isRecommended ? 'RECOMMENDED' : 'RECOMMEND', style: TextStyle(color: isRecommended ? AppTheme.cyberAmber : AppTheme.textPrimary)),
                onPressed: _toggleUserRecommendation,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: userRating != null ? AppTheme.cyberAmber : AppTheme.accentVermilion),
                icon: const Icon(Icons.star, size: 15, color: Colors.black),
                label: Text(userRating != null ? '${userRating.toStringAsFixed(1)} ★' : 'RATE FILM', style: const TextStyle(color: Colors.black)),
                onPressed: _showRateFilmDialog,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isWatched ? AppTheme.accentVermilion : AppTheme.borderLight),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              onPressed: () {
                final nowWatched = _authService.toggleWatched(_currentMovie.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceElevated,
                    content: Text(nowWatched ? '✓ Marked "${_currentMovie.title}" as watched!' : 'Removed from watched list.', style: AppTheme.monoTag),
                  ),
                );
              },
              child: Icon(isWatched ? Icons.check_circle : Icons.visibility_outlined, size: 18, color: isWatched ? AppTheme.accentVermilion : AppTheme.textSecondary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDualRatingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_outlined, size: 16, color: AppTheme.cyberAmber),
              const SizedBox(width: 8),
              const Text('DUAL RATINGS TRANSPARENCY', style: TextStyle(fontFamily: AppTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textPrimary)),
              const Spacer(),
              InkWell(
                onTap: _showScoreBreakdownModal,
                child: const Text('EXPLAIN WHY →', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9.5, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700)),
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
                label: 'IMDb AUDIENCE',
                value: '★ ${_currentMovie.rating.toStringAsFixed(1)}',
                subtext: '${_currentMovie.votes} verified votes',
                valueColor: AppTheme.ratingStar,
              ),
              _buildMetricTile(
                label: 'CINEMATCH SCORE',
                value: '★ ${_currentMovie.cineMatchScore.toStringAsFixed(1)}',
                subtext: 'Bayesian smoothed composite',
                valueColor: AppTheme.cyberAmber,
              ),
              _buildMetricTile(
                label: 'COMMUNITY UPVOTES',
                value: '👍 ${_currentMovie.recommendationPercentage}%',
                subtext: '${_currentMovie.userRecommendationsCount} recommends',
                valueColor: AppTheme.accentVermilion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovieStatisticsGrid() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MOVIE METRICS & ENGAGEMENT', style: AppTheme.monoTag),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol('IMDb Rating', '★ ${_currentMovie.rating.toStringAsFixed(1)}'),
              _buildStatCol('IMDb Votes', _currentMovie.votes),
              _buildStatCol('CineMatch Rating', '★ ${_currentMovie.cineMatchScore.toStringAsFixed(1)}'),
              _buildStatCol('Recommends', '${_currentMovie.userRecommendationsCount}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCol('Reviews', '${_currentMovie.reviewsCount}'),
              _buildStatCol('Recommend %', '${_currentMovie.recommendationPercentage}%'),
              _buildStatCol('Runtime', '${_currentMovie.runtime}m'),
              _buildStatCol('Metascore', _currentMovie.metascore > 0 ? '${_currentMovie.metascore}' : 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildReviewCard(UserReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.accentVermilion,
                child: Text(r.author.isNotEmpty ? r.author[0] : 'U', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author, style: const TextStyle(fontFamily: AppTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textPrimary)),
                    Text(r.date, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.cyberAmber.withValues(alpha: 0.15), border: Border.all(color: AppTheme.cyberAmber, width: 0.8)),
                child: Text('★ ${r.rating.toStringAsFixed(1)}', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.cyberAmber, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              const SizedBox(width: 6),
              if (r.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.accentVermilion.withValues(alpha: 0.15), border: Border.all(color: AppTheme.accentVermilion, width: 0.8)),
                  child: const Text('RECOMMENDED', style: TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700, fontSize: 8.5)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.comment, style: AppTheme.bodyRegular.copyWith(fontSize: 13, height: 1.4)),
          if (r.photoUrl != null && r.photoUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                r.photoUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],
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

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 9, color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 14, fontWeight: FontWeight.w700, color: valueColor)),
        const SizedBox(height: 2),
        Text(subtext, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 8.5, color: AppTheme.textMuted)),
      ],
    );
  }
}
