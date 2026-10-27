# DISPATCH — auditor_m6_1 (Milestone 6 Final Victory Forensic Integrity Auditor)

## Role & Mission
You are `auditor_m6_1`. Your mission is to perform the final project-wide Victory Forensic Integrity Audit across the entire Cinema Booking & Operation Management application:

## Forensic Audit Protocol & Invariants (ZERO TOLERANCE)
1. Authentic implementation check:
   - Ensure NO dummy implementations, NO facade functions, NO mock bypasses in production code (`lib/`).
   - Check that all Supabase database calls, RPCs (`hold_seats`, `confirm_payment`, `cancel_booking`, `cancel_showtime`, `get_dashboard_metrics`, `deliver_food`, `check_in`), and Edge Functions (`create-staff`, `create-vnpay-url`) are genuine invocations.
2. Hardcoding & Test Cheating check:
   - Verify NO test-specific conditionals (`if (isInTest) return ...`) in production code.
   - Verify NO hardcoded test strings or pre-baked answers.
3. Pricing & Currency Invariants:
   - Couple seat formula must genuinely calculate `(2 * base) + surchargeCouple + weekendExtra + primeExtra`.
   - Money values must strictly be integer VND (`int`), never `double`.
4. Token & Design Invariants:
   - Zero raw hex colors outside `app_colors.dart`.
   - Zero raw `Colors.*` (other than `Colors.transparent`).
   - Zero `BoxShadow`. Zero `elevation > 0` (all explicit 0).
   - Uppercase button & nav labels (`.toUpperCase()`).
   - 3 UI states (Loading, Empty, Error) across screens.
5. Run static analysis and verification:
   - Run `flutter analyze` (must be 0 errors, 0 warnings).
   - Run `flutter test test/e2e/e2e_suite_test.dart` (must pass 401/401).
   - Run `flutter test test/challenger/tier5_adversarial_coverage_test.dart`.
   - Run `flutter test test/challenger/tier5_adversarial_stress_test.dart`.
   - Run `flutter test` (must pass 100%).
6. Write your final forensic audit report in:
   `d:\cinema-booking-system-v1\.agents\teamwork\auditor_m6_1\handoff.md` with explicit verdict: `CLEAN` or `INTEGRITY VIOLATION`.
7. Send a completion message to the Project Orchestrator.

## Mandatory Inputs to Read
1. `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. `d:\cinema-booking-system-v1\PROJECT.md`
3. `d:\cinema-booking-system-v1\TEST_READY.md`
4. `d:\cinema-booking-system-v1\docs\TECH_STACK.md`
5. `d:\cinema-booking-system-v1\docs\BUSINESS_RULES.md`
6. `d:\cinema-booking-system-v1\docs\DESIGN_TOKENS.md`
7. `d:\cinema-booking-system-v1\.agents\teamwork\worker_m6_1\handoff.md`

## 2026-10-27T23:04:33Z
You are auditor_m6_1. Your task is to perform the final project-wide Victory Forensic Integrity Audit.
Read your dispatch file at `d:\cinema-booking-system-v1\.agents\teamwork\auditor_m6_1\DISPATCH.md` and all mandatory inputs.
Run forensic checks: authentic implementations (no facades, no mocks in lib/), no test hardcoding, genuine RPC/Edge Function calls, integer VND currency, and design token invariants.
Run `flutter analyze` and the full test suite.
Write your report and verdict (CLEAN or INTEGRITY VIOLATION) in `d:\cinema-booking-system-v1\.agents\teamwork\auditor_m6_1\handoff.md`.
Send a completion message with your verdict to the Project Orchestrator.
