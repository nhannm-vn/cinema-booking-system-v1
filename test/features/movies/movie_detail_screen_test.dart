import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_v1/core/routes/app_router.dart';
import 'package:cinema_booking_v1/core/theme/app_theme.dart';
import 'package:cinema_booking_v1/features/movies/data/movie_model.dart';
import 'package:cinema_booking_v1/features/movies/presentation/screens/movie_detail_screen.dart';
import 'package:cinema_booking_v1/shared/widgets/app_button.dart';
import 'package:cinema_booking_v1/shared/widgets/spec_cell.dart';

Widget createMovieDetailTestHarness({
  required MovieModel movie,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    onGenerateRoute: (settings) {
      if (settings.name == AppRoutes.showtimes) {
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Text('SHOWTIMES FOR: ${args['movieTitle']}')),
        );
      }
      return MaterialPageRoute(
        builder: (_) => Scaffold(body: Text('ROUTE: ${settings.name}')),
      );
    },
    home: MovieDetailScreen(movie: movie),
  );
}

void main() {
  group('S04 Movie Detail Screen Widget Tests', () {
    final nowShowingMovie = MovieModel(
      id: 'mov_detail_01',
      title: 'Oppenheimer',
      genres: const ['Lịch sử', 'Chính kịch'],
      durationMin: 180,
      ageRating: 'T18',
      releaseDate: DateTime.now().subtract(const Duration(days: 10)),
      isActive: true,
      description: 'Câu chuyện về cuộc đời của nhà vật lý J. Robert Oppenheimer.',
      director: 'Christopher Nolan',
      castMembers: const ['Cillian Murphy', 'Emily Blunt', 'Matt Damon'],
      trailerUrl: 'https://youtube.com/watch?v=oppenheimer',
    );

    final upcomingMovie = MovieModel(
      id: 'mov_detail_02',
      title: 'Avatar 3: Fire and Ash',
      genres: const ['Khoa học viễn tưởng', 'Hành động'],
      durationMin: 195,
      ageRating: 'T13',
      releaseDate: DateTime.now().add(const Duration(days: 60)),
      isActive: true,
      description: 'Hành trình mới trên mặt trăng Pandora.',
      director: 'James Cameron',
      castMembers: const ['Sam Worthington', 'Zoe Saldana'],
    );

    testWidgets('renders all movie metadata, spec cells, and crew', (tester) async {
      await tester.pumpWidget(createMovieDetailTestHarness(movie: nowShowingMovie));

      expect(find.text('Oppenheimer'), findsOneWidget);
      expect(find.text('T18'), findsAtLeastNWidgets(1));
      expect(find.byType(SpecCell), findsNWidgets(3));
      expect(find.text('180'), findsOneWidget);
      expect(find.text('PHÚT'), findsOneWidget);
      expect(find.text('ĐỘ TUỔI'), findsOneWidget);
      expect(find.text('THỂ LOẠI'), findsOneWidget);

      expect(find.text('TÓM TẮT NỘI DUNG'), findsOneWidget);
      expect(find.text('Câu chuyện về cuộc đời của nhà vật lý J. Robert Oppenheimer.'), findsOneWidget);
      expect(find.text('Christopher Nolan'), findsOneWidget);
      expect(find.text('Cillian Murphy, Emily Blunt, Matt Damon'), findsOneWidget);
      expect(find.byKey(const Key('movie_detail_trailer_button')), findsOneWidget);
    });

    testWidgets('enables ĐẶT VÉ CTA for now showing movie and navigates to showtimes', (tester) async {
      await tester.pumpWidget(createMovieDetailTestHarness(movie: nowShowingMovie));

      final ctaFinder = find.byKey(const Key('movie_detail_book_cta'));
      expect(ctaFinder, findsOneWidget);
      expect(find.text('ĐẶT VÉ'), findsOneWidget);

      final button = tester.widget<AppButton>(ctaFinder);
      expect(button.onPressed, isNotNull);

      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      expect(find.text('SHOWTIMES FOR: Oppenheimer'), findsOneWidget);
    });

    testWidgets('disables CTA with CHƯA MỞ BÁN label for upcoming movie', (tester) async {
      await tester.pumpWidget(createMovieDetailTestHarness(movie: upcomingMovie));

      final ctaFinder = find.byKey(const Key('movie_detail_book_cta'));
      expect(ctaFinder, findsOneWidget);
      expect(find.text('CHƯA MỞ BÁN'), findsOneWidget);

      final button = tester.widget<AppButton>(ctaFinder);
      expect(button.onPressed, isNull);
    });
  });
}
