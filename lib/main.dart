import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/routes/app_router.dart';
import 'core/routes/route_guards.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_provider.dart';
import 'features/booking/presentation/controllers/booking_provider.dart';
import 'features/cinemas/presentation/controllers/cinema_provider.dart';
import 'features/movies/presentation/controllers/movie_provider.dart';
import 'features/tickets/presentation/controllers/ticket_provider.dart';
import 'features/chat/presentation/controllers/support_chat_provider.dart';
import 'features/management/presentation/controllers/management_provider.dart';
import 'features/notifications/presentation/controllers/notification_provider.dart';
import 'features/staff_counter/presentation/controllers/staff_counter_provider.dart';
import 'features/staff_checkin/presentation/controllers/checkin_provider.dart';
import 'features/staff_food/presentation/controllers/staff_food_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const CinemaApp());
}

class CinemaApp extends StatelessWidget {
  const CinemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MovieProvider>(
          create: (_) => MovieProvider(),
          update: (_, auth, prev) => prev ?? MovieProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, auth, prev) => (prev ?? BookingProvider())..attach(auth),
        ),
        ChangeNotifierProvider(create: (_) => CinemaProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => StaffCounterProvider()),
        ChangeNotifierProvider(create: (_) => ManagementProvider()),
        ChangeNotifierProvider(create: (_) => SupportChatProvider()),
        ChangeNotifierProvider(create: (_) => CheckinProvider()),
        ChangeNotifierProvider(create: (_) => StaffFoodProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final initialRoute = RouteGuards.getInitialRoute(auth.currentUser);

          return MaterialApp(
            title: 'Cinema Booking',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            initialRoute: initialRoute,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
