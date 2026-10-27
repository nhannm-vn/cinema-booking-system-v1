# Milestone 5 — Part A: Technical Implementation Plan
## Customer Tickets, Management Navigation, Operational Dashboard, Support Chat

---

## 1. Executive Summary & Scope

Milestone 5 — Part A implements the critical operational bridging features that connect the customer journey with management supervision and customer service:
1. **S10 My Tickets & S10B Ticket Detail**:
   - Tabbed categorization: **SẮP TỚI** (upcoming), **ĐÃ XEM** (watched/past/no-show), and **ĐÃ HỦY** (cancelled).
   - Electronic ticket cards featuring movie poster, metadata tags, format, cinema location, hall, showtime, seat labels, status badge, and mini QR preview.
   - S10B Detail View: Complete `QrImageView` rendering 8-character booking code, detailed price snapshot breakdown, cinema location, hall, seats, food concessions with fulfillment status.
   - 2-Hour Cancellation Rule: Active "HỦY VÉ" button enabled strictly when showtime is at least 2 hours in the future; displays modal confirmation explaining 100% refund policy; invokes Postgres RPC `cancel_booking(p_booking_code, p_reason)`.
2. **S12 Management Menu**:
   - Central navigation hub for `manager` and `admin` roles with role-based sectioning.
   - Categories: Operations (Dashboard S22, Bookings S15, Staff S23, Check-in S18, Food S19, Counter S20, Support Chat S31), Catalog (Movies S13, Showtimes S14, Concessions S16), Configuration (Rooms & Seat Map S24/S25, Pricing S26, Vouchers S27), System Admin (Managers S28, Audit Logs S29).
   - Enforces strict role-based permission display according to `ROLE_FLOWS.md` Section 4.2.
3. **S22 Operational Dashboard**:
   - Operational command center for Cinema Managers and System Admins.
   - Invokes Postgres RPC `get_dashboard_metrics(p_cinema_id, p_period)`: revenue in VND (`int`), ticket count, occupancy rate percentage, total and sold capacity.
   - Period selector: **HÔM NAY** (`today`), **7 NGÀY** (`week`), **THÁNG NÀY** (`month`).
   - 4 KPI `SpecCell` cards, quick operational action shortcuts, and upcoming showtimes occupancy progress indicators.
4. **S31 Support Chat**:
   - Real-time two-way messaging between customers and theater staff/managers.
   - Powered by `SupportChatRepository` and `SupportChatProvider` with Supabase Realtime channel subscription listening to `messages` table.
   - Cinema selector, optional booking code attachment chip, automatic scroll-to-bottom on new messages, and message formatting.
5. **Manager Bottom Navigation (`ManagerBottomNav`)**:
   - Reusable 3-tab navigation bar according to `ROLE_FLOWS.md` Section 0: **TỔNG QUAN** (S22), **QUẢN LÝ** (S12), **TÀI KHOẢN** (S11).

---

## 2. Architecture & Data Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│                                                                        │
│   S10 My Tickets       S10B Ticket Detail       S12 Management Menu   │
│   (MyTicketsScreen)    (TicketDetailScreen)     (ManagementMenuScreen) │
│                                                                        │
│   S22 Dashboard        S31 Support Chat         ManagerBottomNav       │
│   (OperationalDashboard)(SupportChatScreen)      (3 tabs: S22,S12,S11) │
└──────────────────────────┬─────────────────────────────────────────────┘
                           │ Provider Consumers / ChangeNotifier
┌──────────────────────────▼─────────────────────────────────────────────┐
│                        CONTROLLER LAYER                                │
│                                                                        │
│   TicketProvider          ManagementProvider     SupportChatProvider   │
│   (loadMyTickets,         (loadDashboardMetrics, (initConversation,    │
│    cancelBooking,          period selector,       sendMessage,         │
│    upcoming/history/canc)  loadEmployees)         realtime channel)    │
└──────────────────────────┬─────────────────────────────────────────────┘
                           │ Repositories
┌──────────────────────────▼─────────────────────────────────────────────┐
│                        DATA / BACKEND LAYER                            │
│                                                                        │
│   TicketRepository         ManagementRepository   SupportChatRepository│
│   (bookings table,         (RPC get_dashboard_    (conversations &     │
│    RPC cancel_booking)      metrics)               messages tables)    │
│                                                                        │
│   PostgreSQL 15 + RLS + Supabase Realtime Channels                     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Screen-by-Screen Technical Specifications

