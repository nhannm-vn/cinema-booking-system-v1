# KẾ HOẠCH TRIỂN KHAI KỸ THUẬT MILESTONE 1
## Backend Completeness & Shared Core Data Layer

**Mã phân hệ:** Milestone 1 (M1)  
**Tác giả:** Teamwork Preview Explorer (`explorer_m1_1`)  
**Dự án:** Cinema Booking & Operation Management Application  
**Ngày lập:** 2026-10-27  
**Tham chiếu quy chuẩn:** `docs/TECH_STACK.md`, `docs/BUSINESS_RULES.md`, `docs/ROLE_FLOWS.md`, `docs/PROJECT_STRUCTURE.md`, `AGENTS.md`, `ai-coding-standards`

---

## 1. TỔNG QUAN VÀ MỤC TIÊU MILESTONE 1

Milestone 1 chịu trách nhiệm xây dựng nền tảng backend và lớp dữ liệu (Data & State Controllers) hoàn chỉnh, bảo đảm mọi phân hệ tiếp theo (M2 Khách hàng, M3 Đặt vé, M4 Vận hành rạp, M5 Quản trị) có thể triển khai trơn tru mà không gặp bất kỳ thiếu hụt nào về API, RPC, Trigger hay State Management.

### Các hạng mục trọng yếu trong M1:
1. **Migration SQL mới `0006_missing_rpcs_and_triggers.sql`:**
   - Database Trigger `trg_showtime_conflict` trên bảng `public.showtimes` chặn tạo suất trùng/chồng giờ dưới 15 phút nghỉ.
   - RPC Function `cancel_showtime(p_showtime_id uuid, p_reason text)` hỗ trợ Manager/Admin hủy suất, tự động chuyển đơn sang `cancelled`, gửi thông báo cho khách và giữ nguyên bản ghi `seats`.
   - RPC Function `get_dashboard_metrics(p_cinema_id text, p_period text)` phục vụ S22 Dashboard tính doanh thu, số vé, tỷ lệ lấp đầy phòng và danh sách suất sắp chiếu.
2. **Cập nhật Seed Data `0005_seed.sql`:**
   - Seed tài khoản chuẩn vào `auth.users` bằng băm mật khẩu `pgcrypto` (`123456`) cho 6 tài khoản: `admin@cinema.vn`, `manager1@cinema.vn`, `manager2@cinema.vn`, `staff1@cinema.vn`, `staff2@cinema.vn`, `khach1@cinema.vn`.
   - Seed tương ứng vào `public.profiles` phân bổ đúng vai trò và rạp (`cn_q1`, `cn_tb`).
   - Seed suất chiếu đang chiếu (active) cho hôm nay và các ngày kế tiếp.
   - Seed danh mục món ăn cho rạp Tân Bình (`cn_tb`) và đơn đặt vé mẫu.
3. **Sửa lỗi bảo mật/RLS Edge Function `create-vnpay-url`:**
   - Chuyển thao tác `payments.upsert` sang `SUPABASE_SERVICE_ROLE_KEY` thay vì anon client để vượt qua policy `payments_no_direct_insert`.
4. **Bổ sung tầng dữ liệu & Provider cho Flutter:**
   - `features/staff_counter/`: `StaffCounterRepository` & `StaffCounterProvider` (giữ ghế 3 phút tại quầy, tính tiền thừa, bán vé trực tiếp qua RPC `sell_counter`).
   - `features/management/`: `ManagementRepository` & `ManagementProvider` (thống kê Dashboard, CRUD suất chiếu kèm trigger 15p, toggle bật/tắt đồ ăn, tạo tài khoản staff qua Edge Function `create-staff`, khóa tài khoản).
   - `features/notifications/`: `NotificationProvider` (quản lý danh sách thông báo, số chưa đọc, đánh dấu đã đọc).
   - `features/chat/`: `SupportChatRepository` & `SupportChatProvider` (quản lý hội thoại khách - nhân viên, stream tin nhắn Realtime).
   - Cập nhật `lib/main.dart` đăng ký toàn bộ providers mới vào `MultiProvider`.

---

## 2. BACKEND SQL: MIGRATION `0006_missing_rpcs_and_triggers.sql`

**File:** `supabase/migrations/0006_missing_rpcs_and_triggers.sql`

