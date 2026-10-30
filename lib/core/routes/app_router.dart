import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/controllers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/booking/presentation/screens/checkout_screen.dart';
import '../../features/booking/presentation/screens/food_selection_screen.dart';
import '../../features/booking/presentation/screens/seat_selection_screen.dart';
import '../../features/booking/presentation/screens/showtime_selection_screen.dart';
import '../../features/booking/presentation/screens/vnpay_webview_screen.dart';
import '../../features/cinemas/data/cinema_model.dart';
import '../../features/cinemas/presentation/screens/cinema_detail_screen.dart';
import '../../features/cinemas/presentation/screens/cinema_map_screen.dart';
import '../../features/movies/data/movie_model.dart';
import '../../features/movies/presentation/screens/home_screen.dart';
import '../../features/movies/presentation/screens/movie_detail_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/tickets/presentation/screens/ticket_success_screen.dart';
import '../../features/staff_checkin/presentation/screens/ticket_checkin_screen.dart';
import '../../features/staff_food/presentation/screens/food_board_screen.dart';
import '../../features/staff_counter/presentation/screens/counter_showtimes_screen.dart';
import '../../features/staff_counter/presentation/screens/counter_payment_screen.dart';
import '../../features/management/presentation/screens/staff_accounts_screen.dart';
import '../../features/booking/data/models/booking_model.dart';
import '../../features/booking/data/models/room_model.dart';
import '../../features/chat/presentation/screens/support_chat_screen.dart';
import '../../features/management/presentation/screens/audit_logs_screen.dart';
import '../../features/management/presentation/screens/bookings_management_screen.dart';
import '../../features/management/presentation/screens/cinemas_rooms_screen.dart';
import '../../features/management/presentation/screens/food_catalog_screen.dart';
import '../../features/management/presentation/screens/management_menu_screen.dart';
import '../../features/management/presentation/screens/managers_management_screen.dart';
import '../../features/management/presentation/screens/movies_management_screen.dart';
import '../../features/management/presentation/screens/operational_dashboard_screen.dart';
import '../../features/management/presentation/screens/pricing_settings_screen.dart';
import '../../features/management/presentation/screens/seat_map_designer_screen.dart';
import '../../features/management/presentation/screens/showtimes_management_screen.dart';
import '../../features/management/presentation/screens/vouchers_management_screen.dart';
import '../../features/tickets/presentation/screens/my_tickets_screen.dart';
import '../../features/tickets/presentation/screens/ticket_detail_screen.dart';
import '../../shared/models/app_user.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Named route definitions for all screens S01 to S31.
/// References: ROLE_FLOWS.md Section 6 & PROJECT_STRUCTURE.md
abstract final class AppRoutes {
  // Root / Entry
  static const String root = '/';

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
      // Root / Web entry fallback
      case AppRoutes.root:
      case '':
        return MaterialPageRoute(
          builder: (_) => const _RootDispatcherScreen(),
          settings: settings,
        );

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

      // S05 Showtime Selection
      case AppRoutes.showtimes:
        String? movieId;
        String? movieTitle;
        MovieModel? movie;
        String? cinemaId;
        String? cinemaName;
        if (settings.arguments is MovieModel) {
          movie = settings.arguments as MovieModel;
        } else if (settings.arguments is String) {
          movieId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          movie = map['movie'] as MovieModel?;
          movieId = map['movieId'] as String?;
          movieTitle = map['movieTitle'] as String?;
          cinemaId = map['cinemaId'] as String?;
          cinemaName = map['cinemaName'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => ShowtimeSelectionScreen(
            movieId: movieId,
            movieTitle: movieTitle,
            movie: movie,
            cinemaId: cinemaId,
            cinemaName: cinemaName,
          ),
          settings: settings,
        );

      // S06 Seat Selection
      case AppRoutes.seatSelect:
        return MaterialPageRoute(
          builder: (_) => const SeatSelectionScreen(),
          settings: settings,
        );

      // S07 Food Selection
      case AppRoutes.foodSelect:
        return MaterialPageRoute(
          builder: (_) => const FoodSelectionScreen(),
          settings: settings,
        );

      // S08 Checkout
      case AppRoutes.checkout:
        return MaterialPageRoute(
          builder: (_) => const CheckoutScreen(),
          settings: settings,
        );

      // S08B VNPay WebView
      case AppRoutes.vnpayWebview:
        String paymentUrl = '';
        String bookingCode = '';
        String? txnRef;
        if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          paymentUrl = (map['paymentUrl'] as String?) ?? '';
          bookingCode = (map['bookingCode'] as String?) ?? '';
          txnRef = map['txnRef'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => VNPayWebviewScreen(
            paymentUrl: paymentUrl,
            bookingCode: bookingCode,
            txnRef: txnRef,
          ),
          settings: settings,
        );

      // S09 Ticket Success
      case AppRoutes.ticketSuccess:
        String bookingCode = '';
        if (settings.arguments is String) {
          bookingCode = settings.arguments as String;
        } else if (settings.arguments is Map) {
          bookingCode = ((settings.arguments as Map)['bookingCode'] as String?) ?? '';
        }
        return MaterialPageRoute(
          builder: (_) => TicketSuccessScreen(bookingCode: bookingCode),
          settings: settings,
        );

      // S11 Profile
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      // S11B Edit Profile
      case AppRoutes.editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );

      // S18 Staff Check-in
      case AppRoutes.staffCheckin:
        return MaterialPageRoute(
          builder: (_) => const TicketCheckinScreen(),
          settings: settings,
        );

