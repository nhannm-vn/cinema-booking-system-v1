# BÁO CÁO TOÀN DIỆN AUDIT BACKEND & SUPABASE
**Dự án:** Cinema Booking & Operation Management Application  
**Ngày thực hiện:** 2026-10-27  
**Phạm vi:** Thư mục `supabase/`, schema PostgreSQL, RLS policies, Postgres RPC functions, Edge Functions, Seed data & VNPay Sandbox  
**Tham chiếu tài liệu chuẩn:** `docs/TECH_STACK.md`, `docs/BUSINESS_RULES.md`, `docs/ROLE_FLOWS.md`, `ORIGINAL_REQUEST.md`

---

## 1. TỔNG QUAN TÀI NGUYÊN SUPABASE HIỆN CÓ

```text
supabase/
├── config.toml                     # Cấu hình ports, API, Auth, Storage, Realtime
├── migrations/
│   ├── 0001_schema.sql             # 15 bảng, chỉ mục (index), ràng buộc (constraints)
│   ├── 0002_rls.sql                # Row Level Security trên 15 bảng & helper functions
│   ├── 0003_functions.sql          # 7 Postgres RPC functions xử lý nghiệp vụ
│   ├── 0004_triggers.sql           # Trigger profile creation & bảo vệ nâng quyền
│   └── 0005_seed.sql               # Seed data: rạp, phòng, phim, đồ ăn, voucher, giá
└── functions/
    ├── create-staff/index.ts       # Edge function tạo Staff/Manager bằng Service Role
    ├── create-vnpay-url/index.ts   # Edge function ký HMAC-SHA512 tạo URL VNPay Sandbox
    └── vnpay-return/index.ts       # Edge function nhận callback VNPay & gọi confirm_payment
```

---

## 2. KIỂM TOÁN SCHEMA DATABASE & QUAN HỆ DỮ LIỆU

### 2.1 Danh sách bảng trong `0001_schema.sql` (15 bảng)

| STT | Tên bảng | Khóa chính | Ràng buộc & Khóa ngoại | Ghi chú kiến trúc |
|---|---|---|---|---|
| 1 | `cinemas` | `id text` (`cn_q1`, `cn_tb`) | `lat`, `lng double precision`, `is_active bool` | Rạp chiếu & tọa độ GPS |
| 2 | `profiles` | `id uuid references auth.users(id)` | `role in ('customer', 'staff', 'manager', 'admin')`, `cinema_id references cinemas(id)`, `is_locked bool` | Hồ sơ người dùng đồng bộ Auth |
| 3 | `rooms` | `id uuid` | `cinema_id references cinemas(id)`, `formats text[]`, `seat_layout text[]`, `seat_count int` | Phòng chiếu & ma trận ghế |
| 4 | `movies` | `id uuid` | `age_rating in ('P', 'T13', 'T16', 'T18')`, `duration_min int`, `is_active bool` | Phim đang & sắp chiếu |
| 5 | `foods` | `id uuid` | `cinema_id references cinemas(id)`, `category in ('combo', 'popcorn', 'drink', 'snack')`, `price int` | Bắp, nước, combo |
| 6 | `showtimes` | `id uuid` | `movie_id`, `cinema_id`, `room_id`, `format in ('2D', '3D', 'IMAX')`, `status in ('active', 'cancelled')` | Suất chiếu |
| 7 | `bookings` | `code text (char_length=8)` | `user_id`, `showtime_id`, `cinema_id`, `status in ('holding', 'paid', 'used', 'cancelled', 'expired')`, `seats jsonb`, `foods jsonb`, `price_snapshot jsonb` | Đơn vé & vé điện tử (QR) |
| 8 | `seats` | `(showtime_id, seat_id)` composite | `status in ('holding', 'sold')`, `booking_code references bookings(code)`, `hold_holder`, `hold_until` | Trạng thái ghế realtime |
| 9 | `payments` | `txn_ref text` | `booking_code references bookings(code)`, `status in ('pending', 'success', 'failed', 'expired')` | Giao dịch thanh toán |
| 10 | `notifications` | `id uuid` | `user_id references profiles(id)`, `type in ('bookingPaid', 'showReminder', ...)` | Thông báo người dùng |
| 11 | `pricing_settings` | `id int = 1` | `base_2d`, `base_3d`, `base_imax`, `surcharge_vip`, `surcharge_couple`, `surcharge_weekend`, `surcharge_prime` | Cấu hình bảng giá động |
| 12 | `vouchers` | `code text` | `type in ('percent', 'amount')`, `value int`, `max_uses int`, `used_count int` | Mã voucher |
| 13 | `audit_logs` | `id uuid` | `actor_id`, `actor_role`, `cinema_id`, `action`, `target_type`, `target_id` | Nhật ký thao tác quản trị |
| 14 | `conversations` | `id text (user_id || '_' || cinema_id)` | `user_id`, `cinema_id` | Phiên chat hỗ trợ |
| 15 | `messages` | `id uuid` | `conversation_id`, `sender_id`, `booking_code` | Tin nhắn chat |

