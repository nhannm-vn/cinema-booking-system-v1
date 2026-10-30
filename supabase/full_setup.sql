-- 0001_schema.sql
-- Schema definition for Cinema Booking & Operation Management App
-- References: TECH_STACK.md Section 4 & BUSINESS_RULES.md

create extension if not exists "uuid-ossp";

-- 1. Cinemas (Chuỗi rạp)
create table public.cinemas (
  id text primary key, -- e.g. 'cn_q1', 'cn_tb'
  name text not null,
  address text not null,
  phone text,
  lat double precision not null,
  lng double precision not null,
  opening_hours text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 2. Profiles (Hồ sơ người dùng liên kết auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  role text not null default 'customer' check (role in ('customer', 'staff', 'manager', 'admin')),
  cinema_id text references public.cinemas(id),
  is_locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index on public.profiles (cinema_id);
create index on public.profiles (role);

-- 3. Rooms (Phòng chiếu)
create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  cinema_id text not null references public.cinemas(id) on delete cascade,
  name text not null,
  formats text[] not null default '{"2D"}',
  rows int not null,
  cols int not null,
  seat_layout text[] not null default '{}',
  seat_count int not null,
  created_at timestamptz not null default now()
);

create index on public.rooms (cinema_id);

-- 4. Movies (Phim)
create table public.movies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  genres text[] not null default '{}',
  duration_min int not null,
  age_rating text not null check (age_rating in ('P', 'T13', 'T16', 'T18')),
  release_date date not null,
  is_active boolean not null default true,
  description text,
  director text,
  cast_members text[] default '{}',
  poster_url text,
  backdrop_url text,
  trailer_url text,
  created_at timestamptz not null default now()
);

create index on public.movies (is_active, release_date);

-- 5. Foods (Đồ ăn / Thức uống)
create table public.foods (
  id uuid primary key default gen_random_uuid(),
  cinema_id text not null references public.cinemas(id) on delete cascade,
  name text not null,
  category text not null check (category in ('combo', 'popcorn', 'drink', 'snack')),
  price int not null,
  is_available boolean not null default true,
  image_url text,
  description text,
  created_at timestamptz not null default now()
);

create index on public.foods (cinema_id, is_available);

-- 6. Showtimes (Suất chiếu)
create table public.showtimes (
  id uuid primary key default gen_random_uuid(),
  movie_id uuid not null references public.movies(id) on delete cascade,
  cinema_id text not null references public.cinemas(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  format text not null check (format in ('2D', '3D', 'IMAX')),
  start_time timestamptz not null,
  end_time timestamptz not null,
  status text not null default 'active' check (status in ('active', 'cancelled')),
  cancel_reason text,
  total_seats int not null,
  sold_seats int not null default 0,
  created_at timestamptz not null default now()
);

create index on public.showtimes (cinema_id, start_time);
create index on public.showtimes (movie_id, start_time);
create index on public.showtimes (room_id, start_time);

-- 7. Bookings (Đơn đặt vé)
create table public.bookings (
  code text primary key check (char_length(code) = 8),
  user_id uuid references public.profiles(id),
  channel text not null check (channel in ('online', 'counter')),
  sold_by uuid references public.profiles(id),
  status text not null check (status in ('holding', 'paid', 'used', 'cancelled', 'expired')),
  hold_until timestamptz,
  showtime_id uuid not null references public.showtimes(id),
  cinema_id text not null references public.cinemas(id),
  movie_title text not null,
  poster_url text,
  age_rating text,
  cinema_name text not null,
  room_name text not null,
  format text not null,
  showtime_start timestamptz not null,
  seats jsonb not null default '[]',
  foods jsonb not null default '[]',
  food_status text not null default 'none' check (food_status in ('none', 'pending', 'delivered', 'cancelled')),
  food_delivered_by uuid references public.profiles(id),
  food_delivered_at timestamptz,
  price_snapshot jsonb not null,
  payment_method text check (payment_method in ('sepay', 'vnpay', 'cash', 'card', 'demo')),
  sepay_transaction_id text,
  vnp_transaction_no text,
  paid_at timestamptz,
  checked_in_by uuid references public.profiles(id),
  checked_in_at timestamptz,
  cancel_reason text,
  cancelled_by uuid references public.profiles(id),
  cancelled_at timestamptz,
  created_at timestamptz not null default now()
);

create index on public.bookings (cinema_id, created_at desc);
create index on public.bookings (user_id, created_at desc);
create index on public.bookings (cinema_id, food_status, showtime_start);
create index on public.bookings (showtime_id);

-- 8. Seats (Trạng thái ghế theo suất chiếu)
create table public.seats (
  showtime_id uuid not null references public.showtimes(id) on delete cascade,
  seat_id text not null,
  status text not null check (status in ('holding', 'sold')),
  booking_code text not null references public.bookings(code) on delete cascade,
  hold_holder uuid references public.profiles(id),
  hold_until timestamptz,
  primary key (showtime_id, seat_id)
);

create index on public.seats (booking_code);
create index on public.seats (showtime_id, status);

-- 9. Payments (Giao dịch thanh toán)
create table public.payments (
  txn_ref text primary key,
  booking_code text not null references public.bookings(code) on delete cascade,
  amount int not null,
  status text not null check (status in ('pending', 'success', 'failed', 'expired')),
  response_code text,
  sepay_transaction_id text,
  vnp_transaction_no text,
  created_at timestamptz not null default now()
);

create index on public.payments (booking_code);

-- 10. Notifications (Thông báo người dùng)
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('bookingPaid', 'showReminder', 'showtimeCancelled', 'bookingRefunded', 'foodDelivered', 'chatMessage')),
  title text not null,
  body text not null,
  booking_code text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index on public.notifications (user_id, is_read, created_at desc);

