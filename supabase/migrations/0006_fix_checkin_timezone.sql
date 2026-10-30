-- 0006_fix_checkin_timezone.sql
-- Fix check_in and hold_seats timezone resilience for Vietnam GMT+7
-- Solves issue: showtime at 23:30, check-in at 23:19 rejected as TOO_EARLY due to timezone offset

-- 1. Đồng bộ lại showtime_start từ bảng showtimes cho các booking đã tạo
update public.bookings b
set showtime_start = s.start_time
from public.showtimes s
where b.showtime_id = s.id
  and b.showtime_start <> s.start_time;

-- 2. Cập nhật hàm hold_seats để luôn lấy start_time chính xác từ public.showtimes
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

-- 3. Cập nhật hàm check_in kiểm tra giờ chiếu linh hoạt theo cả UTC và múi giờ Việt Nam GMT+7
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
