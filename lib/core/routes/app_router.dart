import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cinemas/data/cinema_model.dart';
import '../../features/cinemas/presentation/screens/cinema_detail_screen.dart';
import '../../features/cinemas/presentation/screens/cinema_map_screen.dart';
import '../../features/movies/data/movie_model.dart';
import '../../features/movies/presentation/screens/home_screen.dart';
import '../../features/movies/presentation/screens/movie_detail_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Named route definitions for all screens S01 to S31.
/// References: ROLE_FLOWS.md Section 6 & PROJECT_STRUCTURE.md
abstract final class AppRoutes {
  // Auth
  static const String login = '/login'; // S01
  static const String register = '/register'; // S02

  // Customer & Guest
  static const String home = '/home'; // S03
  static const String movieDetail = '/movie-detail'; // S04
  static const String showtimes = '/showtimes'; // S05
  static const String seatSelect = '/seat-select'; // S06
  static const String foodSelect = '/food-select'; // S07
  static const String checkout = '/checkout'; // S08
  static const String vnpayWebview = '/vnpay-webview';
  static const String ticketSuccess = '/ticket-success'; // S09
  static const String myTickets = '/my-tickets'; // S10
  static const String ticketDetail = '/ticket-detail';
  static const String profile = '/profile'; // S11
  static const String editProfile = '/edit-profile';
  static const String cinemas = '/cinemas'; // S17
  static const String cinemaDetail = '/cinema-detail'; // S17B
  static const String notifications = '/notifications'; // S30
  static const String supportChat = '/support-chat'; // S31

  // Staff
  static const String staffCheckin = '/staff/checkin'; // S18
  static const String staffFood = '/staff/food'; // S19
  static const String staffCounterShowtimes = '/staff/counter-showtimes'; // S20
  static const String staffCounterPayment = '/staff/counter-payment'; // S21

  // Management (Manager & Admin)
  static const String managementHome = '/management'; // S12
  static const String dashboard = '/management/dashboard'; // S22
  static const String manageMovies = '/management/movies'; // S13
  static const String manageShowtimes = '/management/showtimes'; // S14
  static const String manageBookings = '/management/bookings'; // S15
  static const String manageFoods = '/management/foods'; // S16
  static const String manageEmployees = '/management/employees'; // S23
  static const String manageRooms = '/management/rooms'; // S25
  static const String configSeatMap = '/management/seat-map'; // S24
  static const String configPricing = '/management/pricing'; // S26
  static const String manageVouchers = '/management/vouchers'; // S27
  static const String manageManagers = '/management/managers'; // S28
  static const String auditLogs = '/management/audit-logs'; // S29
}

/// Central application route generator.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // S01 Login
      case AppRoutes.login:
        String? redirectRoute;
        if (settings.arguments is Map) {
          redirectRoute = (settings.arguments as Map)['redirectRoute'] as String?;
        } else if (settings.arguments is String) {
          redirectRoute = settings.arguments as String?;
        }
        return MaterialPageRoute(
          builder: (_) => LoginScreen(redirectRoute: redirectRoute),
          settings: settings,
        );

      // S02 Register
      case AppRoutes.register:
        String? redirectRoute;
        if (settings.arguments is Map) {
          redirectRoute = (settings.arguments as Map)['redirectRoute'] as String?;
        } else if (settings.arguments is String) {
          redirectRoute = settings.arguments as String?;
        }
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(redirectRoute: redirectRoute),
          settings: settings,
        );

      // S03 Home / Discovery
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      // S04 Movie Detail
      case AppRoutes.movieDetail:
        MovieModel? movie;
        String? movieId;
        if (settings.arguments is MovieModel) {
          movie = settings.arguments as MovieModel;
        } else if (settings.arguments is String) {
          movieId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          if (map['movie'] is MovieModel) {
            movie = map['movie'] as MovieModel;
          }
          if (map['movieId'] is String) {
            movieId = map['movieId'] as String;
          }
        }
        return MaterialPageRoute(
          builder: (_) => MovieDetailScreen(movie: movie, movieId: movieId),
          settings: settings,
        );

      // S17 Cinema Locator
      case AppRoutes.cinemas:
        return MaterialPageRoute(
          builder: (_) => const CinemaMapScreen(),
          settings: settings,
        );

      // S17B Cinema Detail
      case AppRoutes.cinemaDetail:
        CinemaModel? cinema;
        String? cinemaId;
        if (settings.arguments is CinemaModel) {
          cinema = settings.arguments as CinemaModel;
        } else if (settings.arguments is String) {
          cinemaId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          if (map['cinema'] is CinemaModel) {
            cinema = map['cinema'] as CinemaModel;
          }
          if (map['cinemaId'] is String) {
            cinemaId = map['cinemaId'] as String;
          }
        }
        return MaterialPageRoute(
          builder: (_) => CinemaDetailScreen(cinema: cinema, cinemaId: cinemaId),
          settings: settings,
        );

      // S30 Notifications
      case AppRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationCenterScreen(),
          settings: settings,
        );

      // Default placeholder scaffold for future milestone screens
      default:
        return MaterialPageRoute(
          builder: (_) => _buildPlaceholderScreen(settings.name ?? 'Unknown Route'),
          settings: settings,
        );
    }
  }

  static Widget _buildPlaceholderScreen(String routeName) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          routeName.toUpperCase(),
          style: AppTextStyles.titleSm.copyWith(color: AppColors.ink),
        ),
      ),
      body: Center(
        child: Text(
          routeName.toUpperCase(),
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}