```sql
-- ============================================================================
-- 0006_missing_rpcs_and_triggers.sql
-- Bổ sung các Trigger và RPC functions còn thiếu cho Milestone 1
-- Tham chiếu: TECH_STACK.md Section 5.3 & BUSINESS_RULES.md Section 3.3, 10.3, 11
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TRIGGER: trg_showtime_conflict (Kiểm tra khoảng nghỉ 15 phút giữa các suất)
-- Quy tắc: Trong cùng 1 phòng, hai suất chiếu active phải cách nhau tối thiểu 15 phút.
-- Điều kiện chồng lấn:
-- (new.start_time < existing.end_time + 15m) AND (new.end_time > existing.start_time - 15m)
-- ----------------------------------------------------------------------------
create or replace function public.check_showtime_conflict()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_conflict record;
  v_room_name text;
begin
  -- Chỉ kiểm tra khi suất chiếu đang ở trạng thái active
  if new.status <> 'active' then
    return new;
  end if;

  select s.id, s.start_time, s.end_time into v_conflict
  from public.showtimes s
  where s.room_id = new.room_id
    and s.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
    and s.status = 'active'
    and (new.start_time < (s.end_time + interval '15 minutes'))
    and (new.end_time > (s.start_time - interval '15 minutes'))
  order by s.start_time asc
  limit 1;

  if v_conflict.id is not null then
    select name into v_room_name from public.rooms where id = new.room_id;
    raise exception 'SHOWTIME_CONFLICT: % đã có suất từ % đến % (khoảng nghỉ tối thiểu 15 phút)',
      coalesce(v_room_name, 'Phòng chiếu'),
      to_char(v_conflict.start_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI'),
      to_char(v_conflict.end_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI');
  end if;

  return new;
end;
$$;

drop trigger if exists trg_showtime_conflict on public.showtimes;
create trigger trg_showtime_conflict
  before insert or update on public.showtimes
  for each row execute function public.check_showtime_conflict();

-- ----------------------------------------------------------------------------
-- 2. RPC: cancel_showtime (Hủy suất chiếu & tự động hoàn các đơn vé đã thanh toán)
-- Quyền: Manager của rạp đó hoặc Admin hệ thống.
-- Lưu ý: Không xóa dữ liệu trong bảng seats để phục vụ đối soát tài chính.
-- ----------------------------------------------------------------------------
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
  if not found then
    raise exception 'SHOWTIME_NOT_FOUND';
  end if;

  if v_role = 'manager' and v_st.cinema_id <> v_cid then
    raise exception 'WRONG_CINEMA';
  end if;

  if v_st.status = 'cancelled' then
    raise exception 'SHOWTIME_ALREADY_CANCELLED';
  end if;

  -- 1. Cập nhật trạng thái suất chiếu
  update public.showtimes
  set status = 'cancelled',
      cancel_reason = p_reason
  where id = p_showtime_id;

  -- 2. Cập nhật toàn bộ đơn vé paid của suất chiếu sang cancelled
  for v_bk in select * from public.bookings where showtime_id = p_showtime_id and status = 'paid' loop
    update public.bookings
    set status = 'cancelled',
        food_status = case when food_status = 'pending' then 'cancelled' else food_status end,
        cancel_reason = 'Suất chiếu bị hủy: ' || p_reason,
        cancelled_by = v_uid,
        cancelled_at = now()
    where code = v_bk.code;

    -- Gửi thông báo hoàn vé cho khách hàng
    if v_bk.user_id is not null then
      insert into public.notifications (user_id, type, title, body, booking_code)
      values (
        v_bk.user_id,
        'showtimeCancelled',
        'Suất chiếu đã bị hủy',
        'Suất chiếu phim ' || v_bk.movie_title || ' vào lúc ' ||
        to_char(v_bk.showtime_start at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI dd/MM') ||
        ' đã bị hủy do: ' || p_reason || '. Bạn được hoàn tiền 100%.',
        v_bk.code
      );
    end if;

    v_count := v_count + 1;
  end loop;

  -- 3. Ghi nhật ký kiểm toán (Audit Logs)
  insert into public.audit_logs (
    actor_id, actor_role, cinema_id, action, target_type, target_id, reason
  ) values (
    v_uid, v_role, v_st.cinema_id, 'cancelShowtime', 'showtime', p_showtime_id::text, p_reason
  );

  return jsonb_build_object(
    'success', true,
    'showtime_id', p_showtime_id,
    'cancelled_bookings_count', v_count
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. RPC: get_dashboard_metrics (Lấy số liệu vận hành cho S22 Dashboard)
-- Quyền: Manager của rạp đó hoặc Admin.
-- Hỗ trợ tham số p_period: 'today', 'week', 'month'
-- ----------------------------------------------------------------------------
create or replace function public.get_dashboard_metrics(
  p_cinema_id text,
  p_period text default 'today'
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_cid text;
  v_start_time timestamptz;
  v_end_time timestamptz;
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

  -- Xác định khoảng thời gian lọc theo múi giờ Việt Nam
  if p_period = 'week' then
    v_start_time := date_trunc('day', now() at time zone 'Asia/Ho_Chi_Minh') - interval '7 days';
    v_end_time := now() + interval '1 day';
  elsif p_period = 'month' then
    v_start_time := date_trunc('month', now() at time zone 'Asia/Ho_Chi_Minh');
    v_end_time := now() + interval '1 day';
  else
    -- Mặc định 'today'
    v_start_time := date_trunc('day', now() at time zone 'Asia/Ho_Chi_Minh');
    v_end_time := v_start_time + interval '1 day';
  end if;

  -- 1. Doanh thu và số vé bán ra trong kỳ
  select
    coalesce(sum((price_snapshot->>'total')::bigint), 0),
    coalesce(sum(jsonb_array_length(seats)), 0)
  into v_today_revenue, v_today_tickets
  from public.bookings
  where cinema_id = p_cinema_id
    and status in ('paid', 'used')
    and created_at >= v_start_time
    and created_at < v_end_time;

  -- 2. Tỷ lệ lấp đầy phòng chiếu
  select
    coalesce(sum(total_seats), 0),
    coalesce(sum(sold_seats), 0)
  into v_total_capacity, v_sold_capacity
  from public.showtimes
  where cinema_id = p_cinema_id
    and status = 'active'
    and start_time >= v_start_time
    and start_time < v_end_time;

  if v_total_capacity > 0 then
    v_occupancy_rate := round((v_sold_capacity::numeric / v_total_capacity::numeric) * 100, 1);
  end if;

  -- 3. Danh sách 5 suất chiếu active sắp diễn ra
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
    'period', p_period,
    'today_revenue', v_today_revenue,
    'today_tickets', v_today_tickets,
    'occupancy_rate', v_occupancy_rate,
    'total_capacity', v_total_capacity,
    'sold_capacity', v_sold_capacity,
    'upcoming_showtimes', v_upcoming_showtimes
  );
end;
$$;

-- Wrapper tương thích cho p_cinema_id dạng uuid
create or replace function public.get_dashboard_metrics(
  p_cinema_id uuid,
  p_period text default 'today'
) returns jsonb language sql as $$
  select public.get_dashboard_metrics(p_cinema_id::text, p_period);
$$;
```

---

## 3. BACKEND SEED DATA: CẬP NHẬT `0005_seed.sql`

**File:** `supabase/migrations/0005_seed.sql`

Đoạn SQL bổ sung sau phần Vouchers hiện tại (dòng 122 trở đi):

