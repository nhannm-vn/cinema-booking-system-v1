# Handoff Report — Milestone 5 Part A Exploration
## Explorer Agent: explorer_m5_1

---

## 1. Observation

1. **Database Schema & RPC Functions**:
   - `supabase/migrations/0001_schema.sql:105-137`: Table `public.bookings` defines `code text primary key check (char_length(code) = 8)`, `status text check (status in ('holding', 'paid', 'used', 'cancelled', 'expired'))`, `price_snapshot jsonb`, `showtime_start timestamptz`, `seats jsonb`, `foods jsonb`, `food_status text`.
   - `supabase/migrations/0001_schema.sql:229-243`: Table `public.conversations` with `id text primary key` (`${user_id}_${cinema_id}`) and `public.messages` with `conversation_id text`, `sender_id uuid`, `text text`, `booking_code text`.
   - `supabase/migrations/0003_functions.sql:287-352`: RPC `cancel_booking(p_booking_code text, p_reason text)`:
     ```sql
     if v_role = 'customer' or v_role is null then
       if b.user_id <> v_uid then raise exception 'NOT_OWNER'; end if;
       if b.status <> 'paid' then raise exception 'NOT_PAID'; end if;
       if v_now > (b.showtime_start - interval '2 hours') then
         raise exception 'CANNOT_CANCEL_LESS_THAN_2_HOURS';
       end if;
     ```
   - `supabase/migrations/0006_missing_rpcs_and_triggers.sql:147-249`: RPC `get_dashboard_metrics(p_cinema_id text, p_period text default 'today')` returns JSON with `today_revenue`, `today_tickets`, `occupancy_rate`, `total_capacity`, `sold_capacity`, `upcoming_showtimes`.

2. **Existing Data Repositories & Controllers**:
   - `lib/features/tickets/data/ticket_repository.dart:13-44`: Contains `getMyTickets()`, `getTicketByCode(code)`, and `cancelBooking(code, reason)` which invokes `cancel_booking` RPC.
   - `lib/features/tickets/presentation/controllers/ticket_provider.dart:19-31`: Defines getters `upcomingTickets`, `historyTickets`, and `cancelledTickets`. `upcomingTickets` filters `t.status == 'paid' && !t.isNoShow`, which should additionally verify `DateTime.now().isBefore(t.showtimeStart)`.
   - `lib/features/management/data/repositories/management_repository.dart:15-22`: Implements `getDashboardMetrics(cinemaId, period)` calling RPC `get_dashboard_metrics`.
   - `lib/features/management/presentation/controllers/management_provider.dart:33-47`: Implements `loadDashboardMetrics(cinemaId, period)`.
   - `lib/features/chat/data/repositories/support_chat_repository.dart:13-75`: Implements `getOrCreateConversation`, `getMessages`, `sendMessage`, and `subscribeMessages` via Supabase Realtime channel on table `messages`.
   - `lib/features/chat/presentation/controllers/support_chat_provider.dart:25-66`: Implements `initConversation(userId, cinemaId)` with Realtime stream listener and `sendMessage(text, bookingCode)`.

3. **Routing & Navigation**:
   - `lib/core/routes/app_router.dart:43-72`: Defines route constants `myTickets` (`/my-tickets`), `ticketDetail` (`/ticket-detail`), `managementHome` (`/management`), `dashboard` (`/management/dashboard`), `supportChat` (`/support-chat`).
   - `lib/core/routes/app_router.dart:302-308`: Currently routes fall into `_buildPlaceholderScreen`.
   - `lib/shared/widgets/customer_bottom_nav.dart:88-92`: Tab 2 routes to `AppRoutes.myTickets`.
   - `lib/features/profile/presentation/screens/profile_screen.dart:168`: Menu item "HỘP THƯ HỖ TRỢ" routes to `AppRoutes.supportChat`.
   - `lib/core/routes/route_guards.dart:22-23`: Directs `manager` and `admin` roles to `AppRoutes.dashboard` on login.

4. **Shared Widgets & Verification**:
   - `lib/shared/widgets/ticket_card.dart`: Fully renders electronic ticket with `QrImageView`, square modules, and booking code.
   - `lib/shared/widgets/spec_cell.dart`: Displays formatted stats and KPI metrics.
   - `lib/shared/widgets/status_badge.dart`: Supports all booking and order states.
   - Test `test/features/management/dashboard_metrics_model_test.dart` passes with 0 failures (`flutter test` returned exit code 0).