### 3.1 S10 My Tickets (`MyTicketsScreen`)
- **Route**: `AppRoutes.myTickets` (`/my-tickets`).
- **File Location**: `lib/features/tickets/presentation/screens/my_tickets_screen.dart`.
- **Navigation & Scaffolding**:
  - `Scaffold` background: `AppColors.canvas` (`#181818`).
  - `AppBar`:
    - Title: `'VÉ CỦA TÔI'.toUpperCase()` (`AppTextStyles.titleSm.copyWith(color: AppColors.ink)`).
    - Elevation: `0`, background: `AppColors.canvas`.
    - Trailing Action: Notification bell icon with `NotificationBadge` navigating to `AppRoutes.notifications`.
  - Bottom Navigation: `CustomerBottomNav(currentIndex: 2)`.
  - Default Tab Controller with 3 tabs:
    1. **SẮP TỚI** (Upcoming): Count badge or simple tab label.
    2. **ĐÃ XEM** (History / Watched / No-Show).
    3. **ĐÃ HỦY** (Cancelled).
  - TabBar styling:
    - Indicator: `UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.primary, width: 2.0))`.
    - Selected label: `AppTextStyles.button.copyWith(color: AppColors.ink)`.
    - Unselected label: `AppTextStyles.button.copyWith(color: AppColors.muted)`.
- **Card Design**:
  - Container with `AppColors.canvasElevated`, hairline border `AppColors.hairline`, padding `AppSpacing.sm`.
  - Layout:
    - Left: Movie poster thumbnail (`80x110`, with fallback placeholder if `posterUrl` is null).
    - Right / Column:
      - Movie title (`AppTextStyles.titleSm`, max 2 lines).
      - Age rating badge (`AppBadge`) + Format chip (`2D` / `3D` / `IMAX`).
      - Cinema name & Room name (`AppTextStyles.caption.copyWith(color: AppColors.muted)`).
      - Showtime: `DateFormatter.formatDateTime(ticket.showtimeStart)`.
      - Seats: `ticket.seatNamesSummary`.
      - Bottom row: Status badge (`StatusBadge(status: ticket.displayStatus)`) + Mini QR icon/code indicator.
  - Interaction: Tapping the card navigates to `AppRoutes.ticketDetail` passing the `BookingModel`.
- **UI States**:
  - Loading: 4-item `SkeletonBox` placeholder cards.
  - Empty: `EmptyState(message: 'Bạn chưa có vé nào', actionLabel: 'ĐẶT VÉ NGAY', onAction: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false))`.
  - Error: `ErrorState(message: errorMessage, onRetry: () => provider.loadMyTickets())`.
  - Pull-to-refresh: `RefreshIndicator(onRefresh: () => provider.loadMyTickets())`.

---

### 3.2 S10B Ticket Detail (`TicketDetailScreen`)
- **Route**: `AppRoutes.ticketDetail` (`/ticket-detail`).
- **File Location**: `lib/features/tickets/presentation/screens/ticket_detail_screen.dart`.
- **Navigation & Scaffolding**:
  - Arguments: `BookingModel` (or `String bookingCode`). If code passed, load via `TicketRepository.getTicketByCode(bookingCode)`.
  - `AppBar`:
    - Title: `'CHI TIẾT VÉ'.toUpperCase()`.
    - Leading: Back button (`Icons.arrow_back`, `color: AppColors.ink`).
