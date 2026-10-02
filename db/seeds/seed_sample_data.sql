-- ============================================================================
-- Luma - sample data seed (Aug, Sep and Oct 2026)
--
-- Run it in the Supabase SQL Editor (it bypasses RLS) after applying the
-- migrations. Before running, set v_email below to the Google account you use
-- to sign in to the app.
--
-- Scenario:
--   * "Cuenta Sueldo": movements and opening balance for Aug, Sep and Oct.
--   * "Ahorros": Aug and Sep only; nothing at all for Oct (empty-state case).
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
  v_user    uuid;
  v_sueldo  uuid;
  v_ahorros uuid;
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
  create temp table seed_tx (
    acct     text,
    cat      text,
    type     text,
    amount   numeric(12, 2),
    descr    text,
    d        date,
    transfer boolean default false
  ) on commit drop;

  insert into seed_tx (acct, cat, type, amount, descr, d, transfer) values
    -- Cuenta Sueldo - August
    ('Cuenta Sueldo', 'Sueldo',       'income',  1200000, 'Sueldo agosto',          '2026-08-05', false),
    ('Cuenta Sueldo', 'Hogar',        'expense',  400000, 'Alquiler agosto',        '2026-08-03', false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   85000, 'Compra semanal',         '2026-08-08', false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   62500, 'Compra semanal',         '2026-08-22', false),
    ('Cuenta Sueldo', 'Transporte',   'expense',   18000, 'Carga SUBE',             '2026-08-12', false),
    ('Cuenta Sueldo', 'Salidas',      'expense',   45000, 'Cena con amigos',        '2026-08-16', false),
    ('Cuenta Sueldo', 'Salud',        'expense',   30000, 'Farmacia',               '2026-08-20', false),
    ('Cuenta Sueldo', 'Servicios',    'expense',   38200, 'Luz - 08/2026',          '2026-08-10', false),
    ('Cuenta Sueldo', 'Servicios',    'expense',   29900, 'Internet - 08/2026',     '2026-08-12', false),
    ('Cuenta Sueldo', 'Servicios',    'expense',    8500, 'Streaming - 08/2026',    '2026-08-05', false),
    ('Cuenta Sueldo', null,           'expense',  200000, 'Transferencia a Ahorros','2026-08-06', true),
    ('Ahorros',       null,           'income',   200000, 'Transferencia desde Cuenta Sueldo', '2026-08-06', true),
    ('Ahorros',       'Rendimientos', 'income',     3800, 'Intereses agosto',       '2026-08-31', false),
    -- Cuenta Sueldo - September
    ('Cuenta Sueldo', 'Sueldo',       'income',  1250000, 'Sueldo septiembre',      '2026-09-05', false),
    ('Cuenta Sueldo', 'Hogar',        'expense',  400000, 'Alquiler septiembre',    '2026-09-03', false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   91000, 'Compra semanal',         '2026-09-07', false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   74300, 'Compra semanal',         '2026-09-21', false),
    ('Cuenta Sueldo', 'Transporte',   'expense',   20000, 'Carga SUBE',             '2026-09-10', false),
    ('Cuenta Sueldo', 'Salidas',      'expense',   62000, 'Cine y cena',            '2026-09-13', false),
    ('Cuenta Sueldo', 'Salud',        'expense',   55000, 'Consulta médica',        '2026-09-19', false),
    ('Cuenta Sueldo', 'Servicios',    'expense',   41500, 'Luz - 09/2026',          '2026-09-10', false),
    ('Cuenta Sueldo', 'Hogar',        'expense',   35000, 'Arreglo de canilla',     '2026-09-24', false),
    ('Ahorros',       null,           'expense',  100000, 'Transferencia a Cuenta Sueldo', '2026-09-18', true),
    ('Cuenta Sueldo', null,           'income',   100000, 'Transferencia desde Ahorros',   '2026-09-18', true),
    ('Ahorros',       'Rendimientos', 'income',     4200, 'Intereses septiembre',   '2026-09-28', false),
    -- Cuenta Sueldo - October (spread over the whole month on purpose)
    ('Cuenta Sueldo', 'Sueldo',       'income',  1250000, 'Sueldo octubre',         '2026-10-01', false),
    ('Cuenta Sueldo', 'Hogar',        'expense',  420000, 'Alquiler octubre',       '2026-10-02', false),
    ('Cuenta Sueldo', 'Servicios',    'expense',    8500, 'Streaming - 10/2026',    '2026-10-01', false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   88000, 'Compra semanal',         '2026-10-06', false),
    ('Cuenta Sueldo', 'Transporte',   'expense',   22000, 'Carga SUBE',             '2026-10-09', false),
    ('Cuenta Sueldo', 'Salidas',      'expense',   48000, 'Cumpleaños',             '2026-10-17', false),
    ('Cuenta Sueldo', 'Supermercado', 'expense',   79500, 'Compra semanal',         '2026-10-20', false);

  insert into transactions
    (user_id, account_id, category_id, type, amount, description, date,
     is_transfer)
  select v_user,
         case t.acct when 'Cuenta Sueldo' then v_sueldo else v_ahorros end,
         c.id, t.type, t.amount, t.descr, t.d, t.transfer
    from seed_tx t
    left join categories c on c.user_id = v_user and c.name = t.cat;

  -- ─── invoices (paid ones point to their payment movement) ───────────────
  insert into invoices
    (user_id, service_id, month, year, amount, due_date, paid, paid_at,
     transaction_id, cancelled, cancelled_at)
  select v_user, s.id, i.month, i.year, i.amount,
         make_date(i.year, i.month, s.due_day),
         i.status = 'paid',
         case when i.status = 'paid' then t.date + time '12:00' end,
         t.id,
         i.status = 'cancelled',
         case when i.status = 'cancelled'
              then make_date(i.year, i.month, 1) + time '09:00' end
    from (values
      ('Luz',       8, 2026, 38200, 'paid'),
      ('Internet',  8, 2026, 29900, 'paid'),
      ('Streaming', 8, 2026,  8500, 'paid'),
      ('Luz',       9, 2026, 41500, 'paid'),
      ('Internet',  9, 2026, 31000, 'pending'),
      ('Streaming', 9, 2026,  8500, 'cancelled'),
      ('Luz',      10, 2026, 43000, 'pending'),
      ('Internet', 10, 2026, 31000, 'pending'),
      ('Streaming',10, 2026,  8500, 'paid')
    ) as i(service, month, year, amount, status)
    join services s on s.user_id = v_user and s.name = i.service
    left join transactions t
      on i.status = 'paid'
     and t.user_id = v_user
     and t.description =
         i.service || ' - ' || lpad(i.month::text, 2, '0') || '/' || i.year;

  -- ─── monthly balances + final account balances ───────────────────────────
  -- Rows are processed in chronological order per account so each month opens
  -- with the previous month's closing balance:
  --   closing = opening + uncontrolled + sum(income) - sum(expense)
  for m in
    select * from (values
      (v_sueldo,  8, 150000::numeric, -12000::numeric),
      (v_sueldo,  9, null,             -5500),
      (v_sueldo, 10, null,                 0),
      (v_ahorros, 8, 500000,               0),
      (v_ahorros, 9, null,                 0)
    ) as x(acct, mo, opening, uncontrolled)
    order by acct, mo
  loop
    v_open := coalesce(m.opening, v_close);

    insert into monthly_account_balances
      (user_id, account_id, month, year, opening_balance,
       uncontrolled_expenses_total)
    values (v_user, m.acct, m.mo, 2026, v_open, m.uncontrolled);

    select v_open + m.uncontrolled
           + coalesce(sum(case type when 'income' then amount else -amount end), 0)
      into v_close
      from transactions
     where account_id = m.acct
       and extract(month from date) = m.mo
       and extract(year from date) = 2026;

    update accounts set balance = v_close where id = m.acct;
  end loop;

  -- The trigger stamps balance_updated_at on every balance change, so set the
  -- final values afterwards (balance unchanged => trigger does not fire).
  -- Ahorros keeps a stale date to exercise the "last updated" UI.
  update accounts set balance_updated_at = now() where id = v_sueldo;
  update accounts set balance_updated_at = '2026-09-28 12:00+00'
   where id = v_ahorros;
end
$seed$;

commit;