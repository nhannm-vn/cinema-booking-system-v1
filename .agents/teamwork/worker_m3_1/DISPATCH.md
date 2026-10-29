## 2026-10-27T18:25:44Z
You are Worker M3_1 (teamwork_preview_worker).
Your Working Directory: d:\cinema-booking-system-v1\.agents\teamwork\worker_m3_1
Your Parent Orchestrator ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130

### MANDATORY INSTRUCTIONS & SKILLS
1. Read and adhere to the ai-coding-standards skill:
   `C:\Users\vinhmt\.gemini\config\skills\ai-coding-standards\SKILL.md`
2. Read the Authoritative User Request:
   `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
3. Read the Project Architecture and Code Layout:
   `d:\cinema-booking-system-v1\PROJECT.md`
4. Read the Explorer M3 Technical Plan and Handoff:
   `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m3_1\m3_plan.md`
   `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m3_1\handoff.md`

### MANDATORY INTEGRITY WARNING
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

### STRICT INVARIANTS (AGENTS.md & GEMINI.md)
- 100% Design Token usage: Only AppColors, AppTextStyles, AppSpacing, AppRadius. ZERO hardcoded Color(0x...) or raw font/padding values.
- Dark canvas #181818, primary Rosso Corsa #DA291C. ZERO elevation, ZERO BoxShadow.
- All button and nav text UPPERCASE via `.toUpperCase()`. Max 1 primary CTA per screen.
- 3 UI States for async data loading: Loading (SkeletonBox), Empty (EmptyState), Error (ErrorState with 'THỬ LẠI' button).
- All money in integer VND (`int`), NEVER `double`.
- State management: Pure `provider` (ChangeNotifier, ProxyProvider). ZERO Firebase, Riverpod, Bloc.
- Sensitive operations (seats hold, payments) through Postgres RPC functions (`hold_seats`, `confirm_payment`).
- Clean code: ZERO `print(...)`, ZERO `debugPrint(...)`, ZERO `TODO` in final code.

### SCOPE & WRITE OWNERSHIP
You have exclusive write ownership of:
1. `lib/features/booking/data/models/booking_model.dart`:
   - Fix `toMap()` line 122 by adding `'created_at': createdAt.toIso8601String(),` so deserialization via `fromMap` never throws null cast exception.
2. `lib/features/auth/presentation/controllers/auth_provider.dart`:
   - Add `updateProfile({required String fullName, String? phone})`.
3. `lib/features/booking/presentation/controllers/booking_provider.dart`:
   - Add voucher management (`applyVoucher(code)`, `removeVoucher()`, `calculateGrandTotal()`). Note: vouchers discount ONLY ticketTotal, NEVER foodTotal.
   - Add `syncBookingDetails()` (re-invoking `hold_seats` with current bookingCode to safely update foods and price_snapshot in PostgreSQL before checkout).
4. Screens to implement:
   - `lib/features/booking/presentation/screens/showtime_selection_screen.dart` (S05: 7-day DateChip selector, cinema grouping, ShowtimeRow, T16/T18 age modal, guest login redirect).
   - `lib/features/booking/presentation/screens/seat_selection_screen.dart` (S06: Curved screen banner, InteractiveViewer seat map with SeatWidget, SeatLegend, 8-seat limit check, atomic `hold_seats` RPC call, BookingSummaryBar, SeatTakenException handling, back confirmation).
   - `lib/features/booking/presentation/screens/food_selection_screen.dart` (S07: HoldTimer countdown with red warning <60s, concession tabs, QuantityStepper, outline BỎ QUA + primary TIẾP TỤC, booking sync).
   - `lib/features/booking/presentation/screens/checkout_screen.dart` (S08: Order summary, HoldTimer, voucher input & validation, VNPay sandbox selector, payment link request).
   - `lib/features/booking/presentation/screens/vnpay_webview_screen.dart` (S08B: webview_flutter WebViewWidget with NavigationDelegate intercepting cinemaapp://payment-success and vnpay-return redirect, handling cancel/timeout).
   - `lib/features/tickets/presentation/screens/ticket_success_screen.dart` (S09: TicketCard with 8-char code, qr_flutter QR code, primary XEM VÉ CỦA TÔI + outline VỀ TRANG CHỦ, PopScope back prevention).
   - `lib/features/profile/presentation/screens/profile_screen.dart` (S11: avatar initials, role badge, action items, sign out modal, CustomerBottomNav tab 3).
   - `lib/features/profile/presentation/screens/edit_profile_screen.dart` (S11B: fullName & phone editing, read-only email/role, LƯU THAY ĐỔI CTA).
5. Router updates in `lib/core/routes/app_router.dart`:
   - Register routes: `/showtimes`, `/seat-select`, `/food-select`, `/checkout`, `/vnpay-webview`, `/ticket-success`, `/profile`, `/edit-profile`.
6. Unit/Widget tests:
   - `test/features/booking/booking_model_test.dart` (testing toMap/fromMap round-trip)
   - `test/features/booking/booking_flow_screens_test.dart` (testing S05, S06, S07, S08, S09, S11, S11B rendering & key interactions)

### EXECUTION & VERIFICATION REQUIREMENTS
1. Run `flutter analyze` using run_command — ensure 0 errors, 0 warnings.
2. Run `flutter test` using run_command — ensure all tests in repository pass 100%.
3. Write `handoff.md` in `d:\cinema-booking-system-v1\.agents\teamwork\worker_m3_1\handoff.md` with:
   - Observation
   - Logic Chain
   - Caveats
   - Conclusion
   - Verification Method (with exact commands and outputs)
4. Send completion message to Parent Orchestrator `9a20b4d6-8cae-4f73-9d70-c317f7996130`.
