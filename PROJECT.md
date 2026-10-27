# Project: Cinema Booking & Operation Management System

## Architecture
- **Framework**: Flutter 3.x (Dart 3.x), Feature-first clean architecture.
- **Backend**: Supabase (PostgreSQL 15, Row Level Security, RPC functions with row locks, Deno TypeScript Edge Functions, Realtime channels, Storage).
- **State Management**: `provider` strictly (`ChangeNotifier`, `ProxyProvider`).
- **Data Flow**: `Presentation (Screens S01–S31 & Widgets)` ➔ `Controllers (ChangeNotifier Providers)` ➔ `Repositories` ➔ `Supabase Client / Edge Functions / Postgres RPCs`.
- **Styling**: 100% Design Tokens (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`), dark canvas `#181818`, primary Rosso Corsa `#DA291C`, `elevation: 0`, 0px border radius default.
- **UI State Rigor**: Every data screen handles 3 explicit states: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` with retry button).

## Code Layout
```
lib/
├── core/
│   ├── constants/ (app_constants.dart)
│   ├── network/ (supabase_client.dart, api_endpoints.dart)
│   ├── router/ (app_router.dart, app_routes.dart, route_guards.dart)
│   ├── theme/ (app_colors.dart, app_text_styles.dart, app_spacing.dart, app_radius.dart, app_theme.dart)
│   └── utils/ (formatters.dart, validators.dart, date_utils.dart)
├── shared/
│   ├── models/ (app_user.dart, api_response.dart)
│   └── widgets/ (21 standard widgets)
└── features/
    ├── auth/ (models, repositories, controllers, presentation/screens: S01, S02)
    ├── movies/ (models, repositories, controllers, presentation/screens: S03, S04)
    ├── booking/ (models, repositories, controllers, presentation/screens: S05, S06, S07)
    ├── payment/ (models, repositories, controllers, presentation/screens: S08, S08B)
    ├── tickets/ (models, repositories, controllers, presentation/screens: S09, S10, S10B)
    ├── profile/ (presentation/screens: S11, S11B)
    ├── cinemas/ (models, repositories, controllers, presentation/screens: S17, S17B)
    ├── notifications/ (models, repositories, controllers, presentation/screens: S30)
    ├── staff_checkin/ (presentation/screens: S18)
    ├── staff_food/ (presentation/screens: S19)
    ├── staff_counter/ (models, repositories, controllers, presentation/screens: S20, S21)
    └── management/ (models, repositories, controllers, presentation/screens: S12, S13, S14, S15, S16, S22, S23, S24, S25, S26, S27, S28, S29, S31)
```

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Email/Password Login | Customer & Staff authentication with role redirection | M2 | Survey F1 |
| 2 | Customer Registration | Public self-service registration with validation | M2 | Survey F2 |
| 3 | Movie Discovery Carousel & Grid | Now-showing hero backdrop carousel & 2-column grid | M2 | Survey F3 |
| 4 | Movie Detail & Trailer | Specs cells, synopsis, YouTube trailer launcher | M2 | Survey F4 |
| 5 | Showtime Date Filter & Grouping | 7-day date selector grouped by cinema with format/price | M3 | Survey F5 |
| 6 | Interactive Seat Map Realtime | Supabase Realtime seat sync, 8-seat limit enforcement | M3 | Survey F6 |
| 7 | `hold_seats` Transaction | Atomic seat lock via Postgres RPC with row lock `FOR UPDATE` | M1 / M3 | Survey F7 |
| 8 | Seat Hold Countdown Timer | 5-min timer with red warning under 60s and auto-expiry | M3 | Survey F8 |
| 9 | Concession / Food Selection | Quantity stepper, availability check, skipped option | M3 | Survey F9 |
| 10 | VNPay Sandbox Checkout | Edge function HMAC-SHA512 URL generation & WebView | M1 / M3 | Survey F10 |
| 11 | `confirm_payment` RPC | Finalize booking, mark seats sold, queue food order | M1 / M3 | Survey F11 |
| 12 | Electronic QR Ticket Generation | TicketCard with 8-char booking code and valid QR code | M3 | Survey F12 |
| 13 | Tabbed Ticket Management | My Tickets S10 (SẮP TỚI, ĐÃ XEM, ĐÃ HỦY) | M5 | Survey F13 |
| 14 | `cancel_booking` RPC | 100% refund cancellation if >= 2h before showtime | M1 / M5 | Survey F14 |
| 15 | QR Check-in Camera Scanner | `mobile_scanner` with Rosso Corsa viewfinder & manual input | M4 | Survey F15 |
| 16 | `check_in` RPC Validation | 8 strict validation checks (wrong cinema, used, too early, late) | M1 / M4 | Survey F16 |
| 17 | Age Rating ID Verification Check | Legal ID inspection checkbox for T16 & T18 movies | M4 | Survey F17 |
| 18 | Food Queue Fulfillment Board | Tabbed board (CHỜ GIAO / ĐÃ GIAO) sorted by showtime | M4 | Survey F18 |
| 19 | `deliver_food` RPC | Mark food delivered and send notification to customer | M1 / M4 | Survey F19 |
| 20 | Counter Box Office Ticket Sales | Sell tickets at counter with 3-minute seat hold | M4 | Survey F20 |
| 21 | Cash Change Calculator | S21 cash change calculation and direct ticket issuance | M4 | Survey F21 |
| 22 | Operational Dashboard Metrics | Today's revenue, tickets sold, occupancy rate via RPC | M1 / M5 | Survey F22 |
| 23 | Showtime Scheduling & Conflict Check | Schedule new showtimes with automatic 15-min gap trigger | M1 / M5 | Survey F23 |
| 24 | Booking & Order Inspection | Filter and inspect orders by status and channel (Online/Counter) | M5 | Survey F24 |
| 25 | Food Catalog Availability Toggle | Manage food items and availability toggles | M5 | Survey F25 |
| 26 | Staff Account Creation Edge Function | `create-staff` Edge Function with service role | M1 / M4 | Survey F26 |
| 27 | User Account Locking | Lock/unlock staff/customer accounts with RLS enforcement | M1 / M4 | Survey F27 |
| 28 | Movies CRUD & Deletion Protection | Manage movies library, protect movies with active showtimes | M5 | Survey F28 |
| 29 | Room & Seat Grid Configuration | Interactive seat matrix designer (S/V/C/_) | M5 | Survey F29 |
| 30 | Dynamic Pricing Configuration | Configure base rates (2D/3D/IMAX) and surcharges | M5 | Survey F30 |
| 31 | Voucher Management | Create and manage discount codes (% and fixed VND) | M5 | Survey F31 |
| 32 | Audit Logging | Centralized audit trail of sensitive actions | M5 | Survey F32 |
| 33 | Cinema Locator with Google Maps | Interactive map with GPS distance calculation | M2 | Survey F33 |
| 34 | Local Show Reminder Notifications | Local scheduled reminder 1 hour before showtime | M2 | Survey F34 |
| 35 | In-App Customer Support Chat | 2-way messaging between customer and cinema staff | M5 | Survey F35 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Backend Completeness & Shared Core | Missing RPCs (`get_dashboard_metrics`, `cancel_showtime`), 15m gap trigger, seed data for test accounts, Edge function service-role fix, management & counter repositories/controllers | none | DONE |
| M2 | Auth & Customer Discovery (S01–S04, S17, S17B, S30) | Screens S01 Login, S02 Register, S03 Home Discovery, S04 Movie Detail, S17 Cinema Map, S17B Cinema Detail, S30 Notifications | M1 | DONE |
| M3 | Booking Flow & Checkout (S05–S09, S11, S11B) | Screens S05 Showtimes, S06 Seat Select (`hold_seats`), S07 Food Select, S08 Checkout, S08B VNPay WebView, S09 Ticket Success, S11 Profile, S11B Edit Profile | M1, M2 | PLANNED |
| M4 | Staff Operations (S18–S21, S23) | Screens S18 Ticket Check-in (scanner, 8 checks, T16/T18 ID check), S19 Food Delivery Board (`deliver_food`), S20 Counter Showtimes, S21 Counter Payment & Change, S23 Staff Management (`create-staff`) | M1, M3 | PLANNED |
| M5 | Management & Admin Suite (S10, S10B, S12–S16, S22, S24–S29, S31) | Screens S10 My Tickets & S10B Ticket Detail (2h cancellation), S12 Management Menu, S13 Movies CRUD, S14 Showtimes (15m conflict check), S15 Bookings inspection, S16 Food catalog, S22 Dashboard metrics, S24 Room Seat Map designer, S25 Cinemas & Rooms, S26 Pricing, S27 Vouchers, S28 Managers, S29 Audit Logs, S31 Support Chat | M1, M3, M4 | PLANNED |
| M6 | Final E2E Integration & Verification | Route wiring in `main.dart`, pass 100% of E2E test suite (Tiers 1-4), adversarial test hardening (Tier 5), `flutter analyze` 0 issues, `flutter test` 100% pass, Forensic Audit CLEAN | M1–M5, TEST_READY.md | PLANNED |

## Interface Contracts
### Auth & Profile
- `AuthProvider.login(email, password)`: returns `Future<AppUser>`
- `AuthProvider.register(email, password, fullName, phone)`: returns `Future<void>`
- `AuthProvider.currentUser`: `AppUser?` with `id`, `email`, `role`, `cinemaId`, `isLocked`

### Booking & Seats
- `BookingRepository.holdSeats({showtimeId, bookingCode, seatIds, holdMinutes, bookingJson})`: calls RPC `hold_seats`
- `BookingRepository.confirmPayment({bookingCode, txnRef, vnpTransactionNo, amount})`: calls RPC `confirm_payment`
- `BookingRepository.cancelBooking(bookingCode, reason)`: calls RPC `cancel_booking`
- `SeatTakenException(conflictedSeatId)`: thrown when seats are contested

### Staff & Check-in
- `StaffRepository.checkIn(bookingCode)`: calls RPC `check_in`, returns status (`OK`, `WRONG_CINEMA`, `TOO_EARLY`, `EXPIRED_SHOWTIME`, etc.)
- `StaffRepository.deliverFood(bookingCode)`: calls RPC `deliver_food`
- `StaffRepository.sellCounter(...)`: calls RPC `sell_counter`

### Management
- `ManagementRepository.getDashboardMetrics(cinemaId, period)`: calls RPC `get_dashboard_metrics`
- `ManagementRepository.createShowtime(...)`: checks 15m gap conflict
- `ManagementRepository.createStaff(...)`: invokes Edge Function `create-staff`