### 2.2 Đối chiếu với danh sách bảng trong yêu cầu nhiệm vụ (Clarification)
Yêu cầu nhiệm vụ liệt kê: `users/profiles, cinemas, rooms, seat_layouts, seats, movies, showtimes, bookings, booking_seats, tickets, foods, booking_foods, vouchers, audit_logs`.
- **`seat_layouts`**: Không tách thành bảng riêng; được lưu dạng mảng chuỗi `seat_layout text[]` ngay trong bảng `rooms` (ví dụ `{"S,S,S,S", "V,V,V,V", "C,C"}`). Cách làm này đúng 100% với đặc tả `TECH_STACK.md` mục 4 và `rooms` table DDL.
- **`booking_seats` và `booking_foods`**: Không tách thành bảng quan hệ 1-nhiều. Toàn bộ danh sách ghế (`[{"id": "A1", "type": "standard", "price": 80000}]`) và món ăn (`[{"food_id": "...", "name": "Bắp", "qty": 1, "unit_price": 65000}]`) được lưu dạng `jsonb` ngay trong bảng `bookings`. Thiết kế này được quy định rõ trong `TECH_STACK.md` mục 4.1: *“không lưu seats vào bảng riêng cho booking... Hai nơi này phải khớp, hàm hold_seats đảm bảo điều đó.”*
- **`tickets`**: Không tách thành bảng riêng; mỗi đơn `bookings` với mã 8 ký tự duy nhất chính là vé điện tử (mã QR encode trực tiếp mã booking 8 ký tự).
- **`seats`**: Bảng `seats` độc lập theo cặp `(showtime_id, seat_id)` chỉ lưu các ghế đang có trạng thái `holding` hoặc `sold` để phục vụ Supabase Realtime Stream vẽ sơ đồ ghế và kiểm tra chống trùng khóa dòng.

---

## 3. KIỂM TOÁN BẢO MẬT ROW LEVEL SECURITY (RLS)

### 3.1 Trạng thái kích hoạt RLS
Toàn bộ **15/15 bảng** trong `0002_rls.sql` đều đã được chạy `alter table ... enable row level security;`. Không có bảng nào bị bỏ sót.

### 3.2 Đánh giá các hàm trợ giúp (Helper Functions)
- `current_role_name()`:
  ```sql
  select role from public.profiles where id = auth.uid() and not is_locked;
  ```
  *Đánh giá:* **Xuất sắc**. Nếu tài khoản bị khóa (`is_locked = true`), hàm trả về `null`. Khi đó mọi policy kiểm tra role đều không khớp, user bị vô hiệu hóa quyền tức thì.
- `current_cinema()`:
  ```sql
  select cinema_id from public.profiles where id = auth.uid();
  ```
  *Đánh giá:* Phục vụ cô lập dữ liệu theo rạp cho Staff và Manager.