```sql
-- ----------------------------------------------------------------------------
-- 7. Thức ăn bổ sung cho Rạp Tân Bình (cn_tb)
-- ----------------------------------------------------------------------------
insert into public.foods (id, cinema_id, name, category, price, is_available, image_url, description)
values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', 'cn_tb', 'Combo Solo (1 Bắp + 1 Nước)', 'combo', 85000, true, 'https://images.unsplash.com/photo-1585647347483-22b66260dfff?w=500', '1 bắp ngọt 60oz + 1 nước ngọt 32oz'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb02', 'cn_tb', 'Combo Couple (1 Bắp + 2 Nước)', 'combo', 110000, true, 'https://images.unsplash.com/photo-1572177191856-3cde618dee1f?w=500', '1 bắp lớn 80oz + 2 nước ngọt 32oz'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', 'cn_tb', 'Bắp Rang Bơ Truyền Thống', 'popcorn', 60000, true, 'https://images.unsplash.com/photo-1505686994434-e3cc5abf1330?w=500', 'Bắp rang bơ thơm ngon đậm vị'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb04', 'cn_tb', 'Nước Ngọt Sprite 32oz', 'drink', 35000, true, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500', 'Nước giải khát có gas hương chanh mát lạnh')
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 8. Seed Tài Khoản Kiểm Thử (auth.users & public.profiles)
-- Mật khẩu mặc định: 123456
-- ----------------------------------------------------------------------------
create extension if not exists pgcrypto;

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
  -- 1. Chèn vào auth.users
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, role, aud, created_at, updated_at
  ) values
    (uid_admin, '00000000-0000-0000-0000-000000000000', 'admin@cinema.vn', v_enc_pass, now(), '{"provider": "email", "providers": ["email"]}'::jsonb, '{"full_name": "Quản Trị Viên Hệ Thống"}'::jsonb, 'authenticated', 'authenticated', now(), now()),
    (uid_mgr1,  '00000000-0000-0000-0000-000000000000', 'manager1@cinema.vn', v_enc_pass, now(), '{"provider": "email", "providers": ["email"]}'::jsonb, '{"full_name": "Quản Lý Quận 1"}'::jsonb, 'authenticated', 'authenticated', now(), now()),
    (uid_mgr2,  '00000000-0000-0000-0000-000000000000', 'manager2@cinema.vn', v_enc_pass, now(), '{"provider": "email", "providers": ["email"]}'::jsonb, '{"full_name": "Quản Lý Tân Bình"}'::jsonb, 'authenticated', 'authenticated', now(), now()),
    (uid_stf1,  '00000000-0000-0000-0000-000000000000', 'staff1@cinema.vn', v_enc_pass, now(), '{"provider": "email", "providers": ["email"]}'::jsonb, '{"full_name": "Nhân Viên Soát Vé Q1"}'::jsonb, 'authenticated', 'authenticated', now(), now()),
    (uid_stf2,  '00000000-0000-0000-0000-000000000000', 'staff2@cinema.vn', v_enc_pass, now(), '{"provider": "email", "providers": ["email"]}'::jsonb, '{"full_name": "Nhân Viên Soát Vé TB"}'::jsonb, 'authenticated', 'authenticated', now(), now()),
    (uid_kh1,   '00000000-0000-0000-0000-000000000000', 'khach1@cinema.vn', v_enc_pass, now(), '{"provider": "email", "providers": ["email"]}'::jsonb, '{"full_name": "Nguyễn Văn Khách"}'::jsonb, 'authenticated', 'authenticated', now(), now())
  on conflict (id) do nothing;

  -- 2. Tạm thời tắt trigger trg_protect_profile để gán role chuẩn xác
  alter table public.profiles disable trigger trg_protect_profile;

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
    phone = excluded.phone,
    role = excluded.role,
    cinema_id = excluded.cinema_id,
    is_locked = excluded.is_locked;

  alter table public.profiles enable trigger trg_protect_profile;
end $$;

-- ----------------------------------------------------------------------------
-- 9. Seed Suất Chiếu Demo (Hôm nay & Các ngày kế tiếp)
-- Đảm bảo cách nhau >= 15 phút nghỉ giữa các suất trong cùng phòng
-- ----------------------------------------------------------------------------
insert into public.showtimes (
  id, movie_id, cinema_id, room_id, format, start_time, end_time, status, total_seats, sold_seats
) values
  -- [cn_q1 - Phòng IMAX] Suất 1: Oppenheimer (180 phút) hôm nay
  ('b1111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444444', 'cn_q1', '11111111-1111-1111-1111-111111111111', 'IMAX',
   now() + interval '1 hour', now() + interval '4 hours', 'active', 75, 2),

  -- [cn_q1 - Phòng IMAX] Suất 2: Oppenheimer (180 phút) tối nay (cách suất 1: 30 phút > 15 phút)
  ('b1111111-1111-1111-1111-111111111102', '44444444-4444-4444-4444-444444444444', 'cn_q1', '11111111-1111-1111-1111-111111111111', 'IMAX',
   now() + interval '4 hours 30 minutes', now() + interval '7 hours 30 minutes', 'active', 75, 0),

  -- [cn_q1 - Phòng 2 Standard] Suất 1: Dune 2 (166 phút) hôm nay
  ('b2222222-2222-2222-2222-222222222201', '55555555-5555-5555-5555-555555555555', 'cn_q1', '22222222-2222-2222-2222-222222222222', '2D',
   now() + interval '2 hours', now() + interval '4 hours 46 minutes', 'active', 44, 0),

  -- [cn_q1 - Phòng 2 Standard] Suất 2: Kẻ Trộm Mặt Trăng 4 (95 phút) tối nay (cách suất 1: 20 phút)
  ('b2222222-2222-2222-2222-222222222202', '66666666-6666-6666-6666-666666666666', 'cn_q1', '22222222-2222-2222-2222-222222222222', '2D',
   now() + interval '5 hours 6 minutes', now() + interval '6 hours 41 minutes', 'active', 44, 0),

  -- [cn_tb - Phòng 1] Suất 1: Kẻ Trộm Mặt Trăng 4 (95 phút) chiều nay
  ('b3333333-3333-3333-3333-333333333301', '66666666-6666-6666-6666-666666666666', 'cn_tb', '33333333-3333-3333-3333-333333333333', '2D',
   now() + interval '1 hour 30 minutes', now() + interval '3 hours 5 minutes', 'active', 52, 0),

  -- [cn_tb - Phòng 1] Suất 2: Dune 2 (166 phút) tối nay (cách suất 1: 25 phút)
  ('b3333333-3333-3333-3333-333333333302', '55555555-5555-5555-5555-555555555555', 'cn_tb', '33333333-3333-3333-3333-333333333333', '2D',
   now() + interval '3 hours 30 minutes', now() + interval '6 hours 16 minutes', 'active', 52, 0)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 10. Seed Vé Mẫu (Demo Booking để test Soát vé S18 & Quầy bếp S19)
-- ----------------------------------------------------------------------------
insert into public.bookings (
  code, user_id, channel, status, food_status, price_snapshot, payment_method, paid_at,
  showtime_id, cinema_id, movie_title, poster_url, age_rating, cinema_name, room_name,
  format, showtime_start, seats, foods
) values (
  'TESTBK01',
  'a0000000-0000-0000-0000-000000000006',
  'online',
  'paid',
  'pending',
  '{"total": 285000, "base_price": 200000, "food_total": 85000, "discount": 0}'::jsonb,
  'vnpay',
  now(),
  'b1111111-1111-1111-1111-111111111101',
  'cn_q1',
  'Oppenheimer: Kẻ Chế Tạo Bom',
  'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600',
  'T18',
  'Cinema Star Quận 1',
  'Phòng Chiếu 1 (IMAX)',
  'IMAX',
  now() + interval '1 hour',
  '[{"id": "A1", "type": "standard", "price": 100000}, {"id": "A2", "type": "standard", "price": 100000}]'::jsonb,
  '[{"food_id": "77777777-7777-7777-7777-777777777777", "name": "Combo Solo (1 Bắp + 1 Nước)", "qty": 1, "unit_price": 85000}]'::jsonb
) on conflict (code) do nothing;

-- Ghi nhận 2 ghế đã bán vào bảng seats cho đơn TESTBK01
insert into public.seats (showtime_id, seat_id, status, booking_code, hold_holder, hold_until)
values
  ('b1111111-1111-1111-1111-111111111101', 'A1', 'sold', 'TESTBK01', 'a0000000-0000-0000-0000-000000000006', null),
  ('b1111111-1111-1111-1111-111111111101', 'A2', 'sold', 'TESTBK01', 'a0000000-0000-0000-0000-000000000006', null)
on conflict (showtime_id, seat_id) do nothing;
```