---

## 2. Logic Chain

1. **Foundation Completeness**:
   - From Observation 1 & 2, both the database schema/RPC functions (`cancel_booking`, `get_dashboard_metrics`, `conversations`, `messages`) and Dart repository/provider layers (`TicketRepository`, `TicketProvider`, `ManagementRepository`, `ManagementProvider`, `SupportChatRepository`, `SupportChatProvider`) are already implemented and registered in the `MultiProvider` tree in `lib/main.dart`.
2. **Missing Presentation Layer (M5 Part A)**:
   - From Observation 3, the presentation screens S10 (`MyTicketsScreen`), S10B (`TicketDetailScreen`), S12 (`ManagementMenuScreen`), S22 (`OperationalDashboardScreen`), and S31 (`SupportChatScreen`) do not yet exist as screen widgets and are hitting placeholder fallbacks in `AppRouter`.
3. **Navigation Consistency**:
   - While `CustomerBottomNav` and `StaffBottomNav` exist, `ManagerBottomNav` is missing. Introducing `ManagerBottomNav` with 3 tabs (TỔNG QUAN S22, QUẢN LÝ S12, TÀI KHOẢN S11) strictly adheres to `ROLE_FLOWS.md` Section 0 and completes navigation for Manager and Admin.
4. **Business Rule Enforcement**:
   - The 2-hour cancellation rule is enforced at the database level by RPC `cancel_booking` (`showtime_start - interval '2 hours'`). The client UI in S10B must respect this by enabling "HỦY VÉ VÀ HOÀN TIỀN" only when `showtimeStart` is >= 2 hours in the future and displaying a confirmation dialog with 100% refund explanation.
   - S12 menu must dynamically adapt to role: Manager sees operational items and read-only catalog/pricing, whereas Admin sees full CRUD, room layouts (S25), seat designer (S24), vouchers (S27), managers (S28), and audit logs (S29).

---

## 3. Caveats

1. **Admin Cinema Filtering**:
   - For Manager, `cinemaId` is always bound to `user.cinemaId`. For Admin, `user.cinemaId` is null, which defaults to `cn_q1` or allows switching cinemas via a dropdown in the dashboard/menu.
2. **Support Chat Cinema Selection**:
   - Customers may have bookings at multiple cinemas. S31 supports an optional `cinemaId` argument (from ticket detail or cinema detail), defaulting to the customer's most recent cinema or a selector.
3. **No Caveats Beyond Stated Above**:
   - All backend dependencies, models, and tokens are verified.

---

## 4. Conclusion

Milestone 5 — Part A is fully scoped, designed, and ready for immediate implementation:
1. Create `lib/shared/widgets/manager_bottom_nav.dart` (3-tab bar for Manager/Admin).
2. Refine `TicketProvider` ticket classification getters.
3. Implement `lib/features/tickets/presentation/screens/my_tickets_screen.dart` (S10).
4. Implement `lib/features/tickets/presentation/screens/ticket_detail_screen.dart` (S10B).
5. Implement `lib/features/management/presentation/screens/management_menu_screen.dart` (S12).
6. Implement `lib/features/management/presentation/screens/operational_dashboard_screen.dart` (S22).
7. Implement `lib/features/chat/presentation/screens/support_chat_screen.dart` (S31).
8. Wire named routes in `lib/core/routes/app_router.dart`.
9. Add comprehensive widget and unit tests covering S10, S10B, S12, S22, S31.

The comprehensive technical specification is documented in `m5_plan.md`.

---

## 5. Verification Method

1. **Inspect Plan Artifact**:
   - Review `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m5_1\m5_plan.md`.
2. **Run Existing Tests**:
   ```bash
   flutter test test/features/management/dashboard_metrics_model_test.dart
   ```
3. **Post-Implementation Verification**:
   ```bash
   flutter analyze
   flutter test
   ```
4. **Invalidation Conditions**:
   - Any failure of `cancel_booking` RPC to reject cancellation under 2 hours.
   - Any hardcoded color or style values outside `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`.
   - Any missing state (Loading, Empty, Error) in the screens.