### 3.3 Đánh giá các Policies then chốt
1. **Bảng `bookings`**:
   - `SELECT`: Cho phép khách xem vé của chính mình (`user_id = auth.uid()`), Admin xem toàn bộ, Staff/Manager chỉ xem booking của rạp mình (`cinema_id = current_cinema()`).
   - `INSERT`, `UPDATE`, `DELETE`: **CẤM HOÀN TOÀN TỪ PHÍA CLIENT** (`with check (false)`, `using (false)`). Bắt buộc 100% thao tác thay đổi phải đi qua Postgres RPC functions.
2. **Bảng `seats`**:
   - `SELECT`: Khách đã đăng nhập được đọc trạng thái ghế của suất để vẽ sơ đồ Realtime.
   - `INSERT`, `UPDATE`, `DELETE`: Cấm ghi trực tiếp từ client (`check (false)`).
3. **Bảng `profiles`**:
   - Khách chỉ update được profile của mình, đồng thời có trigger `trg_protect_profile` (trong `0004_triggers.sql`) cưỡng chế giữ nguyên `role`, `cinema_id`, `is_locked` nếu người sửa không phải Admin.
4. **Bảng `foods`, `showtimes`**:
   - Public đọc; chỉ Manager (của rạp đó) và Admin mới có quyền thêm/sửa/xóa.
5. **Bảng `audit_logs`**:
   - Chỉ Admin được xem. Authenticated users được ghi nhận qua RPC.

---

## 4. KIỂM TOÁN CÁC HÀM POSTGRES RPC FUNCTIONS

Tập tin `0003_functions.sql` hiện định nghĩa 7 hàm RPC:

### 4.1 Chi tiết 7 hàm hiện có

| STT | Tên hàm RPC | Quyền thực thi & Concurrency Lock | Đánh giá tính toàn vẹn |
|---|---|---|---|
| 1 | `hold_seats` | `auth.uid()`, khóa dòng `showtimes for update` | **Hoàn chỉnh**: Giới hạn ≤ 8 ghế; nhả đơn holding cũ; khóa suất chống race condition; upsert vào `seats` và `bookings`. |
| 2 | `confirm_payment` | Service Role, khóa dòng `bookings for update` | **Hoàn chỉnh**: Kiểm tra trạng thái `holding`, hạn giữ, khớp số tiền snapshot; đổi `seats` sang `sold`; tăng `showtimes.sold_seats`; đổi booking sang `paid`; cập nhật `payments`; tạo notification. |
| 3 | `release_hold` | Chủ sở hữu đơn | **Hoàn chỉnh**: Xóa dòng holding trong `seats`, chuyển `bookings.status = 'expired'`, `payments.status = 'expired'`. |
| 4 | `check_in` | Staff/Manager của rạp, khóa dòng `bookings for update` | **Hoàn chỉnh**: Kiểm tra đủ 6 điều kiện thời gian & trạng thái; báo lỗi chi tiết (WRONG_CINEMA, TOO_EARLY, EXPIRED_SHOWTIME, CANCELLED, ALREADY_USED); chuyển `used`; ghi `audit_logs`. |
| 5 | `deliver_food` | Staff/Manager của rạp, khóa dòng `bookings for update` | **Hoàn chỉnh**: Kiểm tra đúng rạp; `food_status = 'pending'`; chuyển sang `'delivered'`; ghi nhận người giao và thời điểm giao; tạo notification. |
| 6 | `cancel_booking` | Khách (≥ 2h trước giờ chiếu) hoặc Manager/Admin | **Hoàn chỉnh**: Trả ghế (xóa khỏi `seats`); giảm `sold_seats`; đổi trạng thái sang `'cancelled'`; tạo notification hoàn tiền; ghi `audit_logs`. |
| 7 | `sell_counter` | Staff/Manager của rạp, khóa dòng `showtimes for update` | **Hoàn chỉnh**: Bán trực tiếp tại quầy; ghi ghế `sold`; booking `paid` với kênh `'counter'`. |

### 4.2 CÁC HÀM VÀ LOGIC BỊ THIẾU CẦN BỔ SUNG

Qua đối chiếu với `ORIGINAL_REQUEST.md` (mục R3) và `docs/TECH_STACK.md` (mục 5.3):

