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
  payment_method text check (payment_method in ('vnpay', 'cash', 'card', 'demo')),
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