---

## 4. EDGE FUNCTION FIX: `supabase/functions/create-vnpay-url/index.ts`

**Vấn đề:**
Bảng `public.payments` có RLS policy `payments_no_direct_insert` ngăn cấm mọi client chèn trực tiếp.
Ở dòng 35-37, hàm tạo `supabase` bằng `SUPABASE_ANON_KEY` kèm Authorization header của user. Đến dòng 88-93, lệnh `supabase.from('payments').upsert(...)` bị Postgres từ chối với lỗi RLS error.

**Giải pháp sửa đổi (Surgical change):**
Tạo thêm client `supabaseAdmin` sử dụng `SUPABASE_SERVICE_ROLE_KEY` riêng cho thao tác ghi bảng `payments`:

### Diff chi tiết:
```diff
--- a/supabase/functions/create-vnpay-url/index.ts
+++ b/supabase/functions/create-vnpay-url/index.ts
@@ -85,8 +85,13 @@ Deno.serve(async (req) => {
     const hash = await hmacSha512(secret, query);
     const paymentUrl = `${vnpUrl}?${query}&vnp_SecureHash=${hash}`;
 
-    // Insert pending payment record
-    await supabase.from('payments').upsert({
+    // Dùng service role client để upsert payment record (vượt qua RLS payments_no_direct_insert)
+    const supabaseAdmin = createClient(
+      Deno.env.get('SUPABASE_URL')!,
+      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
+    );
+
+    await supabaseAdmin.from('payments').upsert({
       txn_ref: txn_ref,
       booking_code: booking.code,
       amount: totalAmount,
```

---

## 5. FLUTTER DATA & STATE LAYER ADDITIONS

### 5.1 Phân hệ Bán vé tại quầy: `features/staff_counter/`

#### 5.1.1 Repository: `lib/features/staff_counter/data/staff_counter_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../booking/data/models/showtime_model.dart';

/// Repository xử lý nghiệp vụ bán vé tại quầy (S20 & S21).
/// Tham chiếu: BUSINESS_RULES.md Section 10 & TECH_STACK.md RPC sell_counter
class StaffCounterRepository {
  final SupabaseClient _supabase;

  StaffCounterRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Lấy danh sách suất chiếu của rạp hôm nay phục vụ bán vé tại quầy.
  Future<List<ShowtimeModel>> getCounterShowtimes(String cinemaId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final response = await _supabase
        .from('showtimes')
        .select('*, rooms(name), cinemas(name), movies(title)')
        .eq('cinema_id', cinemaId)
        .eq('status', 'active')
        .gte('start_time', startOfDay.toUtc().toIso8601String())
        .lte('start_time', endOfDay.toUtc().toIso8601String())
        .order('start_time', ascending: true);

    return (response as List).map((row) {
      final room = row['rooms'] as Map<String, dynamic>?;
      final cinema = row['cinemas'] as Map<String, dynamic>?;
      final movie = row['movies'] as Map<String, dynamic>?;

      final enriched = Map<String, dynamic>.from(row);
      enriched['room_name'] = room?['name'];
      enriched['cinema_name'] = cinema?['name'];
      enriched['movie_title'] = movie?['title'];

      return ShowtimeModel.fromMap(enriched);
    }).toList();
  }

