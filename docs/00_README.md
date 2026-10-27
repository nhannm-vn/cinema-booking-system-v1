# 00_README.md — Bộ tài liệu vibe coding: Cinema Booking App (Flutter + Firebase)

> [!IMPORTANT]
> **RÀNG BUỘC BẮT BUỘC DÀNH CHO AI AGENT:** Trước khi viết hoặc sửa bất kỳ dòng code nào, Agent **BẮT BUỘC PHẢI ĐỌC** các tài liệu trong thư mục này theo đúng thứ tự quy định. Đã được thiết lập thành quy tắc tự động trong [AGENTS.md](file:///d:/cinema_booking_v1/AGENTS.md), [GEMINI.md](file:///d:/cinema_booking_v1/GEMINI.md) và [.cursorrules](file:///d:/cinema_booking_v1/.cursorrules).

## Thứ tự đưa cho AI (Cursor / Windsurf / Claude Code / Copilot / Antigravity)

| # | File | Mục đích | Khi nào đọc |
|---|------|----------|-------------|
| 1 | `.cursorrules` | Luật bất biến cho AI | Luôn luôn (system instructions) |
| 2 | `DESIGN_TOKENS.md` | Bảng màu, typography, spacing, bo góc, component | Trước khi viết bất kỳ widget nào |
| 3 | `PROJECT_STRUCTURE.md` | Tech stack, pubspec, cấu trúc thư mục, quy ước code, bảo mật | Khi tạo file/thư mục mới |
| 4 | `BUSINESS_RULES.md` | Nghiệp vụ: giá vé, giữ ghế, VNPay, soát vé, đồ ăn, hủy | Khi viết logic / repository / transaction |
| 5 | `ROLE_FLOWS.md` | Luồng chi tiết cho từng role (Guest, Customer, Staff, Manager, Admin) | Khi làm một màn hoặc một role |
| 6 | `DESIGN.md`, `SCREENS.md`, `DATA.md` | Chi tiết giao diện từng màn, schema Firestore, Security Rules, seed | Khi làm đúng màn/collection đó |

## Cách ra lệnh cho AI (mẫu)

```text
Đọc .cursorrules, DESIGN_TOKENS.md, PROJECT_STRUCTURE.md, BUSINESS_RULES.md, ROLE_FLOWS.md, SCREENS.md, DATA.md.
Thực thi build_screen cho màn S06 - Chọn ghế (theo SCREENS.md mục 2, ROLE_FLOWS.md mục Customer bước 4).
Code hoàn chỉnh, không TODO.
```

## Quy tắc vàng khi vibe code

1. **Làm theo thứ tự:** theme & token → widget dùng chung → data layer (model, repository, transaction) → provider → màn hình. Không nhảy màn khi chưa có nền.
2. **Mỗi lần một màn hoặc một component.** Không giao cả app trong một prompt.
3. **Luôn kiểm tra 3 trạng thái:** loading (skeleton), empty, error (có `THỬ LẠI`).
4. **Không tin code AI về nghiệp vụ tiền và ghế** nếu chưa đọc `BUSINESS_RULES.md` và chạy thử transaction với 2 tài khoản song song.
5. **Commit sau mỗi màn** để dễ rollback khi AI sửa lan sang chỗ khác.

## Trạng thái tài liệu

- Tài liệu `REQUIREMENTS.md` (nguồn nghiệp vụ gốc, mã quy tắc như PAY-01, SEAT-03…) **chưa có trong bộ gửi lên**. `BUSINESS_RULES.md` được tổng hợp từ `PROJECT.md`, `SCREENS.md`, `DATA.md` và file kit. Nếu có bản `REQUIREMENTS.md`, hãy đối chiếu lại mục 1 và mục 2 của `BUSINESS_RULES.md`.
- Các điểm chưa thống nhất giữa các tài liệu được ghi ở cuối `PROJECT_STRUCTURE.md` (mục 9) và `BUSINESS_RULES.md` (mục 10). Chốt xong trước khi code phần đó.
