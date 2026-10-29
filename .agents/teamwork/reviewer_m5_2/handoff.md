# Review & Adversarial Challenge Report — Milestone 5

## Review Summary

**Verdict**: REQUEST_CHANGES  
**Reviewer**: reviewer_m5_2 (Roles: reviewer, critic)  
**Target Milestone**: Milestone 5 — Management & Admin Suite  

---

## 1. Observation

1. **Independent Static Analysis & Test Suite Execution**:
   - `flutter analyze` executed directly on `d:\cinema-booking-system-v1`:
     ```
     Analyzing cinema-booking-system-v1...
     No issues found! (ran in 22.9s)
     ```
     Result: 0 errors, 0 warnings.
   - `flutter test` executed across all suites:
     ```
     00:51 +1123: All tests passed!
     ```
     Result: 1123 tests passed, 0 failed, 0 skipped.

2. **Feature-by-Feature Examination**:
   - **S10B (Ticket Cancellation & 2-Hour Rule)**:
     - `lib/features/booking/data/models/booking_model.dart` (lines 76–78):
       ```dart
       bool get canCancel =>
           status == 'paid' &&
           DateTime.now().isBefore(showtimeStart.subtract(const Duration(hours: 2)));
       ```
     - `lib/features/tickets/presentation/screens/ticket_detail_screen.dart` (lines 198, 360–386): HỦY VÉ VÀ HOÀN TIỀN button is guarded by `canCancel`. If within 2 hours of showtime, displays warning: `"Không thể hủy vé vì suất chiếu bắt đầu trong vòng chưa đầy 2 giờ nữa theo chính sách của rạp."`
     - Database RPC `cancel_booking` in `supabase/migrations/0003_functions.sql` (lines 310–312) independently enforces server-side cutoff:
       ```sql
       if v_now > (b.showtime_start - interval '2 hours') then
         raise exception 'CANNOT_CANCEL_LESS_THAN_2_HOURS';
       end if;
       ```
     - Status: **VERIFIED**.

   - **S13 (Movie Deletion Guard)**:
     - `lib/features/management/data/repositories/management_repository.dart` (lines 64–83): `hasActiveFutureShowtimes(movieId)` checks `showtimes` where `status = 'active'` and `start_time >= now()`. `deleteMovie` throws `Exception('Không thể xóa phim vì đang có suất chiếu trong tương lai.')` if active showtimes exist.
     - `lib/features/management/presentation/screens/movies_management_screen.dart` (lines 89–105) & `management_provider.dart` (line 133): User receives actionable warning via SnackBar.
     - Status: **VERIFIED**.

   - **S14 (Showtime Conflict 15-Minute Gap & Cancellation RPC)**:
     - `lib/features/management/presentation/screens/showtimes_management_screen.dart` (lines 523–541): `_hasConflictWith` evaluates `candidateStart.isBefore(limitEnd) && candidateEnd.isAfter(limitStart)` with 15-minute buffers (`startTime - 15m`, `endTime + 15m`).
     - PostgreSQL database trigger `trg_showtime_conflict` in `supabase/migrations/0006_missing_rpcs_and_triggers.sql` (lines 13–48) enforces buffer in PostgreSQL:
       ```sql
       (new.start_time < (s.end_time + interval '15 minutes')) and (new.end_time > (s.start_time - interval '15 minutes'))
       ```
     - RPC `cancel_showtime` in `0006_missing_rpcs_and_triggers.sql` (lines 60–140): Automatically updates showtime to `cancelled`, cascades to all `paid` bookings, marks pending foods `cancelled`, sends refund notifications to all customers, and logs action to `audit_logs`.
     - Status: **VERIFIED**.

   - **S16 (Food Catalog Stock Availability Toggle)**:
     - `lib/features/management/presentation/screens/food_catalog_screen.dart` (lines 387–391): `Switch(value: food.isAvailable, onChanged: (val) => provider.toggleFood(food.id, val))`.
     - `lib/features/management/presentation/controllers/management_provider.dart` (lines 336–348): Updates state optimistically and updates `foods.is_available` via repository.
     - Status: **VERIFIED**.

   - **S22 (Operational Dashboard Metrics)**:
     - `lib/features/management/presentation/screens/operational_dashboard_screen.dart` (lines 28–48): Scoped to `_activeCinemaId` (e.g. `cn_q1`), period selector (`today`, `week`, `month`).
     - Interacts with RPC `get_dashboard_metrics` in `supabase/migrations/0006_missing_rpcs_and_triggers.sql` (lines 147–258) calculating revenue, ticket count, capacity, occupancy rate, and upcoming showtimes list.
     - Displays `ManagerBottomNav(currentIndex: 0)`.
     - Status: **VERIFIED**.

   - **S24 (Room Seat Map Designer & Sold Showtimes Lock)**:
     - `lib/features/management/presentation/screens/seat_map_designer_screen.dart` (lines 164–194): `checkRoomHasFutureSoldShowtimes(_roomId)` checks `showtimes` where `room_id = roomId`, `status = 'active'`, `sold_seats > 0`, and `start_time >= now()`.
     - If future sold tickets exist, prevents saving and prompts dialog: `"KHÔNG THỂ THAY ĐỔI SƠ ĐỒ GHẾ: Phòng '$_roomName' đang có suất chiếu trong tương lai đã phát sinh vé bán..."`.
     - Seat calculation counts couple seat as 1 into `seatCount` per business rules.
     - Status: **VERIFIED**.

   - **S26 (Dynamic Pricing Calculations & Simulator)**:
     - In `docs/BUSINESS_RULES.md` Section 4 lines 88–93:
       ```text
       Ghế thường = base[format] + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
       Ghế VIP    = base[format] + vip + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
       Ghế đôi    = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
       ```
     - In `lib/features/management/data/models/pricing_settings_model.dart` lines 53–55:
       ```dart
       case 'couple':
         // Couple seat base price is doubled or base + couple surcharge
         return base + surchargeCouple + weekendExtra + primeExtra;
       ```
       *Observed defect*: The formula computes `base + surchargeCouple` rather than `2 * base + surchargeCouple`.
     - In `lib/features/management/presentation/screens/pricing_settings_screen.dart` lines 108–120:
       `_calculateSimulatedPrice()` computes `return base + seatExtra + weekendExtra + primeExtra;` without multiplying `base` by 2 for couple seats.
     - In `test/features/management/pricing_settings_model_test.dart` lines 41–51:
       ```dart
       test('calculateSeatPrice 3D couple weekend prime adds all surcharges', () {
         final settings = PricingSettingsModel.defaultSettings();
         final price = settings.calculateSeatPrice(
           format: '3D',
           seatType: 'couple',
           isWeekend: true,
           isPrimeTime: true,
         );
         // base3d (100k) + couple (20k) + weekend (10k) + prime (10k) = 140k
         expect(price, 140000);
       });
       ```
       *Observed defect*: The test asserts 140,000 đ instead of `2 * 100,000 + 20,000 + 10,000 + 10,000 = 240,000 đ`. The test asserts against the buggy implementation instead of verifying the contractual specification.
     - Status: **FAILED (BUSINESS LOGIC DEFECT / INTEGRITY VIOLATION)**.

   - **S27 (Voucher Calculation & Validity States)**:
     - `lib/features/management/data/models/voucher_model.dart` (lines 42–60): Supports percent with `maxDiscount` cap and fixed amount with `minBookingAmount` threshold.
     - Tracks `isExpired`, `isExhausted`, `isUsable`, and badge labels (`CÒN HẠN`, `HẾT HẠN`, `HẾT LƯỢT`, `TẠM KHÓA`).
     - Status: **VERIFIED**.

   - **S28 (Manager Account Creation via Edge Function)**:
     - `lib/features/management/data/repositories/management_repository.dart` (lines 432–455): Calls Edge Function `create-staff` with `role: 'manager'`.
     - `supabase/functions/create-staff/index.ts` (lines 42–85): Admin caller check, creates auth user with service role, updates `profiles.role = 'manager'` without logging out admin.
     - Status: **VERIFIED**.

   - **S29 (System Audit Logs JSON Diff Viewer)**:
     - `lib/features/management/presentation/screens/audit_logs_screen.dart` (lines 282–370): Formats `oldData` and `newData` using `JsonEncoder.withIndent('  ')` into selectable monospace diff view.
     - Status: **VERIFIED**.

   - **S31 (In-App Support Chat Realtime Streaming)**:
     - `lib/features/chat/data/repositories/support_chat_repository.dart` (lines 53–74) & `support_chat_provider.dart` (lines 34–40): Subscribes to Supabase Realtime channel `messages:$conversationId` on Postgres insert event.
     - Unsubscribes in `dispose()`.
     - Supports booking code attachment chip.
     - Status: **VERIFIED**.

