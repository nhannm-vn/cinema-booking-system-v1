# TECH_STACK.md — Công nghệ đơn giản và nhanh nhất cho Cinema Booking App

> File này thay thế Firebase bằng **Supabase + PostgreSQL**. Mục tiêu: ít thứ phải học, ít code phải viết, chạy được demo trong vài ngày.
> Đọc file này sau `00_README.md`, trước `PROJECT_STRUCTURE.md`. Khi xung đột với file khác, file này thắng về công nghệ.

---

## 1. Bộ công nghệ chốt

| Tầng | Công nghệ | Vai trò | Lý do chọn |
|---|---|---|---|
| App client | **Flutter** (Dart 3) | Giao diện Android, iOS | Đã có trong thiết kế |
| State | **provider** | Quản lý state | Đơn giản, đủ dùng |
| Backend as a Service | **Supabase** | Auth, database, realtime, storage, edge functions | Một nền tảng thay cho 5 dịch vụ Firebase |
| Database | **PostgreSQL** (có sẵn trong Supabase) | Dữ liệu quan hệ, transaction, khóa dòng | Giữ ghế cần khóa dòng, Postgres làm tốt hơn NoSQL |
| Bảo mật dữ liệu | **Row Level Security (RLS)** | Phân quyền theo role và rạp ngay trong DB | Thay cho Firestore Rules, chặn lỗi cả khi client bị sửa |
| Logic nghiệp vụ nhạy cảm | **Postgres functions (RPC)** | Giữ ghế, xác nhận thanh toán, hủy vé, soát vé | Chạy trong một transaction phía DB, client không tự ghi trạng thái |
| Xử lý server nhẹ | **Supabase Edge Functions** (Deno/TypeScript) | Tạo URL VNPay, nhận IPN, tạo tài khoản nhân viên | Giữ được HashSecret và service key khỏi app |
| Realtime | **Supabase Realtime** | Sơ đồ ghế cập nhật trực tiếp | Có sẵn, không cần code socket |
| Lưu file | **Supabase Storage** | Poster, backdrop, ảnh món ăn | Có sẵn, có CDN |
| Thanh toán | **VNPay Sandbox** | Cổng thanh toán | Theo yêu cầu |
| Bản đồ | **google_maps_flutter**, **geolocator** | Tab Rạp | Theo thiết kế |
| QR | **qr_flutter**, **mobile_scanner** | Vé điện tử, soát vé | Theo thiết kế |
| Thông báo cục bộ | **flutter_local_notifications** | Nhắc suất chiếu | Theo thiết kế |

**Không dùng:** Firebase (toàn bộ), Cloud Functions, Riverpod, Bloc, Prisma, ORM trên client. Dart chỉ gọi Supabase SDK, không kết nối trực tiếp tới Postgres.

---

## 2. Kiến trúc tổng thể

```text
┌──────────────────────────── Flutter App ────────────────────────────┐
│  Screens → Providers (provider) → Repositories → supabase_flutter   │
└───────────────┬───────────────────────┬──────────────────┬──────────┘
                │ REST / RPC            │ Realtime         │ Storage
                ▼                       ▼                  ▼
┌──────────────────────────── Supabase ───────────────────────────────┐
│  Auth (email/password)                                              │
│  PostgreSQL  ── RLS policies ── RPC functions (giữ ghế, thanh toán) │
│  Realtime    (bảng seats)                                           │
│  Storage     (poster, backdrop, ảnh món)                            │
│  Edge Functions:                                                    │
│     • create-vnpay-url   (ký HMAC-SHA512, giữ HashSecret)           │
│     • vnpay-return       (xác minh chữ ký, gọi confirm_payment)     │
│     • create-staff       (tạo user Auth bằng service role)          │
└─────────────────────────────────────────────────────────────────────┘
                ▲
                │ redirect return URL / IPN
           VNPay Sandbox (WebView trong app)
```