-- 11. Pricing Settings (Cấu hình giá vé hệ thống)
create table public.pricing_settings (
  id int primary key default 1 check (id = 1),
  base_2d int not null default 80000,
  base_3d int not null default 100000,
  base_imax int not null default 120000,
  surcharge_vip int not null default 20000,
  surcharge_couple int not null default 20000,
  surcharge_weekend int not null default 10000,
  surcharge_prime int not null default 10000,
  prime_start_hour int not null default 18,
  prime_end_hour int not null default 22,
  updated_at timestamptz not null default now()
);

-- 12. Vouchers (Mã giảm giá - mức S)
create table public.vouchers (
  code text primary key,
  type text not null check (type in ('percent', 'amount')),
  value int not null,
  expires_at timestamptz not null,
  max_uses int not null default 1,
  used_count int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 13. Audit Logs (Nhật ký thao tác - mức S)
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id),
  actor_role text not null,
  cinema_id text references public.cinemas(id),
  action text not null,
  target_type text not null,
  target_id text not null,
  reason text,
  created_at timestamptz not null default now()
);

create index on public.audit_logs (cinema_id, created_at desc);
create index on public.audit_logs (action, created_at desc);

-- 14. Support Chat (Hỗ trợ khách hàng - mức S)
create table public.conversations (
  id text primary key, -- user_id || '_' || cinema_id
  user_id uuid not null references public.profiles(id) on delete cascade,
  cinema_id text not null references public.cinemas(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id text not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  text text not null,
  booking_code text,
  created_at timestamptz not null default now()
);

create index on public.messages (conversation_id, created_at asc);
-- 0002_rls.sql
-- Row Level Security policies for Cinema Booking App
-- References: TECH_STACK.md Section 6 & BUSINESS_RULES.md Section 2

-- 1. Enable RLS on all tables
alter table public.cinemas enable row level security;
alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.movies enable row level security;
alter table public.foods enable row level security;
alter table public.showtimes enable row level security;
alter table public.bookings enable row level security;
alter table public.seats enable row level security;
alter table public.payments enable row level security;
alter table public.notifications enable row level security;
alter table public.pricing_settings enable row level security;
alter table public.vouchers enable row level security;
alter table public.audit_logs enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- 2. Helper functions for role & cinema checking
create or replace function public.current_role_name() returns text
language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid() and not is_locked;
$$;

create or replace function public.current_cinema() returns text
language sql stable security definer set search_path = public as $$
  select cinema_id from public.profiles where id = auth.uid();
$$;

-- 3. Profiles policies
create policy profiles_select on public.profiles for select using (
  id = auth.uid()
  or public.current_role_name() = 'admin'
  or (public.current_role_name() in ('staff', 'manager') and cinema_id = public.current_cinema())
);

create policy profiles_update_self on public.profiles for update using (
  id = auth.uid()
) with check (
  id = auth.uid()
);

-- 4. Cinemas & Rooms policies (Public read, admin write)
create policy cinemas_read on public.cinemas for select using (true);
create policy cinemas_admin_write on public.cinemas for all
  using (public.current_role_name() = 'admin')
  with check (public.current_role_name() = 'admin');

create policy rooms_read on public.rooms for select using (true);
create policy rooms_admin_write on public.rooms for all
  using (public.current_role_name() = 'admin')
  with check (public.current_role_name() = 'admin');

-- 5. Movies policies (Public read, admin write)
create policy movies_read on public.movies for select using (true);
create policy movies_admin_write on public.movies for all
  using (public.current_role_name() = 'admin')
  with check (public.current_role_name() = 'admin');

-- 6. Foods policies (Public read, manager & admin write)
create policy foods_read on public.foods for select using (true);
create policy foods_write on public.foods for all
  using (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'manager' and cinema_id = public.current_cinema())
  )
  with check (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'manager' and cinema_id = public.current_cinema())
  );

