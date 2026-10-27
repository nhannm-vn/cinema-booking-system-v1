# Code Review & Adversarial Critic Report — Milestone 4: Theater Staff Operations

## 1. Observation

### 1.1 Static Analysis & Test Suite Execution
- **Command:** `flutter analyze`
  - **Result:**
    ```
    Analyzing cinema-booking-system-v1...
    No issues found! (ran in 6.3s)
    ```
  - **Exit Code:** 0
- **Command:** `flutter test test/features/staff_checkin/ticket_checkin_screen_test.dart test/features/staff_food/food_board_screen_test.dart test/features/staff_counter/counter_screens_test.dart test/features/management/staff_accounts_screen_test.dart`
  - **Result:**
    ```
    00:09 +30: All tests passed!
    ```
  - **Exit Code:** 0
- **Command:** `flutter test` (Full workspace regression suite)
  - **Result:**
    ```
    01:32 +1035: All tests passed!
    ```
  - **Exit Code:** 0 (100% pass rate across 1035 tests)

### 1.2 Multi-Tenant Isolation Verification
- `lib/features/staff_food/data/staff_food_repository.dart`:
  - Line 17: `.eq('cinema_id', cinemaId)` in `getPendingOrders()`
  - Line 29: `.eq('cinema_id', cinemaId)` in `getDeliveredOrders()`
- `lib/features/staff_food/presentation/controllers/staff_food_provider.dart`:
  - Line 111-113: Realtime channel filter `PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'cinema_id', value: cinemaId)`
- `lib/features/staff_counter/data/repositories/staff_counter_repository.dart`:
  - Line 21: `.eq('cinema_id', cinemaId)` in `getCounterShowtimes()`
  - Line 52: `p_hold_minutes: 3` passed to RPC `hold_seats`
  - Line 67: RPC `sell_counter` called with payment method and booking details
- `lib/features/management/data/repositories/management_repository.dart`:
  - Line 79: `'cinema_id': cinemaId` passed in body to Edge Function `create-staff`
  - Line 102: `.eq('cinema_id', cinemaId)` in `getEmployees()`
  - Line 111: `.eq('cinema_id', cinemaId)` in `getBookings()`
- `lib/features/staff_checkin/data/checkin_repository.dart`:
  - Line 62: Calls RPC `check_in` with `p_booking_code`. Database security definer RPC handles multi-tenant authorization and returns `WRONG_CINEMA` when ticket belongs to another theater.

