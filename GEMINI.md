# GEMINI.md — Quy tắc dự án Cinema Booking (Flutter / Supabase + PostgreSQL)

> Quy tắc này được áp dụng tự động cho Antigravity / Gemini Code Assist trong toàn bộ workspace này.

## RÀNG BUỘC TIÊN QUYẾT TRƯỚC KHI CODE (BẮT BUỘC)

Trước khi viết hoặc sửa bất kỳ mã nguồn nào, Agent **BẮT BUỘC PHẢI ĐỌC VÀ TUÂN THỦ** các tài liệu trong thư mục `docs/`:

1. [docs/.cursorrules](file:///d:/cinema_booking_v1/docs/.cursorrules) — Luật bất biến của hệ thống.
2. [docs/TECH_STACK.md](file:///d:/cinema_booking_v1/docs/TECH_STACK.md) — Bộ công nghệ chuẩn: **Supabase + PostgreSQL** (thay thế Firebase, luôn thắng về công nghệ).
3. [docs/DESIGN_TOKENS.md](file:///d:/cinema_booking_v1/docs/DESIGN_TOKENS.md) — Quy chuẩn giao diện, màu sắc, font, spacing, bo góc, components.
4. [docs/PROJECT_STRUCTURE.md](file:///d:/cinema_booking_v1/docs/PROJECT_STRUCTURE.md) — Kiến trúc Feature-first, tech stack, phân tầng, thư mục.
5. [docs/BUSINESS_RULES.md](file:///d:/cinema_booking_v1/docs/BUSINESS_RULES.md) — Quy tắc nghiệp vụ đặt vé, giữ ghế, VNPay, soát vé, hủy vé.
6. [docs/ROLE_FLOWS.md](file:///d:/cinema_booking_v1/docs/ROLE_FLOWS.md) — Luồng thao tác của 5 role (Guest, Customer, Staff, Manager, Admin).
7. [docs/00_README.md](file:///d:/cinema_booking_v1/docs/00_README.md) — Quy tắc vàng vibe coding và thứ tự đọc tài liệu.

Xem chi tiết hướng dẫn và checklist tự kiểm tra tại [AGENTS.md](file:///d:/cinema_booking_v1/AGENTS.md).

## CÁC QUY TẮC CỐT LÕI
- **Công nghệ Backend:** Duy nhất **Supabase** (Auth, PostgreSQL, Realtime, Storage, Edge Functions). Không dùng Firebase.
- **State Management:** Duy nhất `provider` (`ChangeNotifier`, `ProxyProvider`). Không dùng Bloc hay Riverpod.
- **Design Tokens:** Tuyệt đối không hardcode màu sắc, font size, padding. Chỉ dùng `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`. Không đổ bóng (`elevation: 0`). Nền `#181818`, màu chính Rosso Corsa `#DA291C`.
- **Nghiệp vụ tiền & ghế:** Giữ ghế (`hold_seats`), thanh toán (`confirm_payment`), hủy vé, soát vé chạy qua Postgres RPC functions. Tiền kiểu `int` VND.
- **Bảo mật:** Row Level Security (RLS) bảo vệ mọi bảng. Query Staff và Manager luôn có `.eq('cinema_id', currentCinemaId)`. Khóa bí mật (`VNPAY_HASH_SECRET`, service role key) chỉ nằm trong Supabase Edge Functions.
- **Trạng thái UI:** Mọi màn hình phải có đủ 3 trạng thái: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` có nút THỬ LẠI).
- **Code sạch:** Không `TODO`, không `print`, nhãn nút và nav luôn `.toUpperCase()`.
