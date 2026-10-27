# PROJECT_STRUCTURE.md — Cấu trúc dự án, công nghệ, quy ước

> Đọc sau `DESIGN_TOKENS.md`. Khi tạo file mới, đặt đúng vị trí trong cây dưới đây.

---

## 1. Tech stack

| Thành phần | Công nghệ | Ghi chú |
|---|---|---|
| Framework | Flutter, Dart `>=3.0.0 <4.0.0` | Android và iOS |
| State | `provider` ^6.1.2 | ChangeNotifier, ProxyProvider |
| Database | Cloud Firestore ^4.17.0 | Realtime, transaction cho ghế và thanh toán |
| Auth | Firebase Auth ^4.19.0 | Email/Password |
| Thanh toán | VNPay Sandbox qua `webview_flutter` ^4.7.0 | Ký HMAC-SHA512 bằng `crypto` ^3.0.3 |
| Quét và tạo QR | `mobile_scanner` ^5.1.0, `qr_flutter` ^4.1.0 | Staff quét, khách hiển thị vé |
| Bản đồ | `google_maps_flutter` ^2.6.0, `geolocator` ^11.0.0 | Tab RẠP, khoảng cách |
| Thông báo | `flutter_local_notifications` ^17.1.0 | Nhắc suất chiếu trước 1 giờ |
| Lưu cục bộ | `shared_preferences` | Cờ đăng nhập, cài đặt |
| Ảnh | `cached_network_image` ^3.3.1 | Poster, backdrop |
| Link ngoài | `url_launcher` ^6.2.5 | Chỉ đường, trailer |
| Định dạng | `intl` ^0.19.0 | Ngày giờ, tiền |
| Font | `google_fonts` | Inter |
| Skeleton | `shimmer` hoặc `skeletonizer` | Loading |
| Icon | `lucide_icons` hoặc `phosphor_flutter` | Chốt một bộ |

---

## 2. pubspec.yaml (đã bổ sung đủ package mà DESIGN yêu cầu)

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

  # Firebase
  firebase_core: ^2.30.0
  firebase_auth: ^4.19.0
  cloud_firestore: ^4.17.0

  # State
  provider: ^6.1.2

  # Helpers
  intl: ^0.19.0
  crypto: ^3.0.3            # HMAC-SHA512 cho VNPay

  # Camera & QR
  mobile_scanner: ^5.1.0
  qr_flutter: ^4.1.0

  # Bản đồ
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0

  # Thanh toán
  webview_flutter: ^4.7.0

  # Thông báo cục bộ
  flutter_local_notifications: ^17.1.0

  # UI
  google_fonts: ^6.2.1      # Inter (thiếu trong PROJECT.md cũ)
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0           # Skeleton (thiếu trong PROJECT.md cũ)
  url_launcher: ^6.2.5
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

> Icon package: thêm đúng một gói đã chốt (`lucide_icons` hoặc `phosphor_flutter`).

---

## 3. Cây thư mục (Feature-First)

