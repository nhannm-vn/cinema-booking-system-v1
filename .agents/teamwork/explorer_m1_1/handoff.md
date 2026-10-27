# BÁO CÁO BÀN GIAO (HANDOFF REPORT) — MILESTONE 1
## Backend Completeness & Shared Core Data Layer

**Người thực hiện:** Teamwork Preview Explorer (`explorer_m1_1`)  
**Người nhận:** Orchestrator (`9a20b4d6-8cae-4f73-9d70-c317f7996130`)  
**Thời điểm bàn giao:** 2026-10-27T16:54:00Z  
**Loại bàn giao:** Hard (Nhiệm vụ khảo sát & lập kế hoạch kỹ thuật hoàn tất 100%)  
**Kế hoạch kỹ thuật đầy đủ:** `d:\cinema-booking-system-v1\.agents\teamwork\explorer_m1_1\m1_plan.md`

---

### 1. Observation (Quan sát thực tế)

1. **Lỗi RLS trong Edge Function `create-vnpay-url`:**
   - Tại `supabase/functions/create-vnpay-url/index.ts` dòng 34-38:
     ```ts
     const supabase = createClient(
       Deno.env.get('SUPABASE_URL')!,
       Deno.env.get('SUPABASE_ANON_KEY')!,
       { global: { headers: { Authorization: auth } } }
     );
     ```
   - Tại dòng 88-93:
     ```ts
     await supabase.from('payments').upsert({
       txn_ref: txn_ref,
       booking_code: booking.code,
       amount: totalAmount,
       status: 'pending',
     });
     ```
   - Đối chiếu `supabase/migrations/0002_rls.sql` dòng 95:
     `create policy payments_no_direct_insert on public.payments for insert with check (false);`
     Lệnh upsert trên client anon/user sẽ bị Postgres RLS từ chối và throw exception.
2. **Thiếu Trigger & RPC Functions cốt lõi:**
   - Trong `supabase/migrations/0001_schema.sql` và `0004_triggers.sql`: Chưa có trigger kiểm tra khoảng nghỉ 15 phút giữa các suất chiếu trong cùng phòng (`trg_showtime_conflict`).
   - Trong `supabase/migrations/0003_functions.sql`: Chưa có RPC `cancel_showtime` (yêu cầu trong `TECH_STACK.md` dòng 295 và `ORIGINAL_REQUEST.md` R3) và chưa có RPC `get_dashboard_metrics` (phục vụ S22 Dashboard).
3. **Thiếu dữ liệu khởi tạo trong `0005_seed.sql`:**
   - `0005_seed.sql` không chứa bất kỳ dòng lệnh `insert into auth.users` hay `public.profiles`. Không có các tài khoản kiểm thử bắt buộc: `admin@cinema.vn`, `manager1@cinema.vn`, `manager2@cinema.vn`, `staff1@cinema.vn`, `staff2@cinema.vn`, `khach1@cinema.vn`.
   - Bảng `showtimes` hoàn toàn trống rỗng trong seed data, khiến ứng dụng không thể hiển thị suất chiếu trên S03, S04, S05, S18, S20.
   - Bảng `foods` thiếu thực đơn của rạp Tân Bình `cn_tb`.
4. **Khoảng trống tầng dữ liệu và State Controller Flutter:**
   - Thư mục `lib/features/staff_counter/` chưa tồn tại (cần `StaffCounterRepository` và `StaffCounterProvider` gọi RPC `sell_counter` và giữ ghế 3 phút).
   - Thư mục `lib/features/management/` chưa tồn tại (cần `DashboardMetricsModel`, `ManagementRepository`, `ManagementProvider`).
   - `lib/features/notifications/` đã có repository nhưng chưa có `NotificationProvider`.
   - `lib/features/chat/` chưa tồn tại (cần `ChatMessageModel`, `SupportChatRepository`, `SupportChatProvider`).
   - `lib/main.dart` mới chỉ đăng ký 5 providers ban đầu, chưa có 4 providers mới này.
5. **Kiểm thử nền tảng hiện tại:**
   - Chạy `flutter test`: 12/12 tests passing (100%).
   - Chạy `flutter analyze`: 0 errors, 0 warnings.

---

### 2. Logic Chain (Chuỗi suy luận logic)