---

## 2. Findings

### [Critical] Finding 1: Incorrect Couple Seat Pricing Formula & Self-Certifying Test
- **What**: Couple seat pricing formula omits the mandatory `2 × base[format]` multiplier required by `BUSINESS_RULES.md` Section 4. Both `PricingSettingsModel.calculateSeatPrice` and `PricingSettingsScreen._calculateSimulatedPrice` price a couple seat with a single base price plus surcharges. Furthermore, `pricing_settings_model_test.dart` hardcoded an expectation of 140,000 đ instead of 240,000 đ, certifying the bug.
- **Where**:
  - `lib/features/management/data/models/pricing_settings_model.dart:53-55`
  - `lib/features/management/presentation/screens/pricing_settings_screen.dart:108-120`
  - `test/features/management/pricing_settings_model_test.dart:41-51`
- **Why**: A couple seat represents 2 seats booked together as a pair. According to `BUSINESS_RULES.md` line 90:
  `Ghế đôi = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)`.
  For a 3D movie (base 100k) on weekend prime hour (couple +20k, weekend +10k, prime +10k), the price must be `2 × 100k + 20k + 10k + 10k = 240,000 đ`.
  Under the current code, the customer is undercharged at 140,000 đ (loss of 100,000 đ per couple seat).
- **Suggestion**:
  1. In `PricingSettingsModel.calculateSeatPrice`:
     ```dart
     case 'couple':
       return (2 * base) + surchargeCouple + weekendExtra + primeExtra;
     ```
  2. In `PricingSettingsScreen._calculateSimulatedPrice`:
     ```dart
     final baseMult = _simSeatType == 'couple' ? 2 : 1;
     return (base * baseMult) + seatExtra + weekendExtra + primeExtra;
     ```
  3. In `pricing_settings_model_test.dart`:
     Update expected value for 3D couple weekend prime to `240000` (2 * 100k + 20k + 10k + 10k).

