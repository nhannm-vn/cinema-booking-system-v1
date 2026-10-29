# Handoff Report: Survey Phase Specification Mining

- **Agent**: `spec_miner_survey_1` (Teamwork Specification Miner)
- **Target Folder**: `d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1`
- **Output Report**: `d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1\spec_inventory.md`
- **Timestamp**: 2026-10-27T16:42:00Z
- **Handoff Type**: Hard (Task Complete)

---

## 1. Observation

Direct evidence gathered from authoritative documentation, schema migrations, and project codebase:

1. **Authoritative Precedence**:
   - `docs/00_README.md:36`: `"Khi có xung đột về mặt công nghệ giữa các tài liệu cũ và TECH_STACK.md, TECH_STACK.md LUÔN THẮNG."`
   - `docs/.cursorrules:17-27`: Framework is Flutter Dart `>=3.0.0 <4.0.0`, State management is `provider` (`ChangeNotifier`, `ProxyProvider`), backend is pure Supabase (PostgreSQL, RLS, RPC, Realtime, Edge Functions). Firebase is strictly banned.

2. **Screen Matrix & Routes**:
   - `lib/core/routes/app_router.dart:4-46`: Enumerates all named routes from S01 to S31 and S17B (`/login`, `/register`, `/home`, `/movie-detail`, `/showtimes`, `/seat-select`, `/food-select`, `/checkout`, `/vnpay-webview`, `/ticket-success`, `/my-tickets`, `/ticket-detail`, `/profile`, `/edit-profile`, `/cinemas`, `/cinema-detail`, `/staff/checkin`, `/staff/food`, `/staff/counter-showtimes`, `/staff/counter-payment`, `/management`, `/management/dashboard`, `/management/movies`, `/management/showtimes`, `/management/bookings`, `/management/foods`, `/management/employees`, `/management/rooms`, `/management/seat-map`, `/management/pricing`, `/management/vouchers`, `/management/managers`, `/management/audit-logs`, `/notifications`, `/support-chat`).
   - `docs/ROLE_FLOWS.md:315-349`: Outlines exact access matrices for Guest, Customer, Staff, Manager, Admin across all screens.

3. **RPC Logic & Invariants in PostgreSQL**:
   - `supabase/migrations/0003_functions.sql:6-100`: `hold_seats` locks showtime row (`perform 1 from public.showtimes where id = p_showtime_id for update;`), verifies `p_seat_ids <= 8`, verifies no sold or active held seats by another user, automatically expires existing holding bookings for the user, writes `holding` status with `hold_until`. Throws `SEAT_TAKEN:<seat_id>`.
   - `supabase/migrations/0003_functions.sql:103-158`: `confirm_payment` verifies booking is in `holding` status, verifies `hold_until >= now()`, checks `(b.price_snapshot->>'total')::int = p_amount` (`AMOUNT_MISMATCH`), updates seats to `sold`, showtimes `sold_seats`, booking to `paid`, sets `food_status = 'pending'` if foods exist, and writes `bookingPaid` notification.
   - `supabase/migrations/0003_functions.sql:184-248`: `check_in` verifies the 8 sequential rules: `NOT_FOUND`, `CANCELLED`, `ALREADY_USED`, `WRONG_CINEMA`, `TOO_EARLY` (before showtime - 30m), `EXPIRED_SHOWTIME` (after showtime + 15m), and updates `status = used` while logging `audit_logs`.
   - `supabase/migrations/0003_functions.sql:287-352`: `cancel_booking` enforces 2-hour refund cutoff for customers (`now() <= showtime_start - interval '2 hours'`), returns seats to pool, decrements `sold_seats`, cancels food, and writes refund notification.

4. **Design Tokens & Component Rules**:
   - `docs/DESIGN_TOKENS.md:19-71`: Color palette consists of `primary` (`#DA291C`), `canvas` (`#181818`), `canvasElevated` (`#303030`), `canvasLight` (`#FFFFFF`), `hairline` (`#303030`), `ink` (`#FFFFFF`), `body` (`#969696`), `muted` (`#666666`), `warning` (`#F13A2C`), `success` (`#03904A`), `focusRing` (`#F6E500`), `shimmerHighlight` (`#3C3C3C`).
   - `docs/DESIGN_TOKENS.md:120-129`: Radius `none` (0px) default for buttons/cards/posters; `xs` (2px) for seats; `sm` (4px) for inputs; `xl` (12px) for sheet tops; `full` (9999px) for pill badges.
   - `docs/DESIGN_TOKENS.md:133-137`: Zero elevation (`elevation: 0`) and zero box shadows across the app.
   - `lib/shared/widgets/app_button.dart:51`: Button labels must be explicitly transformed using `.toUpperCase()`.

