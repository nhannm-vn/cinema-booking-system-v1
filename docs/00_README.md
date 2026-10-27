# 00_README.md — Bộ tài liệu vibe coding: Cinema Booking App (Flutter + Supabase + PostgreSQL)

> [!IMPORTANT]
> **RÀNG BUỘC BẮT BUỘC DÀNH CHO AI AGENT:** Trước khi viết hoặc sửa bất kỳ dòng code nào, Agent **BẮT BUỘC PHẢI ĐỌC** các tài liệu trong thư mục này theo đúng thứ tự quy định. Đã được thiết lập thành quy tắc tự động trong [AGENTS.md](file:///d:/cinema_booking_v1/AGENTS.md), [GEMINI.md](file:///d:/cinema_booking_v1/GEMINI.md), [.cursorrules](file:///d:/cinema_booking_v1/.cursorrules) và [TECH_STACK.md](file:///d:/cinema_booking_v1/docs/TECH_STACK.md).

## Thứ tự đưa cho AI (Cursor / Windsurf / Claude Code / Copilot / Antigravity)

| # | File | Mục đích | Khi nào đọc |
|---|------|----------|-------------|
| 1 | `.cursorrules` | Luật bất biến cho AI (công nghệ, quy ước, cấm kỵ) | Luôn luôn (system instructions) |
| 2 | `TECH_STACK.md` | Bộ công nghệ chuẩn: Supabase + PostgreSQL + RLS + RPC + Edge Functions | Đọc trước khi triển khai backend, auth, realtime, RPC |
| 3 | `DESIGN_TOKENS.md` | Bảng màu, typography, spacing, bo góc, component chuẩn | Trước khi viết bất kỳ widget/UI nào |
| 4 | `PROJECT_STRUCTURE.md` | Cấu trúc thư mục (Feature-First), pubspec, phân tầng kiến trúc | Khi tạo file/thư mục mới, kết nối layer |
| 5 | `BUSINESS_RULES.md` | Toàn bộ nghiệp vụ: giá vé snapshot, giữ ghế, VNPay, soát vé, hủy vé, hằng số | Khi viết logic / repository / RPC / UI flow |
| 6 | `ROLE_FLOWS.md` | Luồng chi tiết cho 5 role (Guest, Customer, Staff, Manager, Admin) và ma trận S01–S31 | Khi làm một màn hình hoặc luồng role |

## Cách ra lệnh cho AI (mẫu)

```text
Đọc .cursorrules, TECH_STACK.md, DESIGN_TOKENS.md, PROJECT_STRUCTURE.md, BUSINESS_RULES.md, ROLE_FLOWS.md.
Thực thi build_screen cho màn S06 - Chọn ghế (theo ROLE_FLOWS.md mục Customer bước 4, TECH_STACK.md mục 5.1).
Code hoàn chỉnh, không TODO.
```

## Quy tắc vàng khi vibe code

1. **Làm theo thứ tự:** theme & token → widget dùng chung → data layer (model, repository, RPC/Supabase) → provider → màn hình. Không nhảy màn khi chưa có nền.
2. **Mỗi lần một màn hoặc một component.** Không giao cả app trong một prompt.
3. **Luôn kiểm tra 3 trạng thái:** loading (skeleton), empty, error (có `THỬ LẠI`).
4. **Không tin code AI về nghiệp vụ tiền và ghế** nếu chưa đối chiếu `BUSINESS_RULES.md` & `TECH_STACK.md` (RPC `hold_seats` có `for update`) và kiểm thử 2 tài khoản song song.
5. **Commit sau mỗi màn** để dễ rollback khi AI sửa lan sang chỗ khác.

## Trạng thái tài liệu

- Backend đã được chuẩn hóa thống nhất theo [TECH_STACK.md](file:///d:/cinema_booking_v1/docs/TECH_STACK.md): **Supabase + PostgreSQL** thay thế toàn bộ Firebase.
- Khi có xung đột về mặt công nghệ giữa các tài liệu cũ và `TECH_STACK.md`, **`TECH_STACK.md` LUÔN THẮNG**.