---

## 3. Adversarial Challenges & Stress-Testing

### Challenge 1: Financial Undercharging via Simulator & Model Mismatch
- **Assumption challenged**: That couple seat pricing in management and customer checkout are consistent.
- **Attack scenario**: Manager configures pricing matrix in S26, tests formula using simulator, sees 140k for 3D couple, believes that is the full charge. Meanwhile, `test/e2e/test_fixtures.dart` (line 387) computes `(2 * base) + coupleSurcharge + timeSurcharge = 240k`. Customers and managers would see conflicting prices between booking checkout and the pricing settings screen.
- **Blast radius**: Discrepancy between management pricing simulator and customer booking snapshot. Potential booking settlement errors.
- **Mitigation**: Synchronize both model and simulator to compute `(2 * base) + coupleSurcharge + timeSurcharge`.

### Challenge 2: Room Layout Mutation Race Condition
- **Assumption challenged**: Checking `hasFutureSoldShowtimes` on client before `updateRoomLayout` is sufficient.
- **Attack scenario**: Admin opens S24, room has 0 sold seats. While admin edits grid, a customer completes a ticket purchase for a future showtime. Admin clicks LƯU SƠ ĐỒ.
- **Stress test result**: `checkRoomHasFutureSoldShowtimes` runs immediately before saving on client (`_saveLayout()`), re-querying Supabase `showtimes` table with `gt('sold_seats', 0)`.
- **Verdict**: Handled adequately at repository/provider level for M5. Future enhancement: add PostgreSQL trigger `trg_room_layout_lock` for database-level atomicity.