- **Layout & Structure**:
  - `SingleChildScrollView` with padding `AppSpacing.md`.
  - **Electronic Ticket Presentation**:
    - Reusable `TicketCard` or custom ticket container with:
      - Movie Title (`AppTextStyles.displayMd`), Format badge, Age rating badge.
      - Cinema name, Room name, Showtime start formatted.
      - Seat labels: `ticket.seatNamesSummary`.
      - Dashed separator line.
      - Large centered QR Code using `QrImageView`:
        - `data: booking.code`
        - `size: 180.0`
        - `backgroundColor: AppColors.canvasLight`
        - `eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.bodyOnLight)`
        - `dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.bodyOnLight)`
      - 8-Character Booking Code in bold uppercase with letter spacing: `booking.code.toUpperCase()`.
      - Status badge: `StatusBadge(status: booking.displayStatus)`.
  - **Food Concession Items Section** (if `booking.foods.isNotEmpty`):
    - Container with `AppColors.canvasElevated`, border `AppColors.hairline`, padding `AppSpacing.sm`.
    - Section title: `'ĐỒ ĂN KÈM (NHẬN TẠI QUẦY)'.toUpperCase()`.
    - List of food items: `${f['qty']}x ${f['name']}` with individual total price.
    - Food delivery status badge: `CHỜ GIAO` (`AppColors.info`), `ĐÃ GIAO` (`AppColors.success`), or `ĐÃ HỦY` (`AppColors.warning`).
  - **Detailed Price Breakdown Section**:
    - Section header: `'CHI TIẾT THANH TOÁN'.toUpperCase()`.
    - Table/Rows with label & value:
      - Tiền vé: `CurrencyFormatter.format(booking.ticketTotal)`
      - Tiền đồ ăn: `CurrencyFormatter.format(booking.foodTotal)`
      - Giảm giá voucher: `- ${CurrencyFormatter.format(booking.discount)}`
      - Tổng thanh toán: `CurrencyFormatter.format(booking.totalAmount)` (`AppTextStyles.titleSm.copyWith(color: AppColors.primary)`)
      - Phương thức thanh toán: `booking.paymentMethod?.toUpperCase() ?? 'VNPAY'`
      - Thời gian thanh toán: `booking.paidAt != null ? DateFormatter.formatDateTime(booking.paidAt!) : '---'`
  - **Cancellation Rule & Action**:
    - Cancellation rule according to `BUSINESS_RULES.md` Section 10.1:
      - Eligible ONLY if `booking.status == 'paid'` AND `DateTime.now().isBefore(booking.showtimeStart.subtract(const Duration(hours: 2)))`.
    - If eligible (`canCancel == true`):
      - Prominent button: `AppButton(label: 'HỦY VÉ VÀ HOÀN TIỀN', variant: AppButtonVariant.outline, isDestructive: true, ...)`
      - When pressed, open confirmation dialog:
        - Title: `'XÁC NHẬN HỦY VÉ'.toUpperCase()`
        - Content text: `'Bạn có chắc chắn muốn hủy vé ${booking.code}? Theo chính sách của rạp, bạn sẽ được hoàn tiền 100% ( ${CurrencyFormatter.format(booking.totalAmount)} ) về phương thức thanh toán ban đầu.'`
        - Buttons: `'QUAY LẠI'.toUpperCase()` and `'XÁC NHẬN HỦY'.toUpperCase()`.
        - Action: Invokes `ticketProvider.cancelBooking(booking.code)`. On success, shows snackbar `'Hủy vé thành công và hoàn tiền 100%'`, reloads tickets, and pops dialog.
    - If showtime is less than 2 hours away (or not `paid`):
      - If `booking.status == 'paid'`: Display explanatory warning info box:
        - Icon `Icons.info_outline` with color `AppColors.warning`.
        - Text: `'Không thể hủy vé vì suất chiếu bắt đầu trong vòng chưa đầy 2 giờ nữa theo chính sách của rạp.'`
      - Cancellation button is hidden or disabled.

---

### 3.3 S12 Management Menu (`ManagementMenuScreen`)
- **Route**: `AppRoutes.managementHome` (`/management`).
- **File Location**: `lib/features/management/presentation/screens/management_menu_screen.dart`.
- **Navigation & Scaffolding**:
  - `Scaffold` background: `AppColors.canvas`.
  - `AppBar`:
    - Title: `'QUẢN LÝ HỆ THỐNG'.toUpperCase()`.
    - Subtitle/Cinema Badge: Current cinema name (e.g. `'RẠP QUẬN 1'` for Manager, or `'TOÀN HỆ THỐNG'` for Admin).
    - Elevation: `0`.
  - Bottom Navigation: `ManagerBottomNav(currentIndex: 1)`.
