# Review & Adversarial Challenge Report — Milestone 5 Iteration 2

## Review Summary

**Verdict**: APPROVE  
**Reviewer**: reviewer_m5_3 (Roles: reviewer, critic)  
**Target Milestone**: Milestone 5 Iteration 2 Remediation  
**Status**: All findings from reviewer_m5_2 resolved. 0 static analysis errors, 0 warnings. 100% test pass rate across 1185 tests.

---

## 1. Observation

### 1.1 Remediation Verification
1. **Couple Seat Pricing Formula Compliance (`BUSINESS_RULES.md` Section 4 lines 88–93)**:
   - Specification:
     ```text
     Ghế đôi = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
     ```
   - In `lib/features/management/data/models/pricing_settings_model.dart` lines 55–58:
     ```dart
     case 'couple':
       // Couple seat base price is doubled per BUSINESS_RULES.md Section 4:
       // Ghế đôi = 2 × base[format] + couple + (cuối tuần ? weekend : 0) + (giờ vàng ? prime : 0)
       return (2 * base) + surchargeCouple + weekendExtra + primeExtra;
     ```
     Observed: Base price multiplier `2 * base` is strictly enforced.
   - In `lib/features/management/presentation/screens/pricing_settings_screen.dart` lines 105–121:
     ```dart
     final int baseMult = _simSeatType == 'couple' ? 2 : 1;
     ...
     return (base * baseMult) + seatExtra + weekendExtra + primeExtra;
     ```
     Observed: Price simulator on S26 applies the exact same factor, preventing mismatch between simulator and checkout snapshot.
   - In `test/features/management/pricing_settings_model_test.dart` lines 41–63:
     - 3D couple weekend prime (`(2 * 100k) + 20k + 10k + 10k = 240,000 đ`) expects `240000`.
     - 2D couple weekday regular (`(2 * 80k) + 20k = 180,000 đ`) expects `180000`.
     Observed: Tests assert genuine specification values, eliminating self-certifying defects.

2. **Primary Button Count Invariant (`DESIGN_TOKENS.md` Section 7.1 line 151 & Section 11 line 243)**:
   - Specification: "Mỗi màn tối đa một nút primary hiển thị cùng lúc."
   - In `lib/features/management/presentation/screens/cinemas_rooms_screen.dart` lines 231–240:
     ```dart
     Expanded(
       child: AppButton.outline(
         label: 'THIẾT KẾ SƠ ĐỒ GHẾ',
         onPressed: () { ... },
       ),
     ),
     ```
     Observed: Room cards render `AppButton.outline`. Even when a cinema has dozens of rooms, 0 primary buttons exist on the room list cards, ensuring total primary button count on the screen view is `<= 1`.
   - In `test/challenger/milestone5_ui_token_test.dart` lines 1270–1312:
     - Test 18 renders a multi-room setup (2 rooms) and verifies:
       - `ElevatedButton` count <= 1.
       - `OutlinedButton` count == 2 for room cards.

3. **Responsive Width Resilience on S27 (`VouchersManagementScreen`)**:
   - In `lib/features/management/presentation/screens/vouchers_management_screen.dart`:
     - Lines 140–150: Filter chips bar is wrapped in `Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [...])`.
     - Lines 480–511: Voucher discount type selector in `_VoucherFormSheet` is wrapped in `Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [ ChoiceChip(...), ChoiceChip(...) ])` with `AppRadius.zeroRadius`, `elevation: 0`, and `pressElevation: 0`.
   - In `test/challenger/milestone5_ui_token_test.dart` lines 1317–1359:
     - Test 19 verifies constrained width rendering (320px viewport width) and asserts zero `RenderFlex` overflow exceptions during both screen mounting and modal bottom sheet rendering.

### 1.2 Verbatim Tool Outputs

1. **Static Analysis (`flutter analyze`)**:
   ```text
   Analyzing cinema-booking-system-v1...                           
   No issues found! (ran in 25.3s)
   ```
   Result: 0 errors, 0 warnings.

2. **Targeted Pricing Unit Tests (`test/features/management/pricing_settings_model_test.dart`)**:
   ```text
   00:00 +7: All tests passed!
   ```
   Result: 7 passed, 0 failed.

3. **Empirical Stress Tests (`test/challenger/milestone5_empirical_stress_test.dart`)**:
   ```text
   00:02 +35: All tests passed!
   ```
   Result: 35 passed, 0 failed (including 36-combination pricing matrix and 2-hour cancellation boundaries).

4. **Empirical UI Token & Routing Tests (`test/challenger/milestone5_ui_token_test.dart`)**:
   ```text
   00:13 +19: All tests passed!
   ```
   Result: 19 passed, 0 failed (including multi-room outline buttons and 320px width wrap stress).