  /// Giữ ghế 3 phút tại quầy qua RPC hold_seats.
  Future<DateTime> holdCounterSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
  }) async {
    final response = await _supabase.rpc('hold_seats', params: {
      'p_showtime_id': showtimeId,
      'p_booking_code': bookingCode,
      'p_seat_ids': seatIds,
      'p_hold_minutes': 3, // Giữ 3 phút theo BUSINESS_RULES.md Section 3.2
      'p_booking': booking,
    });

    return DateTime.parse(response as String).toLocal();
  }

  /// Bán vé trực tiếp và xuất hóa đơn tại quầy qua RPC sell_counter.
  Future<void> sellCounter({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required String paymentMethod, // 'cash' hoặc 'card'
    required Map<String, dynamic> booking,
  }) async {
    await _supabase.rpc('sell_counter', params: {
      'p_showtime_id': showtimeId,
      'p_booking_code': bookingCode,
      'p_seat_ids': seatIds,
      'p_payment_method': paymentMethod,
      'p_booking': booking,
    });
  }
}
```

#### 5.1.2 Controller: `lib/features/staff_counter/presentation/controllers/staff_counter_provider.dart`

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../booking/data/models/showtime_model.dart';
import '../../data/staff_counter_repository.dart';

/// Provider quản lý luồng bán vé tại quầy (S20, S21).
/// Tham chiếu: ROLE_FLOWS.md Section 3.3 & BUSINESS_RULES.md Section 10
class StaffCounterProvider extends ChangeNotifier {
  final StaffCounterRepository _repo;

  StaffCounterProvider([StaffCounterRepository? repo])
      : _repo = repo ?? StaffCounterRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<ShowtimeModel> _showtimes = [];
  ShowtimeModel? _selectedShowtime;
  final List<String> _selectedSeatIds = [];
  final List<Map<String, dynamic>> _selectedFoods = [];
  String? _bookingCode;
  DateTime? _holdUntil;
  int _receivedCash = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ShowtimeModel> get showtimes => _showtimes;
  ShowtimeModel? get selectedShowtime => _selectedShowtime;
  List<String> get selectedSeatIds => List.unmodifiable(_selectedSeatIds);
  List<Map<String, dynamic>> get selectedFoods => List.unmodifiable(_selectedFoods);
  String? get bookingCode => _bookingCode;
  DateTime? get holdUntil => _holdUntil;
  int get receivedCash => _receivedCash;

  /// Tạo mã booking ngẫu nhiên 8 ký tự viết hoa.
  String _generateBookingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (i) => chars[random.nextInt(chars.length)]).join();
  }

  /// Nạp danh sách suất chiếu của rạp.
  Future<void> loadShowtimes(String cinemaId, DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _showtimes = await _repo.getCounterShowtimes(cinemaId, date);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách suất chiếu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectShowtime(ShowtimeModel showtime) {
    _selectedShowtime = showtime;
    _selectedSeatIds.clear();
    _selectedFoods.clear();
    _bookingCode = null;
    _holdUntil = null;
    notifyListeners();
  }

  /// Chọn / bỏ chọn ghế (tối đa 8 ghế).
  bool toggleSeat(String seatId) {
    if (_selectedSeatIds.contains(seatId)) {
      _selectedSeatIds.remove(seatId);
      notifyListeners();
      return true;
    }

    if (_selectedSeatIds.length >= 8) {
      _errorMessage = 'Chỉ được chọn tối đa 8 ghế mỗi lần bán';
      notifyListeners();
      return false;
    }

    _selectedSeatIds.add(seatId);
    notifyListeners();
    return true;
  }

  /// Thêm hoặc giảm món ăn.
  void setFoodQuantity(String foodId, String name, int price, int qty) {
    _selectedFoods.removeWhere((item) => item['food_id'] == foodId);
    if (qty > 0) {
      _selectedFoods.add({
        'food_id': foodId,
        'name': name,
        'unit_price': price,
        'qty': qty,
        'total': price * qty,
      });
    }
    notifyListeners();
  }

  /// Tính tổng tiền đơn quầy (VND).
  int calculateTotal() {
    final seatTotal = _selectedSeatIds.length * (_selectedShowtime?.minPrice ?? 80000);
    final foodTotal = _selectedFoods.fold<int>(0, (sum, item) => sum + ((item['total'] as int?) ?? 0));
    return seatTotal + foodTotal;
  }

  /// Tính tiền thối lại cho khách: receivedCash - total.
  int calculateChange(int received) {
    _receivedCash = received;
    final total = calculateTotal();
    return received > total ? received - total : 0;
  }

  /// Giữ ghế 3 phút tại quầy.
  Future<bool> holdSeatsForCounter() async {
    if (_selectedShowtime == null || _selectedSeatIds.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bookingCode = _generateBookingCode();
      final total = calculateTotal();
      final bookingPayload = {
        'cinema_id': _selectedShowtime!.cinemaId,
        'movie_title': _selectedShowtime!.movieTitle ?? '',
        'cinema_name': _selectedShowtime!.cinemaName ?? '',
        'room_name': _selectedShowtime!.roomName ?? '',
        'format': _selectedShowtime!.format,
        'showtime_start': _selectedShowtime!.startTime.toUtc().toIso8601String(),
        'seats': _selectedSeatIds.map((id) => {'id': id, 'type': 'standard', 'price': _selectedShowtime!.minPrice}).toList(),
        'foods': _selectedFoods,
        'price_snapshot': {'total': total},
      };

      _holdUntil = await _repo.holdCounterSeats(
        showtimeId: _selectedShowtime!.id,
        bookingCode: _bookingCode!,
        seatIds: _selectedSeatIds,
        booking: bookingPayload,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Giữ ghế không thành công: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hoàn tất xuất vé tại quầy (tiền mặt / quẹt thẻ).
  Future<bool> completeSale(String paymentMethod) async {
    if (_selectedShowtime == null || _bookingCode == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final total = calculateTotal();
      final bookingPayload = {
        'cinema_id': _selectedShowtime!.cinemaId,
        'movie_title': _selectedShowtime!.movieTitle ?? '',
        'cinema_name': _selectedShowtime!.cinemaName ?? '',
        'room_name': _selectedShowtime!.roomName ?? '',
        'format': _selectedShowtime!.format,
        'showtime_start': _selectedShowtime!.startTime.toUtc().toIso8601String(),
        'seats': _selectedSeatIds.map((id) => {'id': id, 'type': 'standard', 'price': _selectedShowtime!.minPrice}).toList(),
        'foods': _selectedFoods,
        'price_snapshot': {'total': total},
      };

      await _repo.sellCounter(
        showtimeId: _selectedShowtime!.id,
        bookingCode: _bookingCode!,
        seatIds: _selectedSeatIds,
        paymentMethod: paymentMethod,
        booking: bookingPayload,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Xuất vé tại quầy thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _selectedShowtime = null;
    _selectedSeatIds.clear();
    _selectedFoods.clear();
    _bookingCode = null;
    _holdUntil = null;
    _receivedCash = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
```

