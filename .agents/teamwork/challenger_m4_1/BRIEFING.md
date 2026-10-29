# BRIEFING — 2026-10-28T03:13:00Z

## Mission
Empirically stress-test Milestone 4 (Staff & Manager workflows: S18 Check-in, S19 Food board, S20-S21 Counter booking & cash calculation, S23 Staff management & tenant isolation) by writing and executing tests in `test/challenger/milestone4_empirical_verification_test.dart`.

## 🔒 My Identity
- Archetype: empirical_challenger
- Roles: critic, specialist
- Working directory: d:\cinema-booking-system-v1\.agents\teamwork\challenger_m4_1
- Original parent: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Milestone: Milestone 4
- Instance: 1 of 1

## 🔒 Key Constraints
- Review-only — do NOT modify implementation code (only write verification tests and report findings)
- Must empirically verify claims with runnable tests
- Do not trust unverified claims or logs
- Test file location: `test/challenger/milestone4_empirical_verification_test.dart`
- Multi-tenant cinema scoping check (`.eq('cinema_id', currentCinemaId)`)
- Cash change calculations strictly in integer VND
- Always write "Vinh Pro" at end of responses adhering to ai-coding-standards

## Current Parent
- Conversation ID: 9a20b4d6-8cae-4f73-9d70-c317f7996130
- Updated: 2026-10-28T03:13:00Z

## Review Scope
- **Files reviewed**:
  - `lib/features/staff_checkin/` (S18 Ticket Check-in, `CheckinProvider`, `CheckinRepository`, `ResultSheet`)
  - `lib/features/staff_food/` (S19 Food Board, `StaffFoodProvider`, `StaffFoodRepository`)
  - `lib/features/staff_counter/` (S20 Counter Showtimes, S21 Counter Payment, `StaffCounterProvider`, `StaffCounterRepository`)
  - `lib/features/management/` (S23 Staff Accounts, `ManagementProvider`, `ManagementRepository`)
- **Interface contracts**: `PROJECT.md`, `docs/BUSINESS_RULES.md`, `docs/ROLE_FLOWS.md`, `docs/TECH_STACK.md`
- **Review criteria**: 8 validation rules on S18, T16/T18 gating, food delivery sorting & RPC state transitions, 3-min hold / 8 seats rule, cash change VND integer math, account lock toggle, multi-tenant isolation.

## Key Decisions Made
- Created `test/challenger/milestone4_empirical_verification_test.dart` with 17 adversarial stress tests.
- Verified all 8 check-in validation rules and T16/T18 age restriction gating in ResultSheet.
- Confirmed food orders strictly sort ascending by `showtimeStart` so urgent orders appear first.
- Confirmed counter seat selection strictly caps at 8 seats and counter hold RPC parameter is 3 minutes.
- Verified cash calculation in integer VND across exact, excess, and underpayment conditions.
- Verified staff account lock/unlock toggle and multi-tenant isolation via `.eq('cinema_id', currentCinemaId)`.
- Verified `flutter analyze` runs with 0 errors and 0 warnings.
- Verified full test suite runs with 1094/1094 passing tests.

## Artifact Index
- `test/challenger/milestone4_empirical_verification_test.dart` — 17 dedicated empirical verification tests
- `handoff.md` — 5-component Challenger Handoff Report with verdict `APPROVE`
- `progress.md` — Execution progress and verification milestones

## Attack Surface
- **Hypotheses tested**:
  1. Does S18 correctly enforce all 8 validation rules and gate T16/T18 check-ins until ID check is confirmed? -> PASS
  2. Does S19 Food Board sort pending orders chronologically by showtimeStart ascending? -> PASS
  3. Does S19 `deliver_food` correctly transition state from pending to delivered without regressions? -> PASS
  4. Does S20 counter sales strictly enforce max 8 seats and 3-minute hold duration? -> PASS
  5. Does S21 cash change calculation operate strictly on integer VND and block checkout on underpayment? -> PASS
  6. Does S23 staff account lock toggle work bidirectionally and isolate data by `cinema_id`? -> PASS
- **Vulnerabilities found**: None. All invariants, business rules, and design tokens strictly upheld.
- **Untested angles**: Hardware-specific camera drivers (mocked with desktop fallback view).

## Loaded Skills
- **Source**: `C:\Users\vinhmt\.gemini\config\skills\ai-coding-standards\SKILL.md`
- **Local copy**: `d:\cinema-booking-system-v1\.agents\teamwork\challenger_m4_1\ai-coding-standards.md`
- **Core methodology**: Minimality, empirical verification, non-speculative, reuse existing code, avoid overcomplication.
