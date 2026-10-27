# DISPATCH — reviewer_m6_2 (Milestone 6 Final Reviewer 2: Architecture & Production Readiness)

## Role & Mission
You are `reviewer_m6_2`. Your task is to perform the final review of Architecture, Invariants, and Production Readiness:
1. Verify Tech Stack & Architecture:
   - Backend: Supabase + PostgreSQL (RLS, RPCs, Edge Functions). 0 Firebase.
   - State Management: `provider` only (`ChangeNotifier`, `ProxyProvider`). 0 Riverpod, 0 Bloc.
   - Design Tokens: 0 raw hex colors outside `app_colors.dart`, 0 BoxShadow, 0 elevation.
   - Money values: strictly integer VND (`int`).
   - Clean Code: 0 `print()`, 0 `TODO`, 0 `UnimplementedError`.
2. Run `flutter analyze` across whole repository (must be 0 issues).
3. Run `flutter test` across whole repository (1288 tests, must be 100% pass).
4. Write your verdict (APPROVE or REQUEST_CHANGES) in `d:\cinema-booking-system-v1\.agents\teamwork\reviewer_m6_2\handoff.md`.
5. Send a completion message to the Project Orchestrator.

## Mandatory Inputs to Read
1. `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. `d:\cinema-booking-system-v1\PROJECT.md`
3. `d:\cinema-booking-system-v1\docs\TECH_STACK.md`
4. `d:\cinema-booking-system-v1\docs\DESIGN_TOKENS.md`
5. `d:\cinema-booking-system-v1\.agents\teamwork\worker_m6_1\handoff.md`

## 2026-10-27T23:04:33Z
You are reviewer_m6_2. Your task is to perform the final review of Architecture, Invariants, and Production Readiness.
Read your dispatch file at `d:\cinema-booking-system-v1\.agents\teamwork\reviewer_m6_2\DISPATCH.md` and all mandatory inputs.
Verify Supabase backend, Provider state management, design tokens, integer VND currency, clean code (0 print, 0 TODO).
Run `flutter analyze` (0 issues) and full test suite `flutter test` (1288 tests).
Write your report and verdict (APPROVE or REQUEST_CHANGES) in `d:\cinema-booking-system-v1\.agents\teamwork\reviewer_m6_2\handoff.md`.
Send a completion message with your verdict to the Project Orchestrator.
