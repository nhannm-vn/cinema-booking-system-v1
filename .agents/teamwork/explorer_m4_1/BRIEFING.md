# BRIEFING — 2026-10-27T19:25:00Z

## Mission
Formulate a comprehensive, production-ready technical architecture and implementation plan for Milestone 4: Staff Operations (S18–S21, S23).

## 🔒 My Identity
- Archetype: explorer
- Roles: investigation, synthesis
- Working directory: d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1
- Original parent: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Milestone: Milestone 4 (Staff Operations)

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Multi-tenant isolation: All queries MUST include `.eq('cinema_id', currentCinemaId)`
- 100% Token compliance: `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, zero `BoxShadow`, `elevation: 0`, uppercase buttons, max 1 primary button per screen
- Money strictly in integer VND (`int`)
- Full 3 UI states (Loading `SkeletonBox`, Empty `EmptyState`, Error `ErrorState` with retry button)
- Only Supabase (Auth, Postgres, Realtime, Storage, Edge Functions) + Provider
- Never modify files outside `.agents/teamwork/explorer_m4_1/`

## Current Parent
- Conversation ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Updated: 2026-10-27T19:25:00Z

## Investigation State
- **Explored paths**:
  - `supabase/migrations/0003_functions.sql` (RPCs `check_in`, `deliver_food`, `sell_counter`)
  - `supabase/functions/create-staff/index.ts` (Edge Function for staff creation)
  - `lib/features/staff_checkin/` (repository, checkin model)
  - `lib/features/staff_food/` (repository, food order queries)
  - `lib/features/staff_counter/` (repository, counter provider)
  - `lib/features/management/` (repository, management provider)
  - `lib/shared/widgets/` (`ResultSheet`, `QrScannerView`, `CustomerBottomNav`)
  - `lib/core/routes/` (`AppRouter`, `RouteGuards`)
  - `test/` (E2E & boundary test suites, 1005 tests passing)
- **Key findings**:
  - All DB functions and Edge Function are already implemented and tested.
  - Repositories for Checkin, StaffFood, StaffCounter, and Management already exist.
  - `ResultSheet` and `QrScannerView` exist and conform strictly to tokens.
  - Core M4 tasks are to build the presentation screens (S18, S19, S20, S21, S23), missing providers (`CheckinProvider`, `StaffFoodProvider`), `StaffBottomNav`, and route wiring in `AppRouter` and `lib/main.dart`.
- **Unexplored areas**: None.

## Key Decisions Made
- S18 will support both camera scanner via `QrScannerView` and manual 8-char input fallback modal for desktop/headless testability.
- S19 will support real-time order stream from Supabase `bookings` table for `cinema_id`.
- S20 and S21 will use the existing `StaffCounterProvider` with 3-minute seat hold and fast seat selection modal.
- `StaffBottomNav` will provide unified 4-tab navigation for staff (`SOÁT VÉ`, `ĐỒ ĂN`, `BÁN VÉ`, `TÀI KHOẢN`).

## Artifact Index
- `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\DISPATCH.md` — Inbound parent dispatch
- `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\BRIEFING.md` — Situational awareness
- `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\progress.md` — Heartbeat tracking
- `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\m4_plan.md` — Technical plan for M4
- `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1\handoff.md` — 5-component handoff report