1. **THIẾU RPC `get_dashboard_metrics` (S22 Dashboard)**:
   - *Yêu cầu:* Quản lý xem các chỉ số hôm nay: Doanh thu trong ngày, số vé bán, tỷ lệ lấp đầy phòng chiếu (occupancy rate), danh sách suất sắp chiếu theo rạp (`cinema_id`).
   - *Hiện trạng:* Chưa có hàm RPC này trong DB.
2. **THIẾU RPC `cancel_showtime` (S14 Quản lý suất chiếu)**:
   - *Yêu cầu:* `TECH_STACK.md` dòng 295 và `BUSINESS_RULES.md` mục 10.3: Cho phép Manager/Admin hủy một suất chiếu: Khóa suất, tự động chuyển toàn bộ các đơn `paid` của suất đó sang `cancelled`, gửi thông báo cho từng khách, ghi `audit_logs`, nhưng **không xóa dữ liệu seats** để đối soát.
   - *Hiện trạng:* Chưa được viết trong `0003_functions.sql`.
3. **THIẾU Trigger hoặc Function kiểm tra xung đột suất chiếu 15 phút (S14)**:
   - *Yêu cầu:* `ORIGINAL_REQUEST.md` mục R3 và Acceptance Criteria: *"Creating a showtime overlapping an existing showtime within 15 minutes is rejected with a conflict error."*
   - *Hiện trạng:* Trong `0001_schema.sql` và `0004_triggers.sql` chưa có trigger hay constraint nào ở tầng DB để chặn việc tạo 2 suất trùng nhau trong cùng một phòng cách nhau dưới 15 phút nghỉ. Cần bổ sung trigger `trg_check_showtime_conflict`.

---

## 5. KIỂM TOÁN TÀI KHOẢN MẪU & SEED DATA (`0005_seed.sql`)

### 5.1 Dữ liệu đã có trong `0005_seed.sql`
- `pricing_settings`: Giá chuẩn (2D: 80k, 3D: 100k, IMAX: 120k; phụ thu VIP 20k, Couple 20k, Cuối tuần 10k, Giờ vàng 10k).
- `cinemas`: 2 rạp (`cn_q1` - Cinema Star Quận 1, `cn_tb` - Cinema Star Tân Bình).
- `rooms`: 3 phòng chiếu (Phòng 1 IMAX & Phòng 2 Standard tại `cn_q1`, Phòng 1 tại `cn_tb`).
- `movies`: 3 phim (Oppenheimer, Dune 2, Kẻ Trộm Mặt Trăng 4) kèm trailer, poster, age rating.
- `foods`: 4 món tại `cn_q1` (Combo Solo, Combo Couple, Bắp Phô Mai, Coca Cola).
- `vouchers`: 2 voucher (`CINEMA20`, `VIP50K`).

### 5.2 THIẾU SÓT NGHIÊM TRỌNG TRONG SEED DATA

1. **CHƯA CÓ SEED TÀI KHOẢN AUTH & PROFILES**:
   Trong `0005_seed.sql` hoàn toàn **KHÔNG CÓ DÒNG NÀO** chèn vào `auth.users` và `public.profiles`.
   Các tài khoản kiểm thử bắt buộc theo `BUSINESS_RULES.md` mục 2 và `ORIGINAL_REQUEST.md`:
   - `admin@cinema.vn` / `123456` (role: `admin`)
   - `manager1@cinema.vn` / `123456` (role: `manager`, rạp: `cn_q1`)
   - `manager2@cinema.vn` / `123456` (role: `manager`, rạp: `cn_tb`)
   - `staff1@cinema.vn` / `123456` (role: `staff`, rạp: `cn_q1`)
   - `staff2@cinema.vn` / `123456` (role: `staff`, rạp: `cn_tb`)
   - `khach1@cinema.vn` / `123456` (role: `customer`)
   *Hậu quả:* Khi khởi động Supabase local hoặc reset DB, không thể đăng nhập kiểm thử ngay mà phải dùng UI hoặc gọi API đăng ký thủ công.
