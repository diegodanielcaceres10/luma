-- ============================================================================
-- Luma - sample data seed (current month and the two previous ones)
--
-- Run it in the Supabase SQL Editor (it bypasses RLS) after applying the
-- migrations. Before running, set v_email below to the Google account you use
-- to sign in to the app.
--
-- Every date is relative to the month in which the script is executed: run it
-- in November and you get September, October and November. Days of the month
-- are fixed, so some movements of the current month may be dated in the future.
-- A day that does not exist in a month (e.g. the 31st) falls on its last day.
--
-- Scenario (offsets are relative to the current month):
--   * "Cuenta Sueldo": movements and opening balance for the current month and
--     the two previous ones.
--   * "Ahorros": the two previous months only; nothing at all for the current
--     month (empty-state case). Its balance is left stale on purpose.
--
-- Re-runnable: it first removes the two seeded accounts and the three seeded
-- services (with their movements, monthly balances and invoices) and then
-- recreates them. Categories are created only if missing and are never
-- deleted. Any other data of the user is left untouched.
-- ============================================================================
begin;

do $seed$
declare
  v_email   constant text := 'tu-email@gmail.com';
  v_today   date := current_date;
  -- Fixed Spanish names so the descriptions do not depend on the server locale.
  v_names   constant text[] := array[
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
    'septiembre', 'octubre', 'noviembre', 'diciembre'];
  v_user    uuid;
  v_sueldo  uuid;
  v_ahorros uuid;
  v_prev    date;
  v_stale   timestamptz;
  m         record;
  v_open    numeric(12, 2);
  v_close   numeric(12, 2);
