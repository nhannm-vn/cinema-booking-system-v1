## 2026-10-27T20:27:34Z
You are worker_m5_1.
Working directory: d:\cinema-booking-system-v1\.agents\teamwork\worker_m5_1

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY INPUTS:
1. Read the authoritative original request at: `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`. Subagents MUST read it before starting work.
2. Read project architecture and roadmap: `d:\cinema-booking-system-v1\PROJECT.md`.
3. Read project rules and guidelines: `d:\cinema-booking-system-v1\AGENTS.md`, `d:\cinema-booking-system-v1\GEMINI.md`, and `docs/`.
4. Read the 3 comprehensive explorer implementation plans:
   - `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m5_1\m5_plan.md`
   - `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m5_2\m5_plan.md`
   - `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m5_3\m5_plan.md`

MISSION:
Implement the complete Milestone 5 — Management & Admin Suite across all 14 screens + navigation:
1. `lib/shared/widgets/manager_bottom_nav.dart`: 3 tabs (`TỔNG QUAN` S22, `QUẢN LÝ` S12, `TÀI KHOẢN` S11).
2. Customer Tickets:
   - Refine `lib/features/tickets/presentation/controllers/ticket_provider.dart` (ensure upcoming checks `DateTime.now().isBefore(showtimeStart)`).
   - `lib/features/tickets/presentation/screens/my_tickets_screen.dart` (S10: tabbed SẮP TỚI, ĐÃ XEM, ĐÃ HỦY).
   - `lib/features/tickets/presentation/screens/ticket_detail_screen.dart` (S10B: full QR barcode display, 2-hour cutoff rule gating cancellation button, calls `cancel_booking` RPC, refund policy modal).
3. Operations & Catalog Management:
   - `lib/features/management/presentation/screens/management_menu_screen.dart` (S12: grouped menu based on role Staff / Manager / Admin).
   - `lib/features/management/presentation/screens/movies_management_screen.dart` (S13: status filter tabs, search, add/edit modal, deletion protection if active future showtimes exist).
   - `lib/features/management/presentation/screens/showtimes_management_screen.dart` (S14: room & date filters, add modal with 15-minute gap conflict check, cancel showtime via `cancel_showtime` RPC).
   - `lib/features/management/presentation/screens/bookings_management_screen.dart` (S15: status and channel filters, search code/phone, booking inspection detail modal).
   - `lib/features/management/presentation/screens/food_catalog_screen.dart` (S16: category chips, add/edit modal, integer VND price, availability toggle).
   - `lib/features/management/presentation/screens/operational_dashboard_screen.dart` (S22: `get_dashboard_metrics` RPC, revenue in VND, tickets count, occupancy %, period picker HÔM NAY / 7 NGÀY / THÁNG NÀY).
4. Cinema Configuration, Pricing, Vouchers & Administration:
   - `lib/features/management/presentation/screens/seat_map_designer_screen.dart` (S24: interactive row/column grid editor with S/V/C/_ toggles, real-time seat count computation, save room layout).
   - `lib/features/management/presentation/screens/cinemas_rooms_screen.dart` (S25: cinema & rooms listing, room creation linking to S24).
   - `lib/features/management/presentation/screens/pricing_settings_screen.dart` (S26: base prices 2D/3D/IMAX, surcharges VIP/Couple/Weekend/Prime, interactive formula simulator, integer VND).
   - `lib/features/management/presentation/screens/vouchers_management_screen.dart` (S27: voucher listing, add/edit modal, percent or fixed VND discount, start/expiry dates, is_active toggle).
   - `lib/features/management/presentation/screens/managers_management_screen.dart` (S28: Admin-only, cinema assignment, lock/unlock toggle, create manager via Edge Function `create-staff`).
   - `lib/features/management/presentation/screens/audit_logs_screen.dart` (S29: audit logs list from `public.audit_logs`, action/table filters, old data vs new data JSON diff modal).
   - `lib/features/chat/presentation/screens/support_chat_screen.dart` (S31: in-app customer support chat with Supabase Realtime message stream).
5. Router Integration:
   - Update `lib/core/routes/app_router.dart` to mount all S10, S10B, S12, S13, S14, S15, S16, S22, S24, S25, S26, S27, S28, S29, S31 screens to their defined route names.
6. Verification Tests:
   - Author and run comprehensive unit and widget tests covering all new screens, models, and providers.
   - Run `flutter analyze` to ensure 0 errors and 0 warnings.
   - Run `flutter test` to ensure all tests pass 100%.

DELIVERABLES:
Write a comprehensive report to:
`d:\cinema-booking-system-v1\.agents\teamwork\worker_m5_1\handoff.md`
documenting all implemented files, verification commands, and test outputs.
Notify the orchestrator via `send_message` when done.
