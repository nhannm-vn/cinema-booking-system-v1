-- 0007_fix_staff_locking.sql
-- Fix staff account locking permissions, RLS update policies, and RPC toggle_user_lock

-- 1. Cập nhật trigger function protect_profile_fields để Manager được phép khóa/mở khóa nhân viên rạp mình
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

-- 2. Thêm policy RLS cho phép Manager và Admin cập nhật profiles của nhân viên
drop policy if exists profiles_manager_update on public.profiles;
create policy profiles_manager_update on public.profiles for update
using (
  public.current_role_name() = 'manager'
  and role = 'staff'
  and cinema_id = public.current_cinema()
)
with check (
  public.current_role_name() = 'manager'
  and role = 'staff'
  and cinema_id = public.current_cinema()
);

drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update
using (
  public.current_role_name() = 'admin'
)
with check (
  public.current_role_name() = 'admin'
);

-- 3. Tạo hàm RPC toggle_user_lock để khóa / mở khóa tài khoản an toàn tuyệt đối
create or replace function public.toggle_user_lock(
  p_user_id uuid,
  p_is_locked boolean
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_id uuid := auth.uid();
  v_caller_role text;
  v_caller_cinema text;
  v_target public.profiles%rowtype;
begin
  if v_caller_id is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if v_caller_id = p_user_id then
    raise exception 'CANNOT_LOCK_SELF';
  end if;

  select role, cinema_id into v_caller_role, v_caller_cinema
  from public.profiles where id = v_caller_id;

  select * into v_target from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'USER_NOT_FOUND';
  end if;

  -- Kiểm tra phân quyền:
  -- Admin được khóa/mở khóa mọi người trừ bản thân
  -- Manager chỉ được khóa/mở khóa nhân viên (staff) trong rạp của mình
  if v_caller_role = 'admin' then
    -- Hợp lệ
  elsif v_caller_role = 'manager' then
    if v_target.role <> 'staff' then
      raise exception 'NOT_AUTHORIZED_ROLE';
    end if;
    if v_target.cinema_id is distinct from v_caller_cinema then
      raise exception 'NOT_AUTHORIZED_CINEMA';
    end if;
  else
    raise exception 'NOT_AUTHORIZED';
  end if;

  update public.profiles
  set is_locked = p_is_locked,
      updated_at = now()
  where id = p_user_id;

  insert into public.audit_logs (actor_id, actor_role, cinema_id, action, target_type, target_id, reason)
  values (
    v_caller_id,
    v_caller_role,
    v_target.cinema_id,
    case when p_is_locked then 'lockUser' else 'unlockUser' end,
    'profile',
    p_user_id::text,
    case when p_is_locked then 'Khóa tài khoản nhân viên' else 'Mở khóa tài khoản nhân viên' end
  );

  return jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'is_locked', p_is_locked
  );
end $$;

grant execute on function public.toggle_user_lock(uuid, boolean) to authenticated;
