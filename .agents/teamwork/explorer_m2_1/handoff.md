# Handoff Report: Milestone 2 Technical Implementation Plan
**Agent:** teamwork_preview_explorer (Milestone 2 Explorer)  
**Date:** 2026-10-27T17:31:00Z  
**Scope:** Milestone 2 (Auth & Customer Discovery S01–S04, S17, S17B, S30)

---

## 1. Observation
1. **Codebase Foundation Status:**
   - Evaluated `lib/`: All foundational models, repositories, and controllers for M2 are already established and verified in Milestone 1:
     - Auth: `lib/features/auth/data/auth_repository.dart:36-101`, `lib/features/auth/presentation/controllers/auth_provider.dart:46-90`.
     - Movies: `lib/features/movies/data/movie_model.dart:3-76`, `lib/features/movies/data/movie_repository.dart:13-33`, `lib/features/movies/presentation/controllers/movie_provider.dart:20-56`.
     - Cinemas & Geolocation: `lib/features/cinemas/data/cinema_model.dart:3-75`, `lib/features/cinemas/data/location_service.dart:6-50`, `lib/features/cinemas/data/cinema_repository.dart:15-52`, `lib/features/cinemas/presentation/controllers/cinema_provider.dart:22-45`.
     - Notifications: `lib/features/notifications/data/notification_repository.dart:3-71`, `lib/features/notifications/presentation/controllers/notification_provider.dart:19-56`.
     - Shared Widgets: `lib/shared/widgets/movie_card.dart`, `app_button.dart`, `app_text_field.dart`, `skeleton_box.dart`, `empty_state.dart`, `error_state.dart`, `spec_cell.dart`, `notification_badge.dart`, `app_badge.dart`.
2. **Routing Status:**
   - In `lib/core/routes/app_router.dart:4-24`, route constants are defined:
     - `AppRoutes.login = '/login'`
     - `AppRoutes.register = '/register'`
     - `AppRoutes.home = '/home'`
     - `AppRoutes.movieDetail = '/movie-detail'`
     - `AppRoutes.cinemas = '/cinemas'`
     - `AppRoutes.cinemaDetail = '/cinema-detail'`
     - `AppRoutes.notifications = '/notifications'`
   - In `lib/main.dart:64-75`, only placeholder routes for `/home` and `/login` are registered.
   - In `lib/core/routes/route_guards.dart:18-26`, `UserRole.admin` currently defaults to `AppRoutes.dashboard` instead of `AppRoutes.managementHome` (S12).
3. **Screen Implementation Status:**
   - Search for `*screen*.dart` in `lib/` returned 0 results. Screen presentation files for S01–S04, S17, S17B, S30 are completely unbuilt and ready for implementation.
4. **Static Analysis & Dependencies:**
   - `pubspec.yaml:27-42` includes all required dependencies: `google_maps_flutter: ^2.6.0`, `geolocator: ^11.0.0`, `cached_network_image: ^3.3.1`, `url_launcher: ^6.2.5`, `shimmer: ^3.0.0`.
   - `flutter analyze` executed with 0 errors and 0 warnings (1 info on deprecated member in test fixtures).

---

## 2. Logic Chain
1. *From Observation 1 & 3:* Since all business logic, data models, repositories, and UI primitives are completed and verified, the next implementation milestone (M2) can focus purely on creating the 7 presentation screens without introducing new data layers.
2. *From Observation 2:* The router in `lib/main.dart` must be replaced with `AppRouter.onGenerateRoute` in `lib/core/routes/app_router.dart` so that complex arguments (`MovieModel`, `CinemaModel`, String IDs) can be cleanly passed and extracted across S03 ➔ S04, S03 ➔ S17 ➔ S17B, S04 ➔ S05, S17B ➔ S05.
3. *From Observation 2 & ROLE_FLOWS.md:* In `route_guards.dart`, `UserRole.admin` must be updated to route to `AppRoutes.managementHome` (`/management`, S12) to strictly satisfy the specification "Role-based redirect: Admin -> S12 Management Menu".
4. *From Observation 1 & DESIGN_TOKENS.md:* S03 Home and S17 Cinemas share the customer bottom navigation bar. Creating `lib/shared/widgets/customer_bottom_nav.dart` avoids duplicating navigation tabs (`PHIM`, `RẠP`, `VÉ CỦA TÔI`, `TÀI KHOẢN`), encapsulates guest authentication guards, and guarantees exact token compliance (`AppColors.canvas`, 0 elevation, 64px height, uppercase typography).
5. *From Observation 4:* `url_launcher` is present for trailer opening and external Google Maps directions; `geolocator` and `google_maps_flutter` are present for S17 map markers and distance computation. Both must feature graceful degradation if network or location permission is denied.

---

## 3. Caveats
1. **Google Maps API Key:** Google Maps on Android/iOS requires a valid API key configured in native manifests (`AndroidManifest.xml` / `AppDelegate.swift`). In headless or test environments, Google Maps widget tests should mock or wrap the controller to prevent native platform channel crashes.
2. **External Link Mocking:** `url_launcher` calls to YouTube and Google Maps must be handled defensively with `canLaunchUrl` to prevent uncaught exceptions on devices without browser handlers.
3. **Lazy Expired Seats:** While M2 screens do not mutate seats, showtime navigation from S04/S17B into S05 will be tested and wired in M3.

---

## 4. Conclusion
The technical implementation plan for Milestone 2 has been fully articulated and written to `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m2_1\m2_plan.md`. The plan establishes exact component hierarchies, state flows, error handling, design token rules, and test suites for:
1. `lib/features/auth/presentation/screens/login_screen.dart` (S01)
2. `lib/features/auth/presentation/screens/register_screen.dart` (S02)
3. `lib/features/movies/presentation/screens/home_screen.dart` (S03)
4. `lib/features/movies/presentation/screens/movie_detail_screen.dart` (S04)
5. `lib/features/cinemas/presentation/screens/cinema_map_screen.dart` (S17)
6. `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart` (S17B)
7. `lib/features/notifications/presentation/screens/notification_center_screen.dart` (S30)
8. `lib/shared/widgets/customer_bottom_nav.dart`
9. Router integration in `lib/core/routes/app_router.dart`, `route_guards.dart`, and `lib/main.dart`.

---

## 5. Verification Method
The implementer agent can verify the execution against this plan using the following steps:
1. **File Integrity Verification:**
   - Confirm existence of all 7 target screen files and `customer_bottom_nav.dart`.
2. **Static Analysis Check:**
   ```bash
   flutter analyze
   ```
   *Expected Output:* 0 errors, 0 warnings.
3. **Milestone 2 Widget & Unit Tests:**
   ```bash
   flutter test test/features/auth/
   flutter test test/features/movies/
   flutter test test/features/cinemas/
   flutter test test/features/notifications/
   ```
   *Expected Output:* 100% test pass for all screen states (Loading, Empty, Error, Content).

---
*Vinh Pro*
