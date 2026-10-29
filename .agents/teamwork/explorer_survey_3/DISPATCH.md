## 2026-10-27T16:23:49Z
You are a teamwork_preview_explorer assigned to survey the Backend and Supabase artifacts for the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\explorer_survey_3
Authoritative request: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
Project root: d:\cinema-booking-system-v1

MISSION:
Investigate and audit the backend and Supabase infrastructure:
1. Inspect `supabase/` directory:
   - `supabase/config.toml`
   - Migrations and SQL scripts in `supabase/migrations/`
   - Seed data in `supabase/seed.sql` or scripts
   - Edge Functions in `supabase/functions/` (e.g. `create-staff`, `vnpay-create-url`, `vnpay-ipn`, etc.)
2. Check database schema:
   - Tables: users/profiles, cinemas, rooms, seat_layouts, seats, movies, showtimes, bookings, booking_seats, tickets, foods, booking_foods, vouchers, audit_logs.
   - Row Level Security (RLS) policies on all tables.
   - Postgres RPC functions: `hold_seats`, `confirm_payment`, `cancel_booking`, `check_in`, `deliver_food`, `get_dashboard_metrics`, etc. Check parameter types, return types, concurrency locks (`for update`), transaction isolation.
3. Check seed users and auth accounts:
   - `khach1@cinema.vn` / `123456`
   - `staff1@cinema.vn` / `123456`
   - `manager1@cinema.vn` / `123456`
   - Admin account
4. Check VNPay Sandbox configuration and endpoints.
5. Identify any missing tables, policies, functions, or seed data needed to satisfy `docs/` and `ORIGINAL_REQUEST.md`.
6. Output: Write full backend audit report to `d:\cinema-booking-system-v1\.agents\teamwork\explorer_survey_3\backend_audit.md` and deliver your final handoff at `d:\cinema-booking-system-v1\.agents\teamwork\explorer_survey_3\handoff.md`.
Communicate back to orchestrator using send_message with a summary.
