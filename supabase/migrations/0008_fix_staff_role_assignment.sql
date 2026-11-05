-- 0008_fix_staff_role_assignment.sql
-- Fix: tạo Manager/Staff qua Edge Function create-staff bị lưu role 'customer'.
-- Nguyên nhân: Edge Function dùng service_role nên auth.uid() = null,
-- current_role_name() = null -> trigger protect_profile_fields reset role về giá trị cũ ('customer').

-- 1. handle_new_user: đọc role/cinema_id từ app_metadata (chỉ service_role mới ghi được),
--    KHÔNG đọc từ user_metadata để tránh khách tự nâng quyền khi signUp.
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_role text := coalesce(new.raw_app_meta_data->>'role', 'customer');
  v_cinema text := new.raw_app_meta_data->>'cinema_id';
begin
  if v_role not in ('customer', 'staff', 'manager', 'admin') then
    v_role := 'customer';
  end if;

  insert into public.profiles (id, full_name, phone, role, cinema_id, is_locked)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'phone',
    v_role,
    case when v_role in ('staff', 'manager') then v_cinema else null end,
    false
  )
  on conflict (id) do nothing;
  return new;
end $$;

-- 2. protect_profile_fields: cho phép service_role (Edge Functions backend) cập nhật mọi trường.
create or replace function public.protect_profile_fields() returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_role text := public.current_role_name();
  v_caller_cinema text := public.current_cinema();
begin
  -- Backend tin cậy (service_role trong Edge Functions)
  if coalesce(auth.role(), '') = 'service_role' then
    new.updated_at := now();
    return new;
  end if;

  -- Admin có quyền cập nhật mọi trường
  if v_caller_role = 'admin' then
    new.updated_at := now();
    return new;
  end if;

  -- Manager chỉ được phép đổi is_locked của nhân viên (staff) trong cùng rạp
  if v_caller_role = 'manager' and old.role = 'staff' and old.cinema_id = v_caller_cinema then
    new.role := old.role;
    new.cinema_id := old.cinema_id;
    new.updated_at := now();
    return new;
  end if;

  -- Người dùng thông thường: không được đổi role, cinema_id, is_locked
  new.role := old.role;
  new.cinema_id := old.cinema_id;
  new.is_locked := old.is_locked;
  new.updated_at := now();
  return new;
end $$;

-- 3. Sửa dữ liệu đã tạo sai: user có app_metadata.role là staff/manager nhưng profile đang là customer.
update public.profiles p
set role = u.raw_app_meta_data->>'role',
    cinema_id = coalesce(p.cinema_id, u.raw_app_meta_data->>'cinema_id'),
    updated_at = now()
from auth.users u
where u.id = p.id
  and p.role = 'customer'
  and u.raw_app_meta_data->>'role' in ('staff', 'manager');
