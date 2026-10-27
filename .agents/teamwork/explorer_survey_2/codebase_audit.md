# Báo Cáo Kiểm Toán Toàn Diện Mã Nguồn Flutter (Codebase Audit Report)

**Dự án:** Cinema Booking & Operation Management Application  
**Ngày thực hiện:** 2026-10-27  
**Kiểm toán viên:** Teamwork Preview Explorer (`explorer_survey_2`)  
**Tài liệu tham chiếu chuẩn:**
- `ORIGINAL_REQUEST.md`
- `docs/.cursorrules`
- `docs/TECH_STACK.md`
- `docs/DESIGN_TOKENS.md`
- `docs/PROJECT_STRUCTURE.md`
- `docs/BUSINESS_RULES.md`
- `docs/ROLE_FLOWS.md`
- `docs/00_README.md`
- `AGENTS.md` / `GEMINI.md`

---

## 1. Tổng Quan Tình Trạng Mã Nguồn (Executive Summary)

- **Trạng thái nền tảng (Foundation & Core):** **RẤT TỐT (100% Tuân thủ Tokens & Strict Invariants)**
  - Hệ thống Token thiết kế (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppTheme`) được xây dựng hoàn chỉnh, chuẩn xác 100% theo `DESIGN_TOKENS.md`.
  - Toàn bộ codebase **KHÔNG có bất kỳ mã màu `Color(0x...)` nào** ngoài `app_colors.dart`.
  - Toàn bộ widget tuân thủ nguyên tắc không đổ bóng (`elevation: 0`, không `BoxShadow`), nền tối `#181818` (`canvas`), màu chính Rosso Corsa `#DA291C` (`AppColors.primary`).
  - Thư viện widget dùng chung (`lib/shared/widgets/`) đã có đủ 21 widget quan trọng: `SkeletonBox`, `EmptyState`, `ErrorState`, `AppButton`, `AppTextField`, `TicketCard`, `SeatWidget`, `SeatLegend`, `HoldTimer`, `ResultSheet`, `QrScannerView`, v.v.
  - Backend PostgreSQL (schema, triggers, RLS, 7 RPC functions) và 3 Supabase Edge Functions (`create-vnpay-url`, `vnpay-return`, `create-staff`) đã được định nghĩa đầy đủ trong `supabase/`.
- **Trạng thái phân tầng Dữ liệu & State (Data & State Layers):** **HOÀN THÀNH MỘT PHẦN (~50%)**
  - Đã có 10 models và 10 repositories cho các luồng chính: Auth, Booking, Seats, Showtimes, Foods, Cinemas, Movies, Tickets, Staff Check-in, Staff Food Queue, Payment.
  - Đã có 5 Providers: `AuthProvider`, `BookingProvider`, `CinemaProvider`, `MovieProvider`, `TicketProvider`.
  - Còn thiếu các Repositories & Models phục vụ: Quầy vé (`staff_counter`), Quản trị (`management/`: Dashboard, Phim CRUD, Suất chiếu xung đột 15p, Đơn hàng, Nhân viên, Phòng & Sơ đồ ghế, Bảng giá, Voucher, Nhật ký kiểm toán, Hỗ trợ chat).
  - Còn thiếu các Providers cho: Check-in, Food Queue, Counter, Payment, Notifications, và toàn bộ cụm Management.
- **Trạng thái Giao diện Màn hình (Presentation / Screens S01–S31):** **CHƯA TRIỂN KHAI (0/31 Màn hình)**
  - File `main.dart` hiện chỉ khai báo 2 route tạm thời với `Scaffold` placeholder (`/home` và `/login`).
  - Toàn bộ **31 màn hình (S01 đến S31)** theo ma trận `ROLE_FLOWS.md` chưa được code trong `lib/features/**/presentation/screens/`.
- **Chất lượng mã nguồn tĩnh & Kiểm thử (Lints & Tests Baseline):**
  - `flutter analyze`: **0 lỗi, 0 cảnh báo (No issues found)**.
  - `flutter test`: **12/12 tests vượt qua (100% passing)** trên 4 test file hiện có.

---

## 2. Kiểm Toán `pubspec.yaml` & Phụ Thuộc (Dependencies Audit)

### 2.1 Bảng đối chiếu `pubspec.yaml` với `docs/TECH_STACK.md` (Mục 11)

| Gói phụ thuộc (Package) | Phiên bản hiện tại | Yêu cầu `TECH_STACK.md` | Đánh giá | Ghi chú |
|---|---|---|---|---|
| `supabase_flutter` | `^2.5.0` | `^2.5.0` | ✅ Khớp chuẩn | Backend duy nhất, kết nối Auth, Postgres, Realtime, Storage, RPC, Functions |
| `provider` | `^6.1.2` | `^6.1.2` | ✅ Khớp chuẩn | State management chuẩn duy nhất (ChangeNotifier, ProxyProvider) |
| `intl` | `^0.19.0` | `^0.19.0` | ✅ Khớp chuẩn | Định dạng tiền VND và ngày giờ tiếng Việt |
| `mobile_scanner` | `^5.1.0` | `^5.1.0` | ✅ Khớp chuẩn | Quét mã QR soát vé (S18) |
| `qr_flutter` | `^4.1.0` | `^4.1.0` | ✅ Khớp chuẩn | Hiển thị mã QR vé xem phim (S09, S10) |
| `google_maps_flutter` | `^2.6.0` | `^2.6.0` | ✅ Khớp chuẩn | Bản đồ rạp chiếu (S17, S17B) |
| `geolocator` | `^11.0.0` | `^11.0.0` | ✅ Khớp chuẩn | Tính khoảng cách GPS đến rạp gần nhất |
| `webview_flutter` | `^4.7.0` | `^4.7.0` | ✅ Khớp chuẩn | Hiển thị cổng thanh toán VNPay Sandbox (S08) |
| `flutter_local_notifications` | `^17.1.0` | `^17.1.0` | ✅ Khớp chuẩn | Nhắc giờ chiếu trước 30p, thông báo cục bộ |
| `google_fonts` | `^6.2.1` | `^6.2.1` | ✅ Khớp chuẩn | Font chữ Inter chuẩn `DESIGN_TOKENS.md` |
| `cached_network_image` | `^3.3.1` | `^3.3.1` | ✅ Khớp chuẩn | Tải và cache poster/backdrop/food từ Supabase Storage |
| `shimmer` | `^3.0.0` | `^3.0.0` | ✅ Khớp chuẩn | Hiệu ứng tải dạng xương `SkeletonBox` |
| `url_launcher` | `^6.2.5` | `^6.2.5` | ✅ Khớp chuẩn | Mở trailer YouTube, gọi điện thoại hotline rạp |
| `shared_preferences` | `^2.2.3` | `^2.2.3` | ✅ Khớp chuẩn | Lưu cache rạp đã chọn, thiết lập cá nhân |
| `phosphor_flutter` | `^2.1.0` | *Bổ sung hợp lệ* | ✅ Phù hợp | Cung cấp icon phong cách sharp/editorial cho cinematic UI |
| `flutter_lints` (dev) | `^3.0.0` | `^3.0.0` | ✅ Khớp chuẩn | Bộ quy tắc phân tích mã nguồn Dart tiêu chuẩn |

### 2.2 Kiểm tra các điều cấm kỵ (Strict Invariants Check):
- [x] **KHÔNG có Firebase**: Hoàn toàn không có `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`.
- [x] **KHÔNG có State Management trái phép**: Không có `flutter_riverpod`, `flutter_bloc`, `get`, `mobx`.
- [x] **KHÔNG có `crypto`**: Việc tạo chữ ký HMAC-SHA512 VNPay đã chuyển sang Edge Function `create-vnpay-url`.

---

## 3. Kiểm Toán Phân Tích Mã Nguồn Tĩnh & Quy Tắc Linter

### 3.1 Cấu hình `analysis_options.yaml`
- Kế thừa từ `package:flutter_lints/flutter.yaml`.
- Loại trừ rõ ràng: `build/**`, `android/**`, `ios/**`, `web/**`.
- Không tắt lười các cảnh báo quan trọng.

### 3.2 Kết quả chạy `flutter analyze`
```text
Analyzing cinema-booking-system-v1...                           
No issues found! (ran in 3.6s)
```
- **0 errors, 0 warnings, 0 lints**. Mã nguồn hiện tại hoàn toàn sạch.

### 3.3 Kiểm tra Clean Code & Code Style Invariants:
- **Mã màu hardcode `Color(0x...)`**: 0 trường hợp vi phạm ngoài file token `app_colors.dart`.
- **Đổ bóng `BoxShadow`**: 0 trường hợp.
- **Elevation > 0**: 0 trường hợp (100% đặt `elevation: 0`).
- **Lệnh in tạm `print(...)`**: 0 trường hợp.
- **Bình luận dang dở `TODO`**: 0 trường hợp.

---

## 4. Kiểm Toán Chi Tiết Thư Mục `lib/`

### 4.1 Lớp Nền tảng (Core) — 11 files
1. `lib/core/theme/app_colors.dart`:
   - Định nghĩa đầy đủ: `primary` (#DA291C), `primaryActive` (#B01E0A), `primaryHover` (#9D2211), `canvas` (#181818), `canvasElevated` (#303030), `canvasLight` (#FFFFFF), `surfaceSoftLight` (#F7F7F7), `surfaceStrongLight` (#EBEBEB), `hairline` (#303030), `hairlineOnLight` (#D2D2D2), `ink` (#FFFFFF), `body` (#969696), `muted` (#666666), `success` (#03904A), `warning` (#F13A2C), `focusRing` (#F6E500), `shimmerHighlight` (#3C3C3C), và các token màu ghế (`seatAvailable`, `seatSelected`, `seatSold`, `seatHeld`).
2. `lib/core/theme/app_text_styles.dart`:
   - Định nghĩa 13 kiểu chữ Inter (`displayMega`, `displayXl`, `displayLg`, `displayMd`, `titleMd`, `titleSm`, `bodyMd`, `bodySm`, `caption`, `captionUppercase`, `button`, `navLink`, `numberDisplay`) với đúng size, weight, line height, letter spacing âm cho display.
3. `lib/core/theme/app_spacing.dart`: Thang 8px (`xxxs: 4`, `xxs: 8`, `xs: 16`, `sm: 24`, `md: 32`, `lg: 48`, `xl: 64`, `xxl: 96`, `superSpace: 128`).
4. `lib/core/theme/app_radius.dart`: `none: 0`, `xs: 2`, `sm: 4`, `xl: 12`, `full: 9999`, kèm `sheetRadius` cho bottom sheet.
5. `lib/core/theme/app_theme.dart`: Thiết lập theme tối duy nhất `AppTheme.dark`, Material 3, nền `#181818`, không elevation, viền focus màu `#F6E500`, nút bo góc 0.
6. `lib/core/config/app_constants.dart`: Hằng số nghiệp vụ chuẩn:
   - `maxSeatsPerBooking = 8`
   - `holdOnline = 5 phút`
   - `holdCounter = 3 phút`
   - `gapBetweenShowtimes = 15 phút`
   - `checkInEarly = 30 phút`
   - `checkInLate = 15 phút`
   - `noShowAfter = 15 phút`
   - `cancelBefore = 2 giờ`
   - `paymentWarning = 60 giây`
   - `cancelBatchLimit = 200`
7. `lib/core/config/supabase_config.dart`: Tải URL và ANON_KEY từ `--dart-define`.
8. `lib/core/routes/app_router.dart`: Định nghĩa hằng số route từ `login` (S01) đến `supportChat` (S31).
9. `lib/core/routes/route_guards.dart`: Điều hướng khởi tạo theo role: Staff → S18 (`/staff/checkin`), Manager/Admin → S22 (`/management/dashboard`), Customer/Guest → S03 (`/home`). Danh sách protected routes.
10. `lib/core/utils/currency_formatter.dart`: `CurrencyFormatter.format(int amount)` trả về chuẩn VND (ví dụ `80.000 đ`). Tiền tệ là `int`, không dùng `double`.
11. `lib/core/utils/date_formatter.dart`: Định dạng giờ phút `HH:mm`, ngày `dd/MM/yyyy`, thứ tiếng Việt `T2`-`CN`, đếm ngược `mm:ss`.

### 4.2 Lớp Dùng chung (Shared) — 23 files
- **Models (2 files):**
  - `shared/models/app_user.dart`: Model hồ sơ người dùng (`profiles`), hỗ trợ 4 roles (`customer`, `staff`, `manager`, `admin`), `cinema_id`, `is_locked`.
  - `shared/models/api_response.dart`: Định nghĩa các exceptions nghiệp vụ (`SeatTakenException`, `ShowtimeConflictException`, `CheckinException`, `BusinessException`).
- **Widgets dùng chung (21 files):**
  - `app_button.dart`: `AppButton.primary`, `AppButton.outline`, `AppButton.text`, nhãn luôn `.toUpperCase()`, cao 48px, bo góc 0, có trạng thái loading.
  - `app_text_field.dart`: Ô nhập liệu chuẩn, viền focus vàng `#F6E500`, hiển thị lỗi caption đỏ.
  - `app_badge.dart`: Badge nhãn định dạng phim (2D, 3D, IMAX) hoặc độ tuổi (P, T13, T16, T18).
  - `status_badge.dart`: Badge trạng thái đơn đặt vé (Chờ thanh toán, Đã thanh toán, Đã xem, Đã hủy, Hết hạn, Vắng mặt).
  - `skeleton_box.dart`: Hiệu ứng placeholder shimmer với màu `canvasElevated` và highlight `shimmerHighlight`.
  - `empty_state.dart`: Trạng thái rỗng với icon, tiêu đề, mô tả và nút hành động outline.
  - `error_state.dart`: Trạng thái lỗi với icon cảnh báo, thông điệp lỗi và nút `THỬ LẠI` (`onRetry`).
  - `movie_card.dart`: Thẻ phim hiển thị poster tỷ lệ 2:3, tên phim, thời lượng, thể loại.
  - `showtime_row.dart`: Hàng suất chiếu theo định dạng kèm giờ chiếu dạng chip.
  - `date_chip.dart`: Chip chọn ngày (Thứ, ngày/tháng) trạng thái chọn/không chọn.
  - `seat_widget.dart` & `seat_legend.dart`: Widget vẽ từng ghế (Standard, VIP, Couple) theo đúng màu và viền token, kèm bảng chú thích trạng thái ghế.
  - `spec_cell.dart`: Ô thông số kỹ thuật phim (thời lượng, ngôn ngữ, định dạng).
  - `booking_summary_bar.dart`: Thanh tổng kết số ghế, tổng tiền và nút CTA tiếp tục gắn đáy màn hình.
  - `hold_timer.dart`: Đồng hồ đếm ngược giữ ghế 5 phút / 3 phút, chuyển đỏ khi còn dưới 60 giây.
  - `quantity_stepper.dart`: Bộ tăng giảm số lượng đồ ăn `[ - ] [ n ] [ + ]`.
  - `ticket_card.dart`: Thẻ vé xem phim nền sáng `#FFFFFF` (`canvasLight`), mã booking 8 ký tự, mã QR, đường kẻ răng cưa `hairlineOnLight`.
  - `promo_band.dart`: Dải banner khuyến mãi / thông báo nổi bật.
  - `qr_scanner_view.dart`: Giao diện camera quét QR kèm khung ngắm đỏ Rosso Corsa và vạch quét động.
  - `result_sheet.dart`: Modal bottom sheet thông báo kết quả soát vé hợp lệ (xanh) hoặc từ chối (đỏ).
  - `notification_badge.dart`: Chấm tròn đỏ hiển thị số lượng thông báo chưa đọc.

### 4.3 Lớp Tính năng (Features Layer) — 24 files
- **`features/auth/` (2 files):**
  - `auth_repository.dart`: Xử lý đăng nhập, đăng ký customer, cập nhật profile, lắng nghe auth state.
  - `auth_provider.dart`: Quản lý session đăng nhập, nạp user profile từ bảng `profiles`.
- **`features/booking/` (9 files):**
  - Models: `booking_model.dart`, `showtime_model.dart`, `seat_model.dart`, `room_model.dart`, `food_model.dart`.
  - Repositories:
    - `seat_repository.dart`: Stream Realtime bảng `seats`, gọi RPC `hold_seats` với khóa `for update`, gọi RPC `release_hold`, bắt lỗi `SEAT_TAKEN:`.
    - `showtime_repository.dart`: Truy vấn suất chiếu theo ngày, phim, rạp.
    - `food_repository.dart`: Truy vấn danh sách đồ ăn khả dụng theo rạp.
  - Controller: `booking_provider.dart`: Chọn suất, chọn tối đa 8 ghế, tăng giảm đồ ăn, tính tiền snapshot, đếm ngược giữ ghế.
- **`features/cinemas/` (4 files):**
  - `cinema_model.dart`, `cinema_repository.dart`, `location_service.dart` (Geolocator GPS + tính khoảng cách Km), `cinema_provider.dart`.
- **`features/movies/` (3 files):**
  - `movie_model.dart`, `movie_repository.dart`, `movie_provider.dart` (lọc phim đang chiếu, sắp chiếu, tìm kiếm client-side).
- **`features/payment/` (1 file):**
  - `payment_repository.dart`: Gọi Edge Function `create-vnpay-url`.
- **`features/staff_checkin/` (1 file):**
  - `checkin_repository.dart`: Gọi RPC `check_in`, nhận kết quả `CheckinResult`.
- **`features/staff_food/` (1 file):**
  - `staff_food_repository.dart`: Truy vấn danh sách đơn đồ ăn pending/delivered, gọi RPC `deliver_food`.
- **`features/tickets/` (2 files):**
  - `ticket_repository.dart`: Truy vấn vé của khách, gọi RPC `cancel_booking` (hoàn tiền trước >= 2 giờ).
  - `ticket_provider.dart`: Phân loại vé thành SẮP TỚI, ĐÃ XEM, ĐÃ HỦY.
- **`features/notifications/` (1 file):**
  - `notification_repository.dart`: Lấy danh sách thông báo người dùng, đánh dấu đã đọc.

---

## 5. Bảng Trạng Thái Màn Hình S01–S31 (Screen Implementation Matrix)

Dưới đây là kiểm toán hiện trạng của toàn bộ 31 màn hình được quy định trong `ROLE_FLOWS.md` và `ORIGINAL_REQUEST.md`:

| Mã màn | Tên màn hình (Screen Name) | Phân hệ (Role) | Trạng thái hiện tại | Đường dẫn file dự kiến |
|:---:|---|---|:---:|---|
| **S01** | Đăng nhập (LoginScreen) | Guest / Tất cả | ❌ **Chưa có** (Chỉ có text dummy) | `lib/features/auth/presentation/screens/login_screen.dart` |
| **S02** | Đăng ký (RegisterScreen) | Guest | ❌ **Chưa có** | `lib/features/auth/presentation/screens/register_screen.dart` |
| **S03** | Trang chủ khám phá (HomeScreen) | Customer / Guest | ❌ **Chưa có** (Chỉ có text dummy) | `lib/features/movies/presentation/screens/home_screen.dart` |
| **S04** | Chi tiết phim (MovieDetailScreen) | Customer / Guest | ❌ **Chưa có** | `lib/features/movies/presentation/screens/movie_detail_screen.dart` |
| **S05** | Chọn suất chiếu (ShowtimeScreen) | Customer / Guest | ❌ **Chưa có** | `lib/features/booking/presentation/screens/showtime_screen.dart` |
| **S06** | Chọn ghế & sơ đồ Realtime (SeatSelectScreen) | Customer / Staff | ❌ **Chưa có** | `lib/features/booking/presentation/screens/seat_select_screen.dart` |
| **S07** | Chọn đồ ăn bắp nước (FoodSelectScreen) | Customer / Staff | ❌ **Chưa có** | `lib/features/booking/presentation/screens/food_select_screen.dart` |
| **S08** | Thanh toán & VNPay WebView (CheckoutScreen) | Customer | ❌ **Chưa có** | `lib/features/payment/presentation/screens/checkout_screen.dart` & `vnpay_webview_screen.dart` |
| **S09** | Đặt vé thành công (TicketSuccessScreen) | Customer / Staff | ❌ **Chưa có** | `lib/features/tickets/presentation/screens/ticket_success_screen.dart` |
| **S10** | Quản lý vé của tôi (MyTicketsScreen) | Customer | ❌ **Chưa có** | `lib/features/tickets/presentation/screens/my_tickets_screen.dart` & `ticket_detail_screen.dart` |
| **S11** | Tài khoản & Thông tin cá nhân (ProfileScreen) | Customer / Tất cả | ❌ **Chưa có** | `lib/features/profile/presentation/screens/profile_screen.dart` & `edit_profile_screen.dart` |
| **S12** | Quản lý trung tâm (ManagementHomeScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/management_home_screen.dart` |
| **S13** | Quản lý phim (ManageMoviesScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_movies_screen.dart` |
| **S14** | Quản lý suất chiếu (ManageShowtimesScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_showtimes_screen.dart` |
| **S15** | Quản lý đơn đặt vé (ManageBookingsScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_bookings_screen.dart` |
| **S16** | Quản lý menu đồ ăn (ManageFoodsScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_foods_screen.dart` |
| **S17** | Bản đồ rạp chiếu Google Map (CinemaMapScreen) | Customer / Guest | ❌ **Chưa có** | `lib/features/cinemas/presentation/screens/cinema_map_screen.dart` |
| **S17B**| Chi tiết cụm rạp (CinemaDetailScreen) | Customer / Guest | ❌ **Chưa có** | `lib/features/cinemas/presentation/screens/cinema_detail_screen.dart` |
| **S18** | Soát vé QR & Mã tay (StaffCheckinScreen) | Staff / Manager | ❌ **Chưa có** | `lib/features/staff_checkin/presentation/screens/staff_checkin_screen.dart` |
| **S19** | Hàng đợi chế biến đồ ăn (StaffFoodScreen) | Staff / Manager | ❌ **Chưa có** | `lib/features/staff_food/presentation/screens/staff_food_screen.dart` |
| **S20** | Bán vé tại quầy (CounterShowtimesScreen) | Staff / Manager | ❌ **Chưa có** | `lib/features/staff_counter/presentation/screens/counter_showtimes_screen.dart` |
| **S21** | Thanh toán tiền mặt tại quầy (CounterPaymentScreen) | Staff / Manager | ❌ **Chưa có** | `lib/features/staff_counter/presentation/screens/counter_payment_screen.dart` |
| **S22** | Báo cáo & Tổng quan vận hành (DashboardScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/dashboard_screen.dart` |
| **S23** | Quản lý nhân viên rạp (ManageEmployeesScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_employees_screen.dart` |
| **S24** | Cấu hình sơ đồ ghế phòng chiếu (ConfigSeatMapScreen) | Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/config_seat_map_screen.dart` |
| **S25** | Quản lý rạp và phòng chiếu (ManageRoomsScreen) | Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_rooms_screen.dart` |
| **S26** | Bảng cấu hình giá vé (ConfigPricingScreen) | Manager / Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/config_pricing_screen.dart` |
| **S27** | Quản lý mã giảm giá Voucher (ManageVouchersScreen) | Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_vouchers_screen.dart` |
| **S28** | Quản lý tài khoản Quản lý (ManageManagersScreen) | Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/manage_managers_screen.dart` |
| **S29** | Nhật ký thao tác hệ thống (AuditLogsScreen) | Admin | ❌ **Chưa có** | `lib/features/management/presentation/screens/audit_logs_screen.dart` |
| **S30** | Trung tâm thông báo (NotificationsScreen) | Customer / Tất cả | ❌ **Chưa có** | `lib/features/notifications/presentation/screens/notifications_screen.dart` |
| **S31** | Hỗ trợ & Trò chuyện trực tuyến (SupportChatScreen) | Customer / Tất cả | ❌ **Chưa có** | `lib/features/support_chat/presentation/screens/support_chat_screen.dart` |

**Tổng kết màn hình:**
- Đã hoàn thành: **0**
- Đang hoàn thành dở dang: **0**
- Chưa triển khai: **31 màn hình (100%)**

---

## 6. Kiểm Toán Thư Mục Kiểm Thử `test/` (Test Suite Audit)

### 6.1 Các bài kiểm thử hiện có (4 files, 12 test cases)
1. `test/core/utils/currency_formatter_test.dart` (4 tests):
   - Định dạng tiền VND có ký hiệu `đ`.
   - Định dạng số tiền lớn có phân cách hàng nghìn `1.250.000 đ`.
   - Định dạng 0 VND.
   - Định dạng không kèm ký hiệu `150.000`.
2. `test/core/utils/date_formatter_test.dart` (4 tests):
   - Định dạng giờ chiếu `HH:mm`.
   - Định dạng ngày chiếu `dd/MM/yyyy`.
   - Định dạng thứ tiếng Việt viết tắt (`T2` đến `CN`).
   - Định dạng đếm ngược giữ ghế `mm:ss` và xử lý thời gian âm.
3. `test/shared/widgets/app_button_test.dart` (3 tests):
   - Render nhãn tự động viết hoa uppercase.
   - Kích hoạt sự kiện `onPressed` khi tap.
   - Hiển thị `CircularProgressIndicator` khi `isLoading: true`.
4. `test/widget_test.dart` (1 test):
   - Render `AppBadge` và `SpecCell`.

### 6.2 Lỗ hổng kiểm thử (Coverage Gaps)
- **Unit Tests còn thiếu:**
  - `AuthProvider`: Luồng đăng nhập, đăng ký, khóa tài khoản, sign out.
  - `BookingProvider`: Logic chặn quá 8 ghế, tính giá vé snapshot theo định dạng 2D/3D/IMAX + phụ thu cuối tuần / giờ vàng, RPC `hold_seats`, nhả ghế.
  - `RouteGuards`: Kiểm tra role mapping và danh sách protected routes.
  - `CheckinRepository`: Xử lý 8 điều kiện kiểm tra của soát vé (sai rạp, quá giờ, vé đã dùng, v.v.).
  - `TicketProvider`: Phân loại vé Sắp tới, Đã xem, Đã hủy, điều kiện hủy trước 2 giờ.
- **Widget Tests còn thiếu:**
  - Chưa có test cho bất kỳ màn hình nào trong số S01–S31.
  - Chưa có widget test cho `EmptyState`, `ErrorState`, `SkeletonBox`, `HoldTimer`, `ResultSheet`, `TicketCard`, `SeatWidget`.
- **Integration / Flow Tests còn thiếu:**
  - Luồng End-to-End đặt vé khách hàng (Đăng nhập -> Xem phim -> Chọn suất -> Giữ ghế -> Đồ ăn -> Thanh toán -> Xem vé).
  - Luồng Soát vé Staff (Quét QR -> Xác nhận độ tuổi T16/T18 -> Vào rạp).

---

## 7. Danh Sách Sai Lệch & Khoảng Trống Nghiệp Vụ (Discrepancies & Gaps)

1. **Khoảng trống Màn hình (Critical Gap):** Toàn bộ giao diện S01–S31 chưa được xây dựng. `main.dart` chỉ có placeholder scaffold.
2. **Khoảng trống State Controllers (High Gap):** Cần bổ sung các providers:
   - `CheckinProvider` cho S18.
   - `StaffFoodProvider` cho S19.
   - `CounterProvider` cho S20, S21.
   - `PaymentProvider` cho S08.
   - `NotificationProvider` cho S30.
   - `ManagementProvider` hoặc các sub-providers cho S12–S16, S22–S29.
3. **Khoảng trống Phân hệ Bán vé Quầy (Medium Gap):** Thiếu `staff_counter_repository.dart` gọi RPC `sell_counter`.
4. **Khoảng trống Phân hệ Quản trị (Medium Gap):** Thiếu models và repositories cho:
   - Thống kê doanh thu / tỷ lệ lấp đầy Dashboard (S22).
   - CRUD phim (S13).
   - Lập lịch suất chiếu và thuật toán chặn xung đột 15 phút (S14).
   - Bảng giá `pricing_settings` và phụ thu (S26).
   - Voucher giảm giá (S27).
   - Nhật ký `audit_logs` (S29).
5. **Khoảng trống Khởi tạo Tuyến đường (AppRouter & MultiProvider):** `main.dart` chưa inject đầy đủ các providers vào cây widget và chưa đăng ký các named routes vào `MaterialApp.routes` hoặc `onGenerateRoute`.

---

## 8. Khuyến Nghị Lộ Trình Triển Khai (Actionable Implementation Roadmap)

Để hiện thực hóa ứng dụng đạt 100% tiêu chí nghiệm thu trong `ORIGINAL_REQUEST.md` mà không phá vỡ tính toàn vẹn kiến trúc:

### Giai đoạn 1: Hoàn thiện Tầng Dữ liệu & State còn thiếu (Foundational State Completion)
1. Thêm `CounterRepository` gọi RPC `sell_counter` (`features/staff_counter/data/`).
2. Thêm `ManagementRepository` phục vụ Dashboard, CRUD Phim, Suất chiếu, Phòng, Giá, Voucher, Audit logs (`features/management/data/`).
3. Tạo các Providers tương ứng: `CheckinProvider`, `StaffFoodProvider`, `CounterProvider`, `NotificationProvider`, `ManagementProvider`.
4. Đăng ký toàn bộ Providers trong `MultiProvider` tại `main.dart`.

### Giai đoạn 2: Xây dựng Giao diện Khách hàng — Customer Journey (S01–S11, S17, S17B, S30)
1. Auth: S01 (`LoginScreen`), S02 (`RegisterScreen`).
2. Discovery: S03 (`HomeScreen` với backdrop carousel, movie search), S04 (`MovieDetailScreen` với spec cells, trailer popup).
3. Booking Flow: S05 (`ShowtimeScreen`), S06 (`SeatSelectScreen` có realtime stream + giới hạn 8 ghế), S07 (`FoodSelectScreen` có `QuantityStepper` + `HoldTimer`), S08 (`CheckoutScreen` + VNPay WebView).
4. Tickets: S09 (`TicketSuccessScreen` có QR code & 8-char code), S10 (`MyTicketsScreen` tab SẮP TỚI / ĐÃ XEM / ĐÃ HỦY kèm nút HỦY VÉ), S11 (`ProfileScreen`).
5. Maps & Notifications: S17 (`CinemaMapScreen` Google Map), S17B (`CinemaDetailScreen`), S30 (`NotificationsScreen`).

### Giai đoạn 3: Xây dựng Giao diện Vận hành Rạp — Staff Operations (S18–S21)
1. S18 (`StaffCheckinScreen`): Tích hợp camera scanner `mobile_scanner`, khung ngắm đỏ, nhập mã tay, checkbox xác nhận tuổi T16/T18, hiển thị `ResultSheet`.
2. S19 (`StaffFoodScreen`): Bảng order 2 tab CHỜ GIAO / ĐÃ GIAO, nút giao đồ ăn gọi RPC `deliver_food`.
3. S20 & S21 (`CounterShowtimesScreen` & `CounterPaymentScreen`): Giữ ghế 3 phút tại quầy, tính tiền thừa, xuất vé trực tiếp qua RPC `sell_counter`.

### Giai đoạn 4: Xây dựng Giao diện Quản trị — Management Suite (S12–S16, S22–S29)
1. S12 (`ManagementHomeScreen`): Menu điều hướng phân quyền theo role Manager / Admin.
2. S22 (`DashboardScreen`): 4 thẻ chỉ số chính (doanh thu hôm nay, vé đã bán, tỷ lệ lấp đầy, suất sắp chiếu). Tự động lọc theo `cinema_id` đối với Manager.
3. S13 (`ManageMoviesScreen`): Danh sách phim, form tạo/sửa phim (Admin).
4. S14 (`ManageShowtimesScreen`): Lịch chiếu, form tạo suất kiểm tra xung đột cách 15 phút.
5. S15 (`ManageBookingsScreen`): Lọc đơn vé theo trạng thái (Paid, Used, NoShow, Cancelled, Expired) và kênh (Online, Counter).
6. S16 (`ManageFoodsScreen`): Quản lý món ăn và công tắc toggle còn/hết hàng.
7. S23 & S28 (`ManageEmployeesScreen` & `ManageManagersScreen`): Tạo nhân viên qua Edge Function `create-staff`, khóa/mở khóa tài khoản.
8. S24, S25 (`ConfigSeatMapScreen`, `ManageRoomsScreen`): Thiết kế sơ đồ ghế trực quan qua lưới `SeatWidget`.
9. S26, S27, S29 (`ConfigPricingScreen`, `ManageVouchersScreen`, `AuditLogsScreen`): Bảng giá, mã giảm giá, nhật ký kiểm toán.
10. S31 (`SupportChatScreen`): Trò chuyện hỗ trợ khách hàng.

### Giai đoạn 5: Định tuyến, Kiểm thử Toàn diện & Nghiệm thu
1. Cấu hình bảng route hoàn chỉnh trong `AppRouter` và liên kết với `main.dart`.
2. Viết bổ sung bộ unit tests và widget tests bao phủ các quy tắc nghiệp vụ cốt lõi.
3. Chạy kiểm thử tự động `flutter analyze` và `flutter test` đảm bảo 100% đạt chuẩn.

---
Vinh Pro