### 1.3 Design Tokens & Styling Compliance
- **Grep for raw `Color(0x...)`**: 0 instances across all M4 files.
- **Grep for `Colors.*`**: Only `Colors.transparent` is used for ink splashes / border cutouts; all visual colors map to `AppColors.*`.
- **Grep for `BoxShadow`**: 0 instances across all M4 files.
- **Grep for `elevation`**: All instances explicitly set to `0` (`AppColors.canvas` background throughout).
- **Primary Color**: Rosso Corsa `#DA291C` (`AppColors.primary`) used consistently for accents, active indicators, and primary CTAs.
- **Button & Navigation casing**: All buttons, tabs, and action labels use uppercase strings and `.toUpperCase()`.
- **Primary Button Constraint**: Exactly 1 primary button per visual hierarchy/modal.
- **UI States**: S19, S20, S23 implement all 3 required states: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` with retry button).
- **Currency Data Type**: Integer VND (`int`) throughout `StaffCounterProvider` and `CurrencyFormatter.format()`. Zero floating-point `double` for currency.

### 1.4 Route Wiring and DI Registration
- `lib/core/routes/app_router.dart`:
  - Line 268-272: `AppRoutes.staffCheckin` -> `TicketCheckinScreen()`
  - Line 275-279: `AppRoutes.staffFood` -> `FoodBoardScreen()`
  - Line 282-286: `AppRoutes.staffCounterShowtimes` -> `CounterShowtimesScreen()`
  - Line 289-293: `AppRoutes.staffCounterPayment` -> `CounterPaymentScreen()`
  - Line 296-300: `AppRoutes.manageEmployees` -> `StaffAccountsScreen()`
- `lib/main.dart`:
  - Lines 53-57: `StaffCounterProvider`, `ManagementProvider`, `CheckinProvider`, `StaffFoodProvider` registered in `MultiProvider`.

---

## 2. Logic Chain

1. **Integrity & Authenticity**:
   - Source code was checked for dummy/facade implementations or hardcoded mock responses. None were found. All repositories interact directly with Supabase clients, Postgres RPCs (`check_in`, `deliver_food`, `hold_seats`, `sell_counter`), or Edge Functions (`create-staff`).
   - Mock repositories in `test/` cleanly implement repository interfaces and are strictly confined to test files, avoiding fake test passes.

2. **Multi-Tenant Security Enforcement**:
   - Every staff operation and management screen derives the caller's `cinemaId` from `AuthProvider.currentUser.cinemaId`.
   - All database queries and real-time streams enforce `.eq('cinema_id', cinemaId)`.
   - The ticket check-in RPC securely returns `WRONG_CINEMA` for cross-cinema tickets without leaking private booking details.

3. **Adversarial Challenge & Edge Cases (Critic Analysis)**:
   - **Counter Hold Expiry**: `HoldTimer` in `CounterPaymentScreen` executes `_onHoldExpired()`. On expiry, an alert is displayed and the provider resets state, evicting the temporary hold and returning staff to S20.
   - **Age Rating Verification Gating (T16/T18)**: `ResultSheet` checks `widget.ageRating == 'T16' || widget.ageRating == 'T18'`. The primary button `XÁC NHẬN CHO VÀO` remains disabled until staff checks the ID confirmation box.
   - **Cash Calculator Bounds**: `_receivedCash < totalAmount` displays a warning ("KHÁCH ĐƯA THIẾU: ...") and keeps `XÁC NHẬN BÁN VÉ` disabled. When `_receivedCash >= totalAmount`, the exact change is displayed in green with large typography.
   - **Concession Delivery Order Sequencing**: `StaffFoodProvider.loadOrders()` sorts pending orders ascending by `showtime_start`, ensuring orders for movies starting soonest are prioritized at the top of the queue.
   - **Real-Time Stream Resilience**: Supabase Realtime subscriptions safely handle network degradation without throwing unhandled exceptions.

4. **Quality & Design Standards**:
   - 100% token usage matches the strict design guide (`#181818` canvas, flat styling, 0px border radius default, uppercase typography).
   - Zero static analysis issues and 100% test pass rate across 1035 tests.

---

## 3. Caveats

- Physical camera scanning relies on `mobile_scanner`, which cannot be exercised in headless CI/CD environments. A desktop fallback view is rendered automatically with manual 8-character uppercase entry supported across all platforms.
- Edge Function `create-staff` is mocked in local test harnesses; in a live staging/production deployment, the service role JWT must be configured in Supabase Edge Functions environment secrets.

---

## 4. Conclusion

- **Verdict: APPROVE**
- Milestone 4 meets all specifications outlined in `ORIGINAL_REQUEST.md`, `m4_plan.md`, `ROLE_FLOWS.md`, `BUSINESS_RULES.md`, and `DESIGN_TOKENS.md`.
- Code quality, multi-tenant isolation, architectural boundaries, design tokens, and tests are verified and robust.

---

## 5. Verification Method

To independently reproduce and verify this review:
1. Run static analysis:
   ```pwsh
   flutter analyze
   ```
   *Expected: No issues found!*
2. Run Milestone 4 unit and widget test suites:
   ```pwsh
   flutter test test/features/staff_checkin/ticket_checkin_screen_test.dart test/features/staff_food/food_board_screen_test.dart test/features/staff_counter/counter_screens_test.dart test/features/management/staff_accounts_screen_test.dart
   ```
   *Expected: All 30 tests pass.*
3. Run the complete repository test suite:
   ```pwsh
   flutter test
   ```
   *Expected: All 1035 tests pass.*
