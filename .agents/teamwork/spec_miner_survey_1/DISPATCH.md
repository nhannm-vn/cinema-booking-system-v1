## 2026-10-27T16:23:49Z
You are a teamwork_preview_spec_miner assigned to the Survey phase of the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1
Authoritative request: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
Documentation source: d:\cinema-booking-system-v1\docs (including .cursorrules, TECH_STACK.md, DESIGN_TOKENS.md, PROJECT_STRUCTURE.md, BUSINESS_RULES.md, ROLE_FLOWS.md, 00_README.md)
Also review AGENTS.md and GEMINI.md at d:\cinema-booking-system-v1.

MISSION:
Mine, extract, and systematically document all specifications and requirements from the authoritative documents:
1. Complete Screen Inventory: Enumerate screens S01–S31, S17B, role access, path/route name, UI elements, states (Loading/SkeletonBox, Empty/EmptyState, Error/ErrorState), and primary actions.
2. Complete Business Logic & Invariants:
   - hold_seats RPC (8-seat limit customer, 3-minute hold counter, 10-minute hold customer, 60s countdown warning, row locks)
   - confirm_payment RPC (VND int, snapshot prices, transaction status)
   - cancel_booking RPC (2-hour refund cutoff, status update)
   - check_in RPC (all 8 validation checks, ID check for T16/T18, ResultSheet)
   - deliver_food RPC (CHỜ GIAO / ĐÃ GIAO board, status)
   - Showtime conflict prevention (15-minute gap)
   - Dynamic pricing rules (base, surcharges, weekend, couple, VIP)
3. Architecture, Tokens & Design Rules:
   - AppColors, AppTextStyles, AppSpacing, AppRadius
   - Zero hardcoded colors/dimensions, 0 elevation, dark canvas #181818, Rosso Corsa #DA291C
   - State management rules: provider only (ChangeNotifier, ProxyProvider)
   - Button uppercase rule, max 1 primary button per screen.
4. Output: Write your detailed report to `d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1\spec_inventory.md` and deliver your final handoff at `d:\cinema-booking-system-v1\.agents\teamwork\spec_miner_survey_1\handoff.md`.
Communicate back to orchestrator using send_message with a summary.