**Điểm khác với bản Firebase:** logic giữ ghế và thanh toán chạy trong Postgres, không chạy trong app. App chỉ gọi hàm và nhận kết quả. Chữ ký VNPay và giá tiền được kiểm tra ở Edge Function, nên không bị lộ khóa như khi để trong client.

---

## 3. Cấu trúc project Supabase

```text
supabase/
├── config.toml
├── migrations/
│   ├── 0001_schema.sql            # Bảng, enum, index
│   ├── 0002_rls.sql               # Row Level Security
│   ├── 0003_functions.sql         # RPC: hold_seats, confirm_payment, ...
│   ├── 0004_triggers.sql          # updated_at, đồng bộ profile
│   └── 0005_seed.sql              # Dữ liệu mẫu (DATA.md mục 9)
└── functions/
    ├── create-vnpay-url/index.ts
    ├── vnpay-return/index.ts
    └── create-staff/index.ts
```

---

## 4. Schema PostgreSQL (tóm tắt, ánh xạ từ DATA.md)

Quy ước: tên bảng `snake_case` số nhiều. Khóa chính `uuid` (trừ mã booking là `text`). Tiền là `integer` (VND). Thời gian là `timestamptz`. Enum dùng `text` kèm `CHECK`, dễ đổi hơn `enum` của Postgres.

| Bảng | Khóa chính | Ghi chú |
|---|---|---|
| `profiles` | `id uuid` (= `auth.users.id`) | `full_name`, `phone`, `role`, `cinema_id`, `is_locked` |
| `movies` | `id uuid` | `title`, `genres text[]`, `duration_min`, `age_rating`, `release_date`, `is_active`, `poster_url`, `backdrop_url`, `trailer_url` |
| `cinemas` | `id text` (ví dụ `cn_q1`) | `name`, `address`, `phone`, `lat`, `lng`, `opening_hours`, `is_active` |
| `rooms` | `id uuid` | `cinema_id`, `name`, `formats text[]`, `rows`, `cols`, `seat_layout text[]`, `seat_count` |
| `foods` | `id uuid` | `cinema_id`, `name`, `category`, `price`, `is_available`, `image_url` |
| `showtimes` | `id uuid` | `movie_id`, `cinema_id`, `room_id`, `format`, `start_time`, `end_time`, `status`, `total_seats`, `sold_seats` |
| `seats` | `(showtime_id, seat_id)` | `status` (`holding`/`sold`), `booking_code`, `hold_holder`, `hold_until`. Chỉ tồn tại khi giữ hoặc đã bán |
| `bookings` | `code text` (8 ký tự) | Trạng thái, snapshot suất/phim/rạp, `price_snapshot jsonb`, `foods jsonb`, `seats jsonb` |
| `payments` | `txn_ref text` | `booking_code`, `amount`, `status`, `response_code`, `vnp_transaction_no` |
| `notifications` | `id uuid` | `user_id`, `type`, `title`, `body`, `booking_code`, `is_read` |
| `pricing_settings` | `id int = 1` | 1 dòng duy nhất: giá cơ sở, phụ thu, khung giờ vàng, ngày cuối tuần |
| `vouchers` | `code text` | `type`, `value`, `expires_at`, `max_uses`, `used_count`, `is_active` (mức S) |
| `audit_logs` | `id uuid` | `actor_id`, `actor_role`, `cinema_id`, `action`, `target_type`, `target_id`, `reason` (mức S) |
| `conversations` | `id text` = `user_id || '_' || cinema_id` | (mức S) |
| `messages` | `id uuid` | `conversation_id`, `sender_id`, `text`, `booking_code`, `created_at` (mức S) |

### 4.1 Ví dụ DDL cho ghế và booking