begin
  select id into v_user from auth.users where email = v_email;
  if v_user is null then
    raise exception 'No user found in auth.users with email %. Edit v_email.',
      v_email;
  end if;

  -- ─── cleanup of a previous run ───────────────────────────────────────────
  delete from invoices
   where user_id = v_user
     and service_id in (
       select id from services
        where user_id = v_user
          and name in ('Luz', 'Internet', 'Streaming'));
  delete from services
   where user_id = v_user and name in ('Luz', 'Internet', 'Streaming');
  delete from accounts
   where user_id = v_user and name in ('Cuenta Sueldo', 'Ahorros');

  -- ─── months covered: offset -2, -1 and 0 from the current month ──────────
  create temp table seed_month (
    off    integer primary key,
    base   date not null,
    name   text not null,
    period text not null
  ) on commit drop;

  insert into seed_month (off, base, name, period)
  select x.o,
         x.b,
         v_names[extract(month from x.b)::integer],
         to_char(x.b, 'MM/YYYY')
    from (
      select o,
             (date_trunc('month', v_today::timestamp)
               + o * interval '1 month')::date as b
        from generate_series(-2, 0) as o
    ) x;

  -- ─── categories ──────────────────────────────────────────────────────────
  insert into categories
    (user_id, name, type, color, icon, has_budget, budget_amount)
  values
    (v_user, 'Supermercado', 'expense', '#43A047', '🛒', true,  220000),
    (v_user, 'Transporte',   'expense', '#1E88E5', '🚌', true,   40000),
    (v_user, 'Salidas',      'expense', '#8E24AA', '🍔', true,  100000),
    (v_user, 'Servicios',    'expense', '#FB8C00', '💡', false,   null),
    (v_user, 'Salud',        'expense', '#E53935', '💊', false,   null),
    (v_user, 'Hogar',        'expense', '#6D4C41', '🏠', false,   null),
    (v_user, 'Sueldo',       'income',  '#00897B', '💼', false,   null),
    (v_user, 'Rendimientos', 'income',  '#3949AB', '📈', false,   null)
  on conflict (user_id, name) do nothing;

  -- ─── accounts (balances are set at the end) ──────────────────────────────
  insert into accounts (user_id, name, balance)
  values (v_user, 'Cuenta Sueldo', 0) returning id into v_sueldo;
  insert into accounts (user_id, name, balance)
  values (v_user, 'Ahorros', 0) returning id into v_ahorros;

  -- ─── services ────────────────────────────────────────────────────────────
  insert into services
    (user_id, category_id, name, approximate_amount, due_day)
  select v_user, c.id, s.name, s.amount, s.due_day
    from (values
      ('Luz',       38000, 10),
      ('Internet',  29900, 12),
      ('Streaming',  8500,  5)
    ) as s(name, amount, due_day)
    join categories c on c.user_id = v_user and c.name = 'Servicios';

  -- ─── movements ───────────────────────────────────────────────────────────
  -- off = month offset, day = day of the month. In descr, {name} is replaced
  -- by the month name and {period} by MM/YYYY.
  create temp table seed_tx (
    acct     text,
    cat      text,
    type     text,
    amount   numeric(12, 2),
    descr    text,
    off      integer,
    day      integer,
    transfer boolean default false
  ) on commit drop;

  insert into seed_tx (acct, cat, type, amount, descr, off, day, transfer) values
    -- Cuenta Sueldo - two months ago
    ('Cuenta Sueldo', 'Sueldo',       'income',  1200000, 'Sueldo {name}',          -2,  5, false),
    ('Cuenta Sueldo', 'Hogar',        'expense',  400000, 'Alquiler {name}',        -2,  3, false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   85000, 'Compra semanal',         -2,  8, false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   62500, 'Compra semanal',         -2, 22, false),
    ('Cuenta Sueldo', 'Transporte',   'expense',   18000, 'Carga SUBE',             -2, 12, false),
    ('Cuenta Sueldo', 'Salidas',      'expense',   45000, 'Cena con amigos',        -2, 16, false),
    ('Cuenta Sueldo', 'Salud',        'expense',   30000, 'Farmacia',               -2, 20, false),
    ('Cuenta Sueldo', 'Servicios',    'expense',   38200, 'Luz - {period}',         -2, 10, false),
    ('Cuenta Sueldo', 'Servicios',    'expense',   29900, 'Internet - {period}',    -2, 12, false),
    ('Cuenta Sueldo', 'Servicios',    'expense',    8500, 'Streaming - {period}',   -2,  5, false),
    ('Cuenta Sueldo', null,           'expense',  200000, 'Transferencia a Ahorros',-2,  6, true),
    ('Ahorros',       null,           'income',   200000, 'Transferencia desde Cuenta Sueldo', -2, 6, true),
    ('Ahorros',       'Rendimientos', 'income',     3800, 'Intereses {name}',       -2, 31, false),
    -- Cuenta Sueldo - previous month
    ('Cuenta Sueldo', 'Sueldo',       'income',  1250000, 'Sueldo {name}',          -1,  5, false),
    ('Cuenta Sueldo', 'Hogar',        'expense',  400000, 'Alquiler {name}',        -1,  3, false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   91000, 'Compra semanal',         -1,  7, false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   74300, 'Compra semanal',         -1, 21, false),
    ('Cuenta Sueldo', 'Transporte',   'expense',   20000, 'Carga SUBE',             -1, 10, false),
    ('Cuenta Sueldo', 'Salidas',      'expense',   62000, 'Cine y cena',            -1, 13, false),
    ('Cuenta Sueldo', 'Salud',        'expense',   55000, 'Consulta médica',        -1, 19, false),
    ('Cuenta Sueldo', 'Servicios',    'expense',   41500, 'Luz - {period}',         -1, 10, false),
    ('Cuenta Sueldo', 'Hogar',        'expense',   35000, 'Arreglo de canilla',     -1, 24, false),
    ('Ahorros',       null,           'expense',  100000, 'Transferencia a Cuenta Sueldo', -1, 18, true),
    ('Cuenta Sueldo', null,           'income',   100000, 'Transferencia desde Ahorros',   -1, 18, true),
    ('Ahorros',       'Rendimientos', 'income',     4200, 'Intereses {name}',       -1, 28, false),
    -- Cuenta Sueldo - current month (spread over the whole month on purpose)
    ('Cuenta Sueldo', 'Sueldo',       'income',  1250000, 'Sueldo {name}',           0,  1, false),
    ('Cuenta Sueldo', 'Hogar',        'expense',  420000, 'Alquiler {name}',         0,  2, false),
    ('Cuenta Sueldo', 'Servicios',    'expense',    8500, 'Streaming - {period}',    0,  1, false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   88000, 'Compra semanal',          0,  6, false),
    ('Cuenta Sueldo', 'Transporte',   'expense',   22000, 'Carga SUBE',              0,  9, false),
    ('Cuenta Sueldo', 'Salidas',      'expense',   48000, 'Cumpleaños',              0, 17, false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   79500, 'Compra semanal',          0, 20, false);

  insert into transactions
    (user_id, account_id, category_id, type, amount, description, date,
     is_transfer)
  select v_user,
         case t.acct when 'Cuenta Sueldo' then v_sueldo else v_ahorros end,
         c.id, t.type, t.amount,
         replace(replace(t.descr, '{name}', mo.name), '{period}', mo.period),
         -- Clamp the day to the last day of the month.
         mo.base + (least(
           t.day,
           extract(day from mo.base + interval '1 month' - interval '1 day')::integer
         ) - 1),
         t.transfer
    from seed_tx t
    join seed_month mo on mo.off = t.off
    left join categories c on c.user_id = v_user and c.name = t.cat;

  -- ─── invoices (paid ones point to their payment movement) ───────────────
  insert into invoices
    (user_id, service_id, month, year, amount, due_date, paid, paid_at,
     transaction_id, cancelled, cancelled_at)
  select v_user, s.id,
         extract(month from mo.base)::integer,
         extract(year from mo.base)::integer,
         i.amount,
         make_date(extract(year from mo.base)::integer,
                   extract(month from mo.base)::integer, s.due_day),
         i.status = 'paid',
         case when i.status = 'paid' then t.date + time '12:00' end,
         t.id,
         i.status = 'cancelled',
         case when i.status = 'cancelled' then mo.base + time '09:00' end
    from (values
      ('Luz',       -2, 38200, 'paid'),
      ('Internet',  -2, 29900, 'paid'),
      ('Streaming', -2,  8500, 'paid'),
      ('Luz',       -1, 41500, 'paid'),
      ('Internet',  -1, 31000, 'pending'),
      ('Streaming', -1,  8500, 'cancelled'),
      ('Luz',        0, 43000, 'pending'),
      ('Internet',   0, 31000, 'pending'),
      ('Streaming',  0,  8500, 'paid')
    ) as i(service, off, amount, status)
    join seed_month mo on mo.off = i.off
    join services s on s.user_id = v_user and s.name = i.service
    left join transactions t
      on i.status = 'paid'
     and t.user_id = v_user
     and t.description = i.service || ' - ' || mo.period;

  -- ─── monthly balances + final account balances ───────────────────────────
  -- Rows are processed in chronological order per account so each month opens
  -- with the previous month's closing balance:
  --   closing = opening + uncontrolled + sum(income) - sum(expense)
  for m in
    select x.acct, mo.base, x.opening, x.uncontrolled
      from (values
        (v_sueldo,  -2, 150000::numeric, -12000::numeric),
        (v_sueldo,  -1, null,             -5500),
        (v_sueldo,   0, null,                 0),
        (v_ahorros, -2, 500000,               0),
        (v_ahorros, -1, null,                 0)
      ) as x(acct, off, opening, uncontrolled)
      join seed_month mo on mo.off = x.off
     order by x.acct, x.off
  loop
    v_open := coalesce(m.opening, v_close);

    insert into monthly_account_balances
      (user_id, account_id, month, year, opening_balance,
       uncontrolled_expenses_total)
    values (v_user, m.acct,
            extract(month from m.base)::integer,
            extract(year from m.base)::integer,
            v_open, m.uncontrolled);

    select v_open + m.uncontrolled
           + coalesce(sum(case type when 'income' then amount else -amount end), 0)
      into v_close
      from transactions
     where account_id = m.acct
       and date >= m.base
       and date < (m.base + interval '1 month')::date;

    update accounts set balance = v_close where id = m.acct;
  end loop;

  -- The trigger stamps balance_updated_at on every balance change, so set the
  -- final values afterwards (balance unchanged => trigger does not fire).
  -- Ahorros keeps a stale date to exercise the "last updated" UI: the 28th of
  -- the previous month, and never less than 6 days ago.
  select base into v_prev from seed_month where off = -1;
  v_stale := least(
    ((v_prev + 27) + time '12:00') at time zone 'UTC',
    now() - interval '6 days');

  update accounts set balance_updated_at = now() where id = v_sueldo;
  update accounts set balance_updated_at = v_stale where id = v_ahorros;
end
$seed$;

commit;