2. **CHƯA CÓ SEED SUẤT CHIẾU (`showtimes`)**:
   Bảng `showtimes` hoàn toàn trống rỗng trong `0005_seed.sql`. Nếu không có suất chiếu hôm nay và các ngày tới, màn hình Trang chủ S03, Chi tiết phim S04, Chọn suất S05, Sơ đồ ghế S06, Soát vé S18, Bán vé quầy S20 đều không có dữ liệu để hoạt động.
3. **CHƯA CÓ SEED MÓN ĂN CHO RẠP `cn_tb`**:
   Bảng `foods` chỉ mới có 4 món của `cn_q1`, rạp Tân Bình (`cn_tb`) chưa có món nào.
4. **CHƯA CÓ SEED VÉ MẪU ĐỂ TEST SOÁT VÉ VÀ QUẦY ĐỒ ĂN**:
   Cần có ít nhất 1-2 booking mẫu trạng thái `paid` (có đồ ăn `pending`) để kiểm thử tức thì màn hình Soát vé S18 và Quầy bếp S19.

---

## 6. KIỂM TOÁN VNPAY SANDBOX & EDGE FUNCTIONS

### 6.1 `create-staff` (`supabase/functions/create-staff/index.ts`)
- Kiểm tra JWT người gọi, chỉ cho phép Manager (tạo Staff cho rạp mình) hoặc Admin.
- Sử dụng `SUPABASE_SERVICE_ROLE_KEY` gọi `auth.admin.createUser` và cập nhật `profiles`.
- Khóa bảo mật: Không bị lộ service role key ra app client. **Đạt chuẩn**.

### 6.2 `create-vnpay-url` (`supabase/functions/create-vnpay-url/index.ts`)
- Đọc `price_snapshot.total` từ DB, không nhận tiền từ client. Ký HMAC-SHA512 an toàn.
- **LỖI BẢO MẬT/RUNTIME CRITICAL PHÁT HIỆN ĐƯỢC:**
  Tại dòng 35-37, hàm tạo client `supabase` bằng `SUPABASE_ANON_KEY` kèm Authorization header của user:
  ```ts
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: auth } } }
  );
  ```
  Sau đó ở dòng 88-93, hàm thực hiện:
  ```ts
  await supabase.from('payments').upsert({
    txn_ref: txn_ref,
    booking_code: booking.code,
    amount: totalAmount,
    status: 'pending',
  });
  ```
  **Vấn đề:** Trong `0002_rls.sql`, bảng `payments` có policy:
  `create policy payments_no_direct_insert on public.payments for insert with check (false);`
  Vì vậy lệnh `upsert` này với client anon/user **SẼ BỊ POSTGRES TỪ CHỐI BỞI RLS**!
  **Cách khắc phục:** Cần dùng `SUPABASE_SERVICE_ROLE_KEY` khi tạo bản ghi vào `payments`.

### 6.3 `vnpay-return` (`supabase/functions/vnpay-return/index.ts`)
- Xác minh `vnp_SecureHash` bằng thuật toán HMAC-SHA512.
- Kiểm tra số tiền `vnp_Amount / 100`.
- Dùng `SUPABASE_SERVICE_ROLE_KEY` gọi RPC `confirm_payment`.
- Chuyển hướng app bằng deep link `cinemaapp://payment-success?code=...` hoặc `cinemaapp://payment-failed`.
- **Đạt chuẩn**. Khuyến nghị: Bổ sung phản hồi JSON cho trường hợp IPN webhook server-to-server.

---

## 7. ĐỀ XUẤT NÂNG CẤP & MÃ NGUỒN BỔ SUNG CHI TIẾT

### 7.1 Đề xuất Migration `0006_missing_rpcs_and_triggers.sql`

