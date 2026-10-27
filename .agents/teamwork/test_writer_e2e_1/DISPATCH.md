## 2026-10-27T16:44:44Z
You are teamwork_preview_test_writer assigned to the E2E Testing Track of the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\test_writer_e2e_1
Authoritative request: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
Project plan: d:\cinema-booking-system-v1\PROJECT.md
Test Infrastructure Plan: d:\cinema-booking-system-v1\TEST_INFRA.md

MISSION:
Design and implement the complete opaque-box E2E test suite under `test/e2e/`:
1. `test/e2e/tier1_feature_test.dart`:
   - Feature coverage for all 35 features (Auth S01/S02, Movies S03/S04, Booking S05-S09, Tickets S10, Staff S18-S21, Management S12-S16, S22-S29, S30, S31).
   - Opaque-box tests checking inputs, outputs, UI state transitions, and business invariants.
2. `test/e2e/tier2_boundary_test.dart`:
   - Boundary & corner cases: 8-seat limit enforcement, 9th seat rejection, 60s countdown warning state, 2-hour cancellation cutoff, early check-in window (showtime - 30m), late check-in window (showtime + 15m / noShow), T16/T18 ID check requirement, 15m showtime overlap prevention.
3. `test/e2e/tier3_pairwise_test.dart`:
   - Pairwise cross-feature combinations: hold seats + voucher discount, food queue delivery + cancellation, multi-tenant cinema scoping (staff/manager restricted to cinema_id).
4. `test/e2e/tier4_application_scenarios_test.dart`:
   - Real-world end-to-end user workflows (Customer discovery -> hold -> payment -> QR ticket; Staff QR scan -> ID check -> entry; Counter sales with cash change; Manager dashboard review).
5. `test/e2e/e2e_suite_test.dart`:
   - Master test runner executing all tier suites.
6. Verify all test files with `flutter test test/e2e/e2e_suite_test.dart` and ensure 100% pass with 0 errors.
7. Upon successful execution, generate `d:\cinema-booking-system-v1\TEST_READY.md` according to the template in `PROJECT.md` / `TEST_INFRA.md`.
8. Deliver your handoff report at `d:\cinema-booking-system-v1\.agents\teamwork\test_writer_e2e_1\handoff.md` and notify orchestrator via send_message.
