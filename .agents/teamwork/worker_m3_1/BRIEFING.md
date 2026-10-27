# BRIEFING — 2026-10-27T18:55:00Z

## Mission
Implement Milestone 3 (Booking Flow & Checkout: S05, S06, S07, S08, S08B, S09, S11, S11B, BookingModel fix, AuthProvider & BookingProvider extensions, AppRouter updates, and tests).

## 🔒 My Identity
- Archetype: teamwork_preview_worker
- Roles: implementer, qa, specialist
- Working directory: d:\cinema-booking-system-v1\.agents\teamwork\worker_m3_1
- Original parent: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Milestone: M3 (Booking Flow & Checkout)

## 🔒 Key Constraints
- 100% Design Token usage: Only AppColors, AppTextStyles, AppSpacing, AppRadius. ZERO hardcoded Color(0x...) or raw font/padding values.
- Dark canvas #181818, primary Rosso Corsa #DA291C. ZERO elevation, ZERO BoxShadow.
- All button and nav text UPPERCASE via `.toUpperCase()`. Max 1 primary CTA per screen.
- 3 UI States for async data loading: Loading (SkeletonBox), Empty (EmptyState), Error (ErrorState with 'THỬ LẠI' button).
- All money in integer VND (`int`), NEVER `double`.
- State management: Pure `provider` (ChangeNotifier, ProxyProvider). ZERO Firebase, Riverpod, Bloc.
- Sensitive operations (seats hold, payments) through Postgres RPC functions (`hold_seats`, `confirm_payment`).
- Clean code: ZERO `print(...)`, ZERO `debugPrint(...)`, ZERO `TODO` in final code.
- Follow ai-coding-standards (Karpathy guidelines: surgical changes, goal-driven execution, reuse existing code). Always write "Vinh Pro" at end.

## Current Parent
- Conversation ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Updated: 2026-10-27T18:55:00Z

## Task Summary
- **What was built**:
  1. Fixed `BookingModel.toMap()` line 122 by adding `'created_at': createdAt.toIso8601String()`.
  2. In `AuthProvider`: added `updateProfile({required String fullName, String? phone})`.
  3. In `BookingProvider`: added voucher handling (`applyVoucher(code)`, `removeVoucher()`, `calculateGrandTotal()`, only discounting ticketTotal) and `syncBookingDetails()` (re-invoking `hold_seats` with current bookingCode).
  4. Screens:
     - S05: `lib/features/booking/presentation/screens/showtime_selection_screen.dart`
     - S06: `lib/features/booking/presentation/screens/seat_selection_screen.dart`
     - S07: `lib/features/booking/presentation/screens/food_selection_screen.dart`
     - S08: `lib/features/booking/presentation/screens/checkout_screen.dart`
     - S08B: `lib/features/booking/presentation/screens/vnpay_webview_screen.dart`
     - S09: `lib/features/tickets/presentation/screens/ticket_success_screen.dart`
     - S11: `lib/features/profile/presentation/screens/profile_screen.dart`
     - S11B: `lib/features/profile/presentation/screens/edit_profile_screen.dart`
  5. Router updates in `lib/core/routes/app_router.dart`: registered all routes `/showtimes`, `/seat-select`, `/food-select`, `/checkout`, `/vnpay-webview`, `/ticket-success`, `/profile`, `/edit-profile`.
  6. Unit and widget tests:
     - `test/features/booking/booking_model_test.dart`
     - `test/features/booking/booking_flow_screens_test.dart`
  7. Verification: `flutter analyze` (0 errors, 0 warnings), `flutter test` (943 tests passing, 100%).
- **Success criteria**: 100% achieved.
- **Interface contracts**: PROJECT.md & explorer_m3_1/m3_plan.md
- **Code layout**: Feature-first according to PROJECT.md

## Key Decisions Made
- Reused all existing design tokens and shared widgets.
- Used `PopScope(canPop: false)` on S06 with seat release confirmation dialog and on S09 to redirect back to home.
- Ensured VNPay WebView provides a sandbox simulation mode for headless/desktop test environments.
- Maintained voucher isolation: discount applies strictly to `ticketTotal` and never affects `foodTotal`.

## Artifact Index
- `DISPATCH.md` — Orchestrator instructions
- `BRIEFING.md` — Situational awareness
- `skills/ai-coding-standards.md` — Local methodology copy
- `progress.md` — Liveness heartbeat
- `handoff.md` — Final handoff report

## Change Tracker
- **Files modified**:
  - `lib/features/booking/data/models/booking_model.dart`
  - `lib/features/auth/presentation/controllers/auth_provider.dart`
  - `lib/features/booking/presentation/controllers/booking_provider.dart`
  - `lib/core/routes/app_router.dart`
  - `test/features/auth/login_screen_test.dart`
  - `test/features/auth/register_screen_test.dart`
  - `test/features/cinemas/cinema_map_screen_test.dart`
  - `test/features/movies/home_screen_test.dart`
  - `test/challenger/milestone2_empirical_verification_test.dart`
  - `test/challenger/milestone2_preview_verification_test.dart`
- **Files created**:
  - `lib/features/booking/presentation/screens/showtime_selection_screen.dart`
  - `lib/features/booking/presentation/screens/seat_selection_screen.dart`
  - `lib/features/booking/presentation/screens/food_selection_screen.dart`
  - `lib/features/booking/presentation/screens/checkout_screen.dart`
  - `lib/features/booking/presentation/screens/vnpay_webview_screen.dart`
  - `lib/features/tickets/presentation/screens/ticket_success_screen.dart`
  - `lib/features/profile/presentation/screens/profile_screen.dart`
  - `lib/features/profile/presentation/screens/edit_profile_screen.dart`
  - `test/features/booking/booking_model_test.dart`
  - `test/features/booking/booking_flow_screens_test.dart`
- **Build status**: PASS (flutter analyze: 0 issues; flutter test: 943 passed, 0 failed)
- **Pending issues**: None

## Quality Status
- **Build/test result**: PASS (943/943 passed)
- **Lint status**: 0 issues
- **Tests added/modified**: 11 new tests added covering booking model round-trip, screen rendering, 8-seat limit, and voucher isolation.

## Loaded Skills
- **Source**: `C:\Users\vinhmt\.gemini\config\skills\ai-coding-standards\SKILL.md`
- **Local copy**: `d:\cinema-booking-system-v1\.agents\teamwork\worker_m3_1\skills\ai-coding-standards.md`
- **Core methodology**: Karpathy guidelines: Think before coding, Simplicity first, Surgical changes, Goal-driven execution, Never guess intent, Reuse existing code. Local-only single git commit in Vietnamese. Always end responses with "Vinh Pro".
