# HƯỚNG DẪN VÀ RÀNG BUỘC BẮT BUỘC CHO AI AGENT (AGENTS.md)

> **QUAN TRỌNG:** Đây là quy chuẩn bắt buộc dành cho tất cả AI Agent (Antigravity, Cursor, Windsurf, Claude Code, Copilot, v.v.) khi làm việc trong dự án Cinema Booking & Operation Management App.

---

## 1. RÀNG BUỘC TIÊN QUYẾT TRƯỚC KHI VIẾT CODE (MANDATORY)

**TRƯỚC KHI** tạo mới, chỉnh sửa, hoặc refactor bất kỳ file code nào (Dart, Flutter, Firestore security rules, configs, models, providers, repositories, screens, widgets):

Agent **BẮT BUỘC PHẢI ĐỌC VÀ ĐỐI CHIẾU** các tài liệu trong thư mục [docs/](file:///d:/cinema_booking_v1/docs/) theo đúng thứ tự sau:

1. [docs/.cursorrules](file:///d:/cinema_booking_v1/docs/.cursorrules) — Bộ luật bất biến: công nghệ, thiết kế, nghiệp vụ, quy ước.
2. [docs/DESIGN_TOKENS.md](file:///d:/cinema_booking_v1/docs/DESIGN_TOKENS.md) — Bảng màu, typography, khoảng cách, bo góc, component chuẩn.
3. [docs/PROJECT_STRUCTURE.md](file:///d:/cinema_booking_v1/docs/PROJECT_STRUCTURE.md) — Kiến trúc Feature-first, tech stack, pubspec, đặt tên, phân tầng.
4. [docs/BUSINESS_RULES.md](file:///d:/cinema_booking_v1/docs/BUSINESS_RULES.md) — Nghiệp vụ: giữ ghế, giá vé snapshot, VNPay sandbox, soát vé, hủy vé, đồ ăn, constants.
5. [docs/ROLE_FLOWS.md](file:///d:/cinema_booking_v1/docs/ROLE_FLOWS.md) — Luồng chi tiết từng role (Guest, Customer, Staff, Manager, Admin) và ma trận màn hình S01–S31.
6. [docs/00_README.md](file:///d:/cinema_booking_v1/docs/00_README.md) — Thứ tự triển khai và quy tắc vàng khi vibe coding.

> **Quy tắc dừng:** Nếu yêu cầu của người dùng mâu thuẫn với các quy định trong bộ tài liệu trên, Agent phải **DỪNG LẠI VÀ HỎI XÁC NHẬN**, tuyệt đối không tự ý quyết định cách làm khác.

---

## 2. QUY TRÌNH THỰC THI CHO AGENT KHI NHẬN TASK

Khi nhận yêu cầu code một màn hình (screen) hoặc một tính năng (feature), Agent phải tuân thủ quy trình 4 bước:

### Bước 1: Tra cứu tài liệu (Pre-check)
- Màn hình này thuộc Role nào? Đối chiếu [ROLE_FLOWS.md](file:///d:/cinema_booking_v1/docs/ROLE_FLOWS.md).
- Màn hình này liên quan đến nghiệp vụ gì (giá, giữ ghế, thanh toán, soát vé)? Đối chiếu [BUSINESS_RULES.md](file:///d:/cinema_booking_v1/docs/BUSINESS_RULES.md).
- Màn hình này đặt ở thư mục nào theo kiến trúc Feature-first? Đối chiếu [PROJECT_STRUCTURE.md](file:///d:/cinema_booking_v1/docs/PROJECT_STRUCTURE.md).
- Các widget dùng chung và token nào cần áp dụng? Đối chiếu [DESIGN_TOKENS.md](file:///d:/cinema_booking_v1/docs/DESIGN_TOKENS.md).

### Bước 2: Liệt kê trước khi code
Trước khi ghi code, Agent phải xác định rõ:
1. Danh sách file sẽ tạo hoặc chỉnh sửa (đúng cấu trúc thư mục).
2. Widget dùng chung trong `shared/widgets/` sẽ được tái sử dụng.
3. Provider / Repository liên quan.
4. Cách xử lý đủ 3 trạng thái: **Loading** (`SkeletonBox`), **Empty** (`EmptyState`), **Error** (`ErrorState` có nút `THỬ LẠI`).

### Bước 3: Triển khai theo thứ tự nền tảng (Foundation First)
- Thứ tự chuẩn: Theme & Tokens → Shared Widgets → Data Models & Repositories & Transactions → Providers (Controllers) → Screens.
- Mỗi lần làm đúng một màn hoặc một component hoàn chỉnh. Không viết dở dang, không để `TODO`.

### Bước 4: Tự kiểm tra sau khi code (Post-check)
- [ ] UI không có bất kỳ mã màu `Color(0x...)` hay kích thước hardcode nào; 100% dùng token (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`).
- [ ] Không có `BoxShadow` hay `elevation` > 0. Nền app đúng `#181818` (`canvas`). Nút chính đúng Rosso Corsa `#DA291C` (`AppColors.primary`).
- [ ] Nhãn nút và navigation đều được `.toUpperCase()`.
- [ ] Tối đa 1 nút primary trên một màn hình.
- [ ] Mọi query của Staff và Manager đều có `.where('cinemaId', isEqualTo: currentCinemaId)`.
- [ ] Thao tác nhạy cảm (giữ ghế, thanh toán, hủy vé, soát vé) được chạy qua `FirebaseFirestore.instance.runTransaction`.
- [ ] Tiền kiểu `int` VND (không dùng `double`), VNPay gửi `amount * 100`.
- [ ] Code sạch: không có `print`, không có `TODO`.

---

## 3. CÁC ĐIỀU CẤM KỴ (STRICT INVARIANTS)

1. **CẤM** dùng Riverpod, Bloc, GetX hay bất kỳ state management nào ngoài `provider` (`ChangeNotifier`, `ProxyProvider`).
2. **CẤM** hardcode giá trị style trong file UI. Mọi màu sắc, text style, padding, border radius phải lấy từ `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`.
3. **CẤM** tự ý thêm package bên ngoài danh sách đã định nghĩa trong [PROJECT_STRUCTURE.md mục 2](file:///d:/cinema_booking_v1/docs/PROJECT_STRUCTURE.md#L30-L81).
4. **CẤM** hardcode `hashSecret` của VNPay hoặc API keys vào repo git; phải dùng `env.dart` (đã nằm trong `.gitignore`).
5. **CẤM** tính lại giá từ bảng giá hiện tại cho vé cũ; luôn sử dụng `priceSnapshot` được lưu tại thời điểm tạo booking.
6. **CẤM** tin tưởng kết quả thanh toán VNPay `vnp_ResponseCode == "00"` khi chưa xác minh chữ ký `vnp_SecureHash`.
