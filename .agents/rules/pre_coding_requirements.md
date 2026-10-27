# Ràng buộc bắt buộc: Đọc tài liệu docs trước khi code

Mọi Agent hoạt động trong dự án này phải tuân thủ nghiêm ngặt các yêu cầu sau:

## 1. Hành vi tiên quyết (Prerequisite Action)
Trước khi tạo mới hoặc sửa đổi bất kỳ tệp nguồn nào (.dart, .yaml, .rules, v.v.), Agent phải đọc các tài liệu sau trong thư mục `docs/`:
1. `docs/.cursorrules` - Luật bất biến cho AI
2. `docs/DESIGN_TOKENS.md` - Thiết kế giao diện, màu sắc, typography, spacing, radius
3. `docs/PROJECT_STRUCTURE.md` - Cấu trúc thư mục Feature-first, tech stack, phân tầng kiến trúc
4. `docs/BUSINESS_RULES.md` - Toàn bộ quy tắc nghiệp vụ (giữ ghế, giá vé snapshot, VNPay, soát vé, hủy vé)
5. `docs/ROLE_FLOWS.md` - Luồng hoạt động của 5 role (Guest, Customer, Staff, Manager, Admin)
6. `docs/00_README.md` - Hướng dẫn vibe coding và quy tắc triển khai

## 2. Tiêu chuẩn kiến trúc & code
- Quản lý trạng thái: Duy nhất `provider` (`ChangeNotifier`, `ProxyProvider`).
- Kiến trúc phân tầng: Presentation (Screen/Widget) -> Controllers (Provider) -> Repositories -> Firestore/Services.
- Giao diện: Cấm hardcode màu, text style, padding. Chỉ sử dụng token từ `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`. Không bóng đổ (`elevation: 0`).
- Bảo mật: Staff và Manager query Firestore bắt buộc có điều kiện `.where('cinemaId', isEqualTo: currentCinemaId)`.
- Giao dịch dữ liệu: Các thao tác giữ ghế, cập nhật trạng thái thanh toán, hủy vé, soát vé phải thực hiện bằng `runTransaction`.
- Dữ liệu tiền tệ: Luôn dùng `int` VND, không dùng `double`.
- Màn hình: Luôn xử lý đủ 3 trạng thái: Loading (SkeletonBox), Empty (EmptyState), Error (ErrorState kèm nút thử lại).
- Không có TODO, không print trong code cuối.
