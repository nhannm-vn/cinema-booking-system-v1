# GEMINI.md — Quy tắc dự án Cinema Booking (Flutter / Firebase)

> Quy tắc này được áp dụng tự động cho Antigravity / Gemini Code Assist trong toàn bộ workspace này.

## RÀNG BUỘC TIÊN QUYẾT TRƯỚC KHI CODE (BẮT BUỘC)

Trước khi viết hoặc sửa bất kỳ mã nguồn nào, Agent **BẮT BUỘC PHẢI ĐỌC VÀ TUÂN THỦ** các tài liệu trong thư mục `docs/`:

1. [docs/.cursorrules](file:///d:/cinema_booking_v1/docs/.cursorrules) — Luật bất biến của hệ thống.
2. [docs/DESIGN_TOKENS.md](file:///d:/cinema_booking_v1/docs/DESIGN_TOKENS.md) — Quy chuẩn giao diện, màu sắc, font, spacing, bo góc, components.
3. [docs/PROJECT_STRUCTURE.md](file:///d:/cinema_booking_v1/docs/PROJECT_STRUCTURE.md) — Kiến trúc Feature-first, tech stack, phân tầng, thư mục.
4. [docs/BUSINESS_RULES.md](file:///d:/cinema_booking_v1/docs/BUSINESS_RULES.md) — Quy tắc nghiệp vụ đặt vé, giữ ghế, VNPay, soát vé, hủy vé.
5. [docs/ROLE_FLOWS.md](file:///d:/cinema_booking_v1/docs/ROLE_FLOWS.md) — Luồng thao tác của 5 role (Guest, Customer, Staff, Manager, Admin).
6. [docs/00_README.md](file:///d:/cinema_booking_v1/docs/00_README.md) — Quy tắc vàng vibe coding và thứ tự đọc tài liệu.

Xem chi tiết hướng dẫn và checklist tự kiểm tra tại [AGENTS.md](file:///d:/cinema_booking_v1/AGENTS.md).

## CÁC QUY TẮC CỐT LÕI
- **State Management:** Duy nhất `provider` (`ChangeNotifier`, `ProxyProvider`). Không dùng Bloc hay Riverpod.
- **Design Tokens:** Tuyệt đối không hardcode màu sắc, font size, padding. Chỉ dùng `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`. Không đổ bóng (`elevation: 0`).
- **Nghiệp vụ tiền & ghế:** Giữ ghế, đổi trạng thái booking, hủy vé phải qua `FirebaseFirestore.instance.runTransaction`. Tiền kiểu `int` VND. VNPay nhân 100.
- **Phân quyền rạp:** Query của Staff và Manager bắt buộc có `.where('cinemaId', isEqualTo: currentCinemaId)`.
- **Trạng thái UI:** Mọi màn hình phải có đủ 3 trạng thái: Loading (`SkeletonBox`), Empty (`EmptyState`), Error (`ErrorState` có nút THỬ LẠI).
- **Code sạch:** Không `TODO`, không `print`, nhãn nút và nav luôn `.toUpperCase()`.