```sql
create table public.seats (
  showtime_id uuid not null references public.showtimes(id) on delete cascade,
  seat_id     text not null,                       -- 'A5', 'H3'
  status      text not null check (status in ('holding','sold')),
  booking_code text not null references public.bookings(code) on delete cascade,
  hold_holder uuid,                                -- auth.uid() người giữ
  hold_until  timestamptz,                         -- null khi sold
  primary key (showtime_id, seat_id)
);

create index on public.seats (booking_code);

create table public.bookings (
  code          text primary key check (char_length(code) = 8),
  user_id       uuid references public.profiles(id),
  channel       text not null check (channel in ('online','counter')),
  sold_by       uuid references public.profiles(id),
  status        text not null check (status in ('holding','paid','used','cancelled','expired')),
  hold_until    timestamptz,
  showtime_id   uuid not null references public.showtimes(id),
  cinema_id     text not null references public.cinemas(id),
  movie_title   text not null,
  poster_url    text,
  age_rating    text,
  cinema_name   text not null,
  room_name     text not null,
  format        text not null,
  showtime_start timestamptz not null,
  seats         jsonb not null default '[]',       -- [{id,type,price}]
  foods         jsonb not null default '[]',       -- [{food_id,name,qty,unit_price}]
  food_status   text not null default 'none' check (food_status in ('none','pending','delivered','cancelled')),
  food_delivered_by uuid, food_delivered_at timestamptz,
  price_snapshot jsonb not null,                   -- {ticket_total, food_total, discount, total}
  payment_method text check (payment_method in ('vnpay','cash','card','demo')),
  vnp_transaction_no text,
  paid_at       timestamptz,
  checked_in_by uuid, checked_in_at timestamptz,
  cancel_reason text, cancelled_by uuid, cancelled_at timestamptz,
  created_at    timestamptz not null default now()
);

create index on public.bookings (cinema_id, created_at desc);
create index on public.bookings (user_id, created_at desc);
create index on public.bookings (cinema_id, food_status, showtime_start);
```

`noShow` không lưu, tính khi đọc (giống BUSINESS_RULES mục 6.1). Có thể tạo view `bookings_view` thêm cột `view_status` để app đọc một chỗ.

---

## 5. Hàm nghiệp vụ trong Postgres (thay cho transaction phía client)

Đây là phần thay thế trực tiếp `holdSeats`, `confirmPaid` ở `DATA.md` mục 6. Toàn bộ logic chạy trong một transaction phía DB.

### 5.1 Giữ ghế: `hold_seats`

Khóa dòng `showtimes` để mọi đặt cùng suất được xử lý tuần tự. Cách này đơn giản và đúng, không cần kiểm tra race condition thủ công.

```sql
create or replace function public.hold_seats(
  p_showtime_id uuid,
  p_booking_code text,
  p_seat_ids text[],
  p_hold_minutes int,
  p_booking jsonb              -- toàn bộ dữ liệu booking đã tính giá ở client
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
  if v_uid is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if array_length(p_seat_ids, 1) is null or array_length(p_seat_ids, 1) > 8 then
    raise exception 'INVALID_SEAT_COUNT';
  end if;

  -- Khóa suất: các khách cùng suất xếp hàng
  perform 1 from public.showtimes where id = p_showtime_id for update;
  if not found then raise exception 'SHOWTIME_NOT_FOUND'; end if;

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

  -- Ghi ghế
  insert into public.seats (showtime_id, seat_id, status, booking_code, hold_holder, hold_until)
  select p_showtime_id, unnest(p_seat_ids), 'holding', p_booking_code, v_uid, v_until
  on conflict (showtime_id, seat_id) do update
    set status = 'holding', booking_code = excluded.booking_code,
        hold_holder = excluded.hold_holder, hold_until = excluded.hold_until;

  -- Ghi booking
  insert into public.bookings
    (code, user_id, channel, status, hold_until, food_status, price_snapshot,
     showtime_id, cinema_id, movie_title, poster_url, age_rating, cinema_name,
     room_name, format, showtime_start, seats, foods)
  select
    p_booking_code, v_uid, 'online', 'holding', v_until, 'none', p_booking->'price_snapshot',
    (p_booking->>'showtime_id')::uuid, p_booking->>'cinema_id', p_booking->>'movie_title',
    p_booking->>'poster_url', p_booking->>'age_rating', p_booking->>'cinema_name',
    p_booking->>'room_name', p_booking->>'format', (p_booking->>'showtime_start')::timestamptz,
    p_booking->'seats', coalesce(p_booking->'foods', '[]'::jsonb);

  return v_until;
end $$;
```

