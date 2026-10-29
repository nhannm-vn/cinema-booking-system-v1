# Handoff Report — Milestone 5 Iteration 2 Remediation

## 1. Observation

### 1.1 Remediation Scope & Root Causes
1. **Couple Seat Pricing Formula Inconsistency**:
   - In `docs/BUSINESS_RULES.md` Section 4 lines 88–93:
     ```text
     Ghế thường = base[format] + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
     Ghế VIP    = base[format] + vip + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
     Ghế đôi    = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
     ```
   - Previous implementation in `lib/features/management/data/models/pricing_settings_model.dart` line 55 computed:
     `return base + surchargeCouple + weekendExtra + primeExtra;`
     (missing the mandatory `2 * base` multiplier for couple seats).
   - In `lib/features/management/presentation/screens/pricing_settings_screen.dart` line 119:
     `_calculateSimulatedPrice()` computed `base + seatExtra + weekendExtra + primeExtra` without multiplying `base` by 2 for couple seats.
   - In `test/features/management/pricing_settings_model_test.dart` line 50:
     The test previously asserted `expect(price, 140000)` instead of `240000` for 3D couple weekend prime (`(2 * 100k) + 20k + 10k + 10k`).
   - In `test/challenger/milestone5_empirical_stress_test.dart` lines 608–611 & 652:
     The 36-combination matrix and mixed-case test also certified `1 * base` for couple seats.

2. **Primary Button Count Invariant Violation on S25 (`CinemasRoomsScreen`)**:
   - In `lib/features/management/presentation/screens/cinemas_rooms_screen.dart` line 231:
     Room cards rendered `AppButton.primary(label: 'THIẾT KẾ SƠ ĐỒ GHẾ')`.
     When multiple rooms existed in a cinema, multiple `ElevatedButton` primary buttons were rendered on a single view, violating the invariant "Mỗi màn tối đa một nút primary hiển thị cùng lúc" in `docs/DESIGN_TOKENS.md` Section 7.1.

3. **Potential Width Overflow on S27 (`VouchersManagementScreen`)**:
   - In `lib/features/management/presentation/screens/vouchers_management_screen.dart`:
     - Filter chips bar used a rigid horizontal layout.
     - Type selector in `_VoucherFormSheet` (lines 483–500) used a `Row` containing two `ChoiceChip` widgets (`Phần trăm (%)` and `Số tiền cố định (VND)`), which produced a 15px `RenderFlex` overflow under constrained widths.

### 1.2 Modifications Applied
1. **`lib/features/management/data/models/pricing_settings_model.dart`**:
   - Updated `calculateSeatPrice()`:
     ```dart
     case 'couple':
       // Couple seat base price is doubled per BUSINESS_RULES.md Section 4:
       // Ghế đôi = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
       return (2 * base) + surchargeCouple + weekendExtra + primeExtra;
     ```
   - Updated class doc comments to reflect the 3 distinct seat type pricing formulas.

2. **`lib/features/management/presentation/screens/pricing_settings_screen.dart`**:
   - Updated `_calculateSimulatedPrice()`:
     ```dart
     final int baseMult = _simSeatType == 'couple' ? 2 : 1;
     ...
     return (base * baseMult) + seatExtra + weekendExtra + primeExtra;
     ```

3. **`test/features/management/pricing_settings_model_test.dart`**:
   - Updated 3D couple weekend prime test expectation to `240000` (`(2 * 100k) + 20k + 10k + 10k`).
   - Added test `calculateSeatPrice 2D couple weekday non-prime returns 2 * base2d + couple` expecting `180000` (`(2 * 80k) + 20k`).

4. **`test/challenger/milestone5_empirical_stress_test.dart`**:
   - In Group 3 exhaustive 36-combination matrix:
     ```dart
     final baseMultiplier = seatType == 'couple' ? 2 : 1;
     final expectedTotal = (expectedBase * baseMultiplier) +
         expectedSeatSurcharge +
         expectedWeekend +
         expectedPrime;
     ```
   - In mixed-case test: updated `settings.calculateSeatPrice(format: '3d', seatType: 'CoUpLe', isWeekend: true, isPrimeTime: true)` expectation to `240000`.

5. **`lib/features/management/presentation/screens/cinemas_rooms_screen.dart`**:
   - Replaced `AppButton.primary` on room cards with `AppButton.outline`, preserving screen-level primary styling and ensuring `<= 1` primary CTA per view.