```text
lib/
├── main.dart                          # Firebase.initializeApp, MultiProvider, MaterialApp(theme: AppTheme.dark)
│
├── core/                              # Dùng chung toàn app, không chứa UI
│   ├── config/
│   │   ├── app_constants.dart         # Hằng số nghiệp vụ (8 ghế, 5', 3', 15', 2h, 30')
│   │   ├── vnpay_config.dart          # tmnCode, returnUrl, endpoint (KHÔNG chứa hashSecret)
│   │   └── env.dart                   # Đưa vào .gitignore, chứa hashSecret và khóa nhạy cảm
│   ├── routes/
│   │   ├── app_router.dart            # Bảng route theo tên màn
│   │   └── route_guards.dart          # Chặn theo role và đăng nhập (S05 → S01)
│   ├── theme/
│   │   ├── app_colors.dart            # DESIGN.md mục 9
│   │   ├── app_spacing.dart           # DESIGN.md mục 9 (thiếu trong PROJECT.md cũ)
│   │   ├── app_radius.dart            # DESIGN.md mục 9 (thiếu trong PROJECT.md cũ)
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   └── utils/
│       ├── date_formatter.dart
│       ├── currency_formatter.dart    # 80000 → "80.000đ"
│       └── vnpay_hasher.dart          # sort ASCII, HMAC-SHA512
│
├── shared/
│   ├── models/
│   │   ├── app_user.dart              # uid, fullName, role, cinemaId, isLocked
│   │   └── api_response.dart
│   └── widgets/                       # Xem DESIGN_TOKENS.md mục 7
│       ├── app_button.dart            # primary / outline / text
│       ├── app_text_field.dart
│       ├── app_badge.dart
│       ├── movie_card.dart
│       ├── showtime_row.dart
│       ├── date_chip.dart
│       ├── seat_widget.dart
│       ├── seat_legend.dart
│       ├── spec_cell.dart
│       ├── booking_summary_bar.dart
│       ├── hold_timer.dart
│       ├── quantity_stepper.dart
│       ├── ticket_card.dart
│       ├── status_badge.dart
│       ├── promo_band.dart
│       ├── skeleton_box.dart
│       ├── empty_state.dart
│       ├── error_state.dart
│       ├── notification_badge.dart
│       ├── qr_scanner_view.dart       # Khung ngắm và vạch quét
│       └── result_sheet.dart          # Kết quả soát vé
│
├── features/
│   ├── auth/                          # S01, S02
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       ├── controllers/auth_provider.dart
│   │       └── screens/ login_screen.dart, register_screen.dart
│   │
│   ├── movies/                        # S03, S04
│   │   ├── data/ movie_model.dart, movie_repository.dart
│   │   └── presentation/ controllers/movie_provider.dart, screens/home_screen.dart, movie_detail_screen.dart
│   │
│   ├── cinemas/                       # S17, S17B
│   │   ├── data/ cinema_model.dart, cinema_repository.dart, location_service.dart
│   │   └── presentation/ controllers/cinema_provider.dart, screens/cinema_map_screen.dart, cinema_detail_screen.dart
│   │
│   ├── booking/                       # S05, S06, S07 (+ dùng lại cho S20)
│   │   ├── data/
│   │   │   ├── models/ booking_model.dart, showtime_model.dart, seat_model.dart, room_model.dart, food_model.dart
│   │   │   └── repositories/ booking_repository.dart, showtime_repository.dart, seat_repository.dart, food_repository.dart
│   │   └── presentation/
│   │       ├── controllers/ booking_provider.dart, seat_map_provider.dart
│   │       └── screens/ showtime_screen.dart, seat_select_screen.dart, food_select_screen.dart
│   │
│   ├── payment/                       # S08
│   │   ├── data/ vnpay_service.dart, payment_repository.dart
│   │   └── presentation/ controllers/payment_provider.dart, screens/checkout_screen.dart, vnpay_webview_screen.dart
│   │
│   ├── tickets/                       # S09, S10
│   │   ├── data/ ticket_repository.dart
│   │   └── presentation/ controllers/ticket_provider.dart, screens/ticket_success_screen.dart, my_tickets_screen.dart, ticket_detail_screen.dart
│   │
│   ├── notifications/                 # S30
│   │   ├── data/ notification_repository.dart, local_reminder_service.dart
│   │   └── presentation/ controllers/notification_provider.dart, screens/notifications_screen.dart
│   │
│   ├── profile/                       # S11
│   │   └── presentation/ screens/profile_screen.dart, edit_profile_screen.dart
│   │
│   ├── support_chat/                  # S31 (mức S)
│   │   ├── data/ chat_repository.dart
│   │   └── presentation/ controllers/chat_provider.dart, screens/chat_screen.dart
│   │
│   ├── staff_checkin/                 # S18
│   │   ├── data/ checkin_repository.dart, checkin_validator.dart
│   │   └── presentation/ controllers/checkin_provider.dart, screens/checkin_screen.dart
│   │
│   ├── staff_food/                    # S19
│   │   ├── data/ staff_food_repository.dart
│   │   └── presentation/ controllers/staff_food_provider.dart, screens/food_queue_screen.dart
│   │
│   ├── staff_counter/                 # S20, S21 (mức S)
│   │   ├── data/ counter_repository.dart
│   │   └── presentation/ controllers/counter_provider.dart, screens/counter_showtimes_screen.dart, counter_payment_screen.dart
│   │
│   └── management/                    # Manager và Admin (dùng chung, khác phạm vi dữ liệu)
│       ├── dashboard/                 # S22
│       ├── showtimes/                 # S14
│       ├── orders/                    # S15
│       ├── foods/                     # S16
│       ├── employees/                 # S23 (Manager và Admin), S28 (chỉ Admin)
│       ├── movies_mgmt/               # S13
│       ├── rooms_seats/               # S24, S25
│       ├── pricing/                   # S26
│       ├── vouchers/                  # S27
│       ├── audit_logs/                # S29
│       └── management_home/           # S12 (menu theo role)
│   (mỗi thư mục con có data/, presentation/controllers/, presentation/screens/)
│
└── tool/
    └── seed.dart                      # Seed dữ liệu mẫu (DATA.md mục 9), chạy một lần
```

