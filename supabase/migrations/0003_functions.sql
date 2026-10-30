-- 0003_functions.sql
-- Business Postgres RPC functions for Cinema Booking App
-- References: TECH_STACK.md Section 5 & BUSINESS_RULES.md

-- 1. hold_seats: Giữ ghế online
create or replace function public.hold_seats(
  p_showtime_id uuid,
  p_booking_code text,
  p_seat_ids text[],
  p_hold_minutes int,
  p_booking jsonb
) returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_now timestamptz := now();
  v_until timestamptz := now() + make_interval(mins => p_hold_minutes);
  v_seat text;
  v_st_start timestamptz;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if array_length(p_seat_ids, 1) is null or array_length(p_seat_ids, 1) > 8 then
    raise exception 'INVALID_SEAT_COUNT';
  end if;

  -- Khóa suất: các khách cùng suất xếp hàng
  perform 1 from public.showtimes where id = p_showtime_id for update;
  if not found then
    raise exception 'SHOWTIME_NOT_FOUND';
  end if;

  -- Kiểm tra ghế
  foreach v_seat in array p_seat_ids loop
    if exists (
      select 1 from public.seats s
      where s.showtime_id = p_showtime_id
        and s.seat_id = v_seat
        and (s.status = 'sold'
             or (s.status = 'holding' and s.hold_until > v_now and s.booking_code <> p_booking_code))
    ) then
      raise exception 'SEAT_TAKEN:%', v_seat;
    end if;
  end loop;

  -- Nhả đơn holding cũ của chính khách này (tối đa 1 đơn đang giữ)
  update public.bookings set status = 'expired'
  where user_id = v_uid and status = 'holding' and code <> p_booking_code;

  delete from public.seats s
  using public.bookings b
  where s.booking_code = b.code and b.user_id = v_uid and b.status = 'expired'
    and s.status = 'holding';

  -- Lấy start_time chính xác từ bảng showtimes
  select s.start_time into v_st_start from public.showtimes s where s.id = p_showtime_id;
  if v_st_start is null then
    v_st_start := (p_booking->>'showtime_start')::timestamptz;
  end if;

  -- Ghi booking trước để có khóa chính booking_code
  insert into public.bookings (
    code, user_id, channel, status, hold_until, food_status, price_snapshot,
    showtime_id, cinema_id, movie_title, poster_url, age_rating, cinema_name,
    room_name, format, showtime_start, seats, foods
  ) values (
    p_booking_code,
    v_uid,
    coalesce(p_booking->>'channel', 'online'),
    'holding',
    v_until,
    'none',
    p_booking->'price_snapshot',
    coalesce((p_booking->>'showtime_id')::uuid, p_showtime_id),
    p_booking->>'cinema_id',
    p_booking->>'movie_title',
    p_booking->>'poster_url',
    p_booking->>'age_rating',
    p_booking->>'cinema_name',
    p_booking->>'room_name',
    p_booking->>'format',
    v_st_start,
    coalesce(p_booking->'seats', '[]'::jsonb),
    coalesce(p_booking->'foods', '[]'::jsonb)
  )
  on conflict (code) do update set
    hold_until = excluded.hold_until,
    food_status = excluded.food_status,
    price_snapshot = excluded.price_snapshot,
    foods = excluded.foods,
    seats = excluded.seats;

  -- Giữ các ghế mới
  foreach v_seat in array p_seat_ids loop
    insert into public.seats (showtime_id, seat_id, status, hold_until, hold_holder, booking_code)
    values (p_showtime_id, v_seat, 'holding', v_until, v_uid, p_booking_code)
    on conflict (showtime_id, seat_id) do update set
      status = 'holding',
      hold_until = excluded.hold_until,
      hold_holder = excluded.hold_holder,
      booking_code = excluded.booking_code;
  end loop;

  return v_until;
end $$;

