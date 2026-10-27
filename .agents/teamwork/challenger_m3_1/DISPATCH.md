## 2026-10-27T18:57:27Z
You are Empirical Challenger M3_1 (teamwork_preview_challenger).
Working Directory: d:\cinema-booking-system-v1\.agents\teamwork\challenger_m3_1
Parent Orchestrator ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130

### INPUTS
1. Authoritative Request: `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. Project Architecture: `d:\cinema-booking-system-v1\PROJECT.md`
3. Explorer M3 Plan: `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m3_1\m3_plan.md`
4. Worker M3 Handoff: `d:\cinema-booking-system-v1\.agents\teamwork\worker_m3_1\handoff.md`

### MISSION
Empirically stress-test the Milestone 3 implementation.
Create a dedicated test file `test/challenger/milestone3_empirical_verification_test.dart` to verify:
1. `BookingModel` round-trip serialization (`fromMap(toMap())`) with and without optional fields.
2. 8-seat limit boundary: selecting 8 seats succeeds, 9th seat is rejected with error.
3. Voucher calculations: percentage discounts and fixed amount discounts applied strictly to ticketTotal, foodTotal untouched.
4. HoldTimer calculation & duration remaining.
5. Route resolution in `AppRouter` for all Milestone 3 routes (/showtimes, /seat-select, /food-select, /checkout, /vnpay-webview, /ticket-success, /profile, /edit-profile).

Run the tests via `flutter test` and check code with `flutter analyze`.
Write `handoff.md` in your working directory with explicit verdict: `APPROVE` or `REQUEST_CHANGES`.
Send completion message to parent orchestrator.
