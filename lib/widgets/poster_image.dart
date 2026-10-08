import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PosterImage extends StatelessWidget {
  final String url;
  final String? title;
  final String? genre;
  final int? year;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const PosterImage({
    super.key,
    required this.url,
    this.title,
    this.genre,
    this.year,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(2),
      child: Container(
        width: width,
        height: height,
        color: AppTheme.surfaceElevated,
        child: url.isNotEmpty
            ? Image.network(
                url,
                width: width,
                height: height,
                cacheWidth: 320,
                filterQuality: FilterQuality.low,
                fit: fit,
                loadingBuilder: (_, child, prog) => prog == null ? child : _buildFallback(isLoading: true),
                errorBuilder: (context, error, stackTrace) => _buildFallback(isLoading: false),
              )
            : _buildFallback(isLoading: false),
      ),
    );
  }

  Widget _buildFallback({required bool isLoading}) {
    final safeTitle = (title?.trim().isNotEmpty == true) ? title!.trim() : 'Movie';
    final initials = safeTitle.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      width: width,
      height: height,
      color: const Color(0xFF131722),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/app_logo.png',
                width: (width != null && width! < 100) ? 36 : 64,
                height: (height != null && height! < 140) ? 36 : 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  initials.isNotEmpty ? initials : 'CM',
                  style: TextStyle(
                    fontFamily: AppTheme.fontDisplay,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CINEMATCH', style: TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  if (year != null) Text('$year', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textMuted, fontSize: 9)),
                ],
              ),
              Center(
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentVermilion))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderLight)),
                        child: Text(initials.isNotEmpty ? initials : 'CM', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(safeTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: AppTheme.fontDisplay, color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600, height: 1.15)),
                  const SizedBox(height: 2),
                  Text((genre ?? 'CINEMA').toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textSecondary, fontSize: 8, letterSpacing: 0.8)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
