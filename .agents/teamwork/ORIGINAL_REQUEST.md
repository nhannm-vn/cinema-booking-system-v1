# Original User Request

## Initial Request — 2026-10-27T16:19:51Z

Build the complete, production-ready Cinema Booking & Operation Management application in Flutter (all screens S01–S31) integrated with Supabase (PostgreSQL, RLS, RPC functions, Edge Functions) and VNPay Sandbox, strictly complying with the specifications in `docs/`.

Working directory: D:\cinema-booking-system-v1  
Integrity mode: development

---

## Requirements

### R1. Complete Customer Experience (S01–S11, S17, S17B, S30)
Implement the full end-to-end customer journey:
- **Authentication (S01, S02):** Email/password login and registration, form validation, error handling.
- **Discovery (S03, S04):** Home screen with now-showing hero backdrop carousel, client-side movie search, 2-column now-showing grid, upcoming row, and movie details with metadata spec cells and trailer launcher.
- **Showtimes & Booking Flow (S05–S08):** 7-day date selector, showtimes grouped by cinema, seat selection map with Supabase Realtime synchronization, 8-seat limit enforcement, holding seats via Postgres RPC `hold_seats` (`for update`), hold countdown timer with 60s warning, food add-on selection (`QuantityStepper`), and checkout with VNPay Sandbox WebView payment flow.
- **Tickets & Profile (S09–S11):** Ticket success screen with QR code and booking code, ticket management tabbed into SẮP TỚI, ĐÃ XEM, ĐÃ HỦY with 2-hour refund cancellation RPC `cancel_booking`, and profile screen with personal info editing.
- **Cinema Map & Notifications (S17, S17B, S30):** Google Maps cinema locator with GPS distance calculation, draggable cinema list, and user notifications center.

### R2. Staff Operations (S18–S21)
Implement theater staff operational tools:
- **Ticket Check-in (S18):** QR camera scanner (`mobile_scanner`) with rosso corsa viewfinder and manual 8-character input option. Enforce all 8 validation checks via RPC `check_in` (wrong cinema, already used, before showtime -30m, after showtime +15m / no-show), mandatory ID verification checkbox for T16/T18 age ratings, and `ResultSheet`.
- **Food Counter Queue (S19):** Two-tab order board (CHỜ GIAO / ĐÃ GIAO) sorted by showtime, searchable by booking code, with delivery confirmation via RPC `deliver_food`.
- **Box Office Counter Sales (S20, S21):** Counter showtimes listing, seat selection (3-minute hold), and payment screen with cash change calculation and direct ticket issuance.

### R3. Management & Admin Capabilities (S12–S16, S22–S29)
Implement the unified management suite scoped by role:
- **Dashboard (S22):** Key operational metrics (today's revenue, tickets sold, occupancy rate, upcoming showtimes).
- **Showtimes Management (S14):** Schedule new showtimes with automatic 15-minute gap conflict prevention.
- **Bookings & Orders (S15):** Filter and inspect all bookings by status (Paid, Used, NoShow, Cancelled, Expired) and channel (Online, Counter).
- **Food Catalog Management (S16):** Manage food items and availability toggles.
- **Staff Management (S23):** Create staff accounts via Edge Function `create-staff` (service role), account lock/unlock toggles.
- **Admin System Settings (S13, S24–S27, S29):** Movies CRUD, room layouts & seat grid configuration, dynamic pricing configuration (base rates, VIP/couple/weekend/prime surcharges), voucher management, and audit logs viewer.

### R4. Design Tokens, Architecture & Code Standards
- **Zero Style Hardcoding:** 100% of colors, typography, spacing, and border radius must use `AppColors`, `AppTextStyles`, `AppSpacing`, and `AppRadius`.
- **Dark Cinematic Aesthetic:** Background `#181818` (`canvas`), primary Rosso Corsa `#DA291C` (`AppColors.primary`), 0px default corner radius, zero elevation (`elevation: 0`), no box shadows.
- **UI State Rigor:** Every screen fetching asynchronous data must handle all 3 states: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` with retry button).
- **Navigation & Typography:** All button labels and navigation links must be explicitly uppercase (`.toUpperCase()`). Maximum 1 primary button per screen.
- **Security:** RLS enforced on all tables, staff and manager queries strictly filtered by `cinema_id`, sensitive operations run via Postgres RPC functions.

---

## Acceptance Criteria

### Customer Flow Verification
- [ ] User can log in with `khach1@cinema.vn` / `123456`, browse movies, view movie details, and select a showtime.
- [ ] In seat selection (S06), user can select up to 8 seats; attempting a 9th seat triggers a warning message.
- [ ] Selecting seats and tapping TIẾP TỤC locks the seats via RPC `hold_seats` and transitions to food selection (S07) with an active countdown timer.
- [ ] Completed checkout redirects to S09 with a valid `TicketCard` displaying the 8-character booking code and QR code.
- [ ] Customer's My Tickets screen (S10) separates tickets into SẮP TỚI, ĐÃ XEM, và ĐÃ HỦY; a ticket with showtime > 2 hours away displays the HỦY VÉ button.

### Staff & Management Verification
- [ ] Logging in as `staff1@cinema.vn` / `123456` routes directly to S18 Check-in.
- [ ] Scanning or entering an invalid or wrong-cinema booking code displays an error sheet with the exact reason.
- [ ] Checking in a valid ticket for a T16/T18 movie requires checking the ID verification box before enabling "XÁC NHẬN CHO VÀO".
- [ ] Logging in as `manager1@cinema.vn` / `123456` routes to S22 Dashboard, showing only data for cinema `cn_q1`.
- [ ] Creating a showtime overlapping an existing showtime within 15 minutes is rejected with a conflict error.

### Code Quality & Automated Checks
- [ ] `flutter analyze` runs with **0 errors and 0 warnings**.
- [ ] `flutter test` executes all unit and widget tests with **100% passing**.
- [ ] No `Color(0x...)`, `TextStyle(...)` with hardcoded font size, or raw numeric padding in presentation screen files.
- [ ] No `print(...)` statements or `TODO` comments in final code.
