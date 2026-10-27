# HANDOFF REPORT: MILESTONE 3 INDEPENDENT CODE REVIEW & ADVERSARIAL AUDIT
**Agent**: Code Reviewer M3_2 (`teamwork_preview_reviewer`)  
**Recipient**: Parent Orchestrator (`9a20b4d6-8cae-4f73-9d70-c317f7996130`)  
**Date**: 2026-10-27T19:12:00Z  
**Verdict**: **`APPROVE`**  

---

### 1. OBSERVATION

1. **`BookingModel.toMap()` Serialization Fix**:
   - Location: `lib/features/booking/data/models/booking_model.dart`, line 149:
     ```dart
     'created_at': createdAt.toIso8601String(),
     ```
   - Symmetric deserialization at line 118:
     ```dart
     createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
     ```
   - Direct observation: Round-trip test `test/features/booking/booking_model_test.dart` and independent challenger test `test/challenger/milestone3_preview_verification_test.dart` both confirm that `BookingModel.fromMap(model.toMap())` preserves all fields, timestamps, and nested maps/lists without throwing `TypeError: type 'Null' is not a subtype of type 'String'`.

2. **8-Seat Limit Enforcement**:
   - UI Layer: `lib/features/booking/presentation/screens/seat_selection_screen.dart`, lines 157–170:
     ```dart
     final wasSelected = booking.selectedSeatIds.contains(seatId);
     if (!wasSelected && booking.selectedSeatIds.length >= 8) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           backgroundColor: AppColors.warning,
           content: Text(
             'BẠN CHỈ ĐƯỢC CHỌN TỐI ĐA 8 GHẾ MỖI LẦN'.toUpperCase(),
             style: AppTextStyles.bodySm.copyWith(color: AppColors.ink),
           ),
           duration: const Duration(seconds: 2),
         ),
       );
       return;
     }
     ```
   - Controller Layer: `lib/features/booking/presentation/controllers/booking_provider.dart`, lines 71–75:
     ```dart
     if (_selectedSeatIds.length >= AppConstants.maxSeatsPerBooking) {
       _errorMessage = 'Bạn chỉ được chọn tối đa ${AppConstants.maxSeatsPerBooking} ghế mỗi lần.';
       notifyListeners();
       return;
     }
     ```
   - Direct observation: Attempting to select a 9th seat is rejected at both the UI and controller layers; deselecting from 8 seats is permitted and clears the error state smoothly.

3. **`HoldTimer` Component Behavior**:
   - Component: `lib/shared/widgets/hold_timer.dart`, lines 60–62:
     ```dart
     final bool isWarning = _remaining.inSeconds < 60;
     final Color textColor = isWarning ? AppColors.warning : AppColors.ink;
     ```
   - Semantic color: `AppColors.warning` is Rosso Corsa `#F13A2C`, `AppColors.ink` is `#FFFFFF`.
   - Expiration trigger: lines 44–47:
     ```dart
     if (_remaining == Duration.zero) {
       timer.cancel();
       widget.onExpired?.call();
     }
     ```
   - Screens S07 (`food_selection_screen.dart`, lines 181–185) and S08 (`checkout_screen.dart`, lines 178–182) both bind `onExpired: _handleHoldExpired`. When timer reaches zero, an `AlertDialog` titled `"HẾT THỜI GIAN GIỮ GHẾ"` appears, resetting `BookingProvider` and popping back to `AppRoutes.seatSelect`.

