# DISPATCH — reviewer_m5_4 (Milestone 5 Iteration 2 Reviewer 2)

## Role & Mission
You are `reviewer_m5_4`. Your mission is to conduct an independent review of Milestone 5 (Management & Admin suite S10, S10B, S12–S16, S22, S24–S29, S31) focusing on:
1. Business logic adherence across all screens:
   - S10/S10B: 2-hour refund policy check, QR display, cancellation RPC.
   - S13: Deletion protection when future showtimes exist.
   - S14: 15-minute gap conflict check, cancel showtime RPC.
   - S22: Operational dashboard KPI cards, `get_dashboard_metrics` RPC.
   - S24: Seat Map Designer, safety lock (`hasFutureSoldShowtimes`), brush palette.
   - S26: Pricing Settings & Simulator (with couple seat 2x base multiplier).
   - S28: Managers management via Edge Function `create-staff`.
   - S31: Realtime customer support chat.
2. Invariants & Rules:
   - Multi-tenant cinema isolation: all Staff/Manager queries include `.eq('cinema_id', currentCinemaId)`.
   - Money values strictly in integer VND (`int`), never `double`.
   - 3 UI states (Loading, Empty, Error) on every screen.
   - 0 raw hex colors outside `app_colors.dart`.
   - 0 BoxShadow, 0 elevation.
   - Uppercase button & nav labels (`.toUpperCase()`).
3. Run `flutter analyze` and `flutter test`.

## Mandatory Inputs to Read
1. `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. `d:\cinema-booking-system-v1\PROJECT.md`
3. `d:\cinema-booking-system-v1\docs\BUSINESS_RULES.md`
4. `d:\cinema-booking-system-v1\docs\ROLE_FLOWS.md`
5. `d:\cinema-booking-system-v1\docs\DESIGN_TOKENS.md`
6. `d:\cinema-booking-system-v1\.agents\teamwork\worker_m5_2\handoff.md`

## Instructions
- Run build/test commands via `run_command` in `d:\cinema-booking-system-v1`.
- Verify code matches contracts.
- Write your final verdict (APPROVE or REQUEST_CHANGES) in `d:\cinema-booking-system-v1\.agents\teamwork\reviewer_m5_4\handoff.md`.
- Send a completion message to the Project Orchestrator with your verdict.


## 2026-10-27T21:59:01Z
You are reviewer_m5_4. Your task is to perform Business Logic and Invariant Review for Milestone 5 Iteration 2.
Read your dispatch file at `d:\cinema-booking-system-v1\.agents\teamwork\reviewer_m5_4\DISPATCH.md` and all mandatory inputs.
Verify business rules, multi-tenant isolation, tokens, and 3 UI states across all screens S10, S10B, S12-S16, S22, S24-S29, S31.
Run `flutter analyze` and `flutter test`.
Write your report and verdict (APPROVE or REQUEST_CHANGES) in `d:\cinema-booking-system-v1\.agents\teamwork\reviewer_m5_4\handoff.md`.
Send a completion message with your verdict to the Project Orchestrator.
