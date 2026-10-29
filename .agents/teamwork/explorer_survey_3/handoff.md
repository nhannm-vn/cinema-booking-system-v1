# Handoff Report — explorer_survey_3 (Backend & Supabase Audit)

## 1. Observation
- **`supabase/config.toml`**: Lines 1–32 configures `api` (port 54321), `db` (port 54322, pg 15), `studio` (54323), `auth`, `storage`, and `realtime`.
- **`supabase/migrations/0001_schema.sql`**: Lines 1–246 creates 15 tables (`cinemas`, `profiles`, `rooms`, `movies`, `foods`, `showtimes`, `bookings`, `seats`, `payments`, `notifications`, `pricing_settings`, `vouchers`, `audit_logs`, `conversations`, `messages`).
  - `rooms`: `seat_layout text[] not null default '{}'` (lines 36–45). No dedicated `seat_layouts` table.
  - `bookings`: contains `seats jsonb`, `foods jsonb`, `price_snapshot jsonb` (lines 106–140). No separate `booking_seats`, `booking_foods`, or `tickets` table; booking code (8 chars) represents the ticket.
  - `seats`: composite PK `(showtime_id, seat_id)`, tracks active `holding` and `sold` seats (lines 145–154).
- **`supabase/migrations/0002_rls.sql`**: Lines 1–156 enables RLS on all 15 tables. Direct INSERT/UPDATE/DELETE on `bookings` and `seats` is denied (`with check (false)`, lines 95–103). Payments table has `payments_no_direct_insert with check (false)` (line 114).
- **`supabase/migrations/0003_functions.sql`**: Lines 1–410 defines 7 Postgres RPC functions: `hold_seats` (lines 6–100), `confirm_payment` (lines 103–158), `release_hold` (lines 161–181), `check_in` (lines 184–248), `deliver_food` (lines 251–284), `cancel_booking` (lines 287–352), `sell_counter` (lines 355–409).
  - Grep search for `get_dashboard_metrics`: 0 results found in entire workspace.
  - Grep search for `cancel_showtime`: 0 definitions in SQL (only found in `docs/TECH_STACK.md` line 295 and `docs/BUSINESS_RULES.md` line 320).
- **`supabase/migrations/0004_triggers.sql`**: Lines 1–42 contains `handle_new_user` and `protect_profile_fields`. No trigger exists to validate 15-minute gap between showtimes.
- **`supabase/migrations/0005_seed.sql`**: Lines 1–122 seeds pricing settings, 2 cinemas, 3 rooms, 3 movies, 4 foods (`cn_q1` only), 2 vouchers.
  - Lines 1–122 contains zero inserts into `auth.users`, zero inserts into `public.profiles`, and zero inserts into `public.showtimes`.
  - Grep search for `khach1@cinema.vn`: only appears in `docs/BUSINESS_RULES.md:41`.
- **`supabase/functions/create-vnpay-url/index.ts`**:
  - Lines 34–38 creates supabase client using `SUPABASE_ANON_KEY` and caller's JWT header.
  - Lines 88–93 executes `await supabase.from('payments').upsert(...)`.
- **`supabase/functions/vnpay-return/index.ts`**: Lines 53–56 uses `SUPABASE_SERVICE_ROLE_KEY` to call `confirm_payment` RPC.
- **`supabase/functions/create-staff/index.ts`**: Lines 54–57 uses `SUPABASE_SERVICE_ROLE_KEY` to call `admin.createUser`.

---

## 2. Logic Chain
1. *From 0001_schema.sql (lines 106–140) and TECH_STACK.md (lines 78–145)*: The architecture deliberately unifies `booking_seats`, `booking_foods`, and `tickets` into `bookings` via `jsonb` columns (`seats`, `foods`, `price_snapshot`) and 8-character PK `code`. `rooms.seat_layout` stores the room matrix. This is intentional and optimal for transactional seat holding without multi-table join locking.
2. *From 0002_rls.sql (line 114) and create-vnpay-url/index.ts (lines 35, 88)*: The RLS policy `payments_no_direct_insert` blocks non-service-role inserts (`with check (false)`). Because `create-vnpay-url` uses `SUPABASE_ANON_KEY` with the user's JWT to upsert into `payments`, Postgres RLS will reject this operation at runtime, causing payment URL generation to fail.
3. *From 0003_functions.sql and ORIGINAL_REQUEST.md (R3 / Acceptance Criteria)*:
   - S22 Dashboard requires `get_dashboard_metrics` (today's revenue, tickets sold, occupancy rate, upcoming showtimes).
   - S14 Showtime management requires `cancel_showtime` to cancel showtimes with mass booking cancellation and customer notifications.
   - Neither RPC exists in `0003_functions.sql`.
4. *From 0004_triggers.sql and ORIGINAL_REQUEST.md (R3: "automatic 15-minute gap conflict prevention")*: There is no database trigger or constraint enforcing a 15-minute gap between showtimes in the same room. Double booking can occur without DB validation.
5. *From 0005_seed.sql*: No accounts exist in `auth.users` or `public.profiles`. The Acceptance Criteria requirement to test login with `khach1@cinema.vn`, `staff1@cinema.vn`, `manager1@cinema.vn`, and `admin@cinema.vn` will fail on fresh DB deployment unless accounts are seeded or manually registered. Furthermore, zero showtimes are seeded.

---

## 3. Caveats
- Supabase local instance is not currently running as an active Docker container in this environment, so live connection tests against port 54321 were not executed; findings are based on static code, DDL, and Edge Function TypeScript analysis.
- The VNPay Sandbox hash secret in `create-vnpay-url` and `vnpay-return` defaults to fallback strings if environment variables are not set in Deno.

---

## 4. Conclusion
The backend schema and RPC architecture in `supabase/` provide a solid, secure foundation adhering to `TECH_STACK.md` (15 tables with full RLS, 7 transactional RPC functions with row locks).
However, 4 critical items must be resolved:
1. **Fix Edge Function `create-vnpay-url`**: Switch the `payments.upsert` call to use `SUPABASE_SERVICE_ROLE_KEY` to avoid RLS rejection.
2. **Implement Missing RPCs**: Add `get_dashboard_metrics` and `cancel_showtime` to PostgreSQL functions.
3. **Add 15-minute Gap Trigger**: Implement `trg_showtime_conflict` on `public.showtimes`.
4. **Complete Seed Data**: Add SQL seed scripts for `auth.users` (`khach1`, `staff1`, `manager1`, `admin`), corresponding `public.profiles`, and demo `showtimes`.

Full detailed audit and drop-in SQL/TypeScript implementations have been written to `d:\cinema-booking-system-v1\.agents\teamwork\explorer_survey_3\backend_audit.md`.

---

## 5. Verification Method
1. **Inspect Audit Report**: Open and review `d:\cinema-booking-system-v1\.agents\teamwork\explorer_survey_3\backend_audit.md`.
2. **Verify RLS Bug**: Inspect `supabase/functions/create-vnpay-url/index.ts:35-88` and compare against `supabase/migrations/0002_rls.sql:114`.
3. **Verify Missing Functions**: Run `grep_search` for `get_dashboard_metrics` and `cancel_showtime` in `supabase/migrations/0003_functions.sql`.
4. **Verify Seed Absence**: Inspect `supabase/migrations/0005_seed.sql` to verify absence of `auth.users` and `showtimes`.
