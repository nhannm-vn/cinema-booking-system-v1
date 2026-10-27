# MILESTONE 5 — PART C IMPLEMENTATION PLAN
## CINEMAS & ROOMS, SEAT MAP DESIGNER, DYNAMIC PRICING, VOUCHERS, ADMIN & AUDIT LOGS (S24–S29)

---

## 1. Executive Summary & Scope Overview

Milestone 5 Part C encompasses the comprehensive configuration, financial modeling, promotional management, and audit inspection capabilities of the Cinema Booking & Operation Management system:
- **S24: Room Seat Map Designer (`/management/seat-map`)**: Interactive grid layout editor for cinema rooms, supporting dynamic row/column sizing, four-way cell cycling (`Standard (S)`, `VIP (V)`, `Couple (C)`, `Aisle (_)`), real-time seat tallying (Standard, VIP, Couple, Total), and safety lock preventing edits to rooms with future sold tickets.
- **S25: Cinemas & Rooms Configuration (`/management/rooms`)**: Multi-tenant theater and hall administration. Displays cinema operational metadata, format tags (`2D`, `3D`, `IMAX`), and room inventories with direct seamless navigation into S24.
- **S26: Dynamic Pricing Settings (`/management/pricing`)**: Centralized pricing engine configuring base rates per visual format, seat category surcharges, weekend surcharges, and prime-hour windows in integer VND (`int`), accompanied by an interactive live formula verification simulator.
- **S27: Voucher & Promotion Management (`/management/vouchers`)**: Campaign administration providing voucher generation (alphanumeric uppercase code, percentage vs. fixed VND discount, validity periods, usage ceilings, active state toggles) with visual lifecycle status badges (`CÒN HẠN`, `HẾT LƯỢT`, `HẾT HẠN`, `TẠM KHÓA`).
- **S28: Manager Accounts Management (`/management/managers`)**: Admin-exclusive portal for cinema branch general managers, enabling staff invitation via Supabase Edge Function `create-staff` (with `role = 'manager'`), theater branch reassignment, and immediate security lock/unlock actions.
- **S29: System Audit Logs Viewer (`/management/audit-logs`)**: Immutable compliance log browser with composite multi-criteria filtering (action type, cinema location, temporal range) and a visual before-and-after JSON diff inspector modal.

### Strict Architectural Invariants
1. **Multi-Tenant Isolation & Role Gating**:
   - Managers are strictly scoped to their assigned theater branch (`cinema_id = currentCinemaId`).
   - Admins possess system-wide operational purview across all cinema locations.
   - S24, S25, S27, S28, S29 are Admin-authoritative; S26 is editable by Admin and inspectable by Manager.
2. **100% Token Compliance**:
   - Zero hardcoded colors (`Color(0x...)`), text styles, margins, or paddings.
   - 100% styled via `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`.
   - Dark canvas `#181818` (`AppColors.canvas`), elevated card `#222222` (`AppColors.canvasElevated`), primary Rosso Corsa `#DA291C` (`AppColors.primary`).
   - Strict flat design: zero elevation (`elevation: 0`), zero box-shadows, sharp 0px borders except defined token radii.
3. **Typography & Navigation**:
   - Button labels, tab bars, and navigation headers must be uppercase (`.toUpperCase()`).
   - Maximum 1 primary Rosso Corsa button per viewport.
4. **Currency Handling**:
   - All monetary amounts strictly integer VND (`int`). No `double` for currency.
   - Formatted via `CurrencyFormatter.formatVnd(...)`.
5. **UI State Rigor**:
   - Triple state management on all asynchronous data screens: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` with retry button).
6. **State Management**:
   - Strictly `provider` (`ChangeNotifier`, `Consumer`, `Selector`).

---

## 2. Database Schema & Backend Integration

### 2.1 Existing Tables Mapping

| Table | Relevant Columns | Access & RLS Policy |
|---|---|---|
| `public.cinemas` | `id (text PK)`, `name`, `address`, `phone`, `lat`, `lng`, `opening_hours`, `is_active`, `created_at` | Read: Public (`true`). Write: Admin-only (`public.current_role_name() = 'admin'`). |
| `public.rooms` | `id (uuid PK)`, `cinema_id (FK)`, `name`, `formats (text[])`, `rows (int)`, `cols (int)`, `seat_layout (text[])`, `seat_count (int)`, `created_at` | Read: Public (`true`). Write: Admin-only (`public.current_role_name() = 'admin'`). |
| `public.pricing_settings` | `id (int PK = 1)`, `base_2d`, `base_3d`, `base_imax`, `surcharge_vip`, `surcharge_couple`, `surcharge_weekend`, `surcharge_prime`, `prime_start_hour`, `prime_end_hour`, `updated_at` | Read: Public (`true`). Write: Admin-only (`public.current_role_name() = 'admin'`). |
| `public.vouchers` | `code (text PK)`, `type (check in ('percent', 'amount'))`, `value (int)`, `expires_at (timestamptz)`, `max_uses (int)`, `used_count (int)`, `is_active (bool)`, `created_at` | Read: Active vouchers public; all vouchers Admin read/write. |
| `public.profiles` | `id (uuid PK)`, `full_name`, `phone`, `role (check in ('customer','staff','manager','admin'))`, `cinema_id (FK)`, `is_locked (bool)` | Admin can read/update all profiles. Manager can read staff of same cinema. |
| `public.audit_logs` | `id (uuid PK)`, `actor_id (FK)`, `actor_role (text)`, `cinema_id (FK)`, `action (text)`, `target_type (text)`, `target_id (text)`, `reason (text)`, `created_at` | Read: Admin-only. Insert: Any authenticated user. |

### 2.2 Proposed Schema Enhancements (`0007_part_c_schema_enhancements.sql`)

To support rich JSON before-and-after diffs on S29 and advanced promotion constraints on S27, the following non-breaking additive migration is prepared:

```sql
-- 0007_part_c_schema_enhancements.sql
-- Additive enhancements for Milestone 5 Part C