---

### 5.2 Phân hệ Quản trị: `features/management/`

#### 5.2.1 Model: `lib/features/management/data/models/dashboard_metrics_model.dart`

```dart
/// Model dữ liệu thống kê cho S22 Dashboard.
class DashboardMetricsModel {
  final String cinemaId;
  final String period;
  final int todayRevenue;
  final int todayTickets;
  final double occupancyRate;
  final int totalCapacity;
  final int soldCapacity;
  final List<UpcomingShowtimeItem> upcomingShowtimes;

  const DashboardMetricsModel({
    required this.cinemaId,
    required this.period,
    required this.todayRevenue,
    required this.todayTickets,
    required this.occupancyRate,
    required this.totalCapacity,
    required this.soldCapacity,
    required this.upcomingShowtimes,
  });

  factory DashboardMetricsModel.fromMap(Map<String, dynamic> map) {
    final list = (map['upcoming_showtimes'] as List<dynamic>?) ?? [];
    return DashboardMetricsModel(
      cinemaId: (map['cinema_id'] as String?) ?? '',
      period: (map['period'] as String?) ?? 'today',
      todayRevenue: (map['today_revenue'] as num?)?.toInt() ?? 0,
      todayTickets: (map['today_tickets'] as num?)?.toInt() ?? 0,
      occupancyRate: (map['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      totalCapacity: (map['total_capacity'] as num?)?.toInt() ?? 0,
      soldCapacity: (map['sold_capacity'] as num?)?.toInt() ?? 0,
      upcomingShowtimes: list
          .map((item) => UpcomingShowtimeItem.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class UpcomingShowtimeItem {
  final String id;
  final String movieTitle;
  final String roomName;
  final String format;
  final DateTime startTime;
  final int totalSeats;
  final int soldSeats;

  const UpcomingShowtimeItem({
    required this.id,
    required this.movieTitle,
    required this.roomName,
    required this.format,
    required this.startTime,
    required this.totalSeats,
    required this.soldSeats,
  });

  factory UpcomingShowtimeItem.fromMap(Map<String, dynamic> map) {
    return UpcomingShowtimeItem(
      id: map['id'] as String,
      movieTitle: (map['movie_title'] as String?) ?? '',
      roomName: (map['room_name'] as String?) ?? '',
      format: (map['format'] as String?) ?? '2D',
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      totalSeats: (map['total_seats'] as int?) ?? 0,
      soldSeats: (map['sold_seats'] as int?) ?? 0,
    );
  }
}
```

#### 5.2.2 Repository: `lib/features/management/data/management_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/app_user.dart';
import '../../booking/data/models/booking_model.dart';
import '../../booking/data/models/food_model.dart';
import '../../booking/data/models/showtime_model.dart';
import 'models/dashboard_metrics_model.dart';

/// Repository quản lý vận hành và cấu hình hệ thống (S12–S16, S22–S29).
class ManagementRepository {
  final SupabaseClient _supabase;

  ManagementRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Lấy số liệu vận hành Dashboard (RPC get_dashboard_metrics).
  Future<DashboardMetricsModel> getDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    final response = await _supabase.rpc('get_dashboard_metrics', params: {
      'p_cinema_id': cinemaId,
      'p_period': period,
    });

    return DashboardMetricsModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  /// Tạo suất chiếu mới (DB trigger trg_showtime_conflict tự động kiểm tra 15 phút).
  Future<void> createShowtime({
    required String movieId,
    required String cinemaId,
    required String roomId,
    required String format,
    required DateTime startTime,
    required DateTime endTime,
    required int totalSeats,
  }) async {
    await _supabase.from('showtimes').insert({
      'movie_id': movieId,
      'cinema_id': cinemaId,
      'room_id': roomId,
      'format': format,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'status': 'active',
      'total_seats': totalSeats,
      'sold_seats': 0,
    });
  }

  /// Hủy suất chiếu qua RPC cancel_showtime.
  Future<Map<String, dynamic>> cancelShowtime(String showtimeId, String reason) async {
    final response = await _supabase.rpc('cancel_showtime', params: {
      'p_showtime_id': showtimeId,
      'p_reason': reason,
    });

    return Map<String, dynamic>.from(response as Map);
  }

  /// Bật / tắt khả dụng của món ăn trong thực đơn.
  Future<void> toggleFoodAvailability(String foodId, bool isAvailable) async {
    await _supabase.from('foods').update({
      'is_available': isAvailable,
    }).eq('id', foodId);
  }

