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
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_role text := public.current_role_name();
  v_caller_cinema text := public.current_cinema();
begin
  -- Admin có quyền cập nhật mọi trường
  if v_caller_role = 'admin' then
    new.updated_at := now();
    return new;
  end if;

  -- Manager chỉ được phép đổi is_locked của nhân viên (staff) trong cùng rạp
  if v_caller_role = 'manager' and old.role = 'staff' and old.cinema_id = v_caller_cinema then
    new.role := old.role;           -- Không được đổi role
    new.cinema_id := old.cinema_id; -- Không được đổi rạp
    new.updated_at := now();
    return new;
  end if;

  -- Người dùng thông thường (hoặc tự update): không được đổi role, cinema_id, is_locked
  new.role := old.role;
  new.cinema_id := old.cinema_id;
  new.is_locked := old.is_locked;
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_protect_profile on public.profiles;
create trigger trg_protect_profile
  before update on public.profiles
  for each row execute function public.protect_profile_fields();