5. **Test Suite Baseline**:
   - Ran `flutter test` at `d:\cinema-booking-system-v1`: 12 tests passed successfully.
   - Ran `flutter analyze` at `d:\cinema-booking-system-v1`: 0 issues found.

---

## 2. Logic Chain

1. **Document Authority Determination**: `00_README.md` and `AGENTS.md` mandate reading `TECH_STACK.md` first and establishing it as the supreme authority over older specifications (specifically overruling legacy Firebase notes with Supabase PostgreSQL).
2. **Feature & Screen Exhaustiveness**: By inspecting `lib/core/routes/app_router.dart`, `docs/ROLE_FLOWS.md`, and `docs/PROJECT_STRUCTURE.md`, all 32 screens (S01–S31 + S17B) were discovered, mapped to their feature groupings (`auth`, `movies`, `cinemas`, `booking`, `payment`, `tickets`, `profile`, `staff_checkin`, `staff_food`, `staff_counter`, `management`, `notifications`), authenticated roles, UI layouts, and primary actions.
3. **RPC & Business Invariant Verification**: Cross-referencing `BUSINESS_RULES.md` against actual PL/pgSQL implementations in `supabase/migrations/0003_functions.sql` established the exact contracts for `hold_seats`, `confirm_payment`, `cancel_booking`, `check_in`, `deliver_food`, and `sell_counter`, including row lock semantics (`FOR UPDATE`), time intervals (5 min online / 3 min counter / 15 min gap / 30 min early / 15 min late / 2 hour cancellation), and error messages.
4. **Token Consistency**: Comparing `DESIGN_TOKENS.md` with implementation in `lib/core/theme/` confirms that `AppColors`, `AppTextStyles`, `AppSpacing`, and `AppRadius` match the strict token-based system with zero hardcoding and zero elevation.

---

## 3. Caveats

- **Scope Levels (M vs S)**: Certain management features such as S24 (custom seat grid layout editor), S27 (voucher management), S29 (audit logs inspector), and S31 (support chat) are categorized under level "S" (secondary/stretch tier), while core booking, check-in, and food queue are level "M" (mandatory core). Both tiers are fully enumerated in the inventory report.
- **Edge Function Secrets**: Edge Functions require environment secrets (`VNPAY_HASH_SECRET`, `VNPAY_TMN_CODE`, `SUPABASE_SERVICE_ROLE_KEY`) configured in Supabase server secrets; app client must only receive `SUPABASE_ANON_KEY`.

---

## 4. Conclusion

The specification mining and survey phase is complete. The detailed requirements catalog in `spec_inventory.md` provides an unambiguous, authoritative blueprint covering:
1. All 32 screens (S01–S31, S17B) with route names, roles, layouts, 3 UI states, and primary actions.
2. All 5 PostgreSQL RPC functions and their 8 validation checks, 2-hour refund cutoff, and row lock concurrency protections.
3. Showtime 15-minute gap conflict prevention algorithm and dynamic pricing snapshot formulas.
4. Complete design token rules (Rosso Corsa, dark canvas `#181818`, 0 elevation, uppercase buttons).

---

## 5. Verification Method

To independently verify the observations and findings:

1. **Verify Screen Routing & Guards**:
   Inspect `lib/core/routes/app_router.dart` and `lib/core/routes/route_guards.dart` to verify path coverage for all 32 screens.
2. **Verify Database Functions & Constraints**:
   Review `supabase/migrations/0003_functions.sql` lines 6–352 to confirm PL/pgSQL RPC logic for `hold_seats`, `confirm_payment`, `cancel_booking`, and `check_in`.
3. **Verify Tests & Static Analysis**:
   ```pwsh
   cd d:\cinema-booking-system-v1
   flutter analyze
   flutter test
   ```
4. **Inspect Inventory Deliverable**:
   Examine `d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1\spec_inventory.md`.
