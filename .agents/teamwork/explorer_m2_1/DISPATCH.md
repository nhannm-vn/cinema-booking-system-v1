## 2026-10-27T17:23:51Z
You are teamwork_preview_explorer assigned to Milestone 2 (Auth & Customer Discovery S01–S04, S17, S17B, S30) of the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\explorer_m2_1
Authoritative request: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
Project plan: d:\cinema-booking-system-v1\PROJECT.md
Documentation references:
- d:\cinema-booking-system-v1\docs\ROLE_FLOWS.md (S01, S02, S03, S04, S17, S17B, S30)
- d:\cinema-booking-system-v1\docs\DESIGN_TOKENS.md
- d:\cinema-booking-system-v1\docs\BUSINESS_RULES.md
- d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1\spec_inventory.md

MISSION:
Formulate the exact technical implementation plan for all Milestone 2 screens:
1. S01 Login (`/login`) in `lib/features/auth/presentation/screens/login_screen.dart`:
   - Role-based redirect (Customer -> S03, Staff -> S18 Check-in, Manager -> S22 Dashboard, Admin -> S12 Management Menu).
   - Validation, error message, locked account detection.
2. S02 Register (`/register`) in `lib/features/auth/presentation/screens/register_screen.dart`:
   - Full name, email, phone (10 digits), password (>=6 chars), confirm password.
3. S03 Home / Discovery (`/home`) in `lib/features/movies/presentation/screens/home_screen.dart`:
   - Hero backdrop carousel (<=5 movies), client-side search, 2-column now-showing grid (`MovieCard`), upcoming horizontal row, notification bell with `NotificationBadge`.
   - 3 UI states: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` with retry).
4. S04 Movie Detail (`/movie-detail`) in `lib/features/movies/presentation/screens/movie_detail_screen.dart`:
   - Full-bleed backdrop, `SpecCell` row, synopsis, cast/crew, outline `XEM TRAILER` (YouTube via `url_launcher`), sticky bottom bar `ĐẶT VÉ` (or disabled `CHƯA MỞ BÁN`).
5. S17 Cinema Locator (`/cinemas`) in `lib/features/cinemas/presentation/screens/cinema_map_screen.dart`:
   - Google Maps with cinema markers, GPS distance calculation (`geolocator`), `DraggableScrollableSheet` with distance-sorted cinema list.
6. S17B Cinema Detail (`/cinema-detail`) in `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart`:
   - Cinema details, outline `CHỈ ĐƯỜNG`, `XEM SUẤT CHIẾU HÔM NAY`.
7. S30 Notifications (`/notifications`) in `lib/features/notifications/presentation/screens/notification_center_screen.dart`:
   - Unread badges, mark all as read CTA, tap to navigate.
8. Route registration in `lib/core/router/app_router.dart` and `lib/main.dart`.
9. Ensure 100% token usage (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`), zero hardcoded colors, 0 elevation, uppercase buttons.
10. Deliver detailed plan to `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m2_1\m2_plan.md` and handoff at `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m2_1\handoff.md`. Notify orchestrator via send_message.