Lưu ý: không lưu `seats` vào bảng riêng cho booking. Danh sách ghế nằm trong `bookings.seats` (jsonb) và trong `seats` (cho trạng thái). Hai nơi này phải khớp, hàm trên đảm bảo điều đó.

### 5.2 Xác nhận thanh toán: `confirm_payment`

Chỉ được gọi từ Edge Function `vnpay-return` **sau khi đã xác minh chữ ký**. Client không gọi trực tiếp.

```sql
create or replace function public.confirm_payment(
  p_booking_code text,
  p_txn_ref text,
  p_vnp_transaction_no text,
  p_amount int
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.bookings%rowtype;
begin
  select * into b from public.bookings where code = p_booking_code for update;
  if not found then raise exception 'BOOKING_NOT_FOUND'; end if;
  if b.status <> 'holding' then raise exception 'NOT_HOLDING'; end if;
  if b.hold_until < now() then raise exception 'HOLD_EXPIRED'; end if;
  if (b.price_snapshot->>'total')::int <> p_amount then raise exception 'AMOUNT_MISMATCH'; end if;

  -- Kiểm tra ghế vẫn thuộc booking này
  if exists (
    select 1 from jsonb_array_elements(b.seats) e
    where not exists (
      select 1 from public.seats s
      where s.showtime_id = b.showtime_id and s.seat_id = e->>'id' and s.booking_code = b.code
    )
  ) then raise exception 'SEAT_LOST'; end if;

  update public.seats set status = 'sold', hold_until = null
  where booking_code = b.code;

  update public.showtimes set sold_seats = sold_seats + jsonb_array_length(b.seats)
  where id = b.showtime_id;

  update public.bookings set
    status = 'paid', hold_until = null, payment_method = 'vnpay',
    vnp_transaction_no = p_vnp_transaction_no, paid_at = now(),
    food_status = case when jsonb_array_length(b.foods) > 0 then 'pending' else 'none' end
  where code = b.code;

  update public.payments set status = 'success', response_code = '00',
    vnp_transaction_no = p_vnp_transaction_no
  where txn_ref = p_txn_ref;

  insert into public.notifications (user_id, type, title, body, booking_code)
  values (b.user_id, 'bookingPaid', 'Đặt vé thành công',
          b.movie_title || ' · ' || b.cinema_name, b.code);
end $$;
```

### 5.3 Các hàm còn lại (cùng khuôn)

| Hàm | Quyền gọi | Việc trong một transaction |
|---|---|---|
| `release_hold(code)` | Khách sở hữu | Xóa `seats` của booking, `status = expired`, payment `pending` → `expired` |
| `check_in(code)` | Staff, Manager của rạp | Kiểm tra theo BUSINESS_RULES mục 8, `status = used`, ghi `audit_logs` |
| `deliver_food(code)` | Staff, Manager của rạp | `food_status = pending` → `delivered`, ghi người giao, tạo notification |
| `cancel_booking(code, reason)` | Khách (≥ 2h trước giờ chiếu) hoặc Manager (vé quầy) | Trả ghế, giảm `sold_seats`, `status = cancelled`, `food_status = cancelled`, notification, audit |
| `cancel_showtime(id, reason)` | Manager của rạp, Admin | Khóa suất, hủy mọi booking `paid`, tạo notification cho từng khách. **Không xóa seats** |
| `sell_counter(...)` | Staff, Manager | Giống `hold_seats` nhưng `channel = counter`, `sold_by = auth.uid()`, giữ 3 phút, ghi `paid` luôn |

Mỗi hàm kiểm tra `auth.uid()` và role trong `profiles` ngay đầu hàm. Không tin tham số từ client về quyền.

---

## 6. Row Level Security (thay cho Firestore Rules)