**Quy tắc đặt file:**
- Chỉ đặt widget dùng lại ở ít nhất hai màn vào `shared/widgets/`. Còn lại để trong feature.
- Model Firestore nằm trong `data/models/`. Có hàm `fromFirestore` và `toMap`.
- Repository là nơi duy nhất gọi `FirebaseFirestore.instance`. Widget và Provider không gọi trực tiếp.

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
[ Firestore / Firebase Auth / VNPay Sandbox / Google Maps ]
```

Luồng đặt vé dùng `ProxyProvider`: `AuthProvider` cung cấp uid và role, `BookingProvider` nhận uid và giữ `bookingCode` đang hoạt động.

---

## 5. Thiết lập provider (main.dart)

```dart
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
    // CinemaProvider, TicketProvider, NotificationProvider, ManagementProvider... tương tự
  ],
  child: const CinemaApp(),
)
```

---

## 6. Quy ước đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| File | `snake_case.dart` | `seat_select_screen.dart` |
| Class | `PascalCase` | `SeatSelectScreen` |
| Màn hình | hậu tố `_screen` | `CheckoutScreen` |
| Provider | hậu tố `_provider` | `BookingProvider` |
| Repository | hậu tố `_repository` | `SeatRepository` |
| Widget dùng chung | tên mô tả, không tiền tố | `SeatWidget`, `AppButton` |
| Enum | `camelCase` trong Dart, lưu `String` camelCase trong Firestore | `BookingStatus.holding` → `"holding"` |
| Collection / field Firestore | camelCase | `bookings`, `holdUntil` |
| Doc ID booking | 8 ký tự A–Z (bỏ O, I) và số 2–9 | `K7M2QX9P` |
| Doc ID ghế | `seatId` | `C5`, `H3` |
| Doc ID payment | `txnRef` | `K7M2QX9P-251027213005` |

---

## 7. Quy tắc bảo mật và phạm vi dữ liệu

1. **Lọc rạp ở Repository:** mọi query của Staff và Manager phải có `.where('cinemaId', isEqualTo: currentCinemaId)`.
2. **Transaction cho thao tác nhạy cảm:** giữ ghế, xác nhận thanh toán, hủy vé, hủy suất, soát vé, giao đồ ăn. Tất cả dùng `runTransaction` hoặc `WriteBatch`.
3. **Snapshot giá:** `priceSnapshot` ghi một lần khi tạo booking. Không tính lại.
4. **Secret:** `hashSecret` của VNPay không đưa vào Git. Đặt trong `env.dart` đã có trong `.gitignore`.
5. **Rules:** triển khai `firestore.rules` từ `DATA.md` mục 8.

> Giới hạn đã biết: không có server, nên client tự tính giá và tự xác minh chữ ký VNPay. Phù hợp demo sandbox. Production cần Cloud Function nhận IPN từ VNPay và đặt custom claims cho role.

---

## 8. Khởi chạy và kiểm thử

```bash
flutter pub get
flutterfire configure            # tạo firebase_options.dart (không commit nếu chứa khóa nhạy cảm)
dart run tool/seed.dart          # hoặc nút seed ẩn ở màn debug (chỉ build debug)
flutter run
flutter test
```

Kiểm thử bắt buộc trước khi báo xong:
- [ ] Hai tài khoản cùng giữ một ghế gần như đồng thời: một người thành công, người kia nhận `SeatTakenException`.
- [ ] Giữ ghế quá 5 phút rồi tiếp tục: ghế trả về trống.
- [ ] Thanh toán VNPay sandbox thành công (`vnp_ResponseCode = 00`) và thất bại (hủy giữa chừng).
- [ ] Staff rạp `cn_q1` quét vé rạp `cn_tb`: báo "Vé thuộc rạp khác".
- [ ] Manager `cn_q1` không thấy suất của `cn_tb` dù sửa URL hoặc query.

---

## 9. Điểm chưa thống nhất giữa các tài liệu (cần chốt trước khi code)

| # | Vấn đề | Đề xuất |
|---|---|---|
| 1 | `PROJECT.md` cũ không có `google_fonts`, `shimmer`, `shared_preferences` trong pubspec, nhưng `DESIGN.md` yêu cầu | Dùng pubspec mục 2 ở trên |
| 2 | `PROJECT.md` cũ thiếu `app_spacing.dart` và `app_radius.dart` trong cây thư mục | Đã bổ sung ở mục 3 |
| 3 | `SCREENS.md` S17 ghi "google_maps_flutter hoặc flutter_map" | Chọn `google_maps_flutter` (khớp PROJECT.md). Không thêm `flutter_map` |
| 4 | Hai bản cấu trúc thư mục khác nhau (`PROJECT.md` và file kit). Bản kit không có `management/` chi tiết | Dùng bản `PROJECT.md` mục 3 ở trên |
| 5 | S08 có tùy chọn "Demo Giả lập" nhưng PROJECT.md chỉ nói VNPay | Chốt: có demo hay không. Nếu có, `payments.provider = 'demo'` và bỏ qua WebView |
| 6 | Màn chi tiết suất `S17B` và danh sách suất `S05` cùng dùng `showtime_repository` | Dùng chung repository, khác query |
| 7 | `HashSecret` nằm trong `vnpay_config.dart` (PROJECT.md mục 5) và bị đưa vào `env.dart` (mục 6) | Chỉ giữ trong `env.dart` và `.gitignore` |
| 8 | `REQUIREMENTS.md` chưa có trong bộ tài liệu gửi | Xem `BUSINESS_RULES.md` mục 10 |
