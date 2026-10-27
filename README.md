# Cinema Booking & Operation Management App

Ứng dụng đặt vé xem phim và quản lý vận hành rạp (Flutter + Firebase + VNPay Sandbox).

---

## 📌 Bộ tài liệu & Ràng buộc cho AI Agent

Dự án có bộ tài liệu thiết kế và quy chuẩn nghiệp vụ chặt chẽ trong thư mục [`docs/`](./docs/):

1. [docs/.cursorrules](./docs/.cursorrules) — Bộ luật bất biến của hệ thống.
2. [docs/DESIGN_TOKENS.md](./docs/DESIGN_TOKENS.md) — Quy chuẩn giao diện (Màu sắc, Typography, Spacing, Radius, Component).
3. [docs/PROJECT_STRUCTURE.md](./docs/PROJECT_STRUCTURE.md) — Kiến trúc Feature-first, tech stack, phân tầng và quy ước code.
4. [docs/BUSINESS_RULES.md](./docs/BUSINESS_RULES.md) — Toàn bộ quy tắc nghiệp vụ (Giữ ghế, VNPay, Soát vé, Hủy vé, Đồ ăn, Hằng số).
5. [docs/ROLE_FLOWS.md](./docs/ROLE_FLOWS.md) — Luồng chi tiết từng Role (Guest, Customer, Staff, Manager, Admin).
6. [docs/00_README.md](./docs/00_README.md) — Hướng dẫn vibe coding và thứ tự áp dụng tài liệu.

> [!IMPORTANT]
> **RÀNG BUỘC CHO AI AGENT (Antigravity, Cursor, Windsurf, Claude Code, Copilot):**
> Trước khi thực hiện bất kỳ thao tác viết/sửa code nào, Agent **bắt buộc phải đọc và tuân thủ các file tài liệu trong `docs/`**.
> Chi tiết đã được cấu hình tự động tại [AGENTS.md](./AGENTS.md), [GEMINI.md](./GEMINI.md), [.cursorrules](./.cursorrules) và [`.agents/rules/pre_coding_requirements.md`](./.agents/rules/pre_coding_requirements.md).

---

## 🚀 Công nghệ sử dụng
- **Framework:** Flutter, Dart `>=3.0.0 <4.0.0`
- **State Management:** `provider` (`ChangeNotifier`, `ProxyProvider`)
- **Backend:** Cloud Firestore
- **Authentication:** Firebase Auth
- **Thanh toán:** VNPay Sandbox (`webview_flutter`, HMAC-SHA512)
- **Quét mã:** `mobile_scanner`, `qr_flutter`
- **Font & Design:** Google Fonts (Inter), Dark Cinema Theme (`#181818`), Rosso Corsa (`#DA291C`)