Bật RLS cho mọi bảng. Không có bảng nào để RLS tắt.

```sql
alter table public.profiles enable row level security;
alter table public.bookings enable row level security;
alter table public.seats enable row level security;
-- ... bật cho tất cả bảng

-- Hàm tiện ích
create or replace function public.current_role_name() returns text
language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid() and not is_locked
$$;

create or replace function public.current_cinema() returns text
language sql stable security definer set search_path = public as $$
  select cinema_id from public.profiles where id = auth.uid()
$$;

-- Bookings: khách thấy vé của mình, nhân viên thấy vé rạp mình, admin thấy tất cả
create policy bookings_select on public.bookings for select using (
  user_id = auth.uid()
  or public.current_role_name() = 'admin'
  or (public.current_role_name() in ('staff','manager') and cinema_id = public.current_cinema())
);

-- Staff đọc được vé rạp khác để báo "Vé thuộc rạp khác" (qua RPC check_in, không qua select trực tiếp)
-- Khách không được update trực tiếp bảng bookings: mọi thay đổi đi qua RPC
create policy bookings_no_direct_write on public.bookings for update using (false);
create policy bookings_no_direct_insert on public.bookings for insert with check (false);

-- Seats: đọc tự do trong suất (để vẽ sơ đồ), ghi chỉ qua RPC
create policy seats_select on public.seats for select using (auth.uid() is not null);

-- Movies, cinemas, rooms: đọc công khai, ghi chỉ admin
create policy movies_read on public.movies for select using (true);
create policy movies_admin_write on public.movies for all
  using (public.current_role_name() = 'admin') with check (public.current_role_name() = 'admin');

-- Foods: manager và admin của rạp được sửa
create policy foods_read on public.foods for select using (true);
create policy foods_write on public.foods for all
  using (public.current_role_name() = 'admin'
         or (public.current_role_name() = 'manager' and cinema_id = public.current_cinema()))
  with check (public.current_role_name() = 'admin'
         or (public.current_role_name() = 'manager' and cinema_id = public.current_cinema()));

-- Notifications: chỉ chủ sở hữu
create policy notif_own on public.notifications for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Profiles: khách sửa được họ tên và SĐT của mình, không sửa role hay cinema_id
create policy profiles_read on public.profiles for select using (
  id = auth.uid() or public.current_role_name() = 'admin'
  or (public.current_role_name() = 'manager' and cinema_id = public.current_cinema())
);
create policy profiles_update_self on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());
-- Chặn đổi role/cinema_id bằng trigger (xem 0004_triggers.sql)
```

Trigger chặn tự nâng quyền:

```sql
create or replace function public.protect_profile_fields() returns trigger
language plpgsql as $$
begin
  if public.current_role_name() is distinct from 'admin' then
    new.role := old.role;
    new.cinema_id := old.cinema_id;
    new.is_locked := old.is_locked;
  end if;
  return new;
end $$;

create trigger trg_protect_profile before update on public.profiles
for each row execute function public.protect_profile_fields();
```

### 6.1 Quy tắc phân quyền bằng RLS

- Khách không ghi trực tiếp vào `bookings`, `seats`, `payments`. Mọi ghi đi qua RPC.
- Staff và Manager luôn bị lọc theo `cinema_id` trong policy, không chỉ ở UI.
- Admin bypass qua `current_role_name() = 'admin'`.
- Tài khoản `is_locked = true` không có quyền gì, vì `current_role_name()` trả về null.

---

## 7. Auth

- **Supabase Auth**, phương thức email/password.
- Khi đăng ký khách: trigger tự tạo dòng `profiles` với `role = 'customer'`.
- Tạo Staff và Manager: gọi Edge Function `create-staff` (dùng service role key, chỉ nằm ở server). Không dùng trick FirebaseApp phụ nữa.
- Khóa tài khoản: đặt `profiles.is_locked = true`. Ngoài ra gọi `supabase.auth.admin.signOut(userId)` trong Edge Function để buộc đăng xuất.

