-- 0009_refund_requests_foods_showtimes.sql
-- 1. Luồng yêu cầu hoàn vé: Customer gửi yêu cầu -> Admin xem -> SePay "tiền ra" STK 0000000001 -> webhook hoàn tất.
-- 2. Đồ ăn toàn hệ thống: Admin tạo món với cinema_id = NULL -> mọi rạp đều bán. Manager chỉ tạo món cho rạp mình.
-- 3. Không cho tạo suất chiếu trong quá khứ.

-- ============================================================================
-- 1. REFUND REQUESTS
-- ============================================================================
create table if not exists public.refund_requests (
  id uuid primary key default gen_random_uuid(),
  booking_code text not null references public.bookings(code) on delete cascade,
  user_id uuid not null references public.profiles(id),
  cinema_id text not null references public.cinemas(id),
  cinema_name text not null default '',
  movie_title text not null default '',
  showtime_start timestamptz not null,
  amount int not null check (amount >= 0),
  reason text,
  status text not null default 'pending' check (status in ('pending', 'completed', 'rejected')),
  sepay_transaction_id text,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

-- Mỗi vé chỉ có tối đa 1 yêu cầu đang chờ
create unique index if not exists refund_requests_one_pending
  on public.refund_requests (booking_code) where status = 'pending';
create index if not exists refund_requests_status_idx
  on public.refund_requests (status, created_at desc);

alter table public.refund_requests enable row level security;

drop policy if exists refund_requests_owner_read on public.refund_requests;
create policy refund_requests_owner_read on public.refund_requests for select
  using (user_id = auth.uid() or public.current_role_name() = 'admin');
-- Không có policy insert/update: mọi ghi đi qua RPC security definer hoặc service_role (webhook).

-- RPC: khách gửi yêu cầu hoàn vé (≥ 2h trước giờ chiếu, vé paid)
create or replace function public.request_refund(
  p_booking_code text,
  p_reason text default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  b public.bookings%rowtype;
  v_id uuid;
begin
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;

  select * into b from public.bookings where code = upper(p_booking_code) for update;
  if not found then raise exception 'BOOKING_NOT_FOUND'; end if;
  if b.user_id is distinct from v_uid then raise exception 'NOT_OWNER'; end if;
  if b.status <> 'paid' then raise exception 'NOT_PAID'; end if;
  if now() > (b.showtime_start - interval '2 hours') then
    raise exception 'CANNOT_CANCEL_LESS_THAN_2_HOURS';
  end if;
  if exists (select 1 from public.refund_requests where booking_code = b.code and status = 'pending') then
    raise exception 'REFUND_ALREADY_REQUESTED';
  end if;

  insert into public.refund_requests (
    booking_code, user_id, cinema_id, cinema_name, movie_title, showtime_start, amount, reason
  ) values (
    b.code, v_uid, b.cinema_id, b.cinema_name, b.movie_title, b.showtime_start,
    coalesce((b.price_snapshot->>'total')::int, 0),
    coalesce(p_reason, 'Khách yêu cầu hủy vé trực tuyến')
  ) returning id into v_id;

  insert into public.notifications (user_id, type, title, body, booking_code)
  values (
    v_uid, 'bookingRefunded', 'Đã gửi yêu cầu hoàn vé',
    'Yêu cầu hoàn vé ' || b.code || ' đang chờ Admin xử lý.', b.code
  );

  return jsonb_build_object('success', true, 'id', v_id, 'booking_code', b.code);
end $$;

grant execute on function public.request_refund(text, text) to authenticated;

-- RPC: hoàn tất hoàn vé (chỉ gọi từ webhook bằng service_role)
create or replace function public.complete_refund(
  p_booking_code text,
  p_amount int,
  p_sepay_transaction_id text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.refund_requests%rowtype;
  b public.bookings%rowtype;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select * into r from public.refund_requests
  where booking_code = upper(p_booking_code) and status = 'pending'
  for update;
  if not found then raise exception 'REFUND_REQUEST_NOT_FOUND'; end if;

  if p_amount <> r.amount then
    raise exception 'REFUND_AMOUNT_MISMATCH: cần % nhận %', r.amount, p_amount;
  end if;

  select * into b from public.bookings where code = r.booking_code for update;
  if b.status <> 'paid' and b.status <> 'cancelled' then raise exception 'NOT_PAID'; end if;

  delete from public.seats where booking_code = b.code;

  update public.showtimes
  set sold_seats = greatest(0, sold_seats - jsonb_array_length(b.seats))
  where id = b.showtime_id;

  update public.bookings set
    status = 'cancelled',
    food_status = case when food_status = 'pending' then 'cancelled' else food_status end,
    cancel_reason = coalesce(r.reason, 'Khách hủy vé') || ' · Hoàn tiền SePay ' || p_sepay_transaction_id,
    cancelled_at = coalesce(cancelled_at, now()),
    sepay_transaction_id = p_sepay_transaction_id
  where code = b.code;

  update public.refund_requests set
    status = 'completed',
    sepay_transaction_id = p_sepay_transaction_id,
    processed_at = now()
  where id = r.id;

  insert into public.notifications (user_id, type, title, body, booking_code)
  values (
    r.user_id, 'bookingRefunded', 'Đã hoàn vé xem phim',
    'Vé ' || b.code || ' đã được hoàn ' || r.amount || 'đ (100%) qua SePay.', b.code
  );

  insert into public.audit_logs (actor_id, actor_role, cinema_id, action, target_type, target_id, reason)
  values (null, 'admin', b.cinema_id, 'refund', 'booking', b.code,
          'Hoàn tiền SePay ' || p_sepay_transaction_id || ' số tiền ' || r.amount);

  return jsonb_build_object('success', true, 'booking_code', b.code, 'amount', r.amount);
end $$;

revoke execute on function public.complete_refund(text, int, text) from public, anon, authenticated;

-- Realtime cho màn Admin
do $$
begin
  alter publication supabase_realtime add table public.refund_requests;
exception when others then null;
end $$;

-- ============================================================================
-- 2. FOODS: cinema_id NULL = món toàn hệ thống (Admin tạo)
-- ============================================================================
alter table public.foods alter column cinema_id drop not null;

drop policy if exists foods_write on public.foods;
create policy foods_write on public.foods for all
  using (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'manager' and cinema_id is not null and cinema_id = public.current_cinema())
  )
  with check (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'manager' and cinema_id is not null and cinema_id = public.current_cinema())
  );

-- ============================================================================
-- 3. SHOWTIMES: không cho tạo/dời suất chiếu về quá khứ
-- ============================================================================
create or replace function public.check_showtime_not_past()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'active'
     and (tg_op = 'INSERT' or new.start_time is distinct from old.start_time)
     and new.start_time <= now() then
    raise exception 'SHOWTIME_IN_PAST';
  end if;
  if new.end_time <= new.start_time then
    raise exception 'SHOWTIME_INVALID_RANGE';
  end if;
  return new;
end $$;

drop trigger if exists trg_showtime_not_past on public.showtimes;
create trigger trg_showtime_not_past
  before insert or update on public.showtimes
  for each row execute function public.check_showtime_not_past();
