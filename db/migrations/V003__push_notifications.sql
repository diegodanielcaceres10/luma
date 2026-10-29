-- ─── notifications_due ───────────────────────────────────
-- Daily push notifications to send, one row per (notification, device).
-- Called only by the send-daily-notifications Edge Function (service role).
-- p_today is the current date in p_timezone, computed by the caller.
create or replace function public.notifications_due(
  p_today    date,
  p_timezone text
)
returns table (
  user_id uuid,
  token   text,
  kind    text,
  tag     text,
  title   text,
  body    text
)
language sql
stable
security definer
set search_path = public
as $$
  with notices as (
    -- Pending invoices that expire today (inactive services included).
    select i.user_id,
           'invoice_due'::text as kind,
           'invoice_due:' || i.id || ':' || p_today as tag,
           'Vence hoy: ' || s.name as title,
           'La factura de ' || s.name || ' vence hoy.' as body
    from invoices i
    join services s on s.id = i.service_id
    where i.due_date = p_today
      and not i.paid
      and not i.cancelled

    union all

    -- Active services whose due day is today (clamped to the last day of the
    -- month) and that have no invoice yet for the current month.
    select s.user_id,
           'invoice_missing',
           'invoice_missing:' || s.id || ':' || p_today,
           'Falta cargar la factura: ' || s.name,
           s.name || ' vence hoy y todavía no cargaste la factura de este mes. '
             || 'Ingresala para tenerla al día.'
    from services s
    where s.is_active
      and s.due_day is not null
      and least(
            s.due_day,
            extract(day from (date_trunc('month', p_today) + interval '1 month - 1 day'))::int
          ) = extract(day from p_today)::int
      and not exists (
        select 1
        from invoices i
        where i.service_id = s.id
          and i.month = extract(month from p_today)::int
          and i.year = extract(year from p_today)::int
      )

    union all

    -- Active accounts whose balance has not changed for 5 or more calendar
    -- days, counted in the given time zone.
    select a.user_id,
           'account_stale',
           'account_stale:' || a.id || ':' || p_today,
           'Cuenta sin actualizar: ' || a.name,
           'Hace ' || (p_today - (a.balance_updated_at at time zone p_timezone)::date)
             || ' días que no se actualiza el saldo de ' || a.name
             || '. Revisá si te falta cargar movimientos.'
    from accounts a
    where a.is_active
      and p_today - (a.balance_updated_at at time zone p_timezone)::date >= 5
  )
  select n.user_id, d.token, n.kind, n.tag, n.title, n.body
  from notices n
  join device_tokens d on d.user_id = n.user_id;
$$;

revoke all on function public.notifications_due(date, text)
  from public, anon, authenticated;
grant execute on function public.notifications_due(date, text) to service_role;

-- ─── register_device_token (hardening) ───────────────────
-- Same behavior as V002, plus: empty search_path, blank or oversized token
-- rejected and no access for anon (Supabase grants EXECUTE to anon by default).
create or replace function public.register_device_token(
  p_token    text,
  p_platform text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesión requerida para registrar el dispositivo';
  end if;

  if p_token is null or btrim(p_token) = '' or length(p_token) > 4096 then
    raise exception 'Token inválido';
  end if;

  insert into public.device_tokens (user_id, token, platform)
  values (auth.uid(), p_token, p_platform)
  on conflict (token) do update
    set user_id = auth.uid(),
        platform = excluded.platform,
        updated_at = now();
end;
$$;

revoke all on function public.register_device_token(text, text)
  from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;