- **Role-Based Sections**:
  - Role check via `authProvider.currentUser`:
    - `isManager`: `user.role == UserRole.manager`
    - `isAdmin`: `user.role == UserRole.admin`
  - **Section 1: VẬN HÀNH (Operations)** (Manager & Admin):
    - **Bàn làm việc / Dashboard (S22)**: Subtitle "Số liệu doanh thu, vé bán & tỷ lệ lấp đầy" -> `AppRoutes.dashboard`
    - **Quản lý đơn vé & Bookings (S15)**: Subtitle "Kiểm tra danh sách booking, trạng thái thanh toán" -> `AppRoutes.manageBookings`
    - **Quản lý nhân viên (S23)**: Subtitle "Tạo tài khoản, khóa / mở khóa nhân sự" -> `AppRoutes.manageEmployees`
    - **Hộp thư hỗ trợ khách (S31)**: Subtitle "Tin nhắn trực tuyến hai chiều với khách hàng" -> `AppRoutes.supportChat`
    - **Lối tắt Quầy & Soát vé**:
      - Soát vé tại cửa (S18) -> `AppRoutes.staffCheckin`
      - Quầy giao đồ ăn (S19) -> `AppRoutes.staffFood`
      - Bán vé tại quầy (S20) -> `AppRoutes.staffCounterShowtimes`
  - **Section 2: DANH MỤC & LỊCH CHIẾU (Catalog)**:
    - **Phim (S13)**:
      - Manager: badge `'CHỈ XEM'`, subtitle "Xem danh sách phim đang và sắp chiếu" -> `AppRoutes.manageMovies`
      - Admin: badge `'TOÀN QUYỀN'`, subtitle "Thêm, cập nhật, quản lý phim" -> `AppRoutes.manageMovies`
    - **Lịch suất chiếu (S14)**: Subtitle "Lập lịch suất chiếu mới, kiểm tra giãn cách 15 phút" -> `AppRoutes.manageShowtimes`
    - **Menu bắp nước (S16)**: Subtitle "Bật / tắt trạng thái còn hàng, quản lý món" -> `AppRoutes.manageFoods`
  - **Section 3: CẤU HÌNH & GIÁ (Configuration)**:
    - **Bảng giá vé (S26)**:
      - Manager: badge `'CHỈ XEM'`, subtitle "Xem cấu hình giá vé và phụ thu" -> `AppRoutes.configPricing`
      - Admin: badge `'CHỈNH SỬA'`, subtitle "Cấu hình giá cơ sở và phụ thu động" -> `AppRoutes.configPricing`
    - **Rạp & Phòng chiếu (S25)** (Admin only / Hidden for Manager): Subtitle "Quản lý hệ thống cụm rạp và phòng chiếu" -> `AppRoutes.manageRooms`
    - **Sơ đồ ghế (S24)** (Admin only / Hidden for Manager): Subtitle "Thiết kế ma trận ghế thường, VIP, đôi" -> `AppRoutes.configSeatMap`
    - **Mã giảm giá / Voucher (S27)** (Admin only / Hidden for Manager): Subtitle "Tạo và kiểm soát voucher khuyến mãi" -> `AppRoutes.manageVouchers`
  - **Section 4: QUẢN TRỊ HỆ THỐNG (System Administration - Admin Only)**:
    - **Quản lý Quản lý rạp (S28)**: Subtitle "Phân công và quản lý tài khoản Manager" -> `AppRoutes.manageManagers`
    - **Nhật ký thao tác / Audit Logs (S29)**: Subtitle "Lịch sử kiểm tra soát vé, hoàn tiền, đổi giá" -> `AppRoutes.auditLogs`

---

### 3.4 S22 Operational Dashboard (`OperationalDashboardScreen`)
- **Route**: `AppRoutes.dashboard` (`/management/dashboard`).
- **File Location**: `lib/features/management/presentation/screens/operational_dashboard_screen.dart`.
- **Navigation & Scaffolding**:
  - `Scaffold` background: `AppColors.canvas`.
  - `AppBar`:
    - Title: `'BÀN LÀM VIỆC VẬN HÀNH'.toUpperCase()`.
    - Cinema Name indicator (e.g. `'Rạp CGV Quận 1'`). For Admin, an optional cinema switcher chip or dropdown.
    - Elevation: `0`.
  - Bottom Navigation: `ManagerBottomNav(currentIndex: 0)`.
- **Period Filter Selector**:
  - Horizontal selector with 3 options:
    - `'HÔM NAY'` (`period = 'today'`)
    - `'7 NGÀY'` (`period = 'week'`)
    - `'THÁNG NÀY'` (`period = 'month'`)
  - Active button in Rosso Corsa `AppColors.primary`, inactive in `AppColors.canvasElevated`.
  - Tapping an option invokes `managementProvider.loadDashboardMetrics(cinemaId, period: selectedPeriod)`.
