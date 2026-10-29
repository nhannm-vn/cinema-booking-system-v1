## 2026-10-27T19:26:03Z

Sender: 9a20b4d6-8cae-4f73-9d70-c317f7996130
Priority: MESSAGE_PRIORITY_HIGH

You are Worker M4_1 (teamwork_preview_worker).
Your Working Directory: d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1
Your Parent Orchestrator ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130

### MANDATORY INSTRUCTIONS & SKILLS
1. Read and adhere to the ai-coding-standards skill:
   `C:\Users\vinhmt\.gemini\config\skills\ai-coding-standards\SKILL.md`
2. Read the Authoritative User Request:
   `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
3. Read the Project Architecture and Code Layout:
   `d:\cinema-booking-system-v1\PROJECT.md`
4. Read the Explorer M4 Technical Plan and Handoff:
   `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\m4_plan.md`
   `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\handoff.md`

### MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

### STRICT INVARIANTS (AGENTS.md & GEMINI.md)
- 100% Design Token usage: Only AppColors, AppTextStyles, AppSpacing, AppRadius. ZERO hardcoded Color(0x...) or raw font/padding values.
- Dark canvas #181818, primary Rosso Corsa #DA291C. ZERO elevation, ZERO BoxShadow.
- All button and nav text UPPERCASE via `.toUpperCase()`. Max 1 primary CTA per screen.
- 3 UI States for async data loading: Loading (SkeletonBox), Empty (EmptyState), Error (ErrorState with 'THỬ LẠI' button).
- All money in integer VND (`int`), NEVER `double`.
- State management: Pure `provider` (ChangeNotifier, ProxyProvider). ZERO Firebase, Riverpod, Bloc.
- Multi-tenant isolation: All Staff/Manager queries must include `.eq('cinema_id', currentCinemaId)` backed by RLS.
- Sensitive operations through Postgres RPC functions (`check_in`, `deliver_food`, `sell_counter`) and Edge Functions (`create-staff`).
- Clean code: ZERO `print(...)`, ZERO `debugPrint(...)`, ZERO `TODO` in final code.

### SCOPE & WRITE OWNERSHIP
You have exclusive write ownership of:
1. `lib/shared/widgets/staff_bottom_nav.dart`:
   - 4 tabs: SOÁT VÉ (S18), ĐỒ ĂN (S19), BÁN VÉ (S20), TÀI KHOẢN (S11), Rosso Corsa active indicator.
2. `lib/features/staff_checkin/presentation/controllers/checkin_provider.dart`:
   - `checkIn(String code)`, `isIdVerified` gating for T16/T18, `resetScan()`.
3. `lib/features/staff_checkin/presentation/screens/ticket_checkin_screen.dart` (S18):
   - QrScannerView integration with Rosso Corsa viewfinder, desktop manual input fallback dialog, ResultSheet with T16/T18 age verification gating.
4. `lib/features/staff_food/presentation/controllers/staff_food_provider.dart`:
   - `loadOrders(cinemaId)`, `setTab(index)`, `setSearchQuery(query)`, `deliverFood(code, cinemaId)`, `subscribeRealtime(cinemaId)`.
5. `lib/features/staff_food/presentation/screens/food_board_screen.dart` (S19):
   - Tabs CHỜ GIAO / ĐÃ GIAO, order cards sorted by showtime ascending, `ĐÃ GIAO` primary button invoking RPC `deliver_food`, 3 UI states.
6. `lib/features/staff_counter/presentation/screens/counter_showtimes_screen.dart` (S20):
   - Box office fast showtime selection for today, room chips filter, format/price/available seat indicators, 3-minute seat hold (`holdMinutes: 3`).
7. `lib/features/staff_counter/presentation/screens/counter_payment_screen.dart` (S21):
   - Order summary breakdown, HoldTimer (3m), cash received integer VND input, quick cash buttons (+50k, +100k, +200k, +500k, EXACT), live change calculation, card/POS toggle, primary button `XÁC NHẬN BÁN VÉ` invoking RPC `sell_counter`, success receipt dialog with booking code and QR.
8. `lib/features/management/presentation/screens/staff_accounts_screen.dart` (S23):
   - Multi-tenant staff listing (`.eq('cinema_id', currentCinemaId)`), lock/unlock toggle with confirmation modal, add staff modal invoking Edge Function `create-staff`.
9. `lib/core/routes/app_router.dart`:
   - Wire `/staff/checkin`, `/staff/food`, `/staff/counter-showtimes`, `/staff/counter-payment`, `/management/employees`.
10. `lib/main.dart`:
   - Register `CheckinProvider` and `StaffFoodProvider` in MultiProvider.
11. Unit & Widget tests:
   - `test/features/staff_checkin/ticket_checkin_screen_test.dart`
   - `test/features/staff_food/food_board_screen_test.dart`
   - `test/features/staff_counter/counter_screens_test.dart`
   - `test/features/management/staff_accounts_screen_test.dart`

### EXECUTION & VERIFICATION REQUIREMENTS
1. Run `flutter analyze` using run_command — ensure 0 errors, 0 warnings.
2. Run `flutter test` using run_command — ensure all tests in repository pass 100%.
3. Write `handoff.md` in `d:\cinema-booking-system-v1\.agents\teamwork\worker_m4_1\handoff.md` with:
   - Observation
   - Logic Chain
   - Caveats
   - Conclusion
   - Verification Method (with exact commands and outputs)
4. Send completion message to Parent Orchestrator `9a20b4d6-8cae-4f73-9d70-c317f7996130`.