6. **`lib/features/management/presentation/screens/vouchers_management_screen.dart`**:
   - Wrapped filter chips in `Padding` with `Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [...])`.
   - Wrapped voucher type selector in `_VoucherFormSheet` in `Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [...])` with `AppRadius.zeroRadius`, `elevation: 0`, and `pressElevation: 0`.

7. **`test/challenger/milestone5_ui_token_test.dart`**:
   - Updated Test 18 to assert that room cards render `OutlinedButton` (2 instances) and primary `ElevatedButton` count is `<= 1`.

### 1.3 Verbatim Tool Results
- **`flutter analyze`**:
  ```text
  Analyzing cinema-booking-system-v1...
  No issues found! (ran in 4.9s)
  ```
- **Targeted Unit Tests (`test/features/management/pricing_settings_model_test.dart`)**:
  ```text
  00:00 +7: All tests passed!
  ```
- **Targeted Stress Tests (`test/challenger/milestone5_empirical_stress_test.dart`)**:
  ```text
  00:02 +35: All tests passed!
  ```
- **Targeted UI Token Tests (`test/challenger/milestone5_ui_token_test.dart`)**:
  ```text
  00:09 +18: All tests passed!
  ```
- **Targeted Verification Tests (`test/challenger/milestone5_empirical_verification_test.dart`)**:
  ```text
  00:07 +16: All tests passed!
  ```
- **Full Test Suite (`flutter test`)**:
  ```text
  00:57 +1177: All tests passed!
  ```
  Result: 1177 passed, 0 failed, 0 skipped.

---

## 2. Logic Chain

1. **Section 4 of `docs/BUSINESS_RULES.md` Contract Adherence**:
   - The contract defines couple seat pricing as `2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)`.
   - By multiplying `base` by 2 when `seatType == 'couple'` in both `PricingSettingsModel.calculateSeatPrice` and `PricingSettingsScreen._calculateSimulatedPrice`, customer booking snapshots, simulator calculations, and management pricing settings now produce identical pricing figures.
   - All tests in `pricing_settings_model_test.dart`, `milestone5_empirical_stress_test.dart`, and `tier3_pairwise_test.dart` now verify genuine contract requirements.

2. **Design Tokens & Primary Button Invariant Enforcement**:
   - `docs/DESIGN_TOKENS.md` Section 7.1 establishes that at most one primary button should appear simultaneously per view.
   - Changing the room card action button on S25 (`CinemasRoomsScreen`) to `AppButton.outline` prevents button duplication regardless of how many room cards are rendered, while maintaining full tap-to-navigate functionality.
   - Verified empirically by `milestone5_ui_token_test.dart` Test 18 (2 outline buttons rendered, 0 duplicate primary buttons).

3. **Responsive Width Resilience**:
   - Wrapping chips in `Wrap` with explicit horizontal and run spacing eliminates rigid row overflows on compact devices, bottom modal sheets, and split-screen layouts.
   - Verified with 0 layout overflow exceptions across all widget tests.

4. **Zero Regressions**:
   - All 1177 tests across the entire project repository passed without failures or regressions.

---

## 3. Caveats

- No caveats. All 3 reported issues (couple seat formula, button duplication on room cards, chip layout wrapping) have been resolved with zero static analysis issues and 100% test pass rate.

---

## 4. Conclusion

All requested Milestone 5 Iteration 2 remediations have been fully implemented, verified, and regression-tested. The codebase complies strictly with `BUSINESS_RULES.md` Section 4, `DESIGN_TOKENS.md`, and all automated static and empirical checks.

---

## 5. Verification Method

To independently reproduce and verify this work:
1. Run static analysis:
   ```bash
   flutter analyze
   ```
   *Expected output: `No issues found!` (0 errors, 0 warnings).*
2. Run pricing settings model tests:
   ```bash
   flutter test test/features/management/pricing_settings_model_test.dart
   ```
   *Expected output: `00:00 +7: All tests passed!`.*
3. Run empirical stress tests:
   ```bash
   flutter test test/challenger/milestone5_empirical_stress_test.dart
   ```
   *Expected output: `00:02 +35: All tests passed!`.*
4. Run UI token and routing test suite:
   ```bash
   flutter test test/challenger/milestone5_ui_token_test.dart
   ```
   *Expected output: `00:09 +18: All tests passed!`.*
5. Run full test suite:
   ```bash
   flutter test
   ```
   *Expected output: `00:57 +1177: All tests passed!`.*

Vinh Pro
