# BRIEFING — 2026-10-27T17:57:00Z

## Mission
Implement Milestone 2: Auth & Customer Discovery (S01–S04, S17, S17B, S30) with 100% design token compliance, role guards, routing, and automated tests.

## 🔒 My Identity
- Archetype: teamwork_preview_worker
- Roles: implementer, qa, specialist
- Working directory: d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1
- Original parent: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Milestone: Milestone 2 (Auth & Customer Discovery S01–S04, S17, S17B, S30)

## 🔒 Key Constraints
- Exclusive write ownership:
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
- DO NOT CHEAT: No hardcoded test results, no dummy facade implementations, genuine state and logic.
- Design tokens: 100% tokens (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`), 0 elevation, no BoxShadow, background `#181818`, Rosso Corsa `#DA291C` primary, uppercase buttons, max 1 primary CTA per screen.
- 3 explicit UI states for async data: `SkeletonBox`, `EmptyState`, `ErrorState`.
- No Firebase, only Supabase. State management: only `provider` (`ChangeNotifier`, `ProxyProvider`).
- Zero `flutter analyze` errors/warnings, 100% `flutter test` passing.
- No `git push`. Single local commit with Vietnamese message with accents when complete. End with Vinh Pro.

## Current Parent
- Conversation ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Updated: 2026-10-27T17:31:38Z

## Task Summary
- **What to build**: S01 Login, S02 Register, S03 Home Discovery, S04 Movie Detail, S17 Cinema Locator, S17B Cinema Detail, S30 Notifications, customer bottom nav, route guards & app router, widget tests.
- **Success criteria**: All screens implemented with genuine data binding to existing repositories/providers, 0 analyze errors/warnings, 100% widget tests pass.
- **Interface contracts**: PROJECT.md, docs/ROLE_FLOWS.md, docs/BUSINESS_RULES.md.
- **Code layout**: Feature-first architecture in lib/features/, lib/core/, lib/shared/.

## Key Decisions Made
- `RouteGuards.getInitialRoute(admin)` maintains `AppRoutes.dashboard` for app startup initial route contract, while `LoginScreen._resolveDestination` handles explicit redirect to `AppRoutes.managementHome` (S12) upon login submission.
- Preserved root `CINEMA BOOKING APP` label in `HomeScreen` title area to keep backward compatibility with Milestone 1 verification tests.
- Accommodated 2-line movie titles in upcoming movie row with container height 280px to prevent RenderFlex overflow.
- Enhanced `DraggableScrollableSheet` with `SingleChildScrollView` to prevent overflow in empty/error states in test environments.

## Change Tracker
- **Files modified**:
  - `lib/shared/widgets/customer_bottom_nav.dart` (4 uppercase tabs, guest guard)
  - `lib/core/routes/app_router.dart` (routing table for S01–S31)
  - `lib/core/routes/route_guards.dart` (role-based route guard logic)
  - `lib/main.dart` (configured `onGenerateRoute: AppRouter.onGenerateRoute`)
  - `lib/features/auth/presentation/screens/login_screen.dart` (S01 Login implementation)
  - `lib/features/auth/presentation/screens/register_screen.dart` (S02 Register implementation)
  - `lib/features/movies/presentation/screens/home_screen.dart` (S03 Discovery implementation)
  - `lib/features/movies/presentation/screens/movie_detail_screen.dart` (S04 Movie Detail implementation)
  - `lib/features/cinemas/presentation/screens/cinema_map_screen.dart` (S17 Cinema Locator implementation)
  - `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart` (S17B Cinema Detail implementation)
  - `lib/features/notifications/presentation/screens/notification_center_screen.dart` (S30 Notification Center implementation)
  - `test/features/auth/login_screen_test.dart` (10 tests)
  - `test/features/auth/register_screen_test.dart` (6 tests)
  - `test/features/movies/home_screen_test.dart` (8 tests)
  - `test/features/movies/movie_detail_screen_test.dart` (3 tests)
  - `test/features/cinemas/cinema_map_screen_test.dart` (5 tests)
  - `test/features/cinemas/cinema_detail_screen_test.dart` (2 tests)
  - `test/features/notifications/notification_center_screen_test.dart` (6 tests)
- **Build status**: PASS (`flutter analyze`: 0 errors/warnings)
- **Pending issues**: None

## Quality Status
- **Build/test result**: PASS (890/890 tests passed in 24s)
- **Lint status**: 0 issues
- **Tests added/modified**: 40 new widget tests across 7 test suites

## Loaded Skills
- Source: C:\Users\vinhmt\.gemini\config\skills\ai-coding-standards\SKILL.md
- Local copy: d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1\ai_coding_standards.md
- Core methodology: Karpathy guidelines: Think before coding, simplicity first, surgical changes, goal-driven execution, reuse existing code, git commit rules, end with Vinh Pro.

## Artifact Index
- d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1\DISPATCH.md
- d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1\BRIEFING.md
- d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1\progress.md
- d:\cinema-booking-system-v1\.agents\teamwork\worker_m2_1\handoff.md
