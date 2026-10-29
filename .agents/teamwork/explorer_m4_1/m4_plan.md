# MILESTONE 4 IMPLEMENTATION PLAN: STAFF OPERATIONS (S18–S21, S23)

## 1. Executive Summary & Architecture Overview

Milestone 4 delivers the complete operational suite for theater staff and managers in the Cinema Booking & Operation Management system:
- **S18: Ticket Check-in (`/staff/checkin`)** — QR camera scanner with Rosso Corsa viewfinder, desktop manual input fallback, 8-step validation cascade via RPC `check_in`, age verification gating for `T16`/`T18`, and `ResultSheet`.
- **S19: Food Delivery Board (`/staff/food`)** — Tabbed order queue (`CHỜ GIAO` / `ĐÃ GIAO`), sorted ascending by showtime, instant delivery fulfillment via RPC `deliver_food`, real-time booking stream sync.
- **S20: Counter Showtimes (`/staff/counter-showtimes`)** — Box office fast showtime picker for today, room filter, format/price/available seat indicators, fast interactive seat selection with 3-minute seat hold.
- **S21: Counter Payment & Change Calculator (`/staff/counter-payment`)** — Order summary breakdown, integer VND cash calculator with quick cash buttons (+50k, +100k, +200k, +500k, EXACT), live change calculation, card/POS toggle, and RPC `sell_counter` execution.
- **S23: Staff Account Management (`/management/employees`)** — Staff listing scoped to cinema, lock/unlock account toggle, create staff modal invoking Edge Function `create-staff` (service role).

### Strict Architectural Invariants
1. **Multi-tenant isolation:** Every single staff and manager query and RPC call MUST filter by `cinema_id = currentCinemaId`.
2. **100% Token compliance:** Zero hardcoded colors (`Color(0x...)`), zero raw text styles or sizes, zero raw padding values. All styles derive from `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`.
3. **No box shadows or elevation:** `elevation: 0`, flat dark canvas `#181818`, primary Rosso Corsa `#DA291C`, `borderRadius: 0` (sharp edges default).
4. **Button & Nav casing:** All button labels, navigation labels, and headers MUST be `.toUpperCase()`. Maximum 1 primary button per screen.
5. **Money strictly in integer VND (`int`):** No `double` for currency amounts. Formatted via `CurrencyFormatter.formatVnd(...)`.
6. **Triple UI State Rigor:** Every data screen must handle Loading (`SkeletonBox`), Empty (`EmptyState`), and Error (`ErrorState` with retry button).
7. **Clean State Management:** Exclusively `provider` (`ChangeNotifier`, `ProxyProvider`).

---

## 2. Multi-Tenant Isolation & Backend Integration

### 2.1 Database & Security Model (RLS + RPC)
- **RLS Policy on `bookings`:** Staff and managers can only read bookings where `cinema_id = public.current_cinema()`. Cross-cinema validation for S18 check-in is securely performed via Postgres RPC `public.check_in` (`security definer`), returning `WRONG_CINEMA` with the foreign cinema name without leaking other bookings.
- **RPC `check_in(p_booking_code)`:**
  1. Checks caller role in (`staff`, `manager`, `admin`).
  2. Selects booking `FOR UPDATE`.
  3. Verifies 8 validation checks:
     - Check 1: `NOT_FOUND` ("Mã vé không tồn tại trong hệ thống")
     - Check 2: `CANCELLED` ("Vé đã bị hủy và hoàn tiền")
     - Check 3: `ALREADY_USED` ("Vé đã sử dụng lúc [giờ:phút]")
     - Check 4: `WRONG_CINEMA` ("Vé thuộc rạp khác ([Tên rạp])")
     - Check 5: `TOO_EARLY` (Now < `showtime_start` - 30m: "Chưa đến giờ vào rạp (Chỉ vào trước tối đa 30 phút)")
     - Check 6: `EXPIRED_SHOWTIME` (Now > `showtime_start` + 15m: "Vé đã quá hạn sử dụng (Quá 15 phút sau giờ chiếu)")
     - Check 7: `status == 'paid'` ("Vé chưa hoàn tất thanh toán")
     - Check 8: `age_rating` verification in `ResultSheet` for `T16`/`T18`.
  4. On valid ticket: updates `status = 'used'`, `checked_in_by = auth.uid()`, `checked_in_at = now()`, inserts into `audit_logs` (`action = 'checkIn'`).
