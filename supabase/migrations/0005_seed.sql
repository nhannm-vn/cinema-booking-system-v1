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
  ('cn_q1', 'Cinema Star Quận 1', '123 Lê Lợi, Phường Bến Nghé, Quận 1, TP.HCM', '028 3822 1234', 10.7725, 106.6980, '08:00 - 23:30', true),
  ('cn_tb', 'Cinema Star Tân Bình', '456 Hoàng Văn Thụ, Phường 4, Quận Tân Bình, TP.HCM', '028 3844 5678', 10.7981, 106.6534, '08:30 - 23:00', true)
on conflict (id) do nothing;

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