Trigger tạo profile:

```sql
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), 'customer');
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();
```

---

## 8. Edge Functions

### 8.1 `create-vnpay-url`
- Nhận `booking_code`, `txn_ref`. Đọc `bookings.price_snapshot` từ DB, **không** nhận số tiền từ client.
- Tạo tham số VNPay, sắp xếp key ASCII, ký HMAC-SHA512 bằng `VNPAY_HASH_SECRET` (secret của function).
- Trả về URL thanh toán.
- Trước khi trả, ghi `payments` với `status = pending`.

### 8.2 `vnpay-return`
- VNPay redirect về đây (hoặc IPN). Xác minh `vnp_SecureHash` bằng cùng secret.
- Kiểm tra `vnp_Amount` khớp `price_snapshot.total × 100`.
- `vnp_ResponseCode == '00'` → gọi RPC `confirm_payment` bằng service role.
- Trả về trang HTML ngắn hoặc redirect deep link để app đóng WebView.

### 8.3 `create-staff`
- Chỉ Manager (của rạp) và Admin gọi được. Kiểm tra quyền bằng JWT trước khi tạo.
- Tạo user Auth, cập nhật `profiles` với `role = 'staff'` và `cinema_id` theo người gọi.

Ví dụ khung `create-vnpay-url`:

```ts
// supabase/functions/create-vnpay-url/index.ts
import { createClient } from 'jsr:@supabase/supabase-js@2';

const secret = Deno.env.get('VNPAY_HASH_SECRET')!;

async function hmacSha512(key: string, data: string): Promise<string> {
  const enc = new TextEncoder();
  const k = await crypto.subtle.importKey('raw', enc.encode(key),
    { name: 'HMAC', hash: 'SHA-512' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', k, enc.encode(data));
  return [...new Uint8Array(sig)].map(b => b.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async (req) => {
  const auth = req.headers.get('Authorization') ?? '';
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: auth } } },
  );
  const { booking_code, txn_ref, return_url, ip } = await req.json();

  const { data: booking, error } = await supabase
    .from('bookings').select('code, price_snapshot, movie_title')
    .eq('code', booking_code).single();
  if (error || !booking) return new Response('NOT_FOUND', { status: 404 });

  const params: Record<string, string> = {
    vnp_Version: '2.1.0', vnp_Command: 'pay',
    vnp_TmnCode: Deno.env.get('VNPAY_TMN_CODE')!,
    vnp_Amount: String(booking.price_snapshot.total * 100),
    vnp_CurrCode: 'VND', vnp_TxnRef: txn_ref,
    vnp_OrderInfo: `Thanh toan ${booking.code}`,
    vnp_OrderType: 'other', vnp_Locale: 'vn',
    vnp_ReturnUrl: return_url, vnp_IpAddr: ip,
    vnp_CreateDate: new Date().toISOString().replace(/\D/g, '').slice(0, 14),
  };

  const query = Object.keys(params).sort()
    .map(k => `${k}=${encodeURIComponent(params[k]).replace(/%20/g, '+')}`).join('&');
  const hash = await hmacSha512(secret, query);

  return Response.json({ url: `${Deno.env.get('VNPAY_URL')}?${query}&vnp_SecureHash=${hash}` });
});
```

> Khung trên chỉ để tham khảo. Trước khi dùng, đối chiếu với tài liệu VNPay sandbox về cách encode và thời hạn `vnp_ExpireDate`. Ghi chú này đúng với PROJECT.md mục 5.

---

## 9. Realtime (sơ đồ ghế)

Lắng nghe bảng `seats` theo suất. Không cần polling.

```dart
final seatStream = supabase
    .from('seats')
    .stream(primaryKey: ['showtime_id', 'seat_id'])
    .eq('showtime_id', showtimeId);
```

Bật Realtime cho bảng `seats` trong dashboard, mục Database → Replication.

Ghế `holding` quá `hold_until` vẫn được coi là trống ở client (hết hạn lười, giống BUSINESS_RULES mục 5). Không cần job xóa.