- **RPC `deliver_food(p_booking_code)`:**
  1. Checks caller authorization and cinema match.
  2. Requires `food_status == 'pending'`.
  3. Updates `food_status = 'delivered'`, `food_delivered_by = auth.uid()`, `food_delivered_at = now()`.
  4. Inserts notification (`type = 'foodDelivered'`) to customer.
- **RPC `sell_counter(p_showtime_id, p_booking_code, p_seat_ids, p_payment_method, p_booking)`:**
  1. Row locks showtime `FOR UPDATE`.
  2. Checks for `sold` seat conflicts (`SEAT_TAKEN:<seat_id>`).
  3. Inserts seats as `sold`.
  4. Increments `showtimes.sold_seats`.
  5. Inserts booking with `channel = 'counter'`, `status = 'paid'`, `sold_by = auth.uid()`, `user_id = null`.
- **Edge Function `create-staff`:**
  1. Invoked by Manager or Admin with JWT.
  2. Uses Supabase Service Role client to create Auth user without logging out caller.
  3. Updates `profiles` with `role = 'staff'`, `cinema_id = assignedCinema`, `is_locked = false`.

---

## 3. Screen-by-Screen Implementation Specifications

### 3.1 S18: Ticket Check-in Screen (`/staff/checkin`)
- **Route:** `AppRoutes.staffCheckin` (`/staff/checkin`)
- **Target File:** `lib/features/staff_checkin/presentation/screens/ticket_checkin_screen.dart`
- **Controller:** `lib/features/staff_checkin/presentation/controllers/checkin_provider.dart`
- **Repository:** `lib/features/staff_checkin/data/checkin_repository.dart`
- **Shared Widgets Used:** `QrScannerView`, `ResultSheet`, `AppButton`, `AppTextField`, `NotificationBadge`, `StaffBottomNav`
- **Component Design & Behavior:**
  - **AppBar:**
    - Background: `AppColors.canvas`, `elevation: 0`.
    - Title: Staff cinema name in uppercase (`AppTextStyles.titleSm`), e.g., "CINEMA QUẬN 1".
    - Actions: `NotificationBadge` for notification center S30.
  - **Body / Viewfinder Area:**
    - Uses `QrScannerView`: Rosso Corsa 2px border frame, darkened background cutout.
    - Automatic normalization: scanned barcode string is trimmed and converted to uppercase.
    - Fallback on Desktop / Camera Permission Denied: Displays clean placeholder with "CAMERA KHÔNG KHẢ DỤNG TRÊN THIẾT BỊ NÀY" and direct "NHẬP MÃ TAY" input field.
  - **Manual Input Modal / Dialog:**
    - "NHẬP MÃ TAY" button triggers modal with 8-character uppercase text field (`AppTextField`), character length counter, and "KIỂM TRA" primary button.
  - **Validation & `ResultSheet` Flow:**
    - On scan / input: calls `CheckinProvider.checkIn(code)`.
    - Shows modal bottom sheet using `ResultSheet`:
      - **Valid ticket:** Displays green check icon (`AppColors.success`), `VÉ HỢP LỆ`, movie title, room name, showtime, seats list, foods summary (if any).
      - **T16 / T18 Age Check Gating:** If `ageRating == 'T16'` or `'T18'`, displays a warning bordered box with checkbox: "Khán giả phim [T16/T18]. Đã kiểm tra giấy tờ tùy thân hợp lệ." The primary button "XÁC NHẬN CHO VÀO" remains disabled until the box is checked.
      - **Invalid ticket:** Displays red cross icon (`AppColors.warning`), `VÉ KHÔNG HỢP LỆ`, exact error message from RPC/evaluator, and "QUÉT TIẾP" outline button.
  - **Bottom Navigation:** `StaffBottomNav(currentIndex: 0)`.

