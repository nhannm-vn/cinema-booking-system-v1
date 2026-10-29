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
