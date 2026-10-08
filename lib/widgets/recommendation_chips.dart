import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecommendationChips extends StatelessWidget {
  final String selectedMood;
  final String selectedGenre;
  final ValueChanged<String> onMoodChanged;
  final ValueChanged<String> onGenreChanged;

  const RecommendationChips({
    super.key,
    required this.selectedMood,
    required this.selectedGenre,
    required this.onMoodChanged,
    required this.onGenreChanged,
  });

  static const List<Map<String, String>> registers = [
    {'internal': 'Adrenaline', 'display': '🔥 Adrenaline'},
    {'internal': 'Mind-Bending', 'display': '🧠 Mind-Bending'},
    {'internal': 'Suspense', 'display': '😱 Suspense'},
    {'internal': 'Romantic', 'display': '❤️ Romantic'},
    {'internal': 'Feel-Good', 'display': '😂 Feel-Good'},
    {'internal': 'Emotional', 'display': '😢 Emotional'},
    {'internal': 'Scary', 'display': '👻 Scary'},
    {'internal': 'Sci-Fi', 'display': '🚀 Sci-Fi'},
    {'internal': 'Mystery', 'display': '🕵️ Mystery'},
    {'internal': 'Chill', 'display': '🌙 Chill'},
    {'internal': 'Thought-Provoking', 'display': '🎭 Thought-Provoking'},
  ];

  static const List<String> genres = [
    'All',
    'Action',
    'Crime',
    'Drama',
    'Sci-Fi',
    'Thriller',
    'Mystery',
    'Adventure',
    'Comedy',
    'Animation',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.borderLight, width: 1),
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Mood Selection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                const Text(
                  'CHOOSE MOOD',
                  style: TextStyle(
                    fontFamily: AppTheme.fontMono,
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentVermilion,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: registers.length,
              separatorBuilder: (context, index) => const SizedBox(
                width: 16,
                child: Center(
                  child: Text(
                    '/',
                    style: TextStyle(
                      fontFamily: AppTheme.fontMono,
                      color: AppTheme.borderLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              itemBuilder: (context, index) {
                final r = registers[index];
                final isSelected = selectedMood.toLowerCase() ==
                    r['internal']!.toLowerCase();

                return InkWell(
                  onTap: () => onMoodChanged(r['internal']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppTheme.accentVermilion
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      r['display']!,
                      style: TextStyle(
                        fontFamily: AppTheme.fontDisplay,
                        fontSize: 14,
                        fontStyle: isSelected ? FontStyle.italic : FontStyle.normal,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppTheme.borderSubtle),

          // Row 2: Genre Selection
          SizedBox(
            height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: genres.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final g = genres[index];
                final isSelected =
                    selectedGenre.toLowerCase() == g.toLowerCase();

                return InkWell(
                  onTap: () => onGenreChanged(g),
                  child: Center(
                    child: Text(
                      g.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 1.0,
                        color: isSelected
                            ? AppTheme.accentVermilion
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