5. **Empirical Verification Tests (`test/challenger/milestone5_empirical_verification_test.dart`)**:
   ```text
   00:06 +16: All tests passed!
   ```
   Result: 16 passed, 0 failed across all M5 screens (S10, S10B, S12–S16, S22, S24–S29, S31).

6. **Adversarial Pricing Oracle Matrix Tests (`test/challenger/milestone5_empirical_pricing_adversarial_test.dart`)**:
   ```text
   00:00 +6: All tests passed!
   ```
   Result: 6 passed, 0 failed verifying exact integer vnd price oracle for all 36 seat/format combinations.

7. **Full Test Suite (`flutter test`)**:
   ```text
   00:48 +1185: All tests passed!
   ```
   Result: 1185 passed, 0 failed, 0 skipped. Zero regressions across the entire project.

---

## 2. Logic Chain

1. **Resolution of Finding 1 (Couple Seat Pricing Formula)**:
   - In Iteration 1, `reviewer_m5_2` identified that couple seats were priced as `1 * base + couple + weekend + prime` instead of `2 × base[format] + couple + weekend + prime`.
   - In `pricing_settings_model.dart:58` and `pricing_settings_screen.dart:121`, the code now applies `(2 * base) + surchargeCouple + weekendExtra + primeExtra`.
   - This matches `BUSINESS_RULES.md` Section 4 lines 88–93 and `test/e2e/test_fixtures.dart:387`.
   - Verified empirically by `pricing_settings_model_test.dart`, `milestone5_empirical_stress_test.dart`, and `milestone5_empirical_pricing_adversarial_test.dart` (36-combination oracle).

2. **Resolution of Finding 2 (Primary Button Invariant on S25)**:
   - In Iteration 1, room cards on S25 rendered `AppButton.primary`, leading to multiple primary CTA buttons if more than one room existed.
   - In `cinemas_rooms_screen.dart:231`, the button is converted to `AppButton.outline`.
   - This strictly adheres to `DESIGN_TOKENS.md` Section 7.1 ("Mỗi màn tối đa một nút primary hiển thị cùng lúc").
   - Verified empirically by `milestone5_ui_token_test.dart` Test 18.

3. **Resolution of Finding 3 (Responsive Chip Layout on S27)**:
   - In Iteration 1, filter chips and voucher type selection could overflow under constrained widths.
   - In `vouchers_management_screen.dart:140` and `vouchers_management_screen.dart:480`, layout utilizes `Wrap(spacing: ..., runSpacing: ...)`.
   - Verified empirically by `milestone5_ui_token_test.dart` Test 19 under 320px viewport constraints without any `RenderFlex` exceptions.

4. **Integrity & Code Quality Verification**:
   - No hardcoded test results or mock bypasses detected in source code.
   - No `print(...)` statements or `TODO` markers in production source code.
   - Full test suite execution confirms 1185 tests passing with 0 failures and 0 skipped.
   - Static analysis confirms 0 errors and 0 warnings.

---

## 3. Caveats

No caveats. All remediation items have been verified against specifications, and full regression testing across the entire system confirms total system health.

---

## 4. Conclusion

Milestone 5 Iteration 2 remediation has satisfied all functional, architectural, design token, and business rule requirements. The previous critical finding regarding the couple seat formula has been completely resolved and independently verified.

**Final Verdict**: **APPROVE**

---

## 5. Verification Method

To independently reproduce and verify this review:
1. Run static analysis:
   ```bash
   flutter analyze
   ```
   *Expected: `No issues found!` (0 errors, 0 warnings).*

2. Run targeted pricing tests:
   ```bash
   flutter test test/features/management/pricing_settings_model_test.dart
   ```
   *Expected: `00:00 +7: All tests passed!`.*

3. Run empirical stress suite:
   ```bash
   flutter test test/challenger/milestone5_empirical_stress_test.dart
   ```
   *Expected: `00:02 +35: All tests passed!`.*

4. Run UI token and routing stress suite:
   ```bash
   flutter test test/challenger/milestone5_ui_token_test.dart
   ```
   *Expected: `00:13 +19: All tests passed!`.*

5. Run full test suite:
   ```bash
   flutter test
   ```
   *Expected: `00:48 +1185: All tests passed!`.*

Invalidation conditions:
- Any failure in `flutter analyze` or `flutter test`.
- Discrepancy in couple seat pricing formula between `PricingSettingsModel`, `PricingSettingsScreen`, and `BUSINESS_RULES.md`.
- Occurrence of more than 1 primary button on any screen view.

Vinh Pro
