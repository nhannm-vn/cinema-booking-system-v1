## 2026-10-27T18:15:01Z
You are teamwork_preview_explorer assigned to Milestone 3 (Booking Flow & Checkout S05–S09, S11, S11B) of the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\explorer_m3_1
Authoritative request: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
Project plan: d:\cinema-booking-system-v1\PROJECT.md
Documentation references:
- d:\cinema-booking-system-v1\docs\ROLE_FLOWS.md (S05, S06, S07, S08, S08B, S09, S11, S11B)
- d:\cinema-booking-system-v1\docs\BUSINESS_RULES.md (hold_seats, pricing snapshot, VNPay, food order, cancellation)
- d:\cinema-booking-system-v1\docs\DESIGN_TOKENS.md
- d:\cinema-booking-system-v1\docs\TECH_STACK.md

MISSION:
Formulate the exact technical implementation plan for all Milestone 3 screens and models:
1. Fix `BookingModel.toMap()` defect:
   - In `lib/features/booking/data/models/booking_model.dart` line 122, add `'created_at': createdAt.toIso8601String(),` so round-trip serialization never throws null cast error.
2. S05 Showtime Selection (`/showtimes`) in `lib/features/booking/presentation/screens/showtime_selection_screen.dart`:
   - 7-day date selector (`DateChip`), grouped by cinema, `ShowtimeRow` with format & price, "HẾT VÉ" indicators, age warning dialog for T16/T18 movies.
3. S06 Seat Map Selection (`/seat-select`) in `lib/features/booking/presentation/screens/seat_selection_screen.dart`:
   - "MÀN HÌNH" curved banner, `InteractiveViewer` with matrix of seats (`SeatWidget`), `SeatLegend`, 8-seat limit enforcement, holding seats via Postgres RPC `hold_seats`, sticky `BookingSummaryBar` with seat count & total price, handling `SeatTakenException`.
4. S07 Food & Concessions (`/food-select`) in `lib/features/booking/presentation/screens/food_selection_screen.dart`:
   - `HoldTimer` countdown with 60s warning (turns red), concession categories tabs, `QuantityStepper`, disabled stepper if out of stock, outline `BỎ QUA` button, primary `TIẾP TỤC` CTA.
5. S08 Checkout & Voucher (`/checkout`) in `lib/features/booking/presentation/screens/checkout_screen.dart`:
   - Order summary (movie, showtime, seats, food items), voucher code input & validation, payment method selector (VNPay Sandbox default), `HoldTimer`, timeout expiration dialog leading back to S06.
6. S08B VNPay Sandbox WebView (`/vnpay-webview`) in `lib/features/booking/presentation/screens/vnpay_webview_screen.dart`:
   - `WebViewWidget` embedding sandbox payment URL, listening to URL redirect to `vnpay-return` edge function, routing to S09 on success or showing error dialog on cancel.
7. S09 Ticket Success (`/ticket-success`) in `lib/features/tickets/presentation/screens/ticket_success_screen.dart`:
   - `TicketCard` displaying 8-character booking code, QR code (`qr_flutter`), `XEM VÉ CỦA TÔI` primary button, `VỀ TRANG CHỦ` outline button.
8. S11 Profile (`/profile`) in `lib/features/profile/presentation/screens/profile_screen.dart` & S11B Edit Profile (`/edit-profile`) in `lib/features/profile/presentation/screens/edit_profile_screen.dart`:
   - User details, role badge, `SỬA HỒ SƠ`, `HỘP THƯ HỖ TRỢ`, `ĐĂNG XUẤT`, name and phone editing.
9. Route wiring in `lib/core/routes/app_router.dart` and `lib/main.dart`.
10. Ensure strict Design Token adherence (100% tokens, zero hardcoded colors, 0 elevation, no BoxShadow, uppercase buttons, max 1 primary CTA per screen).
11. Deliver detailed plan to `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m3_1\m3_plan.md` and handoff at `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m3_1\handoff.md`. Notify orchestrator via send_message.
