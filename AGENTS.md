# HƯỚNG DẪN VÀ RÀNG BUỘC BẮT BUỘC CHO AI AGENT (AGENTS.md)

> **QUAN TRỌNG:** Đây là quy chuẩn bắt buộc dành cho tất cả AI Agent (Antigravity, Cursor, Windsurf, Claude Code, Copilot, v.v.) khi làm việc trong dự án Cinema Booking & Operation Management App.

---

## 1. RÀNG BUỘC TIÊN QUYẾT TRƯỚC KHI VIẾT CODE (MANDATORY)

**TRƯỚC KHI** tạo mới, chỉnh sửa, hoặc refactor bất kỳ file code nào (Dart, Flutter, SQL, Edge Functions, configs, models, providers, repositories, screens, widgets):

Agent **BẮT BUỘC PHẢI ĐỌC VÀ ĐỐI CHIẾU** các tài liệu trong thư mục [docs/](file:///d:/cinema_booking_v1/docs/) theo đúng thứ tự sau:

1. [docs/.cursorrules](file:///d:/cinema_booking_v1/docs/.cursorrules) — Bộ luật bất biến: công nghệ, thiết kế, nghiệp vụ, quy ước.
2. [docs/TECH_STACK.md](file:///d:/cinema_booking_v1/docs/TECH_STACK.md) — **Bộ công nghệ chuẩn (Supabase + PostgreSQL + RLS + RPC + Edge Functions)**. Khi xung đột công nghệ với file khác, file này **LUÔN THẮNG**.
3. [docs/DESIGN_TOKENS.md](file:///d:/cinema_booking_v1/docs/DESIGN_TOKENS.md) — Bảng màu, typography, khoảng cách, bo góc, component chuẩn.
4. [docs/PROJECT_STRUCTURE.md](file:///d:/cinema_booking_v1/docs/PROJECT_STRUCTURE.md) — Kiến trúc Feature-first, tech stack, pubspec, đặt tên, phân tầng.
5. [docs/BUSINESS_RULES.md](file:///d:/cinema_booking_v1/docs/BUSINESS_RULES.md) — Nghiệp vụ: giữ ghế, giá vé snapshot, VNPay sandbox, soát vé, hủy vé, đồ ăn, constants.
6. [docs/ROLE_FLOWS.md](file:///d:/cinema_booking_v1/docs/ROLE_FLOWS.md) — Luồng chi tiết từng role (Guest, Customer, Staff, Manager, Admin) và ma trận màn hình S01–S31.
7. [docs/00_README.md](file:///d:/cinema_booking_v1/docs/00_README.md) — Thứ tự triển khai và quy tắc vàng khi vibe coding.

> **Quy tắc dừng:** Nếu yêu cầu của người dùng mâu thuẫn với các quy định trong bộ tài liệu trên, Agent phải **DỪNG LẠI VÀ HỎI XÁC NHẬN**, tuyệt đối không tự ý quyết định cách làm khác.

---

## 2. QUY TRÌNH THỰC THI CHO AGENT KHI NHẬN TASK

Khi nhận yêu cầu code một màn hình (screen) hoặc một tính năng (feature), Agent phải tuân thủ quy trình 4 bước:

### Bước 1: Tra cứu tài liệu (Pre-check)
- Màn hình này thuộc Role nào? Đối chiếu [ROLE_FLOWS.md](file:///d:/cinema_booking_v1/docs/ROLE_FLOWS.md).
- Màn hình này liên quan đến nghiệp vụ gì (giá, giữ ghế, thanh toán, soát vé)? Đối chiếu [BUSINESS_RULES.md](file:///d:/cinema_booking_v1/docs/BUSINESS_RULES.md) và RPC trong [TECH_STACK.md](file:///d:/cinema_booking_v1/docs/TECH_STACK.md).
- Màn hình này đặt ở thư mục nào theo kiến trúc Feature-first? Đối chiếu [PROJECT_STRUCTURE.md](file:///d:/cinema_booking_v1/docs/PROJECT_STRUCTURE.md).
- Các widget dùng chung và token nào cần áp dụng? Đối chiếu [DESIGN_TOKENS.md](file:///d:/cinema_booking_v1/docs/DESIGN_TOKENS.md).

### Bước 2: Liệt kê trước khi code
Trước khi ghi code, Agent phải xác định rõ:
1. Danh sách file sẽ tạo hoặc chỉnh sửa (đúng cấu trúc thư mục Feature-first).
2. Widget dùng chung trong `shared/widgets/` sẽ được tái sử dụng.
3. Provider / Repository liên quan (gọi `supabase_flutter` hoặc RPC).
4. Cách xử lý đủ 3 trạng thái: **Loading** (`SkeletonBox`), **Empty** (`EmptyState`), **Error** (`ErrorState` có nút `THỬ LẠI`).

### Bước 3: Triển khai theo thứ tự nền tảng (Foundation First)
- Thứ tự chuẩn: Theme & Tokens → Shared Widgets → Data Models & Repositories & RPC calls → Providers (Controllers) → Screens.
- Mỗi lần làm đúng một màn hoặc một component hoàn chỉnh. Không viết dở dang, không để `TODO`.

### Bước 4: Tự kiểm tra sau khi code (Post-check)
- [ ] UI không có bất kỳ mã màu `Color(0x...)` hay kích thước hardcode nào; 100% dùng token (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`).
- [ ] Không có `BoxShadow` hay `elevation` > 0. Nền app đúng `#181818` (`canvas`). Nút chính đúng Rosso Corsa `#DA291C` (`AppColors.primary`).
- [ ] Nhãn nút và navigation đều được `.toUpperCase()`.
- [ ] Tối đa 1 nút primary trên một màn hình.
- [ ] Mọi query của Staff và Manager đều có `.eq('cinema_id', currentCinemaId)` (và được DB bảo vệ bởi RLS).
- [ ] Thao tác nhạy cảm (giữ ghế, xác nhận thanh toán, hủy vé, soát vé) được chạy qua Postgres RPC (`hold_seats`, `confirm_payment`, `cancel_booking`, `check_in`).
- [ ] Tiền kiểu `int` VND (không dùng `double`).
- [ ] Code sạch: không có `print`, không có `TODO`.

---

## 3. CÁC ĐIỀU CẤM KỴ (STRICT INVARIANTS)

1. **CẤM** dùng Firebase. Toàn bộ backend chạy trên **Supabase + PostgreSQL** theo [TECH_STACK.md](file:///d:/cinema_booking_v1/docs/TECH_STACK.md).
2. **CẤM** dùng Riverpod, Bloc, GetX hay bất kỳ state management nào ngoài `provider` (`ChangeNotifier`, `ProxyProvider`).
3. **CẤM** hardcode giá trị style trong file UI. Mọi màu sắc, text style, padding, border radius phải lấy từ `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`.
4. **CẤM** đưa `service_role_key` của Supabase hoặc `VNPAY_HASH_SECRET` vào code app client Flutter. Khóa bí mật chỉ nằm trong Supabase Edge Functions. App client chỉ dùng `anonKey`.
5. **CẤM** khách hàng ghi trực tiếp vào bảng `bookings`, `seats`, `payments`. Mọi ghi dữ liệu nhạy cảm phải thông qua Postgres RPC.
6. **CẤM** tính lại giá từ bảng giá hiện tại cho vé cũ; luôn sử dụng `price_snapshot` được lưu tại thời điểm tạo booking.
7. **CẤM** tự ý thêm package bên ngoài danh sách đã định nghĩa trong [TECH_STACK.md mục 11](file:///d:/cinema_booking_v1/docs/TECH_STACK.md#L511-L565).
