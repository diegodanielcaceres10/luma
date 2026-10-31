-- ─── device_tokens ────────────────────────────────────────
-- One row per installed app instance that can receive push notifications
-- (FCM registration token). A user can have several devices.
create table device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  token      text not null unique,
  platform   text not null check (platform in ('android', 'web')),
  updated_at timestamptz not null default now()
);

create index device_tokens_user_id_idx on device_tokens (user_id);

-- ─── RLS (Row Level Security) ────────────────────────────
alter table device_tokens enable row level security;

create policy "users manage own device tokens"
  on device_tokens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─── register_device_token ───────────────────────────────
create or replace function public.register_device_token(
  p_token    text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesión requerida para registrar el dispositivo';
  end if;

  -- The owner is always the caller. A token already stored for another
  -- account (same phone, new login) moves to the caller.
  insert into device_tokens (user_id, token, platform)
  values (auth.uid(), p_token, p_platform)
  on conflict (token) do update
    set user_id = auth.uid(),
        platform = excluded.platform,
        updated_at = now();
end;
$$;

revoke all on function public.register_device_token(text, text) from public;
grant execute on function public.register_device_token(text, text) to authenticated;
