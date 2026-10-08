import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import 'poster_image.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool showScore;
  final int? rankNumber;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.showScore = false,
    this.rankNumber,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final watchlistService = WatchlistService();
    final movie = widget.movie;
    final rank = widget.rankNumber;

    return AnimatedBuilder(
      animation: watchlistService,
      builder: (context, _) {
        final isBookmarked = watchlistService.isBookmarked(movie.id);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isHovered
                    ? AppTheme.accentVermilion.withValues(alpha: 0.8)
                    : AppTheme.borderLight,
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Area
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PosterImage(
                          url: movie.posterUrl,
                          title: movie.title,
                          genre: movie.genre,
                          year: movie.year,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.zero,
                        ),

                        // Scrim gradient
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black38,
                                  Colors.transparent,
                                  Colors.black87,
                                ],
                                stops: [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Top Rank Tag
                        if (rank != null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.background.withValues(alpha: 0.9),
                                border: Border.all(
                                  color: rank == 1 ? AppTheme.accentVermilion : AppTheme.borderLight,
                                ),
                              ),
                              child: Text(
                                '#${rank.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontMono,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: rank == 1 ? AppTheme.accentVermilion : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),

                        // Watchlist Bookmark Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: InkWell(
                            onTap: () => watchlistService.toggleBookmark(movie),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppTheme.background.withValues(alpha: 0.85),
                                border: Border.all(
                                  color: isBookmarked ? AppTheme.accentVermilion : AppTheme.borderLight,
                                ),
                              ),
                              child: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                size: 14,
                                color: isBookmarked ? AppTheme.accentVermilion : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),

                        // Bottom Poster Metadata (Rating & Match)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.85),
                                  border: Border.all(color: AppTheme.borderLight, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '★ ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.ratingStar,
                                      ),
                                    ),
                                    Text(
                                      movie.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontMono,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ratingStar,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.showScore)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background.withValues(alpha: 0.92),
                                    border: Border.all(color: AppTheme.accentVermilion, width: 0.8),
                                  ),
                                  child: Text(
                                    '${movie.matchPercentage}% MATCH',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontMono,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accentVermilion,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.background.withValues(alpha: 0.88),
                                    border: Border.all(color: AppTheme.borderLight, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.thumb_up_alt,
                                        size: 9,
                                        color: AppTheme.cyberAmber,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${movie.userRecommendationsCount}',
                                        style: const TextStyle(
                                          fontFamily: AppTheme.fontMono,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.cyberAmber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Film Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontDisplay,
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${movie.year}  /  ${movie.genre.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontMono,
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.cyberAmber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                'TOP ${movie.compositeTopRating.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontMono,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.cyberAmber,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${movie.userRecommendationsCount} recs',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontMono,
                                fontSize: 8.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
