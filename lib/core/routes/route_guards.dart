import '../../shared/models/app_user.dart';
import 'app_router.dart';

/// Route guard and redirect logic based on User Role.
/// References: ROLE_FLOWS.md Section 0
abstract final class RouteGuards {
  /// Determine home initial route based on user profile.
  static String getInitialRoute(AppUser? user) {
    if (user == null) {
      // Guest
      return AppRoutes.home;
    }

    if (user.isLocked) {
      return AppRoutes.login;
    }

    switch (user.role) {
      case UserRole.staff:
        return AppRoutes.staffCheckin; // S18
      case UserRole.manager:
      case UserRole.admin:
        return AppRoutes.dashboard; // S22
      case UserRole.customer:
        return AppRoutes.home; // S03
    }
  }

  /// Check if a guest can access a route, otherwise redirect to login.
  static bool requiresAuth(String route) {
    const protectedRoutes = [
      AppRoutes.myTickets,
      AppRoutes.profile,
      AppRoutes.editProfile,
      AppRoutes.notifications,
      AppRoutes.supportChat,
      AppRoutes.seatSelect,
      AppRoutes.foodSelect,
      AppRoutes.checkout,
      AppRoutes.staffCheckin,
      AppRoutes.staffFood,
      AppRoutes.staffCounterShowtimes,
      AppRoutes.staffCounterPayment,
      AppRoutes.managementHome,
      AppRoutes.dashboard,
      AppRoutes.manageMovies,
      AppRoutes.manageShowtimes,
      AppRoutes.manageBookings,
      AppRoutes.manageFoods,
      AppRoutes.manageEmployees,
      AppRoutes.manageRooms,
      AppRoutes.configSeatMap,
      AppRoutes.configPricing,
      AppRoutes.manageVouchers,
      AppRoutes.manageManagers,
      AppRoutes.auditLogs,
    ];

    return protectedRoutes.contains(route);
  }
}
