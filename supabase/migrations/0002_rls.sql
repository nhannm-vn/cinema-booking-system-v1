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

create policy profiles_manager_update on public.profiles for update using (
  public.current_role_name() = 'manager'
  and role = 'staff'
  and cinema_id = public.current_cinema()
) with check (
  public.current_role_name() = 'manager'
  and role = 'staff'
  and cinema_id = public.current_cinema()
);

create policy profiles_admin_update on public.profiles for update using (
  public.current_role_name() = 'admin'
) with check (
  public.current_role_name() = 'admin'
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