-- 2. confirm_payment: Xác nhận thanh toán (gọi từ Edge Function)
create or replace function public.confirm_payment(
  p_booking_code text,
  p_txn_ref text,
  p_vnp_transaction_no text default null,
  p_amount int default null,
  p_sepay_transaction_id text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings%rowtype;
  v_trans_id text;
begin
  v_trans_id := coalesce(p_sepay_transaction_id, p_vnp_transaction_no, '');

  select * into b from public.bookings where code = p_booking_code for update;
  if not found then raise exception 'BOOKING_NOT_FOUND'; end if;
  if b.status <> 'holding' then raise exception 'NOT_HOLDING'; end if;
  if b.hold_until < now() then raise exception 'HOLD_EXPIRED'; end if;
  if (b.price_snapshot->>'total')::int <> p_amount then raise exception 'AMOUNT_MISMATCH'; end if;

  -- Cập nhật ghế thành sold
  update public.seats set status = 'sold', hold_until = null
  where booking_code = b.code;

  -- Cập nhật số ghế đã bán
  update public.showtimes set sold_seats = sold_seats + jsonb_array_length(b.seats)
  where id = b.showtime_id;

  -- Cập nhật booking
  update public.bookings set
    status = 'paid',
    hold_until = null,
    payment_method = 'sepay',
    sepay_transaction_id = v_trans_id,
    vnp_transaction_no = v_trans_id,
    paid_at = now(),
    food_status = case when jsonb_array_length(b.foods) > 0 then 'pending' else 'none' end
  where code = b.code;

  -- Cập nhật payments
  update public.payments set
    status = 'success',
    response_code = '00',
    sepay_transaction_id = v_trans_id,
    vnp_transaction_no = v_trans_id
  where txn_ref = p_txn_ref;

  -- Tạo thông báo
  if b.user_id is not null then
    insert into public.notifications (user_id, type, title, body, booking_code)
    values (
      b.user_id,
      'bookingPaid',
      'Đặt vé thành công',
      b.movie_title || ' · ' || b.cinema_name,
      b.code
    );
  end if;
end $$;

-- 3. release_hold: Nhả ghế khi thoát hoặc hết giờ
create or replace function public.release_hold(
  p_booking_code text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  delete from public.seats
  where booking_code = p_booking_code and status = 'holding';

  update public.bookings
  set status = 'expired'
  where code = p_booking_code and (user_id = v_uid or v_uid is null);

  update public.payments
  set status = 'expired'
  where booking_code = p_booking_code and status = 'pending';
end $$;

-- 4. check_in: Soát vé tại cửa rạp
create or replace function public.check_in(
  p_booking_code text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings%rowtype;
  v_uid uuid := auth.uid();
  v_role text;
  v_cid text;
  v_now timestamptz := now();
  v_st_start timestamptz;
  v_diff_utc_mins numeric;
  v_diff_vn_mins numeric;
  v_effective_mins numeric;
begin
  select role, cinema_id into v_role, v_cid from public.profiles where id = v_uid;
  if v_role not in ('staff', 'manager', 'admin') then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select * into b from public.bookings where code = p_booking_code for update;
  if not found then
    return jsonb_build_object('success', false, 'error_code', 'NOT_FOUND', 'message', 'Mã vé không tồn tại trong hệ thống');
  end if;

  if b.status = 'cancelled' then
    return jsonb_build_object('success', false, 'error_code', 'CANCELLED', 'message', 'Vé đã bị hủy và hoàn tiền');
  end if;

  if b.status = 'used' then
    return jsonb_build_object(
      'success', false,
      'error_code', 'ALREADY_USED',
      'message', 'Vé đã sử dụng lúc ' || to_char(b.checked_in_at at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI')
    );
  end if;

  if v_role <> 'admin' and b.cinema_id <> v_cid then
    return jsonb_build_object('success', false, 'error_code', 'WRONG_CINEMA', 'message', 'Vé thuộc rạp khác (' || b.cinema_name || ')');
  end if;

  -- Lấy start_time chính xác từ bảng showtimes hoặc từ booking
  select coalesce(s.start_time, b.showtime_start) into v_st_start
  from public.bookings bk
  left join public.showtimes s on s.id = bk.showtime_id
  where bk.code = b.code;

  if v_st_start is null then
    v_st_start := b.showtime_start;
  end if;

  -- Tính khoảng cách thời gian theo cả 2 cách (tránh lệch timezone UTC vs GMT+7):
  -- Cách 1: So sánh UTC chuẩn
  v_diff_utc_mins := extract(epoch from (v_st_start - v_now)) / 60.0;
  -- Cách 2: So sánh theo giờ địa phương Việt Nam (nếu dữ liệu bị lưu dạng wall-clock time mà không có offset)
  v_diff_vn_mins := extract(epoch from (v_st_start::timestamp - (v_now at time zone 'Asia/Ho_Chi_Minh')::timestamp)) / 60.0;

  -- Ưu tiên cách tính nào đưa thời gian vào khung cho phép soát vé (-15 phút đến 30 phút)
  if v_diff_utc_mins >= -15 and v_diff_utc_mins <= 30 then
    v_effective_mins := v_diff_utc_mins;
  elsif v_diff_vn_mins >= -15 and v_diff_vn_mins <= 30 then
    v_effective_mins := v_diff_vn_mins;
  else
    if abs(v_diff_utc_mins) < abs(v_diff_vn_mins) then
      v_effective_mins := v_diff_utc_mins;
    else
      v_effective_mins := v_diff_vn_mins;
    end if;
  end if;

  -- Kiểm tra: Chỉ vào trước tối đa 30 phút (v_effective_mins > 30 => quá sớm)
  if v_effective_mins > 30 then
    return jsonb_build_object('success', false, 'error_code', 'TOO_EARLY', 'message', 'Chưa đến giờ vào rạp (Chỉ vào trước tối đa 30 phút)');
  end if;

  -- Kiểm tra: Quá 15 phút sau giờ chiếu (v_effective_mins < -15 => quá muộn)
  if v_effective_mins < -15 then
    return jsonb_build_object('success', false, 'error_code', 'EXPIRED_SHOWTIME', 'message', 'Vé đã quá hạn sử dụng (Quá 15 phút sau giờ chiếu)');
  end if;

  -- Hợp lệ: Check-in
  update public.bookings
  set status = 'used',
      checked_in_by = v_uid,
      checked_in_at = v_now
  where code = b.code;

  insert into public.audit_logs (actor_id, actor_role, cinema_id, action, target_type, target_id)
  values (v_uid, v_role, b.cinema_id, 'checkIn', 'booking', b.code);

  return jsonb_build_object(
    'success', true,
    'code', b.code,
    'movie_title', b.movie_title,
    'room_name', b.room_name,
    'showtime_start', b.showtime_start,
    'seats', b.seats,
    'foods', b.foods,
    'age_rating', b.age_rating
  );
end $$;

-- 5. deliver_food: Giao đồ ăn tại quầy
create or replace function public.deliver_food(
  p_booking_code text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings%rowtype;
  v_uid uuid := auth.uid();
  v_role text;
  v_cid text;
begin
  select role, cinema_id into v_role, v_cid from public.profiles where id = v_uid;
  if v_role not in ('staff', 'manager', 'admin') then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select * into b from public.bookings where code = p_booking_code for update;
  if not found then raise exception 'BOOKING_NOT_FOUND'; end if;
  if v_role <> 'admin' and b.cinema_id <> v_cid then raise exception 'WRONG_CINEMA'; end if;
  if b.food_status <> 'pending' then raise exception 'INVALID_FOOD_STATUS'; end if;

  update public.bookings
  set food_status = 'delivered',
      food_delivered_by = v_uid,
      food_delivered_at = now()
  where code = b.code;

  if b.user_id is not null then
    insert into public.notifications (user_id, type, title, body, booking_code)
    values (b.user_id, 'foodDelivered', 'Đồ ăn đã sẵn sàng', 'Vui lòng nhận đồ ăn tại quầy: ' || b.cinema_name, b.code);
  end if;
end $$;

-- 6. cancel_booking: Hủy vé
create or replace function public.cancel_booking(
  p_booking_code text,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings%rowtype;
  v_uid uuid := auth.uid();
  v_role text;
  v_cid text;
  v_now timestamptz := now();
begin
  select role, cinema_id into v_role, v_cid from public.profiles where id = v_uid;
  select * into b from public.bookings where code = p_booking_code for update;
  if not found then raise exception 'BOOKING_NOT_FOUND'; end if;

  -- Khách chỉ hủy vé của mình và trước >= 2h
  if v_role = 'customer' or v_role is null then
    if b.user_id <> v_uid then raise exception 'NOT_OWNER'; end if;
    if b.status <> 'paid' then raise exception 'NOT_PAID'; end if;
    if v_now > (b.showtime_start - interval '2 hours') then
      raise exception 'CANNOT_CANCEL_LESS_THAN_2_HOURS';
    end if;
  else
    -- Manager/Admin
    if v_role = 'manager' and b.cinema_id <> v_cid then
      raise exception 'WRONG_CINEMA';
    end if;
  end if;

  -- Xóa ghế khỏi bảng seats
  delete from public.seats where booking_code = b.code;

  -- Giảm số ghế đã bán
  update public.showtimes
  set sold_seats = greatest(0, sold_seats - jsonb_array_length(b.seats))
  where id = b.showtime_id;

  -- Cập nhật booking
  update public.bookings set
    status = 'cancelled',
    food_status = case when food_status = 'pending' then 'cancelled' else food_status end,
    cancel_reason = p_reason,
    cancelled_by = v_uid,
    cancelled_at = v_now
  where code = b.code;

  -- Thông báo hoàn tiền
  if b.user_id is not null then
    insert into public.notifications (user_id, type, title, body, booking_code)
    values (
      b.user_id,
      'bookingRefunded',
      'Đã hoàn vé xem phim',
      'Vé ' || b.code || ' đã được hủy và hoàn tiền 100%.',
      b.code
    );
  end if;

  -- Ghi audit log
  insert into public.audit_logs (actor_id, actor_role, cinema_id, action, target_type, target_id, reason)
  values (v_uid, coalesce(v_role, 'customer'), b.cinema_id, 'refund', 'booking', b.code, p_reason);
end $$;

-- 7. sell_counter: Bán vé tại quầy (Staff / Manager)
create or replace function public.sell_counter(
  p_showtime_id uuid,
  p_booking_code text,
  p_seat_ids text[],
  p_payment_method text,
  p_booking jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role text;
  v_cid text;
  v_seat text;
  v_now timestamptz := now();
begin
  select role, cinema_id into v_role, v_cid from public.profiles where id = v_uid;
  if v_role not in ('staff', 'manager', 'admin') then raise exception 'NOT_AUTHORIZED'; end if;

  perform 1 from public.showtimes where id = p_showtime_id for update;

  foreach v_seat in array p_seat_ids loop
    if exists (
      select 1 from public.seats s
      where s.showtime_id = p_showtime_id and s.seat_id = v_seat and s.status = 'sold'
    ) then
      raise exception 'SEAT_TAKEN:%', v_seat;
    end if;
  end loop;

  -- Ghi ghế sold
  insert into public.seats (showtime_id, seat_id, status, booking_code, hold_holder, hold_until)
  select p_showtime_id, unnest(p_seat_ids), 'sold', p_booking_code, v_uid, null
  on conflict (showtime_id, seat_id) do update set status = 'sold', booking_code = excluded.booking_code;

  -- Tăng sold_seats
  update public.showtimes set sold_seats = sold_seats + array_length(p_seat_ids, 1) where id = p_showtime_id;

  -- Ghi booking
  insert into public.bookings (
    code, channel, sold_by, status, food_status, price_snapshot, payment_method, paid_at,
    showtime_id, cinema_id, movie_title, poster_url, age_rating, cinema_name, room_name,
    format, showtime_start, seats, foods
  ) values (
    p_booking_code, 'counter', v_uid, 'paid',
    case when jsonb_array_length(coalesce(p_booking->'foods', '[]'::jsonb)) > 0 then 'pending' else 'none' end,
    p_booking->'price_snapshot', p_payment_method, v_now,
    p_showtime_id, p_booking->>'cinema_id', p_booking->>'movie_title',
    p_booking->>'poster_url', p_booking->>'age_rating', p_booking->>'cinema_name',
    p_booking->>'room_name', p_booking->>'format', (p_booking->>'showtime_start')::timestamptz,
    coalesce(p_booking->'seats', '[]'::jsonb), coalesce(p_booking->'foods', '[]'::jsonb)
  )
  on conflict (code) do update set
    channel = 'counter',
    sold_by = excluded.sold_by,
    status = 'paid',
    food_status = excluded.food_status,
    price_snapshot = excluded.price_snapshot,
    payment_method = excluded.payment_method,
    paid_at = excluded.paid_at,
    seats = excluded.seats,
    foods = excluded.foods;
end $$;

-- 12. toggle_user_lock: Khóa / mở khóa tài khoản nhân viên (an toàn theo role & cinema)
create or replace function public.toggle_user_lock(
  p_user_id uuid,
  p_is_locked boolean
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_id uuid := auth.uid();
  v_caller_role text;
  v_caller_cinema text;
  v_target public.profiles%rowtype;
begin
  if v_caller_id is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if v_caller_id = p_user_id then
    raise exception 'CANNOT_LOCK_SELF';
  end if;

  select role, cinema_id into v_caller_role, v_caller_cinema
  from public.profiles where id = v_caller_id;

  select * into v_target from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'USER_NOT_FOUND';
  end if;

  -- Kiểm tra phân quyền:
  -- Admin được khóa/mở khóa mọi người trừ bản thân
  -- Manager chỉ được khóa/mở khóa nhân viên (staff) trong rạp của mình
  if v_caller_role = 'admin' then
    -- Hợp lệ
  elsif v_caller_role = 'manager' then
    if v_target.role <> 'staff' then
      raise exception 'NOT_AUTHORIZED_ROLE';
    end if;
    if v_target.cinema_id is distinct from v_caller_cinema then
      raise exception 'NOT_AUTHORIZED_CINEMA';
    end if;
  else
    raise exception 'NOT_AUTHORIZED';
  end if;

  update public.profiles
  set is_locked = p_is_locked,
      updated_at = now()
  where id = p_user_id;

  insert into public.audit_logs (actor_id, actor_role, cinema_id, action, target_type, target_id, reason)
  values (
    v_caller_id,
    v_caller_role,
    v_target.cinema_id,
    case when p_is_locked then 'lockUser' else 'unlockUser' end,
    'profile',
    p_user_id::text,
    case when p_is_locked then 'Khóa tài khoản nhân viên' else 'Mở khóa tài khoản nhân viên' end
  );

  return jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'is_locked', p_is_locked
  );
end $$;

grant execute on function public.toggle_user_lock(uuid, boolean) to authenticated;
