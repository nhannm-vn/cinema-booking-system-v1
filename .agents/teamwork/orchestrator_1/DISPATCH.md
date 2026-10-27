# Dispatch Log

## 2026-10-27T16:21:13Z
You are the Project Orchestrator for the Cinema Booking & Operation Management application.

Your working directory is: d:\cinema-booking-system-v1\.agents\teamwork\orchestrator_1
The authoritative user request is recorded at: d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md
The project root is: d:\cinema-booking-system-v1

TASK:
Build the complete, production-ready Cinema Booking & Operation Management application in Flutter (all screens S01–S31) integrated with Supabase (PostgreSQL, RLS, RPC functions, Edge Functions) and VNPay Sandbox, strictly complying with all specifications in `docs/` and the acceptance criteria in ORIGINAL_REQUEST.md.

MANDATORY RULES & INVARIANTS:
1. Comply strictly with AGENTS.md, GEMINI.md, and docs/ (.cursorrules, TECH_STACK.md, DESIGN_TOKENS.md, PROJECT_STRUCTURE.md, BUSINESS_RULES.md, ROLE_FLOWS.md, 00_README.md).
2. Backend is Supabase + PostgreSQL (RLS, RPC functions, Edge Functions). State management is `provider` (ChangeNotifier, ProxyProvider).
3. Design tokens: 100% token usage (AppColors, AppTextStyles, AppSpacing, AppRadius). Dark cinematic canvas #181818, primary Rosso Corsa #DA291C. 0 elevation, no box shadows.
4. UI states: All async fetching screens must handle Loading (SkeletonBox), Empty (EmptyState), and Error (ErrorState with retry button).
5. All buttons and navigation uppercase (.toUpperCase()). Maximum 1 primary button per screen.
6. Queries for Staff and Manager must filter by cinema_id (and be secured by RLS). Sensitive operations (hold_seats, confirm_payment, cancel_booking, check_in, deliver_food) run via Postgres RPC.
7. Verification: `flutter analyze` must pass with 0 errors and 0 warnings. `flutter test` must pass 100%. No hardcoded style codes, no `print`, no `TODO`.

OPERATIONAL REQUIREMENTS:
- Regularly update `progress.md` and `BRIEFING.md` in your working directory `d:\cinema-booking-system-v1\.agents\teamwork\orchestrator_1`.
- When your team completes implementation and passes all verification, report completion back to the Sentinel. Victory audit will be triggered.