- **4 Key Operational Metrics (KPI Grid)**:
  - 2x2 Grid using `SpecCell` within elevated containers (`AppColors.canvasElevated`):
    1. **DOANH THU THỰC**: `CurrencyFormatter.format(metrics.todayRevenue)`
    2. **SỐ VÉ ĐÃ BÁN**: `${metrics.todayTickets} vé`
    3. **TỈ LỆ LẤP ĐẦY**: `${metrics.occupancyRate.toStringAsFixed(1)}%`
    4. **CÔNG SUẤT PHÒNG**: `${metrics.soldCapacity} / ${metrics.totalCapacity} ghế`
- **Quick Operational Shortcuts**:
  - Row of 4 quick access action buttons with icons:
    - `LẬP SUẤT` (Icon: `Icons.schedule`) -> `AppRoutes.manageShowtimes`
    - `BÁN QUẦY` (Icon: `Icons.point_of_sale`) -> `AppRoutes.staffCounterShowtimes`
    - `SOÁT VÉ` (Icon: `Icons.qr_code_scanner`) -> `AppRoutes.staffCheckin`
    - `ĐƠN VÉ` (Icon: `Icons.receipt_long`) -> `AppRoutes.manageBookings`
- **Upcoming Showtimes List ("SUẤT CHIẾU SẮP DIỄN RA")**:
  - Header: `'SUẤT CHIẾU SẮP DIỄN RA'.toUpperCase()`.
  - List of upcoming showtimes from `metrics.upcomingShowtimes`:
    - Movie title, Room name, Format badge (`2D` / `3D` / `IMAX`).
    - Start time: `DateFormatter.formatTime(showtime.startTime)`.
    - Seats sold info: `${showtime.soldSeats} / ${showtime.totalSeats} ghế`.
    - Occupancy progress bar: `LinearProgressIndicator` (color: `AppColors.primary`, background: `AppColors.canvas`, height: `4.0`).
- **UI State Handling**:
  - Loading: Skeleton grid and skeleton list.
  - Empty: `EmptyState(message: 'Không có dữ liệu vận hành trong chu kỳ đã chọn')`.
  - Error: `ErrorState(message: errorMessage, onRetry: () => provider.loadDashboardMetrics(cinemaId, period: selectedPeriod))`.
  - Pull-to-refresh: `RefreshIndicator`.

---

### 3.5 S31 Support Chat (`SupportChatScreen`)
- **Route**: `AppRoutes.supportChat` (`/support-chat`).
- **File Location**: `lib/features/chat/presentation/screens/support_chat_screen.dart`.
- **Navigation & Scaffolding**:
  - Arguments: optional `{String? cinemaId, String? bookingCode}`.
  - Role adaptation:
    - **Customer**: Chats with cinema staff of the selected cinema. If customer has bookings, can choose cinema or pre-select from arguments.
    - **Staff / Manager**: Chats within their cinema (`user.cinemaId`).
    - **Admin**: Has global access across cinemas.
  - `AppBar`:
    - Title: `'HỖ TRỢ TRỰC TUYẾN'.toUpperCase()`.
    - Subtitle: Cinema name indicator or active ticket reference.
- **Message List & Realtime Synchronization**:
  - `SupportChatProvider` initializes via `initConversation(userId, cinemaId)`.
  - Lays out messages chronologically using `ListView.builder` with `ScrollController`.
  - Auto-scroll: When messages load or new realtime message is received, auto-scrolls smoothly to bottom.
  - **Message Bubbles**:
    - **Own Messages (Current User)**:
      - Aligned to `Alignment.centerRight`.
      - Background: `AppColors.primary.withOpacity(0.18)` or `AppColors.canvasElevated`.
      - Border: `Border.all(color: AppColors.primary, width: 1)`.
      - Text color: `AppColors.ink`.
    - **Incoming Messages (Support Staff / Customer)**:
      - Aligned to `Alignment.centerLeft`.
      - Background: `AppColors.canvasElevated`.
      - Border: `Border.all(color: AppColors.hairline, width: 1)`.
      - Text color: `AppColors.ink`.
    - **Attached Booking Code Chip** (if `msg.bookingCode != null`):
      - Chip inside message: `Icons.confirmation_number_outlined` + `'MÃ VÉ: ${msg.bookingCode}'`.
      - Tapping chip copies code or opens ticket details.
    - **Timestamp**: Formatted with `DateFormatter.formatTime(msg.createdAt)` in `AppColors.muted` (`fontSize: 10`).