-- 1. Audit Logs Diff Support (S29)
alter table public.audit_logs
  add column if not exists old_data jsonb default null,
  add column if not exists new_data jsonb default null;

-- 2. Voucher Enhancements (S27)
alter table public.vouchers
  add column if not exists min_booking_amount int not null default 0,
  add column if not exists max_discount int default null,
  add column if not exists start_date timestamptz not null default now();

-- Index for temporal audit log queries
create index if not exists idx_audit_logs_created_at on public.audit_logs (created_at desc);
create index if not exists idx_vouchers_expires_active on public.vouchers (expires_at, is_active);
```

### 2.3 Edge Function: `create-staff` Integration (S28)

The existing Supabase Edge Function `supabase/functions/create-staff/index.ts` already handles:
1. Caller verification via JWT (`auth.getUser()`).
2. Role verification: If caller is `admin`, caller is authorized to pass `role: 'manager'` and assign any valid `cinema_id`.
3. Supabase Admin API invocation: Creates the user in `auth.users` with `email_confirm: true` without disconnecting the active Admin session.
4. Updates `public.profiles` with `full_name`, `phone`, `role = 'manager'`, `cinema_id = assignedCinema`, `is_locked = false`.
5. Returns JSON response containing `{ success: true, user: { id, email, full_name, role, cinema_id } }`.

---

## 3. Screen-by-Screen Detailed Implementation Specifications

```
                     ┌────────────────────────────────────────┐
                     │  S12 Management Menu (Role Router)    │
                     └───────────────────┬────────────────────┘
                                         │
        ┌───────────────────┬────────────┴───────┬───────────────────┐
        ▼                   ▼                    ▼                   ▼
 ┌───────────────┐   ┌───────────────┐    ┌───────────────┐   ┌───────────────┐
 │ S25 Cinemas   │   │ S26 Pricing   │    │ S27 Vouchers  │   │ S28 Managers  │
 │ & Rooms Mgmt  │   │ Settings      │    │ Management    │   │ (Admin Only)  │
 └──────┬────────┘   └───────────────┘    └───────────────┘   └───────────────┘
        │                                                             │
        ▼                                                             ▼
 ┌───────────────┐                                            ┌───────────────┐
 │ S24 Seat Map  │                                            │ S29 System    │
 │ Designer Grid │                                            │ Audit Logs    │
 └───────────────┘                                            └───────────────┘
