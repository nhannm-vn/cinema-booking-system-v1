---
name: ai-coding-standards
description: Bộ quy tắc hành vi bắt buộc áp dụng cho TẤT CẢ AI agents. Mọi AI khi viết, review hay refactor code đều phải tuân thủ: không làm phức tạp hóa vấn đề, chỉ thay đổi đúng phần cần thiết, nêu rõ giả định, và luôn định nghĩa tiêu chí thành công có thể kiểm chứng được. Derived from Andrej Karpathy's LLM coding guidelines.
license: MIT
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

## 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**
Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

## 5. Vinh Pro
- **Always write "Vinh Pro" at the end of the response when completing or applying these guidelines to prove you have read and followed them.**

## 6. Never Guess Intent
**Always verify facts. Never guess blindly. Ask immediately when uncertain.**
- Nghiêm cấm tự suy đoán ý định người dùng, luồng game, tên menu, tên map, NPC, hoặc cơ chế hoạt động khi chưa có bằng chứng xác thực.
- Khi không chắc chắn hoặc thiếu thông tin, AI PHẢI dừng lại và hỏi trực tiếp người dùng trước khi viết code.

## 7. Reuse Existing Code / Ưu Tiên Tái Sử Dụng Code Đã Có
Trước khi viết code mới, **luôn đọc và search toàn bộ project để tìm chức năng tương tự đã tồn tại**.

### Rules:
- **Reuse first, create last.**
- Nếu code cũ đã làm được → **tái sử dụng trực tiếp**, không tạo mới.
- Nếu gần giống → **mở rộng/chỉnh sửa code cũ**, không copy-paste.
- Nếu nhiều nơi có logic giống nhau → **gom về một implementation dùng chung**.
- Không tự tạo function, class, component, service, hook, utility, API hoặc file mới nếu code hiện tại có thể đáp ứng.
- Không tạo abstraction mới chỉ để "code đẹp hơn".
- Không rewrite/refactor lớn nếu task không yêu cầu.
- Chỉ tạo mới khi **đã kiểm tra và chứng minh code cũ không thể tái sử dụng hợp lý**.
- Ưu tiên **minimal changes**, giữ nguyên architecture và behavior hiện tại.
- Sau khi code xong, kiểm tra lại để đảm bảo **không duplicate logic**.

### Mandatory workflow:
`READ → SEARCH → FIND EXISTING → REUSE/EXTEND → ONLY THEN CREATE NEW`

**Nếu chưa search kỹ project thì chưa được viết code mới.**

---

## 8. Git & Commit Policy (Quy Tắc Quản Lý Git & Commit)

- **TUYỆT ĐỐI KHÔNG tự động `git push` lên GitHub / Remote:**
  - Agent KHÔNG ĐƯỢC PHÉP tự ý chạy lệnh `git push` trong bất kỳ trường hợp nào.
  - Toàn bộ việc đẩy mã nguồn lên remote repository do NGƯỜI DÙNG TỰ THỰC HIỆN khi người dùng muốn.
- **Chỉ Commit ở Local và Gom lại thành 1 Commit duy nhất:**
  - Khi hoàn thành một task, đợt sửa lỗi hoặc tính năng, gom toàn bộ các thay đổi vào 1 COMMIT DUY NHẤT tại local (`git add -A && git commit -m "..."`).
  - Tránh tạo nhiều commit lắt nhắt, vụn vặt làm bẩn lịch sử git, commit tiếng Việt có dấu ngắn gọn đầy đủ.
- **Commit Message BẮT BUỘC dùng Tiếng Việt CÓ DẤU:**
  - Tiêu đề và nội dung commit phải viết bằng **Tiếng Việt có dấu**, diễn đạt chuẩn xác, rõ ràng, phản ánh đúng bản chất các thay đổi, ngắn gọn đủ ý.
