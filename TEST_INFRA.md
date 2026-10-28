# E2E Test Infra: Cinema Booking & Operation Management

## Test Philosophy
- **Opaque-box, requirement-driven**: Test suite derived strictly from `ORIGINAL_REQUEST.md` and user-facing specifications in `docs/`, independent of internal implementation details.
- **Methodology**: Systematic 4-tier approach (Category-Partition, Boundary Value Analysis, Pairwise Combinatorial Testing, Real-World Workload Testing).

## Feature Inventory & Test Mapping
| # | Feature | Source | Tier 1 (>=5) | Tier 2 (>=5) | Tier 3 (Pairwise) | Tier 4 (Scenario) |
|---|---------|--------|:------------:|:------------:|:-----------------:|:-----------------:|
| 1 | Email/Password Login | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S01-Flow |
| 2 | Customer Registration | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S02-Flow |
| 3 | Movie Discovery Carousel & Grid | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S03-Flow |
| 4 | Movie Detail & Trailer | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S04-Flow |
| 5 | Showtime Date Filter & Grouping | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S05-Flow |
| 6 | Interactive Seat Map Realtime | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S06-Flow |
| 7 | `hold_seats` Transaction | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S06-Hold |
| 8 | Seat Hold Countdown Timer | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S07-Timer |
| 9 | Concession / Food Selection | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S07-Food |
| 10 | SePay VietQR Checkout | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S08-Checkout |
| 11 | `confirm_payment` RPC | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S08-Confirm |
| 12 | Electronic QR Ticket Generation | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S09-Ticket |
| 13 | Tabbed Ticket Management | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S10-Management |
| 14 | `cancel_booking` RPC (2h Cutoff) | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S10-Cancel |
| 15 | QR Check-in Camera Scanner | ORIGINAL_REQUEST R2 | 5 | 5 | ✓ | S18-Scan |
| 16 | `check_in` 8 Validation Checks | ORIGINAL_REQUEST R2 | 5 | 5 | ✓ | S18-Checks |
| 17 | Age Rating ID Verification Check | ORIGINAL_REQUEST R2 | 5 | 5 | ✓ | S18-Age |
| 18 | Food Queue Fulfillment Board | ORIGINAL_REQUEST R2 | 5 | 5 | ✓ | S19-Queue |
| 19 | `deliver_food` RPC | ORIGINAL_REQUEST R2 | 5 | 5 | ✓ | S19-Deliver |
| 20 | Counter Box Office Ticket Sales | ORIGINAL_REQUEST R2 | 5 | 5 | ✓ | S20-Counter |
| 21 | Cash Change Calculator | ORIGINAL_REQUEST R2 | 5 | 5 | ✓ | S21-Change |
| 22 | Operational Dashboard Metrics | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S22-Dashboard |
| 23 | Showtime Scheduling & 15m Gap | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S14-Conflict |
| 24 | Booking & Order Inspection | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S15-Orders |
| 25 | Food Catalog Availability Toggle | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S16-FoodToggle |
| 26 | Staff Account Creation Edge Function | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S23-CreateStaff |
| 27 | User Account Locking | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S23-LockUser |
| 28 | Movies CRUD & Deletion Protection | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S13-MoviesCRUD |
| 29 | Room & Seat Grid Configuration | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S24-SeatMap |
| 30 | Dynamic Pricing Configuration | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S26-Pricing |
| 31 | Voucher Management | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S27-Voucher |
| 32 | Audit Logging | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S29-Audit |
| 33 | Cinema Locator with Google Maps | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S17-CinemaMap |
| 34 | Local Show Reminder Notifications | ORIGINAL_REQUEST R1 | 5 | 5 | ✓ | S30-Reminder |
| 35 | In-App Customer Support Chat | ORIGINAL_REQUEST R3 | 5 | 5 | ✓ | S31-Chat |

## Test Architecture
- **Runner**: `flutter test test/e2e/e2e_suite_test.dart`
- **Output format**: Standard Flutter test pass/fail output (exit code 0).
- **Directory layout**:
  ```
  test/
  ├── core/ (existing token & theme tests)
  ├── shared/ (existing widget tests)
  └── e2e/
      ├── e2e_suite_test.dart (master test suite aggregator)
      ├── tier1_feature_test.dart (Tier 1: Feature coverage >= 5 per feature)
      ├── tier2_boundary_test.dart (Tier 2: Boundary & corner cases >= 5 per feature)
      ├── tier3_pairwise_test.dart (Tier 3: Cross-feature combinations)
      └── tier4_application_scenarios_test.dart (Tier 4: End-to-end user journeys)
  ```

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Expected Outcome |
|---|----------|--------------------|------------------|
| 1 | Full Customer Online Booking Journey | F1, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12 | Customer discovers movie, selects seats, holds via RPC, adds popcorn, completes SePay checkout, receives QR ticket S09 |
| 2 | Ticket Cancellation & 2-Hour Cutoff | F1, F13, F14, F32 | Customer cancels ticket with >2h showtime, seats released to inventory, refund notification dispatched, audit log created |
| 3 | Staff QR Check-in with Age Verification | F1, F15, F16, F17, F32 | Staff logs into S18, scans QR for T18 movie, checks ID verification box, confirms check-in, status changes to `used` |
| 4 | Staff Food Delivery Queue | F1, F18, F19, F32 | Staff opens S19, views pending orders sorted by showtime, marks order delivered via RPC `deliver_food`, customer gets notification |
| 5 | Staff Counter Sales with Cash Change | F1, F20, F21, F7, F11, F12 | Staff sells tickets at counter, calculates cash change, holds seats for 3 min, issues instant ticket |
| 6 | Manager Operational Dashboard Inspection | F1, F22, F24 | Manager logs into S22, verifies today's revenue, tickets sold, occupancy rate filtered by `cn_q1`, inspects bookings |
| 7 | Showtime Conflict Prevention (15-min gap) | F1, F23, F32 | Manager attempts to schedule overlapping showtime in Room 1 within 15 mins; rejected with explicit conflict error |
| 8 | Multi-Tenant Cinema Isolation | F1, F16, F22, F24 | Staff from Cinema A cannot check in ticket from Cinema B (`WRONG_CINEMA`); Manager from Cinema A sees only Cinema A metrics |
| 9 | 8-Seat Limit & Seat Conflict Race Condition | F6, F7 | 9th seat selection blocked; concurrent hold on identical seat fails with `SeatTakenException` |
| 10 | Customer Map Discovery & Notification Center | F33, F34, F30 | User finds nearby cinemas sorted by distance on map, views notifications, opens ticket |

## Coverage Thresholds
- Tier 1: >= 175 test cases (covering all 35 features)
- Tier 2: >= 175 test cases (boundary, error conditions, limits)
- Tier 3: >= 35 test cases (major pairwise feature combinations)
- Tier 4: >= 10 realistic end-to-end scenarios
- Total: >= 395 tests. All must pass 100% with exit code 0.