---

## 10. Storage

- Bucket `posters` (public read), `backdrops` (public read), `foods` (public read). Chỉ Admin và Manager được ghi.
- Ảnh hiển thị qua `cached_network_image` với URL công khai.

---

## 11. Flutter — pubspec.yaml

```yaml
name: cinema_booking_app
description: "Cinema Booking & Operation Management Application"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # Backend: Supabase (Auth, Postgres, Realtime, Storage, Edge Functions)
  supabase_flutter: ^2.5.0

  # State
  provider: ^6.1.2

  # Helpers
  intl: ^0.19.0

  # Camera & QR
  mobile_scanner: ^5.1.0
  qr_flutter: ^4.1.0

  # Bản đồ & vị trí
  google_maps_flutter: ^2.6.0
  geolocator: ^11.0.0

  # Thanh toán (WebView hiển thị VNPay)
  webview_flutter: ^4.7.0

  # Thông báo cục bộ
  flutter_local_notifications: ^17.1.0

  # UI
  google_fonts: ^6.2.1
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  url_launcher: ^6.2.5
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

Bỏ `firebase_core`, `firebase_auth`, `cloud_firestore`, `crypto` (ký VNPay đã chuyển sang Edge Function).

---

## 12. Khởi tạo Supabase trong app

```dart
// main.dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
);
final supabase = Supabase.instance.client;
```

- Chỉ dùng **anon key** trong app. Không bao giờ đưa **service role key** vào app.
- Truyền khóa qua `--dart-define`, không ghi trực tiếp trong code:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Gọi RPC từ Repository:

```dart
class SeatRepository {
  SeatRepository(this._db);
  final SupabaseClient _db;