```

---

### 3.1 S24: Room Seat Map Designer (`/management/seat-map`)

#### Technical Metadata
- **Route**: `AppRoutes.configSeatMap` (`/management/seat-map`)
- **Target File**: `lib/features/management/presentation/screens/room_seat_map_screen.dart`
- **Route Arguments**:
  ```dart
  class RoomSeatMapArgs {
    final String roomId;
    final String cinemaId;
    final String roomName;
    final int rows;
    final int cols;
    final List<String> seatLayout;
    final List<String> formats;
    const RoomSeatMapArgs({
      required this.roomId,
      required this.cinemaId,
      required this.roomName,
      required this.rows,
      required this.cols,
      required this.seatLayout,
      required this.formats,
    });
  }
  ```
- **Controller**: `ManagementProvider`
- **Shared Widgets**: `SeatWidget`, `SeatLegend`, `AppButton`, `AppBadge`, `SkeletonBox`, `ErrorState`

#### Component Design & Interactive Mechanics
1. **App Bar**:
   - Title: `THIẾT KẾ SƠ ĐỒ GHẾ` in `AppTextStyles.titleSm`.
   - Subtitle: `${roomName} · ${cinemaName}` in `AppTextStyles.caption.copyWith(color: AppColors.muted)`.
   - Action: `AppButton(text: 'LƯU SƠ ĐỒ', variant: AppButtonVariant.primary)` in top right or bottom sticky bar.
2. **Dimension Controls Header**:
   - Steppers for Row count ($3 \le \text{rows} \le 20$, labeled A to T) and Column count ($4 \le \text{cols} \le 20$).
   - Dynamic Grid Resizing:
     - Increasing rows appends standard row (`'S,S,...,S'`).
     - Decreasing rows trims the bottom row (with confirmation if trimmed seats were configured).
     - Increasing cols appends `'S'` to all rows.
     - Decreasing cols removes trailing cells.
3. **Interactive Seat Canvas**:
   - Centered inside `InteractiveViewer` ($0.6\times$ to $2.5\times$ zoom, boundary margins).
   - Top curved screen canvas arc painter (`_ScreenArcPainter`), labeled `MÀN HÌNH`.
   - Seat Rows:
     - Left row letter indicator (`A`, `B`, `C`...).
     - Cell types represented by tokens:
       - `'S'` -> Standard Seat (`SeatWidget(type: SeatType.standard, state: SeatState.available)`).
       - `'V'` -> VIP Seat (`SeatWidget(type: SeatType.vip, state: SeatState.available)`).
       - `'C'` -> Couple Seat (`SeatWidget(type: SeatType.couple, state: SeatState.available)`).
       - `'_'` -> Walkway / Empty Space (`SizedBox(width: 28, height: 28)`).
     - Cycle Transition on cell tap:
       $$\text{'S'} \longrightarrow \text{'V'} \longrightarrow \text{'C'} \longrightarrow \text{'_'} \longrightarrow \text{'S'}$$
     - Brush Toolbar: Quick paint mode allows selecting active brush (`Standard`, `VIP`, `Couple`, `Aisle`) and tapping cells directly.
     - Batch Row Actions: Popover to set entire row to Standard, VIP, or Clear to Aisles.
4. **Real-time Seat Tally Bar**:
   - Fixed above bottom navigation or above Save button.
   - Computes live counters:
     - **Standard**: Count of `'S'`.
     - **VIP**: Count of `'V'`.
     - **Couple**: Count of `'C'`. (Note: Per `BUSINESS_RULES.md` line 60, each Couple seat counts as 1 towards room `seatCount`).
     - **Total Seats**: $\text{Standard} + \text{VIP} + \text{Couple}$.
5. **Business Safety Lock Check**:
   - Before allowing save, query active showtimes:
     ```dart
     final hasSold = await repo.hasFutureSoldShowtimes(roomId);
     ```
   - If `hasSold == true`:
     - Show dialog: `"Không thể thay đổi sơ đồ ghế vì phòng đang có suất chiếu tương lai đã bán vé."`
     - Save button is disabled with explanatory tooltip.
6. **Persistence**:
   - Updates `public.rooms` (`rows`, `cols`, `seat_layout`, `seat_count`).
   - Inserts audit log:
     - `action = 'updateRoomLayout'`
     - `target_type = 'room'`
     - `target_id = roomId`
     - `old_data`: previous `seat_layout` and `seat_count`
     - `new_data`: updated `seat_layout` and `seat_count`
   - Returns to S25 with success feedback.

---

### 3.2 S25: Cinemas & Rooms Configuration (`/management/rooms`)

#### Technical Metadata
- **Route**: `AppRoutes.manageRooms` (`/management/rooms`)
- **Target File**: `lib/features/management/presentation/screens/cinemas_rooms_screen.dart`
- **Controller**: `ManagementProvider`
- **Shared Widgets**: `AppButton`, `AppBadge`, `AppTextField`, `SkeletonBox`, `EmptyState`, `ErrorState`, `StatusBadge`

#### Component Design & Flow
1. **App Bar**:
   - Title: `RẠP VÀ PHÒNG CHIẾU` in `AppTextStyles.titleSm`.
   - Action (Admin): `+ THÊM RẠP` outline button opening cinema creation sheet.
2. **Cinema Selector Bar**:
   - If Admin: Horizontal scrollable chip bar of all cinemas (`CinemaStar Quận 1`, `CinemaStar Tân Bình`...) with `isActive` indicators.
   - If Manager: Locked to their assigned theater (`currentCinemaId`), displaying cinema branch badge without switching options.
3. **Selected Cinema Overview Card**:
   - Address, Phone, Operating Hours, Lat/Lng coordinates.
   - Action: `CHỈNH SỬA THÔNG TIN RẠP` (Admin only).
4. **Rooms Catalog List**:
   - Header: `DANH SÁCH PHÒNG CHIẾU (${rooms.length})` with `+ THÊM PHÒNG` button.
   - Room Cards:
     - Name (e.g. `Phòng Chiếu 1 (IMAX)`).
     - Format Badges: `[2D]`, `[3D]`, `[IMAX]`.
     - Layout Metrics: `${rows} hàng × ${cols} cột` · `${seatCount} ghế` (breakdown: Thường, VIP, Đôi).
     - Action Buttons:
       - `THIẾT KẾ SƠ ĐỒ GHẾ`: Pushes to S24 (`AppRoutes.configSeatMap`).
       - `SỬA PHÒNG`: Opens modal to edit name and supported formats.
       - `XÓA`: Protected deletion check (rejects if active showtimes exist).
5. **Add / Edit Room Modal**:
   - Inputs: Room Name, Format multi-select chips (`2D`, `3D`, `IMAX`), Default Rows (e.g. 8), Default Cols (e.g. 10).
   - On creation: Generates standard layout matrix (`S,S,...`), saves to `public.rooms`, and immediately offers to launch S24 designer.
6. **Add / Edit Cinema Modal**:
   - Inputs: Cinema ID code (e.g. `cn_bt`), Full Name, Physical Address, Hotline, Latitude, Longitude, Opening Hours.
   - Saves to `public.cinemas`.

---

### 3.3 S26: Dynamic Pricing Settings (`/management/pricing`)

#### Technical Metadata
- **Route**: `AppRoutes.configPricing` (`/management/pricing`)
- **Target File**: `lib/features/management/presentation/screens/pricing_settings_screen.dart`
- **Model**: `PricingSettingsModel`
- **Controller**: `ManagementProvider`
- **Shared Widgets**: `AppButton`, `AppTextField`, `AppBadge`, `SkeletonBox`, `ErrorState`

#### Component Design & Formula Simulator
1. **App Bar**:
   - Title: `BẢNG GIÁ ĐỘNG` in `AppTextStyles.titleSm`.
   - Action (Admin): `LƯU BẢNG GIÁ` primary button. (If Manager: shows `CHỈ XEM` badge, inputs disabled).
2. **Three Grouped Configuration Cards**:
   - **Nhóm 1: Giá cơ sở theo định dạng (Base Prices)**
     - Giá cơ sở 2D (`base_2d`, default 80.000 đ).
     - Giá cơ sở 3D (`base_3d`, default 100.000 đ).
     - Giá cơ sở IMAX (`base_imax`, default 120.000 đ).
   - **Nhóm 2: Phụ thu theo loại ghế (Seat Surcharges)**
     - Phụ thu ghế VIP (`surcharge_vip`, default 20.000 đ).
     - Phụ thu ghế Đôi (`surcharge_couple`, default 20.000 đ).
   - **Nhóm 3: Phụ thu theo thời điểm (Time Surcharges)**
     - Phụ thu cuối tuần (`surcharge_weekend`, default 10.000 đ) — applies Friday, Saturday, Sunday.
     - Phụ thu giờ vàng (`surcharge_prime`, default 10.000 đ).
     - Khung giờ vàng: Giờ bắt đầu (`prime_start_hour`, 18:00) và Giờ kết thúc (`prime_end_hour`, 22:00).
   - Every input field features suffix `"đ"`, number-only keypad, and real-time thousand separator formatting.
3. **Interactive Price Verification Simulator (Khối VÍ DỤ)**:
   - Fulfills `ROLE_FLOWS.md` Section 5.5 line 292:
     *"Khối VÍ DỤ tính giá một ghế VIP, 3D, cuối tuần giờ vàng để kiểm tra công thức."*
   - Interactive live controls:
     - Format: Segmented selector `[2D | 3D | IMAX]`.
     - Seat Type: Segmented selector `[Thường | VIP | Đôi]`.
     - Weekend: Switch toggle `[Không / Có (T6–CN)]`.
     - Prime Hours: Switch toggle `[Không / Có (18h–22h)]`.
   - Real-time Output Card:
     - Visual equation breakdown:
       $$\text{Giá} = \text{Cơ sở (100.000đ)} + \text{VIP (20.000đ)} + \text{Cuối tuần (10.000đ)} + \text{Giờ vàng (10.000đ)}$$
     - Result Display: **`140.000 đ`** rendered in `AppTextStyles.titleLg` with `AppColors.primary`.
4. **Save & Audit Persistence**:
   - Confirmation dialog: `"Áp dụng bảng giá mới cho tất cả các giao dịch đặt vé phát sinh sau thời điểm này?"`
   - Saves to `public.pricing_settings` (`id = 1`).
   - Inserts audit log:
     - `action = 'changePrice'`
     - `target_type = 'pricing_settings'`
     - `target_id = '1'`
     - `old_data`: previous settings snapshot
     - `new_data`: new settings snapshot
     - `reason = 'Cập nhật bảng giá hệ thống'`

---

### 3.4 S27: Voucher & Promotion Management (`/management/vouchers`)

#### Technical Metadata
- **Route**: `AppRoutes.manageVouchers` (`/management/vouchers`)
- **Target File**: `lib/features/management/presentation/screens/voucher_management_screen.dart`
- **Model**: `VoucherModel`
- **Controller**: `ManagementProvider`
- **Shared Widgets**: `AppButton`, `AppBadge`, `AppTextField`, `SkeletonBox`, `EmptyState`, `ErrorState`, `StatusBadge`

#### Component Design & Flow
1. **App Bar**:
   - Title: `QUẢN LÝ VOUCHER` in `AppTextStyles.titleSm`.
   - Action: `+ THÊM VOUCHER` (`AppButton.primary`).
2. **Filter Chip Bar**:
   - Options: `TẤT CẢ` · `CÒN HẠN` · `HẾT LƯỢT` · `HẾT HẠN` · `TẠM KHÓA`.
3. **Voucher Cards List**:
   - Each card contains:
     - Header: Code in bold monospace uppercase (e.g. `CINEMA20`), status badge (`CÒN HẠN` green, `HẾT LƯỢT` amber, `HẾT HẠN` red/muted, `TẠM KHÓA` grey).
     - Value: `Giảm 20% cho tiền vé` or `Giảm 50.000 đ cho tiền vé`.
     - Limits: `Tối thiểu đơn: ${minBookingAmount}đ` · `Giảm tối đa: ${maxDiscount}đ`.
     - Usage progress bar: `${used_count} / ${max_uses} lượt (${percentage}%)`.
     - Validity: `${DateFormatter.format(start_date)} - ${DateFormatter.format(expires_at)}`.
     - Switch Toggle: Immediate activation/deactivation (`is_active`).
     - Actions: Edit modal button, Delete button (with confirmation).
4. **Create / Edit Voucher Modal**:
   - Fields:
     - Mã voucher: `AppTextField` uppercase, alphanumeric, trim whitespace.
     - Loại giảm giá: `Phần trăm (%)` vs `Số tiền cố định (đ)`.
     - Giá trị giảm: $1\% \dots 100\%$ or integer VND.
     - Giảm tối đa (đối với %): Optional integer VND.
     - Đơn tối thiểu: Integer VND.
     - Tổng lượt sử dụng tối đa: Integer.
     - Ngày & Giờ hết hạn: Date & Time pickers.
     - Kích hoạt ngay: Switch toggle.
   - Validates uniqueness, positive values, future expiry date.
   - Saves to `public.vouchers` and writes audit log (`createVoucher` / `updateVoucher`).

---

### 3.5 S28: Manager Accounts Management (Admin-only) (`/management/managers`)

#### Technical Metadata
- **Route**: `AppRoutes.manageManagers` (`/management/managers`)
- **Target File**: `lib/features/management/presentation/screens/manager_accounts_screen.dart`
- **Controller**: `ManagementProvider`
- **Shared Widgets**: `AppButton`, `AppBadge`, `AppTextField`, `SkeletonBox`, `EmptyState`, `ErrorState`, `StatusBadge`

#### Component Design & Edge Function Flow
1. **App Bar**:
   - Title: `QUẢN LÝ QUẢN LÝ RẠP` in `AppTextStyles.titleSm`.
   - Action: `+ THÊM MANAGER` (`AppButton.primary`).
2. **Cinema Branch Filter & Search Bar**:
   - Cinema chips: `TẤT CẢ RẠP`, `Quận 1`, `Tân Bình`...
   - Search field for manager name, email, or phone.
3. **Manager Directory List**:
   - Display Card per Manager:
     - Full Name, Email, Phone.
     - Assigned Theater badge: e.g. `CINEMA QUẬN 1 (cn_q1)`.
     - Status badge: `HOẠT ĐỘNG` (`AppColors.success`) vs `ĐÃ KHÓA` (`AppColors.warning`).
     - Action 1 — Lock / Unlock Toggle:
       - Triggers confirmation dialog: `"Khóa tài khoản quản lý [Họ tên]? Tài khoản này sẽ bị thu hồi phiên đăng nhập ngay lập tức."`
       - Calls `toggleUserLock(managerId, isLocked)` -> updates `profiles.is_locked = isLocked`, logs `lockUser` / `unlockUser`.
     - Action 2 — Reassign Cinema:
       - Modal to transfer manager to another cinema location, updates `profiles.cinema_id`.
4. **Create Manager Modal (`_showAddManagerModal`)**:
   - Inputs:
     - Họ và tên (`full_name`)
     - Email đăng nhập (`email`)
     - Mật khẩu tạm thời (`password`, min 6 characters)
     - Số điện thoại (`phone`)
     - Rạp phụ trách (`cinema_id` dropdown from active cinemas)
   - Submission:
     - Invokes Supabase Edge Function `create-staff` passing `{ email, password, full_name, phone, role: 'manager', cinema_id }`.
     - Handles errors (e.g. `EMAIL_EXISTS`) cleanly without clearing form.
     - On success: refreshes manager directory and shows toast notification.

---

### 3.6 S29: System Audit Logs Viewer (`/management/audit-logs`)

#### Technical Metadata
- **Route**: `AppRoutes.auditLogs` (`/management/audit-logs`)
- **Target File**: `lib/features/management/presentation/screens/audit_logs_screen.dart`
- **Model**: `AuditLogModel`
- **Controller**: `ManagementProvider`
- **Shared Widgets**: `AppButton`, `AppBadge`, `SkeletonBox`, `EmptyState`, `ErrorState`, `StatusBadge`

#### Component Design & Diff Inspection Modal
1. **App Bar**:
   - Title: `NHẬT KÝ THAO TÁC HỆ THỐNG` in `AppTextStyles.titleSm`.
2. **Composite Filter Bar**:
   - Action Type Filter: Dropdown/chips for `Tất cả`, `Soát vé (checkIn)`, `Hủy suất (cancelShowtime)`, `Hoàn tiền (refund)`, `Đổi giá (changePrice)`, `Khóa User (lockUser)`, `Nhân sự (createStaff/Manager)`, `Sơ đồ ghế (updateRoomLayout)`.
   - Cinema Scope Filter: `Tất cả` or specific cinema.
   - Date Filter: Quick chips `Hôm nay`, `7 ngày qua`, `30 ngày qua`, `Tùy chọn`.
3. **Audit Log Timeline List**:
   - Each row presents:
     - Timestamp: Formatted in Vietnam timezone `Asia/Ho_Chi_Minh` (`dd/MM/yyyy HH:mm:ss`).
     - Action Tag: Visual color-coded badge based on action type.
     - Actor Info: Actor Name, Role tag (`ADMIN`, `MANAGER`, `STAFF`).
     - Cinema Branch: Cinema Name or `HỆ THỐNG`.
     - Target: `target_type: target_id`.
     - Reason / Description: e.g. `"Khách yêu cầu hủy vé"`, `"Cập nhật giá cuối tuần"`.
     - Chevron indicator to open detail view.
4. **Audit Detail & JSON Diff Modal (`AuditDetailModal`)**:
   - Full metadata viewer.
   - **Visual Diff Inspector**:
     - When `old_data` and `new_data` exist:
       - Displays side-by-side or stacked diff container.
       - Highlighted changes (modified attributes highlighted in green for additions/modifications and red for prior values).
     - If only reason or text is present: renders formatted JSON preview block.

---

## 4. Data Models & API Contracts

### 4.1 Data Models Architecture

```
lib/features/management/data/models/
├── dashboard_metrics_model.dart (existing)
├── pricing_settings_model.dart  (S26)
├── voucher_model.dart           (S27)
├── audit_log_model.dart         (S29)
└── room_layout_parser.dart      (S24 helper)
```

#### `PricingSettingsModel` (`pricing_settings_model.dart`)
```dart
class PricingSettingsModel {
  final int id;
  final int base2d;
  final int base3d;
  final int baseImax;
  final int surchargeVip;
  final int surchargeCouple;
  final int surchargeWeekend;
  final int surchargePrime;
  final int primeStartHour;
  final int primeEndHour;
  final DateTime updatedAt;