- **Input Bar**:
  - Pinned to bottom (safe area aware).
  - Row:
    - Optional "Ghim mã vé" icon button: lets user attach a booking code from their tickets.
    - Input text field: styled container with dark background, hint text `'Nhập tin nhắn hỗ trợ...'`, text in `AppColors.ink`.
    - Send button: Rosso Corsa icon button (`Icons.send`), disabled when text is empty.
  - On send: invokes `supportChatProvider.sendMessage(text, bookingCode: attachedBookingCode)`. Clears input field.
- **UI States**:
  - Loading: `SkeletonBox` placeholder message bubbles.
  - Empty: `EmptyState(message: 'Chưa có tin nhắn nào. Hãy gửi tin nhắn để bắt đầu cuộc trò chuyện với rạp.')`.
  - Error: `ErrorState(message: errorMessage, onRetry: () => provider.initConversation(userId, cinemaId))`.

---

### 3.6 Reusable Manager Bottom Navigation (`ManagerBottomNav`)
- **File Location**: `lib/shared/widgets/manager_bottom_nav.dart`.
- **Purpose**: Unified navigation bar for `manager` and `admin` roles across all management screens.
- **Tabs Specification**:
  1. Tab 0: **TỔNG QUAN** (Icon: `Icons.dashboard_outlined`, Active: `Icons.dashboard`) -> `AppRoutes.dashboard` (S22).
  2. Tab 1: **QUẢN LÝ** (Icon: `Icons.menu_outlined`, Active: `Icons.menu`) -> `AppRoutes.managementHome` (S12).
  3. Tab 2: **TÀI KHOẢN** (Icon: `Icons.person_outline`, Active: `Icons.person`) -> `AppRoutes.profile` (S11).
- **Styling**:
  - Height: `64.0`, background: `AppColors.canvas`.
  - Top border: `1.0px` `AppColors.hairline`.
  - Active color: `AppColors.primary` (`#DA291C`).
  - Inactive color: `AppColors.muted` (`#707070`).
  - Text: Uppercase caption, `10px`, bold when selected.

---

## 4. Data Layer & Provider Enhancements

### 4.1 `TicketProvider` Refinement
In `lib/features/tickets/presentation/controllers/ticket_provider.dart`:
```dart
/// Sắp tới: status == 'paid' và suất chiếu chưa diễn ra
List<BookingModel> get upcomingTickets => _tickets
    .where((t) => t.status == 'paid' && !t.isNoShow && DateTime.now().isBefore(t.showtimeStart))
    .toList();

/// Đã xem: status == 'used' hoặc noShow hoặc suất chiếu đã bắt đầu
List<BookingModel> get historyTickets => _tickets
    .where((t) => t.status == 'used' || t.isNoShow || (t.status == 'paid' && DateTime.now().isAfter(t.showtimeStart)))
    .toList();

/// Đã hủy: status == 'cancelled'
List<BookingModel> get cancelledTickets => _tickets
    .where((t) => t.status == 'cancelled')
    .toList();
```
This guarantees no ticket falls through the cracks if `showtimeStart` has passed but `showtimeStart + 15m` has not yet elapsed.

### 4.2 Central Router Integration
In `lib/core/routes/app_router.dart`:
- Map `AppRoutes.myTickets` to `MyTicketsScreen()`.
- Map `AppRoutes.ticketDetail` to `TicketDetailScreen(...)`.
- Map `AppRoutes.managementHome` to `ManagementMenuScreen()`.
- Map `AppRoutes.dashboard` to `OperationalDashboardScreen()`.
- Map `AppRoutes.supportChat` to `SupportChatScreen(...)`.

---

## 5. UI State Rigor & Error Handling

Every screen strictly implements the 3 required states:
1. **Loading State**:
   - Uses `SkeletonBox` exclusively with dark cinema theme shimmer.
   - S10: 4 ticket card skeleton placeholders.
   - S22: 4 KPI metric cards and showtimes skeleton.
   - S31: Alternating left/right chat bubble skeletons.
2. **Empty State**:
   - Uses `EmptyState` component.
   - S10: "Bạn chưa có vé nào" + "ĐẶT VÉ NGAY" primary button.
   - S22: "Không có dữ liệu vận hành trong chu kỳ đã chọn".
   - S31: "Chưa có tin nhắn nào. Hãy gửi tin nhắn để bắt đầu cuộc trò chuyện."
3. **Error State**:
   - Uses `ErrorState` component with localized error message and "THỬ LẠI" button.
   - Network drop / connection timeout / RPC failures all provide retry action.