### 3.2 S19: Food Delivery Board (`/staff/food`)
- **Route:** `AppRoutes.staffFood` (`/staff/food`)
- **Target File:** `lib/features/staff_food/presentation/screens/food_board_screen.dart`
- **Controller:** `lib/features/staff_food/presentation/controllers/staff_food_provider.dart`
- **Repository:** `lib/features/staff_food/data/staff_food_repository.dart`
- **Shared Widgets Used:** `StatusBadge`, `AppButton`, `AppTextField`, `SkeletonBox`, `EmptyState`, `ErrorState`, `StaffBottomNav`
- **Component Design & Behavior:**
  - **AppBar:**
    - Title: "QUẦY ĐỒ ĂN" (`AppTextStyles.titleSm`), subtitle cinema name.
    - Actions: `NotificationBadge`.
  - **Search & Quick Scan Bar:**
    - Search field for 8-character booking code with QR scan button shortcut to quickly find a customer's food order.
  - **Tabs (CHỜ GIAO · ĐÃ GIAO):**
    - Custom styled tab bar with Rosso Corsa indicator, uppercase tab labels.
    - Tab 0: `CHỜ GIAO` (`food_status == 'pending'`). Scoped to `currentCinemaId`. Sorted ascending by `showtime_start` (urgent orders first). Excludes cancelled bookings.
    - Tab 1: `ĐÃ GIAO` (`food_status == 'delivered'`). Scoped to `currentCinemaId`. Shows last 50 delivered orders.
  - **Order Card Component:**
    - Container with `AppColors.canvasElevated`, 1px `AppColors.hairline` border, 0px radius.
    - Header: Booking code in bold (`AppTextStyles.titleSm`), showtime and room name (`AppTextStyles.bodySm`), movie title.
    - Items List: Food item name and quantity formatted (e.g. `2x Bắp Ngọt Lớn`, `1x Coca-Cola Vừa`).
    - Action in `CHỜ GIAO`: Single Rosso Corsa primary button `ĐÃ GIAO`. Tapping opens a quick confirmation dialog and executes `StaffFoodProvider.deliverFood(code)`.
    - Action in `ĐÃ GIAO`: `StatusBadge(status: 'ĐÃ GIAO', color: AppColors.success)`.
  - **Realtime Integration:**
    - Stream subscription on `bookings` table for `cinema_id = currentCinemaId` so the board updates automatically when new orders arrive.
  - **3 UI States:**
    - Loading: 4 `SkeletonBox` cards with shimmer.
    - Empty: `EmptyState` ("Chưa có đơn đồ ăn cần giao" / "Chưa có đơn đã giao").
    - Error: `ErrorState` with "THỬ LẠI" retry button.
  - **Bottom Navigation:** `StaffBottomNav(currentIndex: 1)`.

### 3.3 S20: Counter Showtimes Screen (`/staff/counter-showtimes`)
- **Route:** `AppRoutes.staffCounterShowtimes` (`/staff/counter-showtimes`)
- **Target File:** `lib/features/staff_counter/presentation/screens/counter_showtimes_screen.dart`
- **Controller:** `lib/features/staff_counter/presentation/controllers/staff_counter_provider.dart`
- **Repository:** `lib/features/staff_counter/data/repositories/staff_counter_repository.dart`
- **Shared Widgets Used:** `AppBadge`, `AppButton`, `SkeletonBox`, `EmptyState`, `ErrorState`, `StaffBottomNav`
- **Component Design & Behavior:**
  - **Header & Filter Bar:**
    - Title: "BÁN VÉ TẠI QUẦY" (`AppTextStyles.titleSm`).
    - Date indicator: Today's date (e.g. "HÔM NAY · 28/10/2026").
    - Room filter chips: horizontal scrollable list of rooms (`TẤT CẢ`, `Phòng 1`, `Phòng 2`, ...).
  - **Showtimes Listing:**
    - Grouped by movie with poster thumbnail, movie title, age rating badge (`AppBadge`).
    - Showtime cards displaying:
      - Format: 2D, 3D, IMAX.
      - Start time – End time.
      - Available seats indicator: `còn X ghế` (`total_seats - sold_seats`).
      - Base ticket price (e.g. `80.000 đ`).
      - Disabled/muted style if sold out or showtime has passed.
  - **Fast Box Office Seat Selection Flow:**
    - Tapping a showtime selects it in `StaffCounterProvider`.
    - Opens Counter Seat & Food BottomSheet / Modal:
      - Visual seat map or seat matrix for the room.
      - Max 8 seats constraint enforced.
      - Concession quick add: quick quantity stepper for popcorn & drink combos.
      - Total amount preview in VND.
      - Primary button: "TIẾP TỤC BÁN VÉ" -> calls `StaffCounterProvider.holdSeatsForCounter()`.
      - Holds seats for exactly 3 minutes via RPC `hold_seats(p_hold_minutes: 3)`.
      - Transitions directly to S21 (`AppRoutes.staffCounterPayment`).
  - **3 UI States:**
    - Loading: `SkeletonBox` list.
    - Empty: `EmptyState` ("Hôm nay không có suất chiếu nào tại rạp").
    - Error: `ErrorState` with "THỬ LẠI" retry button.
  - **Bottom Navigation:** `StaffBottomNav(currentIndex: 2)`.