  /// Tạo tài khoản nhân viên / quản lý mới qua Edge Function create-staff.
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cinemaId,
  }) async {
    final response = await _supabase.functions.invoke('create-staff', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'cinema_id': cinemaId,
    });

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Lỗi tạo tài khoản nhân viên';
      throw Exception(error);
    }

    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Khóa / mở khóa tài khoản người dùng.
  Future<void> toggleUserLock(String userId, bool isLocked) async {
    await _supabase.from('profiles').update({
      'is_locked': isLocked,
    }).eq('id', userId);
  }

  /// Danh sách nhân sự của rạp.
  Future<List<AppUser>> getEmployees(String cinemaId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('cinema_id', cinemaId)
        .inFilter('role', ['staff', 'manager'])
        .order('created_at', ascending: false);

    return (response as List).map((p) => AppUser.fromMap(p)).toList();
  }

  /// Lấy danh sách các đơn đặt vé (S15).
  Future<List<BookingModel>> getBookings(String cinemaId, {String? status, String? channel}) async {
    var query = _supabase.from('bookings').select().eq('cinema_id', cinemaId);

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }
    if (channel != null && channel.isNotEmpty) {
      query = query.eq('channel', channel);
    }

    final response = await query.order('created_at', ascending: false).limit(100);
    return (response as List).map((b) => BookingModel.fromMap(b)).toList();
  }
}
```

#### 5.2.3 Controller: `lib/features/management/presentation/controllers/management_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../../../shared/models/app_user.dart';
import '../../booking/data/models/booking_model.dart';
import '../../booking/data/models/food_model.dart';
import '../../booking/data/models/showtime_model.dart';
import '../models/dashboard_metrics_model.dart';
import '../management_repository.dart';

/// Provider điều phối màn hình quản trị và báo cáo vận hành.
class ManagementProvider extends ChangeNotifier {
  final ManagementRepository _repo;

  ManagementProvider([ManagementRepository? repo])
      : _repo = repo ?? ManagementRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  DashboardMetricsModel? _metrics;
  List<AppUser> _employees = [];
  List<BookingModel> _bookings = [];
  List<FoodModel> _foods = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  DashboardMetricsModel? get metrics => _metrics;
  List<AppUser> get employees => _employees;
  List<BookingModel> get bookings => _bookings;
  List<FoodModel> get foods => _foods;

