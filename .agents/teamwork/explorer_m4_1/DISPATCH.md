## 2026-10-27T19:13:26Z

You are Explorer M4_1 (teamwork_preview_explorer).
Your Working Directory: d:\cinema-booking-system-v1\.agents\teamwork\explorer_m4_1
Your Parent Orchestrator ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130

### INPUTS
1. Authoritative Request: `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. Project Architecture: `d:\cinema-booking-system-v1\PROJECT.md`
3. Design Tokens & Invariants: `docs/DESIGN_TOKENS.md`, `docs/.cursorrules`, `docs/ROLE_FLOWS.md`, `docs/BUSINESS_RULES.md`, `docs/TECH_STACK.md`

### MISSION
Formulate a comprehensive, production-ready technical architecture and implementation plan for **Milestone 4: Staff Operations (S18–S21, S23)**:
- S18 Ticket Check-in Screen (`/staff/check-in`): Viewfinder with Rosso Corsa frame, `mobile_scanner` integration (with fallback manual input for desktop/headless), 8 strict validation checks via RPC `check_in`, T16/T18 legal ID check confirmation, result bottom sheet.
- S19 Food Delivery Board (`/staff/food-board`): Tabbed board (`CHỜ GIAO` / `ĐÃ GIAO`), sorted by showtime ascending, `deliver_food` RPC action, real-time subscription.
- S20 Counter Showtimes (`/staff/counter-showtimes`): Box office fast showtime picker for today, room filter, format/price/available seat indicators, 3-minute seat hold.
- S21 Counter Payment & Change Calculator (`/staff/counter-payment`): Order breakdown, integer VND cash received input, quick cash buttons (+50k, +100k, +200k, +500k, EXACT), live change calculation, RPC `sell_counter` execution.
- S23 Staff Account Management (`/management/staff-accounts` or `/staff/accounts`): Listing staff filtered by `cinema_id`, lock/unlock account toggle, create staff modal invoking Edge Function `create-staff`.

### ARCHITECTURAL REQUIREMENTS
1. Multi-tenant isolation: All queries MUST include `.eq('cinema_id', currentCinemaId)`.
2. 100% Token compliance: `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, zero `BoxShadow`, `elevation: 0`, uppercase buttons, max 1 primary button per screen.
3. Money strictly in integer VND (`int`).
4. Full 3 UI states (Loading `SkeletonBox`, Empty `EmptyState`, Error `ErrorState` with retry button).

### DELIVERABLES
1. Write `m4_plan.md` in your working directory with step-by-step specifications for all files, models, controllers, screens, and routes.
2. Write a 5-component `handoff.md` (Observation, Logic Chain, Caveats, Conclusion, Verification Method).
3. Send a completion message to Parent Orchestrator `9a20b4d6-8cae-4f73-9d70-c317f7996130`.
