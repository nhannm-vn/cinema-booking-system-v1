# DISPATCH — challenger_m5_3 (Milestone 5 Iteration 2 Empirical Challenger 1)

## Role & Mission
You are `challenger_m5_3`. Your mission is to conduct empirical, adversarial verification of Milestone 5:
1. Verify the 36-combination pricing matrix and couple seat multiplier:
   - For all format ∈ {2D, 3D, IMAX}, seatType ∈ {standard, vip, couple}, isWeekend ∈ {false, true}, isPrimeTime ∈ {false, true}:
     Couple seat MUST strictly equal: `(2 × base[format]) + couple + (weekend ? weekendExtra : 0) + (prime ? primeExtra : 0)`.
   - Verify integer VND math (no floating point rounding issues).
2. Verify business edge cases:
   - Negative values / zero values handling.
   - Case-insensitivity ('couple', 'COUPLE', 'CoUpLe').
   - Cancellation time checks (2-hour limit).
3. Run existing tests and author any additional empirical tests if needed.
4. Run `flutter test test/challenger/milestone5_empirical_stress_test.dart` and the full test suite.
5. Write your findings and final verdict (APPROVE or REQUEST_CHANGES) in `d:\cinema-booking-system-v1\.agents\teamwork\challenger_m5_3\handoff.md`.
6. Send a completion message to the Project Orchestrator with your verdict.

## Mandatory Inputs to Read
1. `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. `d:\cinema-booking-system-v1\PROJECT.md`
3. `d:\cinema-booking-system-v1\docs\BUSINESS_RULES.md`
4. `d:\cinema-booking-system-v1\.agents\teamwork\worker_m5_2\handoff.md`


## 2026-10-27T21:59:01Z
You are challenger_m5_3. Your task is to conduct Empirical Mathematical & Stress Verification for Milestone 5 Iteration 2.
Read your dispatch file at `d:\cinema-booking-system-v1\.agents\teamwork\challenger_m5_3\DISPATCH.md` and all mandatory inputs.
Empirically verify the 36-combination pricing matrix and couple seat multiplier `(2 * base[format]) + couple + weekend + prime`.
Run `flutter test test/challenger/milestone5_empirical_stress_test.dart` and full test suite.
Write your report and verdict (APPROVE or REQUEST_CHANGES) in `d:\cinema-booking-system-v1\.agents\teamwork\challenger_m5_3\handoff.md`.
Send a completion message with your verdict to the Project Orchestrator.


## 2026-10-27T22:08:35Z
**Context**: Empirical Stress Verification for Milestone 5 Iteration 2
**Content**: Checking on your progress. Have you completed the 36-combination pricing matrix stress test and edge cases?
**Action**: Please proceed with your test execution and deliver your handoff report.


## 2026-10-27T22:10:11Z
**Context**: Milestone 5 Iteration 2 Challenger Verification
**Content**: Checking on your progress. Have you completed the test run?
**Action**: Please complete your empirical verification and deliver your handoff report.