      // S19 Staff Food Delivery Board
      case AppRoutes.staffFood:
        return MaterialPageRoute(
          builder: (_) => const FoodBoardScreen(),
          settings: settings,
        );

      // S20 Staff Counter Showtimes
      case AppRoutes.staffCounterShowtimes:
        return MaterialPageRoute(
          builder: (_) => const CounterShowtimesScreen(),
          settings: settings,
        );

      // S21 Staff Counter Payment & Change Calculator
      case AppRoutes.staffCounterPayment:
        return MaterialPageRoute(
          builder: (_) => const CounterPaymentScreen(),
          settings: settings,
        );

      // S23 Staff Account Management
      case AppRoutes.manageEmployees:
        return MaterialPageRoute(
          builder: (_) => const StaffAccountsScreen(),
          settings: settings,
        );

      // S10 My Tickets
      case AppRoutes.myTickets:
        return MaterialPageRoute(
          builder: (_) => const MyTicketsScreen(),
          settings: settings,
        );

      // S10B Ticket Detail
      case AppRoutes.ticketDetail:
        BookingModel? ticket;
        String? bookingCode;
        if (settings.arguments is BookingModel) {
          ticket = settings.arguments as BookingModel;
        } else if (settings.arguments is String) {
          bookingCode = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          if (map['ticket'] is BookingModel) {
            ticket = map['ticket'] as BookingModel;
          }
          if (map['bookingCode'] is String) {
            bookingCode = map['bookingCode'] as String;
          }
        }
        return MaterialPageRoute(
          builder: (_) => TicketDetailScreen(initialTicket: ticket, bookingCode: bookingCode),
          settings: settings,
        );

      // S12 Management Menu
      case AppRoutes.managementHome:
        return MaterialPageRoute(
          builder: (_) => const ManagementMenuScreen(),
          settings: settings,
        );

      // S13 Movies Management
      case AppRoutes.manageMovies:
        return MaterialPageRoute(
          builder: (_) => const MoviesManagementScreen(),
          settings: settings,
        );

      // S14 Showtimes Management
      case AppRoutes.manageShowtimes:
        return MaterialPageRoute(
          builder: (_) => const ShowtimesManagementScreen(),
          settings: settings,
        );

      // S15 Bookings Inspection
      case AppRoutes.manageBookings:
        return MaterialPageRoute(
          builder: (_) => const BookingsManagementScreen(),
          settings: settings,
        );

      // S16 Food & Concessions Catalog
      case AppRoutes.manageFoods:
        return MaterialPageRoute(
          builder: (_) => const FoodCatalogScreen(),
          settings: settings,
        );

      // S22 Operational Dashboard
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const OperationalDashboardScreen(),
          settings: settings,
        );

      // S24 Room Seat Map Designer
      case AppRoutes.configSeatMap:
        RoomModel? room;
        String? roomId;
        String? cinemaId;
        String? roomName;
        if (settings.arguments is RoomModel) {
          room = settings.arguments as RoomModel;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          if (map['room'] is RoomModel) room = map['room'] as RoomModel;
          roomId = map['roomId'] as String?;
          cinemaId = map['cinemaId'] as String?;
          roomName = map['roomName'] as String?;
        }
        return MaterialPageRoute(
          builder: (_) => SeatMapDesignerScreen(
            room: room,
            roomId: roomId,
            cinemaId: cinemaId,
            roomName: roomName,
          ),
          settings: settings,
        );

      // S25 Cinemas & Rooms Configuration
      case AppRoutes.manageRooms:
        return MaterialPageRoute(
          builder: (_) => const CinemasRoomsScreen(),
          settings: settings,
        );

      // S26 Dynamic Pricing Settings
      case AppRoutes.configPricing:
        return MaterialPageRoute(
          builder: (_) => const PricingSettingsScreen(),
          settings: settings,
        );

      // S27 Voucher & Promotion Management
      case AppRoutes.manageVouchers:
        return MaterialPageRoute(
          builder: (_) => const VouchersManagementScreen(),
          settings: settings,
        );

      // S28 Manager Accounts Management
      case AppRoutes.manageManagers:
        return MaterialPageRoute(
          builder: (_) => const ManagersManagementScreen(),
          settings: settings,
        );

      // S29 System Audit Logs Viewer
      case AppRoutes.auditLogs:
        return MaterialPageRoute(
          builder: (_) => const AuditLogsScreen(),
          settings: settings,
        );

      // S31 Customer Support Chat
      case AppRoutes.supportChat:
        String? cinemaId;
        String? bookingCode;
        if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          cinemaId = map['cinemaId'] as String?;
          bookingCode = map['bookingCode'] as String?;
        } else if (settings.arguments is String) {
          cinemaId = settings.arguments as String?;
        }
        return MaterialPageRoute(
          builder: (_) => SupportChatScreen(
            cinemaId: cinemaId,
            initialBookingCode: bookingCode,
          ),
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

/// Dynamic root dispatcher ensuring web entry ('/') or cold reloads seamlessly
/// route to the proper role dashboard without black screen placeholder.
class _RootDispatcherScreen extends StatelessWidget {
  const _RootDispatcherScreen();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.loading || auth.status == AuthStatus.initial) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final user = auth.currentUser;
    if (user != null && (user.role == UserRole.manager || user.role == UserRole.admin)) {
      return const OperationalDashboardScreen();
    }
    if (user != null && user.role == UserRole.staff) {
      return const TicketCheckinScreen();
    }

    return const HomeScreen();
  }
}