### 3.4 S21: Counter Payment & Change Calculator Screen (`/staff/counter-payment`)
- **Route:** `AppRoutes.staffCounterPayment` (`/staff/counter-payment`)
- **Target File:** `lib/features/staff_counter/presentation/screens/counter_payment_screen.dart`
- **Controller:** `lib/features/staff_counter/presentation/controllers/staff_counter_provider.dart`
- **Repository:** `lib/features/staff_counter/data/repositories/staff_counter_repository.dart`
- **Shared Widgets Used:** `AppButton`, `AppTextField`, `HoldTimer` (3-minute countdown), `TicketCard`
- **Component Design & Behavior:**
  - **AppBar:**
    - Title: "THANH TOÁN TẠI QUẦY".
    - Hold Timer Widget: 3-minute countdown displaying remaining time. Transitions to red warning when under 60 seconds. On expiry: displays dialog "Hết thời gian giữ ghế tại quầy" and returns to S20.
  - **Order Breakdown Card:**
    - Movie title, room name, showtime, format.
    - Selected seats list (e.g. `A5, A6`).
    - Selected food items & quantities.
    - Total order amount: prominent VND display (`CurrencyFormatter.formatVnd(total)`).
  - **Payment Method Toggle:**
    - Two choices: `TIỀN MẶT` (Cash) and `THẺ / POS` (Card / Bank Transfer).
  - **Cash Calculator Mode (`TIỀN MẶT`):**
    - Input field: "KHÁCH ĐƯA" (`AppTextField`, number keyboard, integer VND only).
    - Quick Cash Buttons row/grid:
      - `ĐỦ TIỀN` (sets received = total).
      - `+50K` (`received += 50000`).
      - `+100K` (`received += 100000`).
      - `+200K` (`received += 200000`).
      - `+500K` (`received += 500000`).
      - Fixed presets: `100.000 đ`, `200.000 đ`, `500.000 đ`.
    - Live Change Display:
      - If `received < total`: warning message "Khách đưa thiếu [X] đ" (`AppColors.warning`), confirmation button disabled.
      - If `received >= total`: displays "TIỀN THỪA" in prominent `AppTextStyles.displayLg` with `AppColors.success` (e.g., `40.000 đ`).
  - **Card / POS Mode (`THẺ / POS`):**
    - Note to swipe card or scan POS QR. Checkbox: "Đã xác nhận nhận tiền qua POS / Chuyển khoản".
  - **Execution & Confirmation:**
    - Single primary button: "XÁC NHẬN BÁN VÉ" (`.toUpperCase()`).
    - Executes `StaffCounterProvider.completeSale(paymentMethod)` via RPC `sell_counter`.
    - On success: presents Success Receipt Dialog with generated 8-character booking code, QR code, and buttons "IN VÉ" (or share) and "BÁN ĐƠN MỚI" (resets provider state and returns to S20).