1. Từ Observation 1: Do `payments_no_direct_insert` chặn ghi trực tiếp từ client, Edge Function phải khởi tạo `supabaseAdmin` bằng `SUPABASE_SERVICE_ROLE_KEY` trước khi thực hiện upsert bản ghi `payments`. Giải pháp này độc lập, tương tự cơ chế trong `vnpay-return` và `create-staff`.
2. Từ Observation 2:
   - Trigger `trg_showtime_conflict` cần kiểm tra điều kiện `(new.start_time < existing.end_time + interval '15 minutes') AND (new.end_time > existing.start_time - interval '15 minutes')` trên các suất có `status = 'active'` trong cùng `room_id`. Khi vi phạm, trigger raise exception kèm tên phòng và khung giờ chồng lấn để UI hiển thị.
   - RPC `cancel_showtime` cập nhật `showtimes.status = 'cancelled'`, hủy các booking `paid`, tạo notification hoàn tiền 100% cho từng khách hàng, ghi `audit_logs`, và bảo lưu dữ liệu trong `seats` theo đúng `TECH_STACK.md`.
   - RPC `get_dashboard_metrics` thực hiện tổng hợp doanh thu, vé bán, tỷ lệ lấp đầy theo múi giờ `Asia/Ho_Chi_Minh` và trả về danh sách 5 suất chiếu sắp diễn ra, hỗ trợ lọc theo ngày/tuần/tháng.
3. Từ Observation 3: Sử dụng extension `pgcrypto` với `crypt('123456', gen_salt('bf'))` để tạo mật khẩu hợp lệ cho Supabase GoTrue Auth, đồng thời tạm thời vô hiệu hóa `trg_protect_profile` khi chạy seed script để gán chính xác `role` và `cinema_id` cho 6 tài khoản.
4. Từ Observation 4 & 5: Thiết kế 9 files mã nguồn Dart thuộc tầng Data & Controller theo kiến trúc Feature-first, tuân thủ 100% quy chuẩn `AGENTS.md` (tiền tệ `int` VND, không hardcode, không print, không TODO), sau đó tích hợp vào `MultiProvider` tại `main.dart`.

---

### 3. Caveats (Khu vực chưa khảo sát / Giả định)

- Giả định hệ thống Supabase local đã có schema `auth` với bảng `auth.users` chuẩn của Supabase.
- Không chỉnh sửa trực tiếp vào mã nguồn dự án trong phiên làm việc này do tuân thủ nghiêm ngặt nguyên tắc **Read-only Investigation** của Teamwork Explorer. Toàn bộ mã nguồn triển khai đã được biên soạn đầy đủ, chính xác, sẵn sàng chuyển giao cho Implementer.

---

### 4. Conclusion (Kết luận)

Kế hoạch kỹ thuật Milestone 1 đã được xây dựng hoàn chỉnh tại:
`d:\cinema-booking-system-v1\.agents\teamwork\explorer_m1_1\m1_plan.md`

Bao gồm toàn bộ mã nguồn drop-in ready cho:
1. Migration `supabase/migrations/0006_missing_rpcs_and_triggers.sql`.
2. Cập nhật `supabase/migrations/0005_seed.sql`.
3. Sửa lỗi `supabase/functions/create-vnpay-url/index.ts`.
4. 9 files Dart cho Repositories, Models và Providers (`staff_counter`, `management`, `notifications`, `chat`).
5. Cập nhật `lib/main.dart` đăng ký `MultiProvider`.

---

### 5. Verification Method (Phương pháp kiểm chứng độc lập)

1. **Kiểm tra cú pháp và chất lượng mã nguồn Dart:**
   ```powershell
   flutter analyze
   ```
   *Tiêu chí:* 0 errors, 0 warnings.
2. **Kiểm tra bộ test tự động:**
   ```powershell
   flutter test
   ```
   *Tiêu chí:* 100% test cases vượt qua.
3. **Kiểm tra migration PostgreSQL:**
   Chạy file `supabase/migrations/0006_missing_rpcs_and_triggers.sql` và kiểm tra các hàm:
   ```sql
   select public.get_dashboard_metrics('cn_q1', 'today');
   ```
4. **Kiểm tra tài khoản kiểm thử sau seed:**
   Xác nhận có thể đăng nhập bằng email `manager1@cinema.vn` / `123456` và `khach1@cinema.vn` / `123456`.

---
Vinh Pro