-- 7. Showtimes policies (Public read, manager & admin write)
create policy showtimes_read on public.showtimes for select using (true);
create policy showtimes_write on public.showtimes for all
  using (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'manager' and cinema_id = public.current_cinema())
  )
  with check (
    public.current_role_name() = 'admin'
    or (public.current_role_name() = 'manager' and cinema_id = public.current_cinema())
  );

-- 8. Bookings policies (Customer sees own, staff/manager sees their cinema, admin sees all)
create policy bookings_select on public.bookings for select using (
  user_id = auth.uid()
  or public.current_role_name() = 'admin'
  or (public.current_role_name() in ('staff', 'manager') and cinema_id = public.current_cinema())
);

-- Disallow direct insert/update from client; all modifications go through RPC functions
create policy bookings_no_direct_insert on public.bookings for insert with check (false);
create policy bookings_no_direct_update on public.bookings for update using (false);
create policy bookings_no_direct_delete on public.bookings for delete using (false);

-- 9. Seats policies (Read all authenticated, direct write forbidden)
create policy seats_select on public.seats for select using (auth.uid() is not null);
create policy seats_no_direct_insert on public.seats for insert with check (false);
create policy seats_no_direct_update on public.seats for update using (false);
create policy seats_no_direct_delete on public.seats for delete using (false);

-- 10. Payments policies
create policy payments_select on public.payments for select using (
  exists (
    select 1 from public.bookings b
    where b.code = payments.booking_code
      and (b.user_id = auth.uid() or public.current_role_name() = 'admin' or (public.current_role_name() in ('staff', 'manager') and b.cinema_id = public.current_cinema()))
  )
);
create policy payments_no_direct_write on public.payments for update using (false);
create policy payments_no_direct_insert on public.payments for insert with check (false);

-- 11. Notifications policies (Owner only)
create policy notif_own on public.notifications for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 12. Pricing Settings policies (Public read, admin write)
create policy pricing_read on public.pricing_settings for select using (true);
create policy pricing_admin_write on public.pricing_settings for all
  using (public.current_role_name() = 'admin')
  with check (public.current_role_name() = 'admin');

-- 13. Vouchers policies (Public read active, admin write)
create policy vouchers_read on public.vouchers for select using (is_active);
create policy vouchers_admin_write on public.vouchers for all
  using (public.current_role_name() = 'admin')
  with check (public.current_role_name() = 'admin');

-- 14. Audit logs policies (Admin only)
create policy audit_logs_admin on public.audit_logs for select
  using (public.current_role_name() = 'admin');
create policy audit_logs_insert on public.audit_logs for insert
  with check (auth.uid() is not null);

-- 15. Conversations & Messages policies
create policy conv_participants on public.conversations for all
  using (
    user_id = auth.uid()
    or public.current_role_name() = 'admin'
    or (public.current_role_name() in ('staff', 'manager') and cinema_id = public.current_cinema())
  );

