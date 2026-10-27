## 2026-10-27T17:31:38Z
You are teamwork_preview_worker assigned to implement Milestone 2 (Auth & Customer Discovery S01–S04, S17, S17B, S30) of the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1
Authoritative request: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
Project plan: d:\cinema-booking-system-v1\PROJECT.md
Implementation plan & specs: d:\cinema-booking-system-v1\.agents\teamwork\explorer_m2_1\m2_plan.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

EXCLUSIVE WRITE OWNERSHIP:
You own exclusively the following files:
1. `lib/features/auth/presentation/screens/login_screen.dart` (S01 Login)
2. `lib/features/auth/presentation/screens/register_screen.dart` (S02 Register)
3. `lib/features/movies/presentation/screens/home_screen.dart` (S03 Home / Discovery)
4. `lib/features/movies/presentation/screens/movie_detail_screen.dart` (S04 Movie Detail)
5. `lib/features/cinemas/presentation/screens/cinema_map_screen.dart` (S17 Cinema Locator)
6. `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart` (S17B Cinema Detail)
7. `lib/features/notifications/presentation/screens/notification_center_screen.dart` (S30 Notifications)
8. `lib/shared/widgets/customer_bottom_nav.dart`
9. `lib/core/routes/app_router.dart`
10. `lib/core/routes/route_guards.dart`
11. `lib/main.dart`
12. Widget tests in `test/features/auth/`, `test/features/movies/`, `test/features/cinemas/`, `test/features/notifications/`

IMPLEMENTATION TASKS:
1. Implement S01 Login with role-based redirection (Customer -> S03 Home, Staff -> S18 Checkin, Manager -> S22 Dashboard, Admin -> S12 Management Menu), locked account validation, loading, and error feedback.
2. Implement S02 Register with full name, email, 10-digit phone, >=6 char password, confirm password, and auto-profile binding.
3. Implement S03 Home Screen with hero backdrop carousel (<=5 movies), client search bar, 2-column now-showing grid (`MovieCard`), horizontal upcoming row, notification bell badge, customer bottom nav, and 3 explicit UI states (`SkeletonBox`, `EmptyState`, `ErrorState`).
4. Implement S04 Movie Detail Screen with full-bleed backdrop, `SpecCell` metadata row, synopsis, cast/crew, outline `XEM TRAILER` button (`url_launcher` YouTube), and sticky bottom bar `ĐẶT VÉ` CTA.
5. Implement S17 Cinema Map Screen with Google Maps, user geolocation distance sorting, `DraggableScrollableSheet`, search/filter, and fallback list when GPS denied.
6. Implement S17B Cinema Detail Screen with cinema metadata, outline `CHỈ ĐƯỜNG` button, and `XEM SUẤT CHIẾU HÔM NAY` CTA.
7. Implement S30 Notifications Screen with unread badge counter, notification card list, mark all as read CTA, and tap-to-navigate.
8. Wire all routes in `lib/core/routes/app_router.dart` and `lib/main.dart` using `onGenerateRoute`.
9. Ensure strict Design Token adherence (100% tokens, zero hardcoded colors, 0 elevation, no BoxShadow, uppercase buttons, max 1 primary CTA per screen).
10. Run `flutter analyze` and `flutter test`. Ensure 0 errors, 0 warnings, and 100% tests passing.
11. Deliver handoff report to `d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1\handoff.md` with:
    - Observation: created/modified files with line counts
    - Logic Chain: architecture and token adherence
    - Caveats
    - Conclusion
    - Verification: exact commands and output.
Notify orchestrator via send_message when done.