4. **Voucher Business Rule: Ticket Isolation**:
   - Controller: `lib/features/booking/presentation/controllers/booking_provider.dart`, lines 209–218:
     ```dart
     final type = (data['type'] as String?) ?? 'amount';
     final value = (data['value'] as num?)?.toInt() ?? 0;
     final ticketTotal = calculateTicketTotal();

     if (type == 'percent') {
       _discount = (ticketTotal * value / 100).round();
     } else {
       _discount = min(ticketTotal, value);
     }
     ```
   - Grand total calculation: lines 139–141:
     ```dart
     int calculateGrandTotal() {
       return max(0, calculateTicketTotal() + calculateFoodTotal() - _discount);
     }
     ```
   - Direct observation: In our adversarial stress test (`test/challenger/milestone3_preview_verification_test.dart` test 4), an oversized fixed voucher of 300,000 VND against a 160,000 VND ticket total and 100,000 VND food total was strictly capped at 160,000 VND discount. The food total was 100% preserved, and the grand total evaluated to exactly 100,000 VND.

5. **VNPay WebView Navigation & S09 PopScope Back Prevention**:
   - WebView interceptor: `lib/features/booking/presentation/screens/vnpay_webview_screen.dart`, lines 72–90:
     - Intercepts `cinemaapp://payment-success` and `vnp_ResponseCode=00` -> invokes `_handlePaymentSuccess()` which performs `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.ticketSuccess, (route) => route.settings.name == AppRoutes.home)`.
     - Intercepts `cinemaapp://payment-failed` and non-00 codes -> invokes `_handlePaymentFailed()` which displays failure dialog with retry option.
     - Fallback simulator view is rendered on desktop/headless test environments.
   - S09 Electronic Ticket: `lib/features/tickets/presentation/screens/ticket_success_screen.dart`, lines 65–70:
     ```dart
     return PopScope(
       canPop: false,
       onPopInvokedWithResult: (didPop, _) {
         if (didPop) return;
         _navigateToHome();
       },
     ```
     Hardware back button and gesture pop are fully blocked and routed safely to `AppRoutes.home`.

6. **Static Analysis & Full Test Suite Execution**:
   - `flutter analyze`:
     ```
     Analyzing cinema-booking-system-v1...
     No issues found! (ran in 9.5s)
     ```
   - `flutter test`:
     ```
     01:26 +1005: All tests passed!
     ```
   - 1,005 tests passed across unit, widget, boundary, and challenger suites with 0 failures and 0 warnings.

7. **Integrity & Code Quality Verification**:
   - Zero hardcoded colors (`Color(0x...)` absent in presentation layer).
   - Zero elevation (`elevation: 0`, zero `BoxShadow`).
   - Zero `print(...)`, zero `debugPrint(...)`, zero `TODO` comments.
   - All interactive button labels and navigation links explicitly `.toUpperCase()`.
   - Maximum 1 primary button per screen enforced across all 8 screens.
   - Zero facade or dummy mock logic in production files.

---

### 2. LOGIC CHAIN

1. **Serialization Integrity (Observation 1)**:
   - Omitting `created_at` in `toMap()` was the root cause of deserialize failure when calling `fromMap()`.
   - Adding `'created_at': createdAt.toIso8601String()` restores full symmetric serialization.
   - Round-trip stability ensures caching, state persistence, and RPC data passing are fully deterministic.

2. **Capacity Safety & Anti-Scalping (Observation 2)**:
   - In accordance with BUSINESS_RULES.md Section 5, customers are limited to 8 seats per booking session.
   - By validating `_selectedSeatIds.length >= 8` prior to mutating state in both `SeatSelectionScreen` and `BookingProvider.toggleSeat`, the system prevents bypass via rapid UI taps or concurrent input events.
   - Deselecting an existing seat decreases the count, enabling re-selection up to the 8-seat bound.

3. **Session Expiry & Urgency Signaling (Observation 3)**:
   - DESIGN_TOKENS.md Section 7.14 mandates that the hold timer switch to `warning` color (`#F13A2C`) when `< 60 seconds` remain.
   - `HoldTimer` calculates `_remaining.inSeconds < 60` on every periodic tick.
   - Upon timer expiry (`_remaining == Duration.zero`), the timer cancels and triggers `onExpired`, opening an unavoidable dialog that releases the hold and redirects the user to reselect seats, preserving cinema inventory integrity.

