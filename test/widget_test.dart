import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cinematch_flutter_app/main.dart';
import 'package:cinematch_flutter_app/models/movie.dart';
import 'package:cinematch_flutter_app/services/watchlist_service.dart';
import 'package:cinematch_flutter_app/services/api_service.dart';
import 'package:cinematch_flutter_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CineMatch Core Tests', () {
    testWidgets('CineMatch app smoke test and UI mount', (WidgetTester tester) async {
      await tester.pumpWidget(const CineMatchApp());
      expect(find.text('CINEMATCH'), findsWidgets);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Explore'), findsWidgets);
      expect(find.text('For You'), findsWidgets);
    });

    test('Movie model serialization and formatting', () {
      final json = {
        'id': 'test_1',
        'title': 'Inception',
        'genre': 'Action, Sci-Fi',
        'mood': 'Mind-Bending',
        'director': 'Christopher Nolan',
        'actors': 'Leonardo DiCaprio',
        'year': 2010,
        'runtime': 148,
        'rating': 8.8,
        'votes': '2000000',
        'metascore': 74,
        'synopsis': 'A thief who steals corporate secrets through dream-sharing technology.',
        'poster_url': 'https://example.com/poster.jpg',
        'recommended_score': 95.0,
      };

      final movie = Movie.fromJson(json);
      expect(movie.title, 'Inception');
      expect(movie.formattedRuntime, '2h 28m');
      expect(movie.genresList, ['Action', 'Sci-Fi']);
      expect(movie.matchPercentage, 85);

      final exported = movie.toJson();
      expect(exported['id'], 'test_1');
      expect(exported['year'], 2010);
    });

    test('WatchlistService bookmarking lifecycle', () {
      final service = WatchlistService();
      service.clear();
      expect(service.count, 0);

      const movie = Movie(
        id: 'w_test_1',
        title: 'Interstellar',
        genre: 'Sci-Fi',
        synopsis: 'A team of explorers travel through a wormhole.',
        posterUrl: 'https://example.com/interstellar.jpg',
      );

      service.add(movie);
      expect(service.count, 1);
      expect(service.isBookmarked('w_test_1'), isTrue);

      service.toggleBookmark(movie);
      expect(service.count, 0);
      expect(service.isBookmarked('w_test_1'), isFalse);

      service.add(movie);
      service.clear();
      expect(service.count, 0);
    });

    test('ApiService local in-memory recommendation algorithm math', () {
      final api = ApiService();
      // Ensure seed calculations clamp correctly between 72 and 99
      final recs = api.getImmediateRecommendations(mood: 'Adrenaline', genre: 'Action', limit: 5);
      expect(recs, isA<List<Movie>>());
      for (final m in recs) {
        if (m.calculatedScore != null) {
          expect(m.calculatedScore!, greaterThanOrEqualTo(72.0));
          expect(m.calculatedScore!, lessThanOrEqualTo(99.0));
        }
      }
    });

    test('Composite top rating and community recommendations counter', () {
      const movie = Movie(
        id: 'rec_test',
        title: 'The Dark Knight',
        genre: 'Action, Crime',
        synopsis: 'Batman raises the stakes in his war on crime.',
        posterUrl: 'https://example.com/tdk.jpg',
        rating: 9.0,
        userRatingAverage: 9.4,
        userRatingsCount: 12,
        userRecommendationsCount: 150,
      );

      // Composite rating balances IMDb (60%), User Rating (25%), and Recs (15%)
      expect(movie.compositeTopRating, greaterThanOrEqualTo(9.0));
      expect(movie.compositeTopRating, lessThanOrEqualTo(10.0));
      expect(movie.userRecommendationsCount, 150);
      expect(movie.userRatingAverage, 9.4);
    });

    test('AuthService login, recommendations, and personal ratings', () {
      final auth = AuthService();
      auth.login(name: 'Sarah Connor', handle: 'sarah_c', email: 'sarah@cine.io');
      expect(auth.currentUser.name, 'Sarah Connor');
      expect(auth.currentUser.handle, '@sarah_c');

      final toggled = auth.toggleRecommendation('m_101');
      expect(toggled, isTrue);
      expect(auth.hasRecommended('m_101'), isTrue);
      expect(auth.recommendationsCount, greaterThanOrEqualTo(1));

      auth.setUserRating('m_101', 9.5);
      expect(auth.getUserRating('m_101'), 9.5);
      expect(auth.ratingsCount, greaterThanOrEqualTo(1));
    });
  });
}

