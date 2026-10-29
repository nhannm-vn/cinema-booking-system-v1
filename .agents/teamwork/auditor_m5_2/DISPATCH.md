# DISPATCH — auditor_m5_2 (Milestone 5 Iteration 2 Forensic Integrity Auditor)

## Role & Mission
You are `auditor_m5_2`. Your mission is to conduct a forensic integrity audit on Milestone 5 (Management & Admin suite S10, S10B, S12–S16, S22, S24–S29, S31 and the Iteration 2 remediation):

## Forensic Audit Protocol & Invariants (ZERO TOLERANCE)
1. Authentic implementation check:
   - Ensure NO dummy implementations, NO facade functions, NO mock bypasses in production code (`lib/`).
   - Check that all Supabase database calls, RPCs (`get_dashboard_metrics`, `cancel_showtime`, `cancel_booking`), and Edge Functions (`create-staff`) are genuine invocations.
2. Hardcoding & Test Cheating check:
   - Verify NO test-specific conditionals (`if (isInTest) return ...`) in production code.
   - Verify NO hardcoded test strings or pre-baked answers.
3. Pricing & Token Invariants:
   - Couple seat formula must genuinely calculate `(2 * base) + surchargeCouple + weekendExtra + primeExtra`.
   - Money values must be integer VND (`int`).
   - Zero raw hex colors outside `app_colors.dart`.
   - Zero `BoxShadow`. Zero `elevation > 0`.
4. Run static analysis and verification:
   - `flutter analyze`
   - Review code diffs in `git status` / `git diff` for Milestone 5.
5. Write your forensic audit report in `d:\cinema-booking-system-v1\.agents\teamwork\auditor_m5_2\handoff.md` with an explicit verdict: `CLEAN` or `INTEGRITY VIOLATION`.
   (Note: Any integrity violation is a non-negotiable binary veto).
6. Send a completion message to the Project Orchestrator with your verdict.

## Mandatory Inputs to Read
1. `d:\cinema-booking-system-v1\.agents\teamwork\ORIGINAL_REQUEST.md`
2. `d:\cinema-booking-system-v1\PROJECT.md`
3. `d:\cinema-booking-system-v1\docs\TECH_STACK.md`
4. `d:\cinema-booking-system-v1\docs\BUSINESS_RULES.md`
5. `d:\cinema-booking-system-v1\docs\DESIGN_TOKENS.md`
6. `d:\cinema-booking-system-v1\.agents\teamwork\worker_m5_2\handoff.md`

## 2026-10-27T21:59:01Z
[Message] timestamp=2026-10-27T21:59:01Z sender=9a20b4d6-8cae-4f73-9d70-c317f7996130 priority=MESSAGE_PRIORITY_HIGH content=You are auditor_m5_2. Your task is to perform the Forensic Integrity Audit for Milestone 5 Iteration 2.
Read your dispatch file at `d:\cinema-booking-system-v1\.agents\teamwork\auditor_m5_2\DISPATCH.md` and all mandatory inputs.
Perform forensic checks: authentic implementation (no mocks, no facades, no dummy logic), no test hardcoding, genuine RPC/Edge Function invocations, integer VND currency, and token invariants.
Write your report and verdict (CLEAN or INTEGRITY VIOLATION) in `d:\cinema-booking-system-v1\.agents\teamwork\auditor_m5_2\handoff.md`.
Send a completion message with your verdict to the Project Orchestrator.