4. **Revenue & Concessions Isolation Rule (Observation 4)**:
   - BUSINESS_RULES.md Section 11 specifies that promotional voucher discounts apply solely to ticket prices. Concession sales must not be diluted by ticket promotions.
   - `BookingProvider.applyVoucher` computes `discount` based on `calculateTicketTotal()`, capping fixed vouchers at `min(ticketTotal, value)`.
   - `calculateGrandTotal()` subtracts discount after summing ticket and food totals, ensuring food revenue remains strictly insulated.

5. **Transaction Integrity & Navigation Safety (Observation 5)**:
   - In VNPay sandbox flows, returning users must not be allowed to step back into the payment gateway after a transaction has completed.
   - S09's `PopScope(canPop: false)` intercepts physical back and gesture pops, routing directly to `AppRoutes.home`.
   - S08B's `pushNamedAndRemoveUntil` cleans up the intermediate payment screens, eliminating duplicate submissions.

6. **Automated Verification (Observation 6 & 7)**:
   - The entire codebase compiles without errors or linter warnings.
   - All 1,005 automated tests (including our newly written 8-test adversarial challenger suite `test/challenger/milestone3_preview_verification_test.dart`) pass with 100% success.
   - No shortcuts, hardcoded results, or dummy implementations were detected.

---

### 3. CAVEATS

1. **`HoldTimer` Dynamic Updates**:
   - `_HoldTimerState` currently computes remaining time in `initState()` and relies on the 1-second periodic timer tick. If parent screens ever need to dynamically extend or overwrite `holdUntil` during an active screen lifecycle, adding `didUpdateWidget` would ensure instantaneous recalculation on rebuild. In the current M3 booking flow, `holdUntil` is assigned once per booking session upon RPC confirmation, so this does not affect production behavior.
2. **Native WebView in Headless CI**:
   - `webview_flutter` requires platform-specific native binaries (Android/iOS). `VNPayWebviewScreen` provides an integrated fallback simulation UI ensuring headless and desktop test suites pass without crashes.

---

### 4. CONCLUSION

Milestone 3 (Booking Flow & Checkout) meets all functional requirements, security invariants, design token specifications, and business rules set forth in `docs/` and `PROJECT.md`.
- `BookingModel.toMap()` line 122 is permanently resolved.
- 8-seat limit is firmly enforced.
- `HoldTimer` behaves strictly according to design tokens and handles lazy/active expiration safely.
- Voucher discounts apply exclusively to tickets, strictly protecting food revenue.
- VNPay WebView and S09 PopScope prevent invalid navigation states.
- 0 analysis issues and 1,005 passing automated tests.

Final Verdict: **`APPROVE`**

---

### 5. VERIFICATION METHOD

To independently verify this review:

1. **Verify Static Code Analysis (0 issues)**:
   ```powershell
   flutter analyze
   ```
   *Expected Output*: `No issues found!`

2. **Verify Independent Milestone 3 Challenger Stress Suite**:
   ```powershell
   flutter test test/challenger/milestone3_preview_verification_test.dart
   ```
   *Expected Output*: `All 8 tests passed!`

3. **Verify Milestone 3 Screen & Booking Flow Suite**:
   ```powershell
   flutter test test/features/booking/booking_flow_screens_test.dart
   ```
   *Expected Output*: `All 10 tests passed!`

4. **Verify Milestone 3 Empirical Verification Suite**:
   ```powershell
   flutter test test/challenger/milestone3_empirical_verification_test.dart
   ```
   *Expected Output*: `All 23 tests passed!`

5. **Verify Milestone 3 UI Verification Suite**:
   ```powershell
   flutter test test/challenger/milestone3_ui_verification_test.dart
   ```
   *Expected Output*: `All 31 tests passed!`

6. **Verify Complete Repository Test Suite (1,005 tests)**:
   ```powershell
   flutter test
   ```
   *Expected Output*: `All tests passed!` (1005 passed, 0 failed).

---
Vinh Pro