create policy msg_participants on public.messages for all
  using (
    sender_id = auth.uid()
    or exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.user_id = auth.uid() or public.current_role_name() = 'admin' or (public.current_role_name() in ('staff', 'manager') and c.cinema_id = public.current_cinema()))
    )
  );
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
    (p_booking->>'showtime_start')::timestamptz,
    coalesce(p_booking->'seats', '[]'::jsonb),
    coalesce(p_booking->'foods', '[]'::jsonb)
  )
  on conflict (code) do update set
    hold_until = excluded.hold_until,
    price_snapshot = excluded.price_snapshot,
    seats = excluded.seats,
    foods = excluded.foods;

  -- Ghi ghế sau (thỏa mãn foreign key seats_booking_code_fkey)
  insert into public.seats (showtime_id, seat_id, status, booking_code, hold_holder, hold_until)
  select p_showtime_id, unnest(p_seat_ids), 'holding', p_booking_code, v_uid, v_until
  on conflict (showtime_id, seat_id) do update
    set status = 'holding',
        booking_code = excluded.booking_code,
        hold_holder = excluded.hold_holder,
        hold_until = excluded.hold_until;

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
    return jsonb_build_object('success', false, 'error_code', 'ALREADY_USED', 'message', 'Vé đã sử dụng lúc ' || to_char(b.checked_in_at, 'HH24:MI'));
  end if;

  if v_role <> 'admin' and b.cinema_id <> v_cid then
    return jsonb_build_object('success', false, 'error_code', 'WRONG_CINEMA', 'message', 'Vé thuộc rạp khác (' || b.cinema_name || ')');
  end if;

  if v_now < (b.showtime_start - interval '30 minutes') then
    return jsonb_build_object('success', false, 'error_code', 'TOO_EARLY', 'message', 'Chưa đến giờ vào rạp (Chỉ vào trước tối đa 30 phút)');
  end if;

  if v_now > (b.showtime_start + interval '15 minutes') then
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
-- 0004_triggers.sql
-- Triggers for Cinema Booking App
-- References: TECH_STACK.md Section 6 & 7

-- 1. Tự động tạo hồ sơ profile khi đăng ký tài khoản khách mới
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, role, is_locked)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    'customer',
    false
  )
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Chặn tự nâng quyền hoặc đổi rạp trái phép
create or replace function public.protect_profile_fields() returns trigger
language plpgsql as $$
begin
  if public.current_role_name() is distinct from 'admin' then
    new.role := old.role;
    new.cinema_id := old.cinema_id;
    new.is_locked := old.is_locked;
  end if;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_protect_profile on public.profiles;
create trigger trg_protect_profile
  before update on public.profiles
  for each row execute function public.protect_profile_fields();
-- 0005_seed.sql
-- Seed data for Cinema Booking App
-- References: BUSINESS_RULES.md Section 2 & 4

-- 1. Pricing Settings
insert into public.pricing_settings (
  id, base_2d, base_3d, base_imax,
  surcharge_vip, surcharge_couple, surcharge_weekend, surcharge_prime,
  prime_start_hour, prime_end_hour
) values (
  1, 80000, 100000, 120000,
  20000, 20000, 10000, 10000,
  18, 22
) on conflict (id) do nothing;

-- 2. Cinemas
insert into public.cinemas (id, name, address, phone, lat, lng, opening_hours, is_active)
values
  ('cn_q1', 'CGV Vincom Center Đồng Khởi', 'Tầng 3, TTTM Vincom Center, 72 Lê Thánh Tôn, Phường Bến Nghé, Quận 1, TP.HCM', '1900 6017', 10.77810, 106.70220, '08:00 - 23:30', true),
  ('cn_tb', 'Lotte Cinema Cộng Hòa (Pico Plaza)', 'Tầng 4, Pico Plaza, 20 Cộng Hòa, Phường 12, Quận Tân Bình, TP.HCM', '028 3844 5678', 10.80155, 106.65225, '08:30 - 23:00', true)
on conflict (id) do update set
  name = excluded.name,
  address = excluded.address,
  phone = excluded.phone,
  lat = excluded.lat,
  lng = excluded.lng,
  opening_hours = excluded.opening_hours,
  is_active = excluded.is_active;

-- 3. Rooms
insert into public.rooms (id, cinema_id, name, formats, rows, cols, seat_layout, seat_count)
values
  ('11111111-1111-1111-1111-111111111111', 'cn_q1', 'Phòng Chiếu 1 (IMAX)', '{"2D", "IMAX"}', 8, 10, '{
    "S,S,S,S,S,S,S,S,S,S",
    "S,S,S,S,S,S,S,S,S,S",
    "S,S,S,S,S,S,S,S,S,S",
    "V,V,V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V,V,V",
    "C,C,C,C,C"
  }', 75),
  ('22222222-2222-2222-2222-222222222222', 'cn_q1', 'Phòng Chiếu 2 (Standard)', '{"2D", "3D"}', 6, 8, '{
    "S,S,S,S,S,S,S,S",
    "S,S,S,S,S,S,S,S",
    "V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V",
    "C,C,C,C"
  }', 44),
  ('33333333-3333-3333-3333-333333333333', 'cn_tb', 'Phòng Chiếu 1', '{"2D", "3D"}', 7, 8, '{
    "S,S,S,S,S,S,S,S",
    "S,S,S,S,S,S,S,S",
    "V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V",
    "V,V,V,V,V,V,V,V",
    "C,C,C,C"
  }', 52)