### 3.5 S23: Staff Account Management Screen (`/management/employees`)
- **Route:** `AppRoutes.manageEmployees` (`/management/employees`)
- **Target File:** `lib/features/management/presentation/screens/staff_accounts_screen.dart`
- **Controller:** `lib/features/management/presentation/controllers/management_provider.dart`
- **Repository:** `lib/features/management/data/repositories/management_repository.dart`
- **Shared Widgets Used:** `StatusBadge`, `AppButton`, `AppTextField`, `SkeletonBox`, `EmptyState`, `ErrorState`, `NotificationBadge`
- **Component Design & Behavior:**
  - **AppBar:**
    - Title: "QUẢN LÝ NHÂN VIÊN" (`AppTextStyles.titleSm`), subtitle cinema name.
    - Actions: `NotificationBadge`.
  - **Staff List:**
    - Scoped strictly to `cinema_id = currentCinemaId` (or all cinemas if caller is Admin).
    - Each employee card:
      - Full name in bold, email, phone number, role badge (`STAFF`).
      - Status badge: `StatusBadge(status: 'ĐANG HOẠT ĐỘNG', color: AppColors.success)` or `StatusBadge(status: 'ĐÃ KHÓA', color: AppColors.warning)`.
      - Action button: `KHÓA` or `MỞ KHÓA`.
      - Tapping toggle shows confirmation dialog: "Khóa tài khoản [Tên]?" / "Mở khóa tài khoản [Tên]?".
      - Calls `ManagementProvider.toggleUserLock(userId, isLocked, cinemaId)`.
  - **Add Staff Modal / Dialog:**
    - Triggered by "THÊM NHÂN VIÊN" button or floating action button.
    - Form fields:
      - Họ và tên (`AppTextField`, text)
      - Email (`AppTextField`, emailAddress keyboard, regex validated)
      - Số điện thoại (`AppTextField`, phone keyboard, 10 digits)
      - Mật khẩu tạm (`AppTextField`, obscure text, min 6 characters)
      - Cinema: for Manager, automatically fixed to manager's `cinemaId`; for Admin, selectable cinema dropdown.
    - Submits via `ManagementProvider.createStaffAccount(...)` which calls Edge Function `create-staff` (service role).
    - Handles error responses (e.g. email duplicate: "Email đã được sử dụng").
    - On success: refreshes staff list, closes modal, shows snackbar "Tạo nhân viên thành công".
  - **3 UI States:**
    - Loading: `SkeletonBox` list.
    - Empty: `EmptyState` ("Rạp chưa có nhân viên" + "THÊM NHÂN VIÊN").
    - Error: `ErrorState` with "THỬ LẠI" retry button.

---

## 4. Shared Components Specification

### 4.1 Staff Bottom Navigation Bar (`StaffBottomNav`)
- **Target File:** `lib/shared/widgets/staff_bottom_nav.dart`
- **Height:** 64px, Dark background `#181818`, 1px top border `AppColors.hairline`.
- **Tabs (4):**
  - Index 0: `SOÁT VÉ` (`Icons.qr_code_scanner`) -> `AppRoutes.staffCheckin` (S18)
  - Index 1: `ĐỒ ĂN` (`Icons.fastfood_outlined`) -> `AppRoutes.staffFood` (S19)
  - Index 2: `BÁN VÉ` (`Icons.point_of_sale`) -> `AppRoutes.staffCounterShowtimes` (S20)
  - Index 3: `TÀI KHOẢN` (`Icons.person_outline`) -> `AppRoutes.profile` (S11)
- **Active state:** `AppColors.primary` (Rosso Corsa `#DA291C`), `FontWeight.w700`.
- **Inactive state:** `AppColors.muted` (`#707070`), `FontWeight.w500`.
- **Navigation:** `Navigator.pushReplacementNamed` to avoid stacking staff tabs.

---

## 5. State Management & Controllers

### 5.1 `CheckinProvider`
- **File:** `lib/features/staff_checkin/presentation/controllers/checkin_provider.dart`
- **State Properties:**
  - `bool isLoading`
  - `String? errorMessage`
  - `CheckinResult? lastResult`
  - `bool isIdVerified` (for T16/T18 age verification)
  - `String? currentScannedCode`
- **Methods:**
  - `Future<CheckinResult> checkIn(String code)`: normalizes code, calls `CheckinRepository.checkIn(code)`.
  - `void setIdVerified(bool verified)`: updates `isIdVerified`.
  - `void resetScan()`: clears current code and result to re-arm scanner.

### 5.2 `StaffFoodProvider`
- **File:** `lib/features/staff_food/presentation/controllers/staff_food_provider.dart`
- **State Properties:**
  - `bool isLoading`
  - `String? errorMessage`
  - `int currentTabIndex` (0 = `CHỜ GIAO`, 1 = `ĐÃ GIAO`)
  - `String searchQuery`
  - `List<BookingModel> pendingOrders`
  - `List<BookingModel> deliveredOrders`
  - `StreamSubscription? realtimeSubscription`
