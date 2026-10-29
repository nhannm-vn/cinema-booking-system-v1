# BRIEFING — 2026-10-28T03:00:00Z

## Mission
Implement Milestone 4: Theater Staff Operations & Staff Management (S18 Ticket Check-in, S19 Food Delivery Board, S20 Counter Showtimes, S21 Counter Payment, S23 Staff Accounts, StaffBottomNav, controllers, routes, DI, and unit/widget tests) with 100% test pass rate and 0 analyze issues.

## 🔒 My Identity
- Archetype: teamwork_preview_worker
- Roles: implementer, qa, specialist
- Working directory: d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1
- Original parent: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Milestone: M4 Staff Operations

## 🔒 Key Constraints
- 100% Design Token usage: Only AppColors, AppTextStyles, AppSpacing, AppRadius. ZERO hardcoded Color(0x...) or raw font/padding values.
- Dark canvas #181818, primary Rosso Corsa #DA291C. ZERO elevation, ZERO BoxShadow.
- All button and nav text UPPERCASE via `.toUpperCase()`. Max 1 primary CTA per screen.
- 3 UI States for async data loading: Loading (SkeletonBox), Empty (EmptyState), Error (ErrorState with 'THỬ LẠI' button).
- All money in integer VND (`int`), NEVER `double`.
- State management: Pure `provider` (ChangeNotifier, ProxyProvider). ZERO Firebase, Riverpod, Bloc.
- Multi-tenant isolation: All Staff/Manager queries must include `.eq('cinema_id', currentCinemaId)` backed by RLS.
- Sensitive operations through Postgres RPC functions (`check_in`, `deliver_food`, `sell_counter`) and Edge Functions (`create-staff`).
- Clean code: ZERO `print(...)`, ZERO `debugPrint(...)`, ZERO `TODO` in final code.
- Always conclude with "Vinh Pro" in responses per ai-coding-standards.

## Current Parent
- Conversation ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Updated: 2026-10-28T02:27:00Z

## Task Summary
- **What to build**: Staff operations screens (S18, S19, S20, S21, S23), StaffBottomNav, CheckinProvider, StaffFoodProvider, route wiring, MultiProvider registration, and comprehensive unit/widget tests.
- **Success criteria**: `flutter analyze` 0 errors 0 warnings, `flutter test` 100% passing across all existing and new test suites.
- **Interface contracts**: `PROJECT.md`, `m4_plan.md`, `docs/BUSINESS_RULES.md`, `docs/ROLE_FLOWS.md`.
- **Code layout**: `PROJECT.md` Feature-first clean architecture.

## Change Tracker
- **Files modified/created**:
  - `lib/shared/widgets/staff_bottom_nav.dart` — 4 staff tabs with active state highlighting
  - `lib/features/staff_checkin/presentation/controllers/checkin_provider.dart` — Check-in logic and state
  - `lib/features/staff_checkin/presentation/screens/ticket_checkin_screen.dart` — S18 QR scanner & manual check-in
  - `lib/features/staff_food/presentation/controllers/staff_food_provider.dart` — Food order board provider with realtime support
  - `lib/features/staff_food/presentation/screens/food_board_screen.dart` — S19 Food Delivery Board
  - `lib/features/staff_counter/presentation/screens/counter_showtimes_screen.dart` — S20 Counter showtimes & seat selection
  - `lib/features/staff_counter/presentation/screens/counter_payment_screen.dart` — S21 Counter payment & cash calculator
  - `lib/features/staff_counter/presentation/controllers/staff_counter_provider.dart` — Counter booking & sales controller
  - `lib/features/management/presentation/screens/staff_accounts_screen.dart` — S23 Staff Accounts Management
  - `lib/features/management/presentation/controllers/management_provider.dart` — Enhanced loadEmployees for full 3-state UI
  - `lib/core/routes/app_router.dart` — Registered routes `/staff/checkin`, `/staff/food`, `/staff/counter-showtimes`, `/staff/counter-payment`, `/management/employees`
  - `lib/main.dart` — Registered `CheckinProvider` and `StaffFoodProvider` in MultiProvider
  - `test/features/staff_checkin/ticket_checkin_screen_test.dart` — 9 unit & widget tests
  - `test/features/staff_food/food_board_screen_test.dart` — 9 widget tests
  - `test/features/staff_counter/counter_screens_test.dart` — 6 widget tests
  - `test/features/management/staff_accounts_screen_test.dart` — 6 widget tests
- **Build status**: PASS (`flutter test` 1035/1035 passed, `flutter analyze` 0 issues)
- **Pending issues**: None

## Quality Status
- **Build/test result**: 1035/1035 tests passed (100% pass rate)
- **Lint status**: 0 issues found by `flutter analyze`
- **Tests added/modified**: 30 new unit and widget tests covering all Milestone 4 features

## Loaded Skills
- **Source**: C:\Users\vinhmt\.gemini\config\skills\ai-coding-standards\SKILL.md
- **Local copy**: d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\ai-coding-standards.md
- **Core methodology**: Karpathy LLM coding guidelines (think before coding, simplicity first, surgical changes, goal-driven execution, reuse existing code, local git only with Vietnamese commit message, always write "Vinh Pro" at the end).

## Key Decisions Made
- Reused existing repositories (`CheckinRepository`, `StaffFoodRepository`, `StaffCounterRepository`, `ManagementRepository`) and components (`ResultSheet`, `QrScannerView`, `TicketCard`, `HoldTimer`).
- Created `StaffBottomNav` with 4 uppercase tabs (SOÁT VÉ, ĐỒ ĂN, BÁN VÉ, TÀI KHOẢN) and Rosso Corsa active indicator.
- Implemented age check verification gate (T16/T18) in S18 `TicketCheckinScreen` prior to check-in completion.
- Implemented S19 `FoodBoardScreen` with CHỜ GIAO / ĐÃ GIAO tabs, showtime sorting, and `deliver_food` confirmation modal.
- Implemented S20 `CounterShowtimesScreen` with room filter chips, 8-seat matrix modal, quick food selectors, and 3-minute hold.
- Implemented S21 `CounterPaymentScreen` with integer VND cash calculator, quick cash buttons (`ĐỦ TIỀN`, `+50K`, `+100K`, `+200K`, `+500K`), live change display, POS mode confirmation checkbox, and receipt dialog with `TicketCard`.
- Implemented S23 `StaffAccountsScreen` with cinema-scoped employees, lock/unlock confirmation modal, and Edge Function `create-staff` add modal.
- Enhanced `ManagementProvider.loadEmployees` to properly manage `isLoading` and `errorMessage` for triple-state UI (SkeletonBox, EmptyState, ErrorState).

## Artifact Index
- `d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\DISPATCH.md` — Dispatch assignment
- `d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\ai-coding-standards.md` — Local copy of skill
- `d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\progress.md` — Liveness heartbeat
- `d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\handoff.md` — Final handoff report