on conflict (id) do nothing;

-- 4. Movies
insert into public.movies (
  id, title, genres, duration_min, age_rating, release_date, is_active,
  description, director, cast_members, poster_url, backdrop_url, trailer_url
) values
  (
    '44444444-4444-4444-4444-444444444444',
    'Oppenheimer: Kẻ Chế Tạo Bom',
    '{"Hồi kịch", "Lịch sử", "Tiểu sử"}',
    180,
    'T18',
    '2026-08-11',
    true,
    'Câu chuyện về nhà vật lý lý thuyết J. Robert Oppenheimer, người đứng đầu Dự án Manhattan tạo ra quả bom nguyên tử đầu tiên trong lịch sử loài người.',
    'Christopher Nolan',
    '{"Cillian Murphy", "Emily Blunt", "Matt Damon", "Robert Downey Jr."}',
    'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600',
    'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=1200',
    'https://www.youtube.com/watch?v=uYPbbksJxIg'
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    'Dune: Hành Tinh Cát - Phần Hai',
    '{"Hành động", "Phiêu lưu", "Khoa học viễn tưởng"}',
    166,
    'T16',
    '2026-09-01',
    true,
    'Paul Atreides hợp lực cùng Chani và người Fremen để trả thù những kẻ đã tàn phá gia đình mình, đồng thời đối mặt với lựa chọn giữa tình yêu và số phận vũ trụ.',
    'Denis Villeneuve',
    '{"Timothée Chalamet", "Zendaya", "Rebecca Ferguson", "Javier Bardem"}',
    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600',
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200',
    'https://www.youtube.com/watch?v=Way9Dexny3w'
  ),
  (
    '66666666-6666-6666-6666-666666666666',
    'Kẻ Trộm Mặt Trăng 4',
    '{"Hoạt hình", "Hài hước", "Gia đình"}',
    95,
    'P',
    '2026-12-20',
    true,
    'Gru và đại gia đình trở lại trong một cuộc phiêu lưu hoàn toàn mới, đối đầu với kẻ thù mới cùng những trò tinh quái vô tiền khoáng hậu của biệt đội Minions.',
    'Chris Renaud',
    '{"Steve Carell", "Kristen Wiig", "Will Ferrell"}',
    'https://images.unsplash.com/photo-1578328819058-b69f3a3b0f6b?w=600',
    'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1200',
    'https://www.youtube.com/watch?v=qQlr9-rF32A'
  )
on conflict (id) do nothing;

-- 5. Foods
insert into public.foods (id, cinema_id, name, category, price, is_available, image_url, description)
values
  ('77777777-7777-7777-7777-777777777777', 'cn_q1', 'Combo Solo (1 Bắp + 1 Nước)', 'combo', 85000, true, 'https://images.unsplash.com/photo-1585647347483-22b66260dfff?w=500', '1 bắp ngọt 60oz + 1 nước ngọt 32oz tự chọn'),
  ('88888888-8888-8888-8888-888888888888', 'cn_q1', 'Combo Couple (1 Bắp + 2 Nước)', 'combo', 110000, true, 'https://images.unsplash.com/photo-1572177191856-3cde618dee1f?w=500', '1 bắp ngọt lớn 80oz + 2 nước ngọt 32oz'),
  ('99999999-9999-9999-9999-999999999999', 'cn_q1', 'Bắp Rang Phô Mai', 'popcorn', 65000, true, 'https://images.unsplash.com/photo-1505686994434-e3cc5abf1330?w=500', 'Bắp rang giòn thơm vị phô mai thượng hạng'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cn_q1', 'Coca Cola Tươi 32oz', 'drink', 35000, true, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500', 'Nước ngọt có gas ướp lạnh mát lạnh sảng khoái')
on conflict (id) do nothing;

-- 6. Vouchers
insert into public.vouchers (code, type, value, expires_at, max_uses, used_count, is_active)
values
  ('CINEMA20', 'percent', 20, now() + interval '90 days', 500, 0, true),
  ('VIP50K', 'amount', 50000, now() + interval '60 days', 200, 0, true)
on conflict (code) do nothing;

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
  'sepay',
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