  Future<DateTime> holdSeats({
    required String showtimeId,
    required String bookingCode,
    required List<String> seatIds,
    required Map<String, dynamic> booking,
    int holdMinutes = 5,
  }) async {
    final res = await _db.rpc('hold_seats', params: {
      'p_showtime_id': showtimeId,
      'p_booking_code': bookingCode,
      'p_seat_ids': seatIds,
      'p_hold_minutes': holdMinutes,
      'p_booking': booking,
    });
    return DateTime.parse(res as String);
  }
}
```

Bắt lỗi `SEAT_TAKEN:<ghế>` từ `PostgrestException.message` và ném `SeatTakenException` để UI hiện "Ghế [X] vừa có người chọn".

---

## 13. Ánh xạ Firebase → Supabase (dùng khi sửa các file cũ)

| Cũ (Firebase) | Mới (Supabase/Postgres) |
|---|---|
| `FirebaseAuth` | `supabase.auth` |
| `users/{uid}` | bảng `profiles` + trigger từ `auth.users` |
| Collection + subcollection | Bảng quan hệ, khóa ngoại |
| `runTransaction` ở client | RPC `hold_seats`, `confirm_payment`… |
| `FieldValue.increment` | `sold_seats = sold_seats + n` trong function |
| `snapshots()` | `.stream()` (Realtime) |
| `firestore.rules` | RLS policies + trigger bảo vệ cột |
| Cloud Storage (nếu có) | Supabase Storage |
| Secondary FirebaseApp để tạo staff | Edge Function `create-staff` |
| `Timestamp` | `timestamptz` |
| `DocumentSnapshot.data()` | `Map<String, dynamic>` từ `.select()` |
| `FieldValue.serverTimestamp()` | `default now()` |
| Mã booking làm doc ID | Cột `code` là primary key |
| Ký VNPay trong `vnpay_hasher.dart` | Edge Function `create-vnpay-url` và `vnpay-return` |

---

## 14. Thiết lập (từ đầu đến chạy được)

1. Tạo project trên supabase.com. Ghi lại `Project URL` và `anon key`.
2. Cài CLI: `npm i -g supabase`. Chạy `supabase login`, `supabase init`, `supabase link --project-ref <ref>`.
3. Chạy migrations theo thứ tự `0001` → `0005`: `supabase db push`.
4. Vào Storage, tạo các bucket ở mục 10.
5. Bật Realtime cho bảng `seats`.
6. Đặt secret cho Edge Functions:
   ```bash
   supabase secrets set VNPAY_HASH_SECRET=... VNPAY_TMN_CODE=... VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
   ```
7. Deploy: `supabase functions deploy create-vnpay-url vnpay-return create-staff`.
8. Tạo tài khoản admin đầu tiên trong Auth (Dashboard), rồi chạy seed để tạo các tài khoản còn lại qua `create-staff`.
9. Chạy app: `flutter run --dart-define=...`.

---

## 15. Bảo mật — bắt buộc

- [ ] Service role key chỉ có trong Edge Function, không có trong app và không commit.
- [ ] `VNPAY_HASH_SECRET` chỉ nằm trong `supabase secrets`.
- [ ] RLS bật ở mọi bảng. Kiểm tra bằng `select tablename, rowsecurity from pg_tables where schemaname='public';`.
- [ ] Không có policy `for all using (true)` ở bảng nhạy cảm.
- [ ] Thử bằng tài khoản khách: gọi trực tiếp `from('bookings').update(...)` phải bị từ chối.
- [ ] Thử bằng tài khoản Staff rạp `cn_q1`: query bookings của `cn_tb` trả về rỗng.

---

## 16. Kiểm thử nhanh

- Hai tài khoản cùng giữ một ghế gần như đồng thời: một người thành công, người kia nhận `SEAT_TAKEN`. Nhờ `for update` trên `showtimes`, các đặt cùng suất được xếp hàng.
- Giữ ghế rồi chờ quá `hold_until`: ghế hiển thị trống.
- Thanh toán với `vnp_Amount` khác `price_snapshot`: `confirm_payment` ném `AMOUNT_MISMATCH`.
- Gọi `confirm_payment` trực tiếp từ app: bị từ chối (không có quyền, vì hàm chỉ cấp cho service role).

---

## 17. Giới hạn cần biết

- `for update` trên `showtimes` làm các đặt cùng suất chạy tuần tự. Với một rạp vài trăm người/giờ thì không đáng kể. Nếu tải lớn hơn thì đổi sang khóa theo từng ghế.
- VNPay Sandbox không có IPN đáng tin cho demo. Vẫn nên triển khai `vnpay-return` để app không phụ thuộc vào việc người dùng quay lại WebView.
- Supabase free tier có giới hạn số Edge Function calls và băng thông. Đủ cho demo đồ án.
- Realtime có giới hạn số kết nối đồng thời theo gói. Demo không chạm tới giới hạn.

---

## 18. Việc cần làm lại trong các file cũ

File này đổi công nghệ nên các file trước cần sửa:

| File | Cần sửa |
|---|---|
| `.cursorrules` | Mục 1 (Firestore → Supabase + Postgres), mục 3 (transaction → RPC), mục 4 (`env.dart` → `--dart-define`) |
| `PROJECT_STRUCTURE.md` | Mục 2 (pubspec), mục 3 (thêm `supabase/`, bỏ `firebase_options.dart`), mục 7 (bảo mật), mục 8 (lệnh chạy) |
| `BUSINESS_RULES.md` | Không đổi nghiệp vụ. Chỉ đổi cách thực thi ở mục 5, 6.2 |
| `ROLE_FLOWS.md` | Không đổi luồng. Chỉ đổi "tạo tài khoản bằng FirebaseApp phụ" thành Edge Function |
| `DESIGN_TOKENS.md` | Không đổi |
| `DATA.md` và `SCREENS.md` | Phần Firestore (cây collection, rules, index) cần thay bằng schema mục 4 của file này |

Bạn muốn tôi viết lại 4 file cần sửa (`.cursorrules`, `PROJECT_STRUCTURE.md`, `ROLE_FLOWS.md`, `BUSINESS_RULES.md`) theo stack mới không? Và `DATA.md` có thể thay bằng file schema SQL riêng.