```sql
-- 1. Trigger kiểm tra xung đột suất chiếu trong phòng (cách nhau tối thiểu 15 phút)
create or replace function public.check_showtime_conflict()
returns trigger language plpgsql as $$
declare
  v_conflict record;
begin
  select s.id, s.start_time, s.end_time into v_conflict
  from public.showtimes s
  where s.room_id = new.room_id
    and s.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
    and s.status = 'active'
    -- Suất mới bắt đầu trước khi suất cũ kết thúc + 15 phút, và kết thúc sau khi suất cũ bắt đầu - 15 phút
    and (new.start_time < (s.end_time + interval '15 minutes'))
    and (new.end_time > (s.start_time - interval '15 minutes'))
  limit 1;

  if v_conflict.id is not null then
    raise exception 'SHOWTIME_CONFLICT: Phòng đã có suất từ % đến % (khoảng nghỉ tối thiểu 15 phút)',
      to_char(v_conflict.start_time, 'HH24:MI'), to_char(v_conflict.end_time, 'HH24:MI');
  end if;

  return new;
end;
$$;

drop trigger if exists trg_showtime_conflict on public.showtimes;
create trigger trg_showtime_conflict
  before insert or update on public.showtimes
  for each row execute function public.check_showtime_conflict();

-- 2. RPC cancel_showtime: Hủy suất chiếu (Manager / Admin)
create or replace function public.cancel_showtime(
  p_showtime_id uuid,
  p_reason text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_cid text;
  v_st public.showtimes%rowtype;
  v_bk record;
  v_count int := 0;
begin
  select role, cinema_id into v_role, v_cid from public.profiles where id = v_uid;
  if v_role not in ('manager', 'admin') then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select * into v_st from public.showtimes where id = p_showtime_id for update;
  if not found then raise exception 'SHOWTIME_NOT_FOUND'; end if;
  if v_role = 'manager' and v_st.cinema_id <> v_cid then
    raise exception 'WRONG_CINEMA';
  end if;

  -- Đổi trạng thái suất
  update public.showtimes
  set status = 'cancelled', cancel_reason = p_reason
  where id = p_showtime_id;

  -- Hủy tất cả booking paid của suất
  for v_bk in select * from public.bookings where showtime_id = p_showtime_id and status = 'paid' loop
    update public.bookings
    set status = 'cancelled',
        food_status = case when food_status = 'pending' then 'cancelled' else food_status end,
        cancel_reason = 'Suất chiếu bị hủy: ' || p_reason,
        cancelled_by = v_uid,
        cancelled_at = now()
    where code = v_bk.code;

    if v_bk.user_id is not null then
      insert into public.notifications (user_id, type, title, body, booking_code)
      values (v_bk.user_id, 'showtimeCancelled', 'Suất chiếu đã bị hủy',
              'Suất chiếu phim ' || v_bk.movie_title || ' đã bị hủy do: ' || p_reason || '. Bạn được hoàn tiền 100%.',
              v_bk.code);
    end if;

    v_count := v_count + 1;
  end loop;

  -- Ghi nhật ký audit
  insert into public.audit_logs (actor_id, actor_role, cinema_id, action, target_type, target_id, reason)
  values (v_uid, v_role, v_st.cinema_id, 'cancelShowtime', 'showtime', p_showtime_id::text, p_reason);

  return jsonb_build_object('success', true, 'cancelled_bookings_count', v_count);
end;
$$;

-- 3. RPC get_dashboard_metrics: Số liệu vận hành cho S22 Dashboard
create or replace function public.get_dashboard_metrics(
  p_cinema_id text,
  p_date date default current_date
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_cid text;
  v_today_revenue bigint := 0;
  v_today_tickets bigint := 0;
  v_total_capacity bigint := 0;
  v_sold_capacity bigint := 0;
  v_occupancy_rate numeric := 0.0;
  v_upcoming_showtimes jsonb;
begin
  select role, cinema_id into v_role, v_cid from public.profiles where id = v_uid;
  if v_role not in ('manager', 'admin') then
    raise exception 'NOT_AUTHORIZED';
  end if;
  if v_role = 'manager' and p_cinema_id <> v_cid then
    raise exception 'WRONG_CINEMA';
  end if;

  -- Doanh thu & vé trong ngày
  select
    coalesce(sum((price_snapshot->>'total')::bigint), 0),
    coalesce(sum(jsonb_array_length(seats)), 0)
  into v_today_revenue, v_today_tickets
  from public.bookings
  where cinema_id = p_cinema_id
    and status in ('paid', 'used')
    and date(created_at at time zone 'Asia/Ho_Chi_Minh') = p_date;

  -- Tỷ lệ lấp đầy
  select
    coalesce(sum(total_seats), 0),
    coalesce(sum(sold_seats), 0)
  into v_total_capacity, v_sold_capacity
  from public.showtimes
  where cinema_id = p_cinema_id
    and status = 'active'
    and date(start_time at time zone 'Asia/Ho_Chi_Minh') = p_date;

  if v_total_capacity > 0 then
    v_occupancy_rate := round((v_sold_capacity::numeric / v_total_capacity::numeric) * 100, 1);
  end if;

  -- Danh sách 5 suất sắp chiếu
  select coalesce(jsonb_agg(item), '[]'::jsonb)
  into v_upcoming_showtimes
  from (
    select
      s.id,
      m.title as movie_title,
      r.name as room_name,
      s.format,
      s.start_time,
      s.total_seats,
      s.sold_seats
    from public.showtimes s
    join public.movies m on m.id = s.movie_id
    join public.rooms r on r.id = s.room_id
    where s.cinema_id = p_cinema_id
      and s.status = 'active'
      and s.start_time >= now()
    order by s.start_time asc
    limit 5
  ) item;

  return jsonb_build_object(
    'cinema_id', p_cinema_id,
    'date', p_date,
    'today_revenue', v_today_revenue,
    'today_tickets', v_today_tickets,
    'occupancy_rate', v_occupancy_rate,
    'total_capacity', v_total_capacity,
    'sold_capacity', v_sold_capacity,
    'upcoming_showtimes', v_upcoming_showtimes
  );
end;
$$;
```