- **Methods:**
  - `Future<void> loadOrders(String cinemaId)`: fetches pending and delivered orders.
  - `void setTab(int index)`: switches tab.
  - `void setSearchQuery(String query)`: filters orders by booking code.
  - `Future<bool> deliverFood(String bookingCode, String cinemaId)`: calls `StaffFoodRepository.deliverFood(bookingCode)`.
  - `void subscribeRealtime(String cinemaId)`: listens to changes on `bookings` for `cinema_id`.

### 5.3 `StaffCounterProvider` (Existing — Verified)
- **File:** `lib/features/staff_counter/presentation/controllers/staff_counter_provider.dart`
- **State Properties:**
  - `List<ShowtimeModel> showtimes`, `ShowtimeModel? selectedShowtime`
  - `List<String> selectedSeatIds`, `List<Map<String, dynamic>> selectedFoods`
  - `int receivedCash`, `String? bookingCode`, `DateTime? holdUntil`
- **Methods:**
  - `loadShowtimes(cinemaId, date)`, `selectShowtime(showtime)`
  - `toggleSeat(seatId)` (enforces max 8 seats)
  - `setFoodQuantity(foodId, name, price, qty)`
  - `calculateTotal()`, `calculateChange(received)`
  - `holdSeatsForCounter()` (3-minute hold duration)
  - `completeSale(paymentMethod)` (calls RPC `sell_counter`)
  - `reset()`

### 5.4 `ManagementProvider` (Existing — Verified)
- **File:** `lib/features/management/presentation/controllers/management_provider.dart`
- **Methods:**
  - `loadEmployees(cinemaId)`
  - `createStaffAccount(...)` (invokes Edge Function `create-staff`)
  - `toggleUserLock(userId, isLocked, cinemaId)`

---

## 6. Route Configuration & App Wiring

### 6.1 `AppRouter` (`lib/core/routes/app_router.dart`)
Replace placeholders with screen builders:
- `AppRoutes.staffCheckin` -> `TicketCheckinScreen()`
- `AppRoutes.staffFood` -> `FoodBoardScreen()`
- `AppRoutes.staffCounterShowtimes` -> `CounterShowtimesScreen()`
- `AppRoutes.staffCounterPayment` -> `CounterPaymentScreen()`
- `AppRoutes.manageEmployees` -> `StaffAccountsScreen()`

### 6.2 `RouteGuards` (`lib/core/routes/route_guards.dart`)
- `UserRole.staff` routes directly to `AppRoutes.staffCheckin`.
- Locked accounts redirect to `AppRoutes.login`.

### 6.3 App Providers Registration (`lib/main.dart`)
Add `CheckinProvider` and `StaffFoodProvider` into `MultiProvider`:
```dart
ChangeNotifierProvider(create: (_) => CheckinProvider()),
ChangeNotifierProvider(create: (_) => StaffFoodProvider()),
```

---

## 7. Step-by-Step Implementation Sequence

1. **Step 1: Shared Widgets**
   - Create `lib/shared/widgets/staff_bottom_nav.dart` with 4 staff tabs.
2. **Step 2: S18 Ticket Check-in**
   - Create `lib/features/staff_checkin/presentation/controllers/checkin_provider.dart`.
   - Create `lib/features/staff_checkin/presentation/screens/ticket_checkin_screen.dart`.
3. **Step 3: S19 Food Delivery Board**
   - Create `lib/features/staff_food/presentation/controllers/staff_food_provider.dart`.
   - Create `lib/features/staff_food/presentation/screens/food_board_screen.dart`.
4. **Step 4: S20 Counter Showtimes**
   - Create `lib/features/staff_counter/presentation/screens/counter_showtimes_screen.dart` with room filtering and fast seat selection modal.
5. **Step 5: S21 Counter Payment & Change Calculator**
   - Create `lib/features/staff_counter/presentation/screens/counter_payment_screen.dart` with quick cash buttons, change calculator, and receipt modal.
6. **Step 6: S23 Staff Account Management**
   - Create `lib/features/management/presentation/screens/staff_accounts_screen.dart` with lock toggle and Edge Function `create-staff` modal.
7. **Step 7: Route Wiring & MultiProvider Registration**
   - Wire all screens into `lib/core/routes/app_router.dart`.
   - Register `CheckinProvider` and `StaffFoodProvider` in `lib/main.dart`.
8. **Step 8: Verification & Automated Tests**
   - Run `flutter analyze` ensuring 0 errors and 0 warnings.
   - Run `flutter test` verifying 100% test pass rate across all suites.