---

## 4. Verified Claims

| Claim from Worker M5 | Verified Via | Status |
|---|---|---|
| `flutter analyze` 0 issues | Direct CLI execution | **PASS** |
| `flutter test` 1123 passing | Direct CLI execution | **PASS** |
| S10B 2-hour refund policy enforcement | Source inspection of model, UI dialog, and DB RPC | **PASS** |
| S13 Movie deletion protection with future showtimes | Source inspection of repository query, provider, and UI | **PASS** |
| S14 Showtime 15m gap conflict prevention | Source inspection of client check & `trg_showtime_conflict` | **PASS** |
| S14 `cancel_showtime` RPC auto-refund | Source inspection of RPC implementation and UI dialog | **PASS** |
| S16 Food stock availability switch | Source inspection of UI toggle and repository update | **PASS** |
| S22 Operational dashboard RPC | Source inspection of `get_dashboard_metrics` RPC & S22 | **PASS** |
| S24 Room seat designer sold showtimes lock | Source inspection of lock query and warning dialog | **PASS** |
| S27 Voucher calculation and state chips | Source inspection of model, unit tests, and UI | **PASS** |
| S28 Manager creation via Edge Function | Source inspection of `create-staff` Edge Function & S28 | **PASS** |
| S29 Audit log JSON diff inspector | Source inspection of modal, JSON formatting, and diff view | **PASS** |
| S31 In-app support chat Realtime streaming | Source inspection of Realtime subscription and message list | **PASS** |
| S26 Dynamic pricing couple seat formula | Comparison of `PricingSettingsModel` against `BUSINESS_RULES.md` | **FAIL (Defect)** |

---

## 5. Coverage Gaps & Unverified Items
- **None**: All 11 requested functional domains and full automated suites were examined and verified independently.

---

## 6. Logic Chain
1. The specification in `docs/BUSINESS_RULES.md` Section 4 lines 88–93 defines the pricing formula:
   `Ghế đôi = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)`.
2. In `lib/features/management/data/models/pricing_settings_model.dart`, the couple seat formula is implemented as `base + surchargeCouple + weekendExtra + primeExtra`.
3. In `lib/features/management/presentation/screens/pricing_settings_screen.dart`, `_calculateSimulatedPrice` also omits the 2x multiplier for couple seats.
4. In `test/features/management/pricing_settings_model_test.dart`, the unit test was tailored to match the buggy implementation (`expect(price, 140000)` instead of `240000`), constituting a self-certifying defect.
5. In accordance with system instructions, defects where tests certify incorrect logic must result in a `REQUEST_CHANGES` verdict.

---

## 7. Conclusion

Milestone 5 is approximately 95% complete with excellent code quality, zero static analysis issues, proper design token adherence, and robust verification across 10 of the 11 feature areas. However, because of the formula defect in `PricingSettingsModel.calculateSeatPrice`, `PricingSettingsScreen._calculateSimulatedPrice`, and the self-certifying assertion in `pricing_settings_model_test.dart`, changes are requested before Milestone 5 can be officially approved.

---

## 8. Verification Method for Rework

1. Modify `lib/features/management/data/models/pricing_settings_model.dart`:
   Multiply `base` by 2 when `seatType == 'couple'`: `(2 * base) + surchargeCouple + weekendExtra + primeExtra`.
2. Modify `lib/features/management/presentation/screens/pricing_settings_screen.dart`:
   In `_calculateSimulatedPrice`, apply factor 2 to `base` when `_simSeatType == 'couple'`.
3. Modify `test/features/management/pricing_settings_model_test.dart`:
   Update test assertion for 3D couple weekend prime to `240000`.
4. Re-run test and analysis commands:
   ```bash
   flutter test test/features/management/pricing_settings_model_test.dart
   flutter analyze
   flutter test
   ```
   Confirm 100% passing tests with 0 errors and 0 warnings.

Vinh Pro