### 7.2 Đề xuất Script Seed Auth Users & Suất chiếu (`supabase/seed.sql`)

```sql
-- Kích hoạt pgcrypto để băm mật khẩu
create extension if not exists pgcrypto;

-- 1. Tạo auth users mặc định (password: 123456)
do $$
declare
  v_enc_pass text := crypt('123456', gen_salt('bf'));
  uid_admin uuid := 'a0000000-0000-0000-0000-000000000001';
  uid_mgr1  uuid := 'a0000000-0000-0000-0000-000000000002';
  uid_mgr2  uuid := 'a0000000-0000-0000-0000-000000000003';
  uid_stf1  uuid := 'a0000000-0000-0000-0000-000000000004';
  uid_stf2  uuid := 'a0000000-0000-0000-0000-000000000005';
  uid_kh1   uuid := 'a0000000-0000-0000-0000-000000000006';
begin
  -- Chèn auth.users
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, role, aud)
  values
    (uid_admin, '00000000-0000-0000-0000-000000000000', 'admin@cinema.vn', v_enc_pass, now(), '{"full_name": "Quản Trị Viên Hệ Thống"}'::jsonb, 'authenticated', 'authenticated'),
    (uid_mgr1,  '00000000-0000-0000-0000-000000000000', 'manager1@cinema.vn', v_enc_pass, now(), '{"full_name": "Quản Lý Quận 1"}'::jsonb, 'authenticated', 'authenticated'),
    (uid_mgr2,  '00000000-0000-0000-0000-000000000000', 'manager2@cinema.vn', v_enc_pass, now(), '{"full_name": "Quản Lý Tân Bình"}'::jsonb, 'authenticated', 'authenticated'),
    (uid_stf1,  '00000000-0000-0000-0000-000000000000', 'staff1@cinema.vn', v_enc_pass, now(), '{"full_name": "Nhân Viên Soát Vé Q1"}'::jsonb, 'authenticated', 'authenticated'),
    (uid_stf2,  '00000000-0000-0000-0000-000000000000', 'staff2@cinema.vn', v_enc_pass, now(), '{"full_name": "Nhân Viên Soát Vé TB"}'::jsonb, 'authenticated', 'authenticated'),
    (uid_kh1,   '00000000-0000-0000-0000-000000000000', 'khach1@cinema.vn', v_enc_pass, now(), '{"full_name": "Nguyễn Văn Khách"}'::jsonb, 'authenticated', 'authenticated')
  on conflict (id) do nothing;

  -- Chèn profiles
  insert into public.profiles (id, full_name, phone, role, cinema_id, is_locked)
  values
    (uid_admin, 'Quản Trị Viên Hệ Thống', '0901000001', 'admin', null, false),
    (uid_mgr1,  'Quản Lý Quận 1', '0901000002', 'manager', 'cn_q1', false),
    (uid_mgr2,  'Quản Lý Tân Bình', '0901000003', 'manager', 'cn_tb', false),
    (uid_stf1,  'Nhân Viên Soát Vé Q1', '0901000004', 'staff', 'cn_q1', false),
    (uid_stf2,  'Nhân Viên Soát Vé TB', '0901000005', 'staff', 'cn_tb', false),
    (uid_kh1,   'Nguyễn Văn Khách', '0901000006', 'customer', null, false)
  on conflict (id) do update set
    full_name = excluded.full_name,
    role = excluded.role,
    cinema_id = excluded.cinema_id,
    is_locked = excluded.is_locked;
end $$;

-- 2. Chèn Suất chiếu mẫu (Hôm nay & Ngày mai)
insert into public.showtimes (id, movie_id, cinema_id, room_id, format, start_time, end_time, status, total_seats, sold_seats)
values
  -- Suất Oppenheimer tại cn_q1 Phòng IMAX
  ('b1111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'cn_q1', '11111111-1111-1111-1111-111111111111', 'IMAX', now() + interval '1 hour', now() + interval '4 hours', 'active', 75, 0),
  -- Suất Dune 2 tại cn_q1 Phòng 2
  ('b2222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555555', 'cn_q1', '22222222-2222-2222-2222-222222222222', '2D', now() + interval '2 hours', now() + interval '4 hours 46 minutes', 'active', 44, 0),
  -- Suất Despicable Me 4 tại cn_tb
  ('b3333333-3333-3333-3333-333333333333', '66666666-6666-6666-6666-666666666666', 'cn_tb', '33333333-3333-3333-3333-333333333333', '2D', now() + interval '1 hour 30 minutes', now() + interval '3 hours 5 minutes', 'active', 52, 0)
on conflict (id) do nothing;
```

