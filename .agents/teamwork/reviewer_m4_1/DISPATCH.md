## 2026-10-27T20:01:35Z
You are Code Reviewer M4_1 (teamwork_preview_reviewer).
Working Directory: d:\cinema-booking-system-v1\.agents\teamwork\reviewer_m4_1
Parent Orchestrator ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130

### INPUTS
1. Authoritative Request: `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. Project Architecture: `d:\cinema-booking-system-v1\PROJECT.md`
3. Explorer M4 Plan: `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\m4_plan.md`
4. Worker M4 Handoff: `d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\handoff.md`

### MISSION
Independently review the Milestone 4 implementation:
- `lib/shared/widgets/staff_bottom_nav.dart` (4 tabs, Rosso Corsa indicator)
- `lib/features/staff_checkin/presentation/controllers/checkin_provider.dart` & `ticket_checkin_screen.dart` (S18)
- `lib/features/staff_food/presentation/controllers/staff_food_provider.dart` & `food_board_screen.dart` (S19)
- `lib/features/staff_counter/presentation/screens/counter_showtimes_screen.dart` (S20)
- `lib/features/staff_counter/presentation/screens/counter_payment_screen.dart` (S21)
- `lib/features/management/presentation/screens/staff_accounts_screen.dart` (S23)
- Routes in `lib/core/routes/app_router.dart` and DI in `lib/main.dart`

### CHECKLIST
1. Multi-tenant isolation: All Staff/Manager queries include `.eq('cinema_id', currentCinemaId)`.
2. Zero hardcoded colors/styles: 100% tokens (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`).
3. Canvas `#181818`, primary Rosso Corsa `#DA291C`, elevation 0, zero `BoxShadow`.
4. All button text and nav uppercase (`.toUpperCase()`). Max 1 primary button per screen.
5. 3 UI States (Loading, Empty, Error) for screens loading data.
6. Money strictly integer VND (`int`).
7. Run `flutter analyze` and `flutter test`.

### DELIVERABLES
Write `handoff.md` in your working directory with explicit verdict: `APPROVE` or `REQUEST_CHANGES`.
Send completion message to parent orchestrator.
