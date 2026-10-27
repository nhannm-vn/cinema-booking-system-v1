# HANDOFF REPORT: EMPIRICAL CHALLENGER M3_1

**Agent**: Empirical Challenger (challenger_m3_1)  
**Recipient**: Parent Orchestrator (`9a20b4d6-8cae-4f73-9d70-c317f7996130`)  
**Date**: 2026-10-27T19:12:00Z  
**Verdict**: **APPROVE**  

---

### 1. OBSERVATION

We designed, authored, and executed a dedicated adversarial test suite in `test/challenger/milestone3_empirical_verification_test.dart` containing 23 empirical test cases covering all 5 mission requirements:

1. **`BookingModel` Serialization Round-Trip Fidelity (`fromMap(toMap())`)**:
   - `test 1.1`: Full fields round-trip with non-null dates, IDs, format, seats, foods, price snapshot, transaction numbers, and check-in audit stamps. Deserialized object preserved 100% of data attributes.
   - `test 1.2`: Minimal fields round-trip where all optional attributes are `null` and default lists are empty. Handled cleanly without null type-cast exceptions (`created_at` field included).
   - `test 1.3`: Resiliency against omitted JSON keys (`channel`, `format`, `food_status`, `seats`, `foods`, `price_snapshot`) defaulting gracefully.
   - `test 1.4`: Business rule state-machine invariants for `isNoShow` (threshold >15 minutes post-showtime when unchecked), `canCancel` (threshold >= 2 hours pre-showtime for paid bookings), and `displayStatus` ('noShow', 'expired', 'holding', 'paid', 'used', 'cancelled').

2. **8-Seat Limit Boundary Enforcement**:
   - `test 2.1`: Sequential seat selection from 1 to 8 seats succeeded without error (`errorMessage == null`). Attempting to add a 9th seat (`A9`) was rejected; count remained strictly 8, and `errorMessage` explicitly alerted the user to the maximum limit of 8 seats. Attempting a 10th seat was also rejected. Deselecting 1 seat decreased the count to 7, and adding a replacement seat brought the total back to 8 without error.
   - `test 2.2`: Rapid toggle idempotency and `reset()` cleanly cleared all selections and state.

3. **Voucher Calculations & Strict Concession Isolation**:
   - `test 3.1`: Percentage discounts (e.g. 20% on 160,000 VND tickets = 32,000 VND discount) applied strictly to `ticketTotal`. `foodTotal` (150,000 VND) remained 100% untouched. Grand total computed to `(160,000 - 32,000) + 150,000 = 278,000 VND`.
   - `test 3.2`: 100% voucher discount zeroed out tickets (`ticketTotal` = 80,000, `discount` = 80,000), while concessions (`foodTotal` = 50,000) remained payable in full (grand total = 50,000 VND).
   - `test 3.3`: Fixed amount discount (50,000 VND) applied directly to ticket prices. Concession total untouched.
   - `test 3.4 (Stress Oracle)`: Fixed amount discount (500,000 VND) applied to an 80,000 VND ticket order with 200,000 VND concessions. Discount was capped at `ticketTotal` (`min(80000, 500000) = 80000 VND`). The surplus 420,000 VND voucher value **did not bleed into concessions**. Grand total was strictly 200,000 VND.
   - `test 3.5`: Voucher validation error paths verified via mock client (empty code, whitespace, non-existent, inactive, expired, max uses exceeded).

4. **HoldTimer Calculation & Warning State**:
   - `test 4.1`: `DateFormatter.formatTimer` boundary tests (negative -> "00:00", 0 -> "00:00", 1s -> "00:01", 59s -> "00:59", 60s -> "01:00", 4m32s -> "04:32", 10m -> "10:00").
   - `test 4.2`: Initial render with >=60s displays ink color (`#FFFFFF`).
   - `test 4.3`: Warning state transition with <60s switches text and icon to `AppColors.warning` (`#E6A23C`).
   - `test 4.4`: Countdown decrements every second and fires `onExpired` callback once reaching 0.

5. **AppRouter Milestone 3 Route Resolution**:
   - Tested all 8 routes registered in `AppRouter`:
     - `/showtimes` (with `MovieModel`, String `movieId`, `Map` arguments, and nulls) -> `ShowtimeSelectionScreen`.
     - `/seat-select` -> `SeatSelectionScreen`.
     - `/food-select` -> `FoodSelectionScreen`.
     - `/checkout` -> `CheckoutScreen`.
     - `/vnpay-webview` (with `paymentUrl`, `bookingCode`, `txnRef`) -> `VNPayWebviewScreen`.
     - `/ticket-success` (with `bookingCode`) -> `TicketSuccessScreen`.
     - `/profile` -> `ProfileScreen`.
     - `/edit-profile` -> `EditProfileScreen`.
   - All 8 routes instantiated their respective widget hierarchies without throwing any runtime or route generation exceptions.

---

### 2. LOGIC CHAIN

1. **Serialization Integrity**:
   - With `'created_at': createdAt.toIso8601String()` present in `BookingModel.toMap()`, deserializing via `BookingModel.fromMap(model.toMap())` is completely symmetric and stable across all edge scenarios.
2. **Boundary Protection**:
   - In `BookingProvider.toggleSeat()`, `_selectedSeatIds.length >= AppConstants.maxSeatsPerBooking` blocks any attempts to exceed 8 seats before updating state, keeping the client selection strictly bounded.
3. **Financial Isolation Invariant**:
   - The calculation `min(ticketTotal, voucherValue)` and `(ticketTotal * percent / 100).round()` in `applyVoucher()` guarantees that vouchers never touch `foodTotal`. Concessions are always charged at face value.
4. **Static & Dynamic Proof**:
   - `flutter analyze` completed with **0 issues** across the entire repository.
   - `flutter test` executed all 1005 tests across unit, widget, boundary, e2e, and challenger suites: **1005 passed, 0 failed**.

---

### 3. CAVEATS

- No caveats. The implementation exhibits complete adherence to the specifications and passes all adversarial stress criteria.

---

### 4. CONCLUSION

**VERDICT: APPROVE**

Milestone 3 (Booking Flow & Checkout) is thoroughly stress-tested, mathematically accurate, resilient against adversarial boundary inputs, and structurally compliant with all project constraints.

---

### 5. VERIFICATION METHOD

To reproduce and verify these findings independently:

1. **Run Empirical Challenger Test Suite**:
   ```powershell
   flutter test test/challenger/milestone3_empirical_verification_test.dart
   ```
   *Expected output*: `All 23 tests passed!`

2. **Run Full Test Suite**:
   ```powershell
   flutter test
   ```
   *Expected output*: `1005: All tests passed!`

3. **Run Static Code Analysis**:
   ```powershell
   flutter analyze
   ```
   *Expected output*: `No issues found!`

Vinh Pro
