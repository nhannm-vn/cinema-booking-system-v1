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
