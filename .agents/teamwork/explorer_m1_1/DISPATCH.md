## 2026-10-27T16:44:44Z
From: 9a20b4d6-8cae-4f73-9d70-c317f7996130
Priority: MESSAGE_PRIORITY_HIGH

You are teamwork_preview_explorer assigned to Milestone 1 (Backend Completeness & Shared Core) of the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\explorer_m1_1
Authoritative request: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
Project plan: d:\cinema-booking-system-v1\PROJECT.md
Survey reports:
- d:\cinema-booking-system-v1\.agents\teamwork\explorer_survey_3\backend_audit.md
- d:\cinema-booking-system-v1\.agents\teamwork\explorer_survey_2\codebase_audit.md
- d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1\spec_inventory.md

MISSION:
Formulate the exact technical implementation plan for Milestone 1:
1. Backend SQL Migration `supabase/migrations/0006_missing_rpcs_and_triggers.sql`:
   - RPC `get_dashboard_metrics(p_cinema_id uuid, p_period text)` for S22 Dashboard.
   - RPC `cancel_showtime(p_showtime_id uuid, p_reason text)` for S14 Showtime Management.
   - Database trigger `trg_showtime_conflict` on `public.showtimes` to enforce 15-minute gap between showtimes in the same room.
2. Backend Seed Data Update in `supabase/migrations/0005_seed.sql`:
   - Seed accounts in `auth.users` for `khach1@cinema.vn`, `staff1@cinema.vn`, `manager1@cinema.vn`, `admin@cinema.vn` with encrypted passwords.
   - Insert corresponding records in `public.profiles` (`role` customer, staff, manager, admin; cinema_id `cn_q1`).
   - Seed demo active showtimes for today and upcoming dates.
3. Backend Edge Function Fix:
   - `supabase/functions/create-vnpay-url/index.ts`: Fix `payments.upsert` to use `SUPABASE_SERVICE_ROLE_KEY` to prevent RLS failure.
4. Flutter Shared / Data Layer Additions:
   - Repositories and ChangeNotifier providers for:
     - `features/staff_counter/` (StaffCounterRepository, StaffCounterProvider)
     - `features/management/` (ManagementRepository, ManagementProvider: metrics, showtimes, food toggle, staff account creation)
     - `features/notifications/` (NotificationRepository, NotificationProvider)
     - `features/chat/` (SupportChatRepository, SupportChatProvider)
   - Register all new providers in `lib/main.dart` `MultiProvider` list.
5. Provide precise file diffs, code implementations, and verification commands in `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m1_1\m1_plan.md`.
6. Deliver handoff at `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m1_1\handoff.md` and notify orchestrator via send_message.
