# Handoff Report — Empirical Challenger for Milestone 2

## 1. Observation
- Target Milestone: Milestone 2 (Auth & Customer Discovery S01–S04, S17, S17B, S30).
- Authoritative Request: `ORIGINAL_REQUEST.md`, `ROLE_FLOWS.md`, `BUSINESS_RULES.md`, `TECH_STACK.md`, `DESIGN_TOKENS.md`.
- Created empirical verification test suite: `test/challenger/milestone2_empirical_verification_test.dart` (1,044 lines, 22 automated widget and unit tests).
- Static analysis execution (`flutter analyze`):
  ```
  Analyzing cinema-booking-system-v1...
  No issues found! (ran in 5.3s)
  ```
- Challenger test suite execution (`flutter test test/challenger/`):
  ```
  00:15 +55: All tests passed!
  ```
- Full test suite execution (`flutter test`):
  ```
  00:27 +932: All tests passed!
  ```
- Specific empirical behaviors observed:
  1. **Authentication Boundary Inputs**:
     - S01 Login & S02 Register reject empty, whitespace, and malformed emails (`plainaddress`, `@missingusername.com`, `username@.com`, `username@domain..com`, `username@domain.c`, `username name@domain.com`) with verbatim error `'Email không hợp lệ'`.
     - Passwords with length 5 chars (`12345`) are rejected with `'Mật khẩu phải từ 6 ký tự trở lên'`; passwords with length >= 6 chars pass validation.
     - S02 Register rejects 9-digit phones (`090123456`), 11-digit phones (`09012345678`), non-0 leading phones (`1901234567`), and alphanumeric/symbolic inputs (`090123456a`) with `'Số điện thoại phải gồm 10 chữ số bắt đầu bằng số 0'`. Exactly 10 digits starting with 0 (`0901234567`) pass validation.
     - S02 Register rejects mismatched confirm passwords (`123456` vs `123457`) with `'Mật khẩu xác nhận không khớp'`.
  2. **Locked Account Eviction & Warning Banner**:
     - Attempting login with an account having `is_locked == true` triggers immediate invocation of `auth.signOut()`, aborts routing, remains on `LoginScreen`, and displays the warning banner:
       `'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản lý.'`.
  3. **Role Redirection Matrix**:
     - Customer routes to `AppRoutes.home` (`/home`).
     - Staff routes to `AppRoutes.staffCheckin` (`/staff/checkin`).
     - Manager routes to `AppRoutes.dashboard` (`/management/dashboard`).
     - Admin routes to `AppRoutes.managementHome` (`/management`).
     - Intercepted guest with deep-link `redirectRoute` (`/my-tickets`) is forwarded to `/my-tickets` post-login.
  4. **S03 Search Engine Stress Testing**:
     - Querying regex meta-characters (`?.*+[]`, `([a-z]+`, `[a-z`, `\\`, `^.*$`, `+++`, `????`, `{1,2`) does NOT throw `FormatException` or uncaught crash because `MovieProvider.searchResults` safely uses case-folded substring containment (`m.title.toLowerCase().contains(q)`).
     - Querying Vietnamese diacritics (`đất`, `ĐẤT`, `Phương Nam`, `kẻ ăn hồn`, `LẬT MẶT`, `điều ước`, `mai`) reliably matches Vietnamese movie titles across uppercase and lowercase variants.
     - Empty query strings and whitespace strings (`""`, `"   "`, `"\t"`, `"\n"`) are safely treated as non-search mode (`searchQuery.trim().isEmpty`), keeping the discovery view active with Hero Carousel and Now Showing sections.
     - Tapping the clear search button (`Icons.clear`) properly resets the query and restores discovery view.
  5. **CustomerBottomNav Guest Interception**:
     - When unauthenticated (`currentUser == null`), tapping `'VÉ CỦA TÔI'` intercepts and redirects to `/login` with arguments `{'redirectRoute': '/my-tickets'}`.
     - When unauthenticated, tapping `'TÀI KHOẢN'` intercepts and redirects to `/login` with arguments `{'redirectRoute': '/profile'}`.
     - When unauthenticated, tapping `'PHIM'` or `'RẠP'` allows direct navigation without interception.
     - When authenticated, tapping `'VÉ CỦA TÔI'` or `'TÀI KHOẢN'` navigates directly to `/my-tickets` or `/profile` respectively.
     - Tapping the currently active tab is an idempotent no-op.

## 2. Logic Chain
1. *Observation 1 (Validation)*: Verified through tests 1.1, 1.2, 1.3, 1.4 in `test/challenger/milestone2_empirical_verification_test.dart` that inputs violating domain boundary rules fail immediately at the form validation layer with clear, localized Vietnamese error strings before contacting backend services.
2. *Observation 2 (Security)*: Verified through test 1.5 that locked users (`is_locked == true`) cannot obtain an active session or bypass the login screen; `auth.signOut()` is executed immediately, revoking any authenticated state in memory.
3. *Observation 3 (Search Stability)*: Verified through tests 2.1, 2.2, 2.3 that client-side search filtering handles hostile and complex inputs (regex meta-characters, Unicode accented characters, and empty whitespace strings) without exceptions or UI stalls.
4. *Observation 4 (Guest Interception)*: Verified through tests 3.1–3.5 that guest interception cleanly redirects unauthenticated users to `/login` with proper deep-link arguments while preserving guest access to public discovery screens (`/home` and `/cinemas`).
5. *Observation 5 (Route Guards)*: Verified through tests 4.1–4.2 that `RouteGuards.requiresAuth` covers all 24 protected routes and `RouteGuards.getInitialRoute` segregates roles and locked states accurately.

## 3. Caveats
- Widget testing with `CachedNetworkImage` requires avoiding real network URL requests; hence mock movie dataset utilizes `posterUrl: null` in widget tests to prevent pending async HTTP timer timeouts under `TestWidgetsFlutterBinding`.
- Map and location services in S17 use Hanoi center coordinates as fallback when device permissions are not granted.

## 4. Conclusion
**VERDICT: APPROVE**

Milestone 2 (Auth & Customer Discovery S01–S04, S17, S17B, S30) has passed all empirical boundary tests, security stress tests, search filter resilience tests, and guest interception challenges. Static analysis reports 0 issues, and 100% of the 932 tests in the project test suite pass cleanly.

## 5. Verification Method
1. Run static analysis:
   ```bash
   flutter analyze
   ```
   *Expected: "No issues found!"*
2. Run empirical challenge test suite:
   ```bash
   flutter test test/challenger/milestone2_empirical_verification_test.dart
   ```
   *Expected: "All tests passed!" (22 tests)*
3. Run entire project test suite:
   ```bash
   flutter test
   ```
   *Expected: "All tests passed!" (932 tests)*