---

## 6. Design Token & Aesthetic Conformance Checklist

- [x] **Colors**: Background is `#181818` (`AppColors.canvas`), elevated surfaces `#222222` (`AppColors.canvasElevated`), primary is Rosso Corsa `#DA291C` (`AppColors.primary`), text `#F5F5F5` (`AppColors.ink`), muted `#707070` (`AppColors.muted`).
- [x] **No BoxShadow or Elevation**: `elevation: 0`, zero box shadow everywhere.
- [x] **Zero Border Radius**: Default `AppRadius.zeroRadius` (`0px`) matching dark brutalist cinema tokens.
- [x] **Uppercase Labels**: All button texts and navigation labels explicitly call `.toUpperCase()`.
- [x] **Single Primary Button**: At most 1 primary button per screen view.
- [x] **Currency**: Vietnamese Dong formatted as `int` via `CurrencyFormatter.format(...)`.
- [x] **Clean Code**: No `print` statements, no `TODO` comments.

---

## 7. Testing Strategy & Test Scenarios

### 7.1 Unit & Widget Test Manifest
1. `test/features/tickets/my_tickets_screen_test.dart`:
   - Tab switching between SẮP TỚI, ĐÃ XEM, ĐÃ HỦY.
   - Verifies ticket card contents (title, format, cinema, hall, showtime, seats).
   - Verifies empty state and retry on error state.
   - Verifies navigation to S10B on card tap.
2. `test/features/tickets/ticket_detail_screen_test.dart`:
   - Renders QR code (`QrImageView`) with 8-character booking code.
   - Displays price snapshot breakdown (ticket total, food total, discount, final total).
   - Tests 2-hour cancellation rule:
     - Showtime >= 2h away: "HỦY VÉ VÀ HOÀN TIỀN" button visible and enabled.
     - Tap opens dialog with 100% refund explanation.
     - Confirm calls `cancel_booking` RPC.
     - Showtime < 2h away: button disabled/hidden with policy message.
3. `test/features/management/management_menu_screen_test.dart`:
   - Tests role segmentation: Manager vs Admin.
   - Verifies Manager sees Phim and Bảng giá with "CHỈ XEM" badge.
   - Verifies Admin sees full CRUD access and Admin-only sections (S28, S29).
   - Verifies navigation to Dashboard, Showtimes, Bookings, Employees, Chat.
4. `test/features/management/operational_dashboard_screen_test.dart`:
   - Tests loading metrics from RPC `get_dashboard_metrics`.
   - Tests period selector chips (HÔM NAY, 7 NGÀY, THÁNG NÀY).
   - Displays 4 KPI metric cells with formatted VND and percentages.
   - Displays upcoming showtimes with occupancy progress bar.
   - Tests quick shortcut navigation.
5. `test/features/chat/support_chat_screen_test.dart`:
   - Tests message list rendering with timestamps.
   - Tests bubble alignment (customer right, staff left).
   - Tests booking code attachment chip.
   - Tests sending message and clearing input field.

---

## 8. Implementation Order & Manifest

| Step | File Path | Type | Description |
|---|---|---|---|
| 1 | `lib/shared/widgets/manager_bottom_nav.dart` | New | Reusable 3-tab navigation bar for Manager & Admin |
| 2 | `lib/features/tickets/presentation/controllers/ticket_provider.dart` | Refactor | Refine `upcomingTickets` and `historyTickets` getters |
| 3 | `lib/features/tickets/presentation/screens/my_tickets_screen.dart` | New | S10 My Tickets screen with 3 tabs and ticket cards |
| 4 | `lib/features/tickets/presentation/screens/ticket_detail_screen.dart` | New | S10B Ticket Detail screen with QR, price breakdown, 2h cancel RPC |
| 5 | `lib/features/management/presentation/screens/management_menu_screen.dart` | New | S12 Management Menu with role-based sectioning |
| 6 | `lib/features/management/presentation/screens/operational_dashboard_screen.dart` | New | S22 Operational Dashboard with KPI metrics and period selector |
| 7 | `lib/features/chat/presentation/screens/support_chat_screen.dart` | New | S31 Support Chat with realtime messages and booking code chip |
| 8 | `lib/core/routes/app_router.dart` | Update | Wire routes for S10, S10B, S12, S22, S31 |
| 9 | `test/features/...` | New Tests | Full suite of widget & unit tests for M5 Part A |
