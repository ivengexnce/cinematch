import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../models/movie.dart';
import 'movie_card.dart';
import 'recommendation_chips.dart';

@Preview(name: 'Movie Card - Sci-Fi', size: Size(220, 320))
Widget previewSciFiMovieCard() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0E1B),
      cardColor: const Color(0xFF1E2230),
    ),
    home: Scaffold(
      backgroundColor: const Color(0xFF0B0E1B),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 300,
          child: MovieCard(
            movie: const Movie(
              id: 'prev_1',
              title: 'Interstellar',
              genre: 'Sci-Fi',
              director: 'Christopher Nolan',
              year: 2014,
              rating: 8.7,
              synopsis: 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity survival.',
              posterUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=800&q=80',
              mood: 'Mind-Bending',
              recommendedScore: 98.0,
            ),
            onTap: () {},
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Movie Card - Animation', size: Size(220, 320))
Widget previewAnimationMovieCard() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0E1B),
      cardColor: const Color(0xFF1E2230),
    ),
    home: Scaffold(
      backgroundColor: const Color(0xFF0B0E1B),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 300,
          child: MovieCard(
            movie: const Movie(
              id: 'prev_2',
              title: 'Spider-Verse',
              genre: 'Animation',
              director: 'Joaquim Dos Santos',
              year: 2023,
              rating: 8.9,
              synopsis: 'Miles Morales catapults across the Multiverse.',
              posterUrl: 'https://images.unsplash.com/photo-1635805737707-575885ab0820?auto=format&fit=crop&w=800&q=80',
              mood: 'Exciting',
              recommendedScore: 96.5,
            ),
            onTap: () {},
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Recommendation Chips Filter Bar', size: Size(500, 160))
Widget previewRecommendationChips() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: Scaffold(
      backgroundColor: const Color(0xFF0B0E1B),
      body: Center(
        child: RecommendationChips(
          selectedMood: 'Adrenaline',
          selectedGenre: 'Action',
          onMoodChanged: (_) {},
          onGenreChanged: (_) {},
        ),
      ),
    ),
  );
}