### 7.3 Sửa lỗi Edge Function `create-vnpay-url`

Tại `supabase/functions/create-vnpay-url/index.ts`:
Thay vì dùng client anon `supabase` để chèn vào `payments`, khởi tạo `supabaseAdmin` bằng `SUPABASE_SERVICE_ROLE_KEY` cho thao tác upsert:

```ts
// Dùng service role client để upsert payment record (vượt qua RLS payments_no_direct_insert)
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

await supabaseAdmin.from('payments').upsert({
  txn_ref: txn_ref,
  booking_code: booking.code,
  amount: totalAmount,
  status: 'pending',
});
```

---

## 8. KẾT LUẬN KIỂM TOÁN VÀ ĐÁNH GIÁ SẴN SÀNG

1. **Khung kiến trúc chung:** Cơ sở dữ liệu và hạ tầng Supabase bám sát và tuân thủ chặt chẽ kiến trúc trong `docs/TECH_STACK.md` và `docs/BUSINESS_RULES.md`. Thiết kế JSONB cho `seats`, `foods`, `price_snapshot` trong `bookings` là hoàn toàn đúng đắn, tối ưu hóa giao dịch khóa suất và hiệu năng đọc ghi.
2. **Hệ thống RLS:** Được kích hoạt 100% trên cả 15 bảng, bảo vệ triệt để quyền dữ liệu từ phía database.
3. **Các lỗ hổng cần xử lý ngay:**
   - [x] Lỗi client anon trong Edge Function `create-vnpay-url` dẫn tới RLS vi phạm khi ghi bảng `payments`.
   - [x] Bổ sung 2 RPC functions `get_dashboard_metrics` và `cancel_showtime`.
   - [x] Bổ sung trigger ngăn chặn xung đột suất chiếu dưới 15 phút `trg_showtime_conflict`.
   - [x] Bổ sung seed tài khoản xác thực `auth.users`, profiles tương ứng và suất chiếu demo để sẵn sàng cho các bài kiểm thử E2E và Acceptance Criteria.