  const PricingSettingsModel({
    this.id = 1,
    required this.base2d,
    required this.base3d,
    required this.baseImax,
    required this.surchargeVip,
    required this.surchargeCouple,
    required this.surchargeWeekend,
    required this.surchargePrime,
    this.primeStartHour = 18,
    this.primeEndHour = 22,
    required this.updatedAt,
  });

  /// Business Formula calculation per BUSINESS_RULES.md Section 4
  int calculateSeatPrice({
    required String format,
    required SeatType seatType,
    required bool isWeekend,
    required bool isPrimeTime,
  }) {
    int base = base2d;
    if (format.toUpperCase() == '3D') base = base3d;
    if (format.toUpperCase() == 'IMAX') base = baseImax;

    final weekendExtra = isWeekend ? surchargeWeekend : 0;
    final primeExtra = isPrimeTime ? surchargePrime : 0;

    switch (seatType) {
      case SeatType.standard:
        return base + weekendExtra + primeExtra;
      case SeatType.vip:
        return base + surchargeVip + weekendExtra + primeExtra;
      case SeatType.couple:
        return (2 * base) + surchargeCouple + weekendExtra + primeExtra;
    }
  }

  factory PricingSettingsModel.fromMap(Map<String, dynamic> map) {
    return PricingSettingsModel(
      id: (map['id'] as num?)?.toInt() ?? 1,
      base2d: (map['base_2d'] as num?)?.toInt() ?? 80000,
      base3d: (map['base_3d'] as num?)?.toInt() ?? 100000,
      baseImax: (map['base_imax'] as num?)?.toInt() ?? 120000,
      surchargeVip: (map['surcharge_vip'] as num?)?.toInt() ?? 20000,
      surchargeCouple: (map['surcharge_couple'] as num?)?.toInt() ?? 20000,
      surchargeWeekend: (map['surcharge_weekend'] as num?)?.toInt() ?? 10000,
      surchargePrime: (map['surcharge_prime'] as num?)?.toInt() ?? 10000,
      primeStartHour: (map['prime_start_hour'] as num?)?.toInt() ?? 18,
      primeEndHour: (map['prime_end_hour'] as num?)?.toInt() ?? 22,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base_2d': base2d,
      'base_3d': base3d,
      'base_imax': baseImax,
      'surcharge_vip': surchargeVip,
      'surcharge_couple': surchargeCouple,
      'surcharge_weekend': surchargeWeekend,
      'surcharge_prime': surchargePrime,
      'prime_start_hour': primeStartHour,
      'prime_end_hour': primeEndHour,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
```

#### `VoucherModel` (`voucher_model.dart`)
```dart
class VoucherModel {
  final String code;
  final String type; // 'percent' or 'amount'
  final int value;
  final int minBookingAmount;
  final int? maxDiscount;
  final DateTime startDate;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final bool isActive;
  final DateTime createdAt;

  const VoucherModel({
    required this.code,
    required this.type,
    required this.value,
    this.minBookingAmount = 0,
    this.maxDiscount,
    required this.startDate,
    required this.expiresAt,
    required this.maxUses,
    required this.usedCount,
    required this.isActive,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExhausted => usedCount >= maxUses;
  bool get isUsable => isActive && !isExpired && !isExhausted;

  String get statusBadgeText {
    if (!isActive) return 'TẠM KHÓA';
    if (isExpired) return 'HẾT HẠN';
    if (isExhausted) return 'HẾT LƯỢT';
    return 'CÒN HẠN';
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    return VoucherModel(
      code: map['code'] as String,
      type: map['type'] as String? ?? 'amount',
      value: (map['value'] as num).toInt(),
      minBookingAmount: (map['min_booking_amount'] as num?)?.toInt() ?? 0,
      maxDiscount: (map['max_discount'] as num?)?.toInt(),
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : DateTime.now(),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      maxUses: (map['max_uses'] as num?)?.toInt() ?? 1,
      usedCount: (map['used_count'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'type': type,
      'value': value,
      'min_booking_amount': minBookingAmount,
      'max_discount': maxDiscount,
      'start_date': startDate.toUtc().toIso8601String(),
      'expires_at': expiresAt.toUtc().toIso8601String(),
      'max_uses': maxUses,
      'used_count': usedCount,
      'is_active': isActive,
    };
  }
}
```

#### `AuditLogModel` (`audit_log_model.dart`)
```dart
class AuditLogModel {
  final String id;
  final String? actorId;
  final String actorRole;
  final String? actorName;
  final String? cinemaId;
  final String? cinemaName;
  final String action;
  final String targetType;
  final String targetId;
  final String? reason;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    this.actorId,
    required this.actorRole,
    this.actorName,
    this.cinemaId,
    this.cinemaName,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.reason,
    this.oldData,
    this.newData,
    required this.createdAt,
  });

  String get actionLabel {
    switch (action) {
      case 'checkIn': return 'SOÁT VÉ';
      case 'cancelShowtime': return 'HỦY SUẤT';
      case 'refund': return 'HOÀN TIỀN';
      case 'changePrice': return 'ĐỔI GIÁ';
      case 'lockUser': return 'KHÓA USER';
      case 'unlockUser': return 'MỞ KHÓA USER';
      case 'createStaff': return 'TẠO NHÂN VIÊN';
      case 'createManager': return 'TẠO QUẢN LÝ';
      case 'updateRoomLayout': return 'SỬA SƠ ĐỒ GHẾ';
      case 'createVoucher': return 'TẠO VOUCHER';
      case 'updateVoucher': return 'SỬA VOUCHER';
      default: return action.toUpperCase();
    }
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] as String,
      actorId: map['actor_id'] as String?,
      actorRole: map['actor_role'] as String? ?? 'staff',
      actorName: map['profiles']?['full_name'] as String?,
      cinemaId: map['cinema_id'] as String?,
      cinemaName: map['cinemas']?['name'] as String?,
      action: map['action'] as String? ?? 'general',
      targetType: map['target_type'] as String? ?? '',
      targetId: map['target_id'] as String? ?? '',
      reason: map['reason'] as String?,
      oldData: map['old_data'] as Map<String, dynamic>?,
      newData: map['new_data'] as Map<String, dynamic>?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
```

---

### 4.2 Extended Repository Contracts (`ManagementRepository`)

The existing `ManagementRepository` will be expanded with the following method signatures:

```dart
// Cinema & Rooms Configuration (S24, S25)
Future<List<CinemaModel>> getAllCinemas();
Future<void> createCinema(CinemaModel cinema);
Future<void> updateCinema(CinemaModel cinema);
Future<List<RoomModel>> getRoomsByCinema(String cinemaId);
Future<void> createRoom(RoomModel room);
Future<void> updateRoom(RoomModel room);
Future<bool> hasFutureSoldShowtimes(String roomId);
Future<void> updateRoomLayout({
  required String roomId,
  required int rows,
  required int cols,
  required List<String> seatLayout,
  required int seatCount,
  required Map<String, dynamic> oldSnapshot,
});

// Dynamic Pricing (S26)
Future<PricingSettingsModel> getPricingSettings();
Future<void> updatePricingSettings(PricingSettingsModel settings, {required PricingSettingsModel oldSettings});

// Voucher Management (S27)
Future<List<VoucherModel>> getVouchers();
Future<void> createVoucher(VoucherModel voucher);
Future<void> updateVoucher(VoucherModel voucher);
Future<void> toggleVoucherStatus(String code, bool isActive);
Future<void> deleteVoucher(String code);

// Manager Accounts (S28)
Future<List<AppUser>> getManagers();
Future<void> reassignManagerCinema(String managerId, String cinemaId);

// Audit Logs (S29)
Future<List<AuditLogModel>> getAuditLogs({
  String? action,
  String? cinemaId,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 100,
});
Future<void> logAudit({
  required String action,
  required String targetType,
  required String targetId,
  String? cinemaId,
  String? reason,
  Map<String, dynamic>? oldData,
  Map<String, dynamic>? newData,
});
```

---

## 5. Testing Strategy & Verification Matrix

### 5.1 Unit Tests Scope
- `pricing_settings_model_test.dart`:
  - 2D/3D/IMAX baseline rate computations.
  - Surcharges for VIP seat (+20k), Couple seat (+20k and double base), Weekend (+10k), and Prime hour (+10k).
  - Multiplier combination test (VIP + 3D + Weekend + Prime = 100k + 20k + 10k + 10k = 140k).
- `voucher_model_test.dart`:
  - Lifecycle state checks: `isExpired`, `isExhausted`, `isUsable`, `statusBadgeText`.
  - Discount evaluation for percentage vs. fixed amount against minimum booking thresholds.
- `room_layout_parser_test.dart`:
  - Row and column token splitting.
  - Total seat tallying with couple seat single-count rule.
  - Serialization to `text[]` for PostgreSQL array compatibility.
- `audit_log_model_test.dart`:
  - Action label translations.
  - Deserialization of `old_data` and `new_data` JSON diff payloads.

### 5.2 Widget & Screen Tests Scope
- `room_seat_map_screen_test.dart` (S24):
  - Renders grid canvas with correct row letters (A-H) and cell types.
  - Cell tap cycles through `S` -> `V` -> `C` -> `_` -> `S`.
  - Steppers alter row and col dimensions dynamically.
  - Live seat count bar updates synchronously on cell toggles.
  - Blocks saving and presents warning dialog when `hasFutureSoldShowtimes` is true.
- `cinemas_rooms_screen_test.dart` (S25):
  - Triple UI state validation: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState`).
  - Cinema selector: Manager restricted to assigned cinema, Admin shows global list.
  - Room cards display format tags and seat counts.
  - Tapping room pushes route to S24.
- `pricing_settings_screen_test.dart` (S26):
  - Populates input controllers with DB values.
  - Interactive formula simulator updates live preview on selector changes.
  - Input fields enforce integer VND numbers.
  - Saving triggers confirmation and invokes `updatePricingSettings`.
- `voucher_management_screen_test.dart` (S27):
  - Filter chips filter voucher list by status.
  - Toggle switch changes active status.
  - Add voucher modal validates uppercase code and future expiry.
- `manager_accounts_screen_test.dart` (S28):
  - Manager list renders status badge and assigned cinema.
  - Lock/Unlock toggle shows warning modal and calls `toggleUserLock`.
  - Add manager modal validates inputs and invokes Edge Function `create-staff`.
- `audit_logs_screen_test.dart` (S29):
  - Timeline lists audit log items sorted by timestamp desc.
  - Filter by action type, cinema, and date range.
  - Tapping log item opens `AuditDetailModal` with JSON diff viewer.

---

## 6. Implementation Roadmap & Sequence

```
  ┌──────────────────────────────────────────────────────────────┐
  │ Phase 1: Database Migration & Models                         │
  │ • 0007_part_c_schema_enhancements.sql (diffs & voucher fields)│
  │ • PricingSettingsModel, VoucherModel, AuditLogModel          │
  └──────────────────────────────┬───────────────────────────────┘
                                 │
  ┌──────────────────────────────▼───────────────────────────────┐
  │ Phase 2: Repository & Provider Integration                   │
  │ • ManagementRepository extension                             │
  │ • ManagementProvider controller methods & state management   │
  └──────────────────────────────┬───────────────────────────────┘
                                 │
  ┌──────────────────────────────▼───────────────────────────────┐
  │ Phase 3: Screen Implementations & Route Wiring               │
  │ • S24: RoomSeatMapScreen (Interactive Grid, Real-time Tally) │
  │ • S25: CinemasRoomsScreen (Cinemas, Rooms Catalog)           │
  │ • S26: PricingSettingsScreen (Dynamic Matrix, Live Tester)   │
  │ • S27: VoucherManagementScreen (Cards, Statuses, Modal)      │
  │ • S28: ManagerAccountsScreen (Edge Function, Lock Toggle)    │
  │ • S29: AuditLogsScreen (Timeline, Filters, JSON Diff Modal)  │
  │ • AppRouter.onGenerateRoute wiring                           │
  └──────────────────────────────┬───────────────────────────────┘
                                 │
  ┌──────────────────────────────▼───────────────────────────────┐
  │ Phase 4: Automated Testing & Verification                    │
  │ • Unit test suite for models and logic                       │
  │ • Widget test suite for all 6 screens                        │
  │ • flutter analyze (0 errors, 0 warnings)                     │
  │ • flutter test (100% passing)                                │
  └──────────────────────────────────────────────────────────────┘
```

---

Vinh Pro
