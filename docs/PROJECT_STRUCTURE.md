# PROJECT_STRUCTURE.md — Cấu trúc dự án, công nghệ, quy ước

> Đọc sau `TECH_STACK.md` và `DESIGN_TOKENS.md`. Khi tạo file mới, đặt đúng vị trí trong cây dưới đây.
> Backend đã được chuẩn hóa theo **Supabase + PostgreSQL** (theo [TECH_STACK.md](file:///d:/cinema_booking_v1/docs/TECH_STACK.md)).

---

## 1. Tech stack

| Thành phần | Công nghệ | Ghi chú |
|---|---|---|
| Framework | Flutter, Dart `>=3.0.0 <4.0.0` | Android và iOS |
| State | `provider` ^6.1.2 | ChangeNotifier, ProxyProvider |
| Backend as a Service | `supabase_flutter` ^2.5.0 | Auth, PostgreSQL, Realtime, Storage, Edge Functions |
| Database & Bảo mật | PostgreSQL + Row Level Security (RLS) | Dữ liệu quan hệ, transaction DB, phân quyền theo role/rạp |
| Nghiệp vụ nhạy cảm | Postgres functions (RPC) | `hold_seats`, `confirm_payment`, `cancel_booking`, `check_in` |
| Serverless / Secret | Supabase Edge Functions (Deno/TypeScript) | Tạo thanh toán SePay VietQR (`create-sepay-url`), Webhook SePay (`sepay-webhook`), tạo nhân viên (`create-staff`) |
| Realtime | Supabase Realtime | Cập nhật trực tiếp trạng thái ghế (`seats`) |
| Thanh toán | SePay VietQR và SePay Checkout | Tạo mã VietQR tự động, quét mã chuyển khoản, tự động cập nhật vé |
| Quét và tạo QR | `mobile_scanner` ^5.1.0, `qr_flutter` ^4.1.0 | Staff quét vé QR, khách hiển thị vé |
| Bản đồ | `google_maps_flutter` ^2.6.0, `geolocator` ^11.0.0 | Tab RẠP, tính khoảng cách GPS |
| Thông báo | `flutter_local_notifications` ^17.1.0 | Nhắc suất chiếu trước 1 giờ |
| Lưu cục bộ | `shared_preferences` ^2.2.3 | Cờ ghi nhớ, cài đặt |
| Ảnh | `cached_network_image` ^3.3.1 | Poster, backdrop, ảnh món ăn |
| Link ngoài | `url_launcher` ^6.2.5 | Chỉ đường, trailer YouTube |
| Định dạng | `intl` ^0.19.0 | Ngày giờ, tiền tệ VND |
| Font | `google_fonts` ^6.2.1 | Inter |
| Skeleton | `shimmer` ^3.0.0 | Loading placeholder góc vuông 0px |
| Icon | `lucide_icons` hoặc `phosphor_flutter` | Chốt một bộ duy nhất |

---

## 2. pubspec.yaml (Chuẩn theo TECH_STACK.md)

```yaml
name: cinema_booking_app
description: "Cinema Booking & Operation Management Application"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # Backend: Supabase (Auth, Postgres, Realtime, Storage, Edge Functions)
  supabase_flutter: ^2.5.0

  # State
  provider: ^6.1.2

  # Helpers
  intl: ^0.19.0

  # Camera & QR
  mobile_scanner: ^5.1.0
  qr_flutter: ^4.1.0

  # Bản đồ & vị trí
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0

  # Thanh toán (SePay VietQR & WebView hiển thị cổng thanh toán)
  webview_flutter: ^4.7.0

  # Thông báo cục bộ
  flutter_local_notifications: ^17.1.0

  # UI
  google_fonts: ^6.2.1
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  url_launcher: ^6.2.5
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

> **Tuyệt đối không thêm:** `firebase_*`, `crypto` (xử lý thanh toán SePay đã nằm trên Edge Function).

---

## 3. Cây thư mục (Feature-First)

```text
cinema_booking_v1/
│
├── supabase/                          # Backend Supabase & Edge Functions
│   ├── config.toml
│   ├── migrations/
│   │   ├── 0001_schema.sql            # Bảng, enum, index
│   │   ├── 0002_rls.sql               # Row Level Security
│   │   ├── 0003_functions.sql         # RPC: hold_seats, confirm_payment, ...
│   │   ├── 0004_triggers.sql          # updated_at, đồng bộ profile
│   │   └── 0005_seed.sql              # Dữ liệu mẫu (tài khoản, phim, rạp, giá)
│   └── functions/
│       ├── create-sepay-url/index.ts  # Tạo mã VietQR & URL thanh toán SePay
│       ├── sepay-webhook/index.ts     # Xác thực webhook, gọi confirm_payment
│       └── create-staff/index.ts      # Tạo user bằng service role key
│
├── lib/
│   ├── main.dart                      # Supabase.initialize, MultiProvider, MaterialApp(theme: AppTheme.dark)
│   │
│   ├── core/                          # Dùng chung toàn app, không chứa UI
│   │   ├── config/
│   │   │   ├── app_constants.dart     # Hằng số nghiệp vụ (8 ghế, 5', 3', 15', 2h, 30')
│   │   │   └── supabase_config.dart   # Đọc SUPABASE_URL & ANON_KEY từ --dart-define
│   │   ├── routes/
│   │   │   ├── app_router.dart        # Bảng route theo tên màn
│   │   │   └── route_guards.dart      # Chặn theo role và đăng nhập (S05 → S01)
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # Mã màu chuẩn token (Rosso Corsa #DA291C, canvas #181818)
│   │   │   ├── app_spacing.dart       # Thang 8px (xxxs=4, xxs=8, xs=16, sm=24, md=32, lg=48, xl=64)
│   │   │   ├── app_radius.dart        # none=0, xs=2 (ghế), sm=4 (input), xl=12, full=9999
│   │   │   ├── app_text_styles.dart   # Inter typography
│   │   │   └── app_theme.dart         # Dark theme duy nhất (AppTheme.dark)
│   │   └── utils/
│   │       ├── date_formatter.dart
│   │       └── currency_formatter.dart # 80000 → "80.000đ"
│   │
│   ├── shared/
│   │   ├── models/
│   │   │   ├── app_user.dart          # id (uuid), fullName, phone, role, cinemaId, isLocked
│   │   │   └── api_response.dart
│   │   └── widgets/                   # Xem DESIGN_TOKENS.md mục 7
│   │       ├── app_button.dart        # primary / outline / text
│   │       ├── app_text_field.dart
│   │       ├── app_badge.dart
│   │       ├── movie_card.dart
│   │       ├── showtime_row.dart
│   │       ├── date_chip.dart
│   │       ├── seat_widget.dart
│   │       ├── seat_legend.dart
│   │       ├── spec_cell.dart
│   │       ├── booking_summary_bar.dart
│   │       ├── hold_timer.dart
│   │       ├── quantity_stepper.dart
│   │       ├── ticket_card.dart
│   │       ├── status_badge.dart
│   │       ├── promo_band.dart
│   │       ├── skeleton_box.dart
│   │       ├── empty_state.dart
│   │       ├── error_state.dart
│   │       ├── notification_badge.dart
│   │       ├── qr_scanner_view.dart   # Khung ngắm và vạch quét camera
│   │       └── result_sheet.dart      # Kết quả soát vé bottom sheet
│   │
│   ├── features/
│   │   ├── auth/                      # S01, S02
│   │   │   ├── data/ auth_repository.dart
│   │   │   └── presentation/ controllers/auth_provider.dart, screens/login_screen.dart, register_screen.dart
│   │   │
│   │   ├── movies/                    # S03, S04
│   │   │   ├── data/ movie_model.dart, movie_repository.dart
│   │   │   └── presentation/ controllers/movie_provider.dart, screens/home_screen.dart, movie_detail_screen.dart
│   │   │
│   │   ├── cinemas/                   # S17, S17B
│   │   │   ├── data/ cinema_model.dart, cinema_repository.dart, location_service.dart
│   │   │   └── presentation/ controllers/cinema_provider.dart, screens/cinema_map_screen.dart, cinema_detail_screen.dart
│   │   │
│   │   ├── booking/                   # S05, S06, S07 (+ dùng lại cho S20)
│   │   │   ├── data/
│   │   │   │   ├── models/ booking_model.dart, showtime_model.dart, seat_model.dart, room_model.dart, food_model.dart
│   │   │   │   └── repositories/ booking_repository.dart, showtime_repository.dart, seat_repository.dart, food_repository.dart
│   │   │   └── presentation/
│   │   │       ├── controllers/ booking_provider.dart, seat_map_provider.dart
│   │   │       └── screens/ showtime_screen.dart, seat_select_screen.dart, food_select_screen.dart
│   │   │
│   │   ├── payment/                   # S08
│   │   │   ├── data/ payment_repository.dart
│   │   │   └── presentation/ screens/checkout_screen.dart, sepay_payment_screen.dart
│   │   │
│   │   ├── tickets/                   # S09, S10
│   │   │   ├── data/ ticket_repository.dart
│   │   │   └── presentation/ controllers/ticket_provider.dart, screens/ticket_success_screen.dart, my_tickets_screen.dart, ticket_detail_screen.dart
│   │   │
│   │   ├── notifications/             # S30
│   │   │   ├── data/ notification_repository.dart, local_reminder_service.dart
│   │   │   └── presentation/ controllers/notification_provider.dart, screens/notifications_screen.dart
│   │   │
│   │   ├── profile/                   # S11
│   │   │   └── presentation/ screens/profile_screen.dart, edit_profile_screen.dart
│   │   │
│   │   ├── staff_checkin/             # S18
│   │   │   ├── data/ checkin_repository.dart, checkin_validator.dart
│   │   │   └── presentation/ controllers/checkin_provider.dart, screens/checkin_screen.dart
│   │   │
│   │   ├── staff_food/                # S19
│   │   │   ├── data/ staff_food_repository.dart
│   │   │   └── presentation/ controllers/staff_food_provider.dart, screens/food_queue_screen.dart
│   │   │
│   │   ├── staff_counter/             # S20, S21 (mức S)
│   │   │   ├── data/ counter_repository.dart
│   │   │   └── presentation/ controllers/counter_provider.dart, screens/counter_showtimes_screen.dart, counter_payment_screen.dart
│   │   │
│   │   └── management/                # Manager và Admin (dùng chung, phân quyền theo role)
│   │       ├── dashboard/             # S22
│   │       ├── showtimes/             # S14
│   │       ├── orders/                # S15
│   │       ├── foods/                 # S16
│   │       ├── employees/             # S23 (Manager & Admin), S28 (Admin)
│   │       ├── movies_mgmt/           # S13
│   │       ├── rooms_seats/           # S24, S25
│   │       ├── pricing/               # S26
│   │       ├── vouchers/              # S27
│   │       ├── audit_logs/            # S29
│   │       └── management_home/       # S12 (menu theo role)
│   │
│   └── tool/
│       └── seed.dart                  # Tool hỗ trợ dev seed dữ liệu
```

---

## 4. Kiến trúc phân tầng

```text
[ Presentation: Screens, Widgets ]
            │  gọi action, lắng nghe state
            ▼
[ Controllers: ChangeNotifier Providers ]
            │  gọi logic dữ liệu
            ▼
[ Repositories & Services: Auth, Booking, Seat, Payment, Location, Notification ]
            │
            ▼
[ Supabase Flutter SDK (REST / RPC / Realtime) / Edge Functions ]
            │
            ▼
[ Supabase: Auth + PostgreSQL (RLS & RPC Functions) + Storage ]
```

---

## 5. Thiết lập Supabase và Provider (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MovieProvider>(
          create: (_) => MovieProvider(),
          update: (_, auth, prev) => prev!..attach(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (_) => BookingProvider(),
          update: (_, auth, prev) => prev!..attach(auth),
        ),
        // CinemaProvider, TicketProvider, NotificationProvider...
      ],
      child: const CinemaApp(),
    ),
  );
}
```

---

## 6. Quy ước đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| File Dart | `snake_case.dart` | `seat_select_screen.dart` |
| Class Dart | `PascalCase` | `SeatSelectScreen` |
| Màn hình | hậu tố `_screen` | `CheckoutScreen` |
| Provider | hậu tố `_provider` | `BookingProvider` |
| Repository | hậu tố `_repository` | `SeatRepository` |
| Widget dùng chung | tên mô tả, không tiền tố | `SeatWidget`, `AppButton` |
| Bảng PostgreSQL | `snake_case` số nhiều | `bookings`, `showtimes`, `seats`, `profiles` |
| Cột PostgreSQL | `snake_case` | `booking_code`, `hold_until`, `price_snapshot` |
| Khóa chính | `uuid` (ngoại trừ `bookings.code` là 8 ký tự, `cinemas.id` là `text`) | `code = 'K7M2QX9P'` |
| Enum DB | `text` kèm ràng buộc `CHECK` | `status in ('holding','paid','used','cancelled','expired')` |

---

## 7. Quy tắc bảo mật và phân quyền

1. **Row Level Security (RLS):** Bật RLS cho 100% các bảng. Khách chỉ xem vé của mình. Staff và Manager chỉ truy cập dữ liệu của rạp mình (`cinema_id = public.current_cinema()`).
2. **Postgres RPC cho thao tác nhạy cảm:** Khách và nhân viên không insert/update trực tiếp các bảng `bookings`, `seats`, `payments`. Mọi ghi dữ liệu đi qua RPC: `hold_seats`, `confirm_payment`, `cancel_booking`, `check_in`, `deliver_food`.
3. **Snapshot giá:** `price_snapshot` tính toán và chốt khi tạo booking, không tính lại.
4. **Bảo mật Secret Key:** `SEPAY_API_KEY` và Supabase `service_role_key` chỉ nằm trong Supabase Edge Functions. Tuyệt đối không đưa vào mã nguồn app client Flutter.
5. **App Client chỉ dùng Anon Key:** App chỉ giao tiếp qua `SUPABASE_ANON_KEY` được truyền an toàn qua `--dart-define`.

---

## 8. Khởi chạy và kiểm thử

```bash
# 1. Cài đặt dependencies Flutter
flutter pub get

# 2. Đẩy migrations lên Supabase
supabase db push

# 3. Deploy Edge Functions
supabase functions deploy create-sepay-url sepay-webhook create-staff

# 4. Chạy ứng dụng với dart-define
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Kiểm thử bắt buộc trước khi bàn giao:
- [ ] Hai tài khoản cùng giữ một ghế gần như đồng thời: một người thành công, người kia nhận `SeatTakenException` (do `for update` trên bảng `showtimes`).
- [ ] Giữ ghế quá 5 phút rồi tiếp tục: ghế trả về trống (cơ chế hết hạn lười).
- [ ] Thanh toán SePay VietQR thành công (`confirm_payment` được gọi từ Edge Function) và thất bại (hủy thanh toán).
- [ ] Staff rạp `cn_q1` quét vé rạp `cn_tb`: báo "Vé thuộc rạp khác".
- [ ] Manager `cn_q1` không thấy danh sách suất/booking của rạp `cn_tb` (được bảo vệ kép bởi RLS và query client).