  /// Tải số liệu Dashboard theo rạp và chu kỳ.
  Future<void> loadDashboardMetrics(String cinemaId, {String period = 'today'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metrics = await _repo.getDashboardMetrics(cinemaId, period: period);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải số liệu Dashboard: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lập lịch suất chiếu mới (Bắt lỗi xung đột 15 phút nếu có).
  Future<bool> createShowtime({
    required String movieId,
    required String cinemaId,
    required String roomId,
    required String format,
    required DateTime startTime,
    required DateTime endTime,
    required int totalSeats,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createShowtime(
        movieId: movieId,
        cinemaId: cinemaId,
        roomId: roomId,
        format: format,
        startTime: startTime,
        endTime: endTime,
        totalSeats: totalSeats,
      );
      _successMessage = 'Tạo suất chiếu thành công';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().contains('SHOWTIME_CONFLICT')
          ? e.toString()
          : 'Lỗi tạo suất chiếu: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hủy suất chiếu.
  Future<bool> cancelShowtime(String showtimeId, String reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.cancelShowtime(showtimeId, reason);
      _successMessage = 'Hủy suất chiếu thành công';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Hủy suất chiếu thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Bật / tắt đồ ăn.
  Future<void> toggleFood(String foodId, bool isAvailable) async {
    try {
      await _repo.toggleFoodAvailability(foodId, isAvailable);
      final idx = _foods.indexWhere((f) => f.id == foodId);
      if (idx != -1) {
        // Cập nhật local state
        _foods[idx] = FoodModel(
          id: _foods[idx].id,
          cinemaId: _foods[idx].cinemaId,
          name: _foods[idx].name,
          category: _foods[idx].category,
          price: _foods[idx].price,
          isAvailable: isAvailable,
          imageUrl: _foods[idx].imageUrl,
          description: _foods[idx].description,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Không thể cập nhật trạng thái đồ ăn: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Tạo tài khoản nhân viên mới.
  Future<bool> createStaffAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String cinemaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.createStaff(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
        cinemaId: cinemaId,
      );
      _successMessage = 'Tạo nhân viên thành công';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Tạo nhân viên thất bại: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Khóa / Mở khóa nhân viên.
  Future<void> toggleUserLock(String userId, bool isLocked, String cinemaId) async {
    try {
      await _repo.toggleUserLock(userId, isLocked);
      await loadEmployees(cinemaId);
    } catch (e) {
      _errorMessage = 'Không thể đổi trạng thái khóa tài khoản: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Nạp danh sách nhân sự của rạp.
  Future<void> loadEmployees(String cinemaId) async {
    try {
      _employees = await _repo.getEmployees(cinemaId);
      notifyListeners();
    } catch (_) {}
  }

  /// Nạp danh sách đơn vé kiểm tra (S15).
  Future<void> loadBookings(String cinemaId, {String? status, String? channel}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _bookings = await _repo.getBookings(cinemaId, status: status, channel: channel);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách đơn vé: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

### 5.3 Phân hệ Thông báo: `features/notifications/`

#### 5.3.1 Controller: `lib/features/notifications/presentation/controllers/notification_provider.dart`

```dart
import 'package:flutter/material.dart';
import '../../data/notification_repository.dart';

/// Provider quản lý thông báo người dùng (S30).
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo;

  NotificationProvider([NotificationRepository? repo])
      : _repo = repo ?? NotificationRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Tải danh sách thông báo.
  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _repo.getNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách thông báo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đánh dấu tất cả thông báo là đã đọc.
  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                userId: n.userId,
                type: n.type,
                title: n.title,
                body: n.body,
                bookingCode: n.bookingCode,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
      notifyListeners();
    } catch (_) {}
  }
}
```

---

### 5.4 Phân hệ Hỗ trợ trực tuyến: `features/chat/`

#### 5.4.1 Model: `lib/features/chat/data/models/chat_message_model.dart`

```dart
/// Model tin nhắn hỗ trợ trực tuyến (S31).
class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? bookingCode;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.bookingCode,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      text: map['text'] as String,
      bookingCode: map['booking_code'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
```

#### 5.4.2 Repository: `lib/features/chat/data/support_chat_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/chat_message_model.dart';

/// Repository xử lý tin nhắn hỗ trợ khách hàng với rạp chiếu (S31).
class SupportChatRepository {
  final SupabaseClient _supabase;

  SupportChatRepository([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Lấy hoặc tạo phiên hội thoại giữa khách và rạp.
  Future<String> getOrCreateConversation(String userId, String cinemaId) async {
    final conversationId = '${userId}_$cinemaId';

    await _supabase.from('conversations').upsert({
      'id': conversationId,
      'user_id': userId,
      'cinema_id': cinemaId,
    });

    return conversationId;
  }

  /// Lấy lịch sử tin nhắn của phiên chat.
  Future<List<ChatMessageModel>> getMessages(String conversationId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((m) => ChatMessageModel.fromMap(m)).toList();
  }

  /// Gửi tin nhắn mới.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    String? bookingCode,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'text': text,
      'booking_code': bookingCode,
    });
  }

  /// Đăng ký lắng nghe Realtime tin nhắn mới.
  RealtimeChannel subscribeMessages(
    String conversationId,
    void Function(ChatMessageModel message) onMessage,
  ) {
    return _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(ChatMessageModel.fromMap(payload.newRecord));
          },
        )
        .subscribe();
  }
}
```

#### 5.4.3 Controller: `lib/features/chat/presentation/controllers/support_chat_provider.dart`

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import '../support_chat_repository.dart';

/// Provider quản lý hội thoại hỗ trợ trực tuyến (S31).
class SupportChatProvider extends ChangeNotifier {
  final SupportChatRepository _repo;

  SupportChatProvider([SupportChatRepository? repo])
      : _repo = repo ?? SupportChatRepository();

  bool _isLoading = false;
  String? _errorMessage;
  String? _conversationId;
  List<ChatMessageModel> _messages = [];
  RealtimeChannel? _subscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get conversationId => _conversationId;
  List<ChatMessageModel> get messages => _messages;

  /// Khởi tạo phiên trò chuyện với rạp.
  Future<void> initConversation(String userId, String cinemaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversationId = await _repo.getOrCreateConversation(userId, cinemaId);
      _messages = await _repo.getMessages(_conversationId!);

      // Lắng nghe realtime
      _subscription?.unsubscribe();
      _subscription = _repo.subscribeMessages(_conversationId!, (msg) {
        _messages.add(msg);
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể tải cuộc trò chuyện: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gửi tin nhắn.
  Future<bool> sendMessage(String text, {String? bookingCode}) async {
    if (_conversationId == null || text.trim().isEmpty) return false;

    try {
      await _repo.sendMessage(
        conversationId: _conversationId!,
        text: text.trim(),
        bookingCode: bookingCode,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Gửi tin nhắn thất bại: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
```

---

### 5.5 Cập nhật `lib/main.dart`

**File:** `lib/main.dart`

### Diff chi tiết:
```diff
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -10,6 +10,10 @@
 import 'features/cinemas/presentation/controllers/cinema_provider.dart';
 import 'features/movies/presentation/controllers/movie_provider.dart';
 import 'features/tickets/presentation/controllers/ticket_provider.dart';
+import 'features/notifications/presentation/controllers/notification_provider.dart';
+import 'features/staff_counter/presentation/controllers/staff_counter_provider.dart';
+import 'features/management/presentation/controllers/management_provider.dart';
+import 'features/chat/presentation/controllers/support_chat_provider.dart';
 
 void main() async {
   WidgetsFlutterBinding.ensureInitialized();
@@ -43,6 +47,10 @@
         ),
         ChangeNotifierProvider(create: (_) => CinemaProvider()),
         ChangeNotifierProvider(create: (_) => TicketProvider()),
+        ChangeNotifierProvider(create: (_) => NotificationProvider()),
+        ChangeNotifierProvider(create: (_) => StaffCounterProvider()),
+        ChangeNotifierProvider(create: (_) => ManagementProvider()),
+        ChangeNotifierProvider(create: (_) => SupportChatProvider()),
       ],
       child: Consumer<AuthProvider>(
         builder: (context, auth, _) {
```

---

## 6. KIỂM THỬ TỰ ĐỘNG & TIÊU CHÍ NGHIỆM THU (VERIFICATION)

### 6.1 Bài kiểm thử Unit Test bổ sung cho M1
Để kiểm chứng ngay mã nguồn Dart mới tạo trước khi chuyển sang Milestone 2, tạo 2 file test:

1. `test/features/management/dashboard_metrics_model_test.dart`:
   - Kiểm tra parse JSON từ RPC `get_dashboard_metrics` ra `DashboardMetricsModel`.
   - Kiểm tra chuyển đổi số tiền VND kiểu int và tỷ lệ lấp đầy double.
2. `test/features/staff_counter/staff_counter_provider_test.dart`:
   - Kiểm tra logic giới hạn tối đa 8 ghế.
   - Kiểm tra tính tổng tiền vé + đồ ăn và tính tiền thối lại cho khách.

### 6.2 Các lệnh kiểm tra thực thi (Commands):
- **Phân tích mã nguồn:** `flutter analyze` (yêu cầu: 0 errors, 0 warnings).
- **Chạy toàn bộ test:** `flutter test` (yêu cầu: 100% passing).
- **Kiểm tra cú pháp SQL:** Supabase CLI hoặc trực tiếp trên PostgreSQL qua migration runner.

---
Vinh Pro
