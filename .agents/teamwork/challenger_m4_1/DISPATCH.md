## 2026-10-27T20:01:35Z
You are Empirical Challenger M4_1 (teamwork_preview_challenger).
Working Directory: d:\cinema-booking-system-v1\.agents\teamwork\challenger_m4_1
Parent Orchestrator ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130

### INPUTS
1. Authoritative Request: `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. Project Architecture: `d:\cinema-booking-system-v1\PROJECT.md`
3. Explorer M4 Plan: `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\m4_plan.md`
4. Worker M4 Handoff: `d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\handoff.md`

### MISSION
Empirically stress-test the Milestone 4 implementation.
Create a dedicated test file `test/challenger/milestone4_empirical_verification_test.dart` to verify:
1. S18 Check-in 8 validation rules & T16/T18 ID check gating.
2. S19 Food board sorting by showtime ascending & RPC `deliver_food` state transitions.
3. S20 Counter 3-minute hold duration and max 8 seats enforcement.
4. S21 Counter cash change calculation (exact, excess cash, insufficient cash warning, quick cash increments) strictly in integer VND.
5. S23 Staff account locking toggle and multi-tenant cinema scoping (`.eq('cinema_id', currentCinemaId)`).

Run the tests via `flutter test` and check code with `flutter analyze`.
Write `handoff.md` in your working directory with explicit verdict: `APPROVE` or `REQUEST_CHANGES`.
Send completion message to parent orchestrator.
