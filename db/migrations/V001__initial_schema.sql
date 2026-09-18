-- ─── accounts ───────────────────────────────────────────
create table accounts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  balance     numeric(12, 2) not null default 0,
  color       text,
  icon        text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (user_id, name)
);

-- ─── categories ─────────────────────────────────────────
create table categories (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  name           text not null,
  type           text not null check (type in ('income', 'expense')),
  color          text,
  icon           text,
  has_budget     boolean not null default false,
  budget_amount  numeric(12, 2),
  created_at     timestamptz not null default now(),
  unique (user_id, name)
);

-- ─── transactions ────────────────────────────────────────
create table transactions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  account_id     uuid not null references accounts(id) on delete cascade,
  category_id    uuid references categories(id) on delete set null,
  type           text not null check (type in ('income', 'expense', 'transfer')),
  amount         numeric(12, 2) not null check (amount > 0),
  description    text,
  date           date not null default current_date,
  created_at     timestamptz not null default now()
);

-- ─── services ───────────────────────────────────────────────
create table services (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  category_id         uuid not null references categories(id) on delete restrict,
  name                text not null,
  approximate_amount  numeric(12, 2) not null default 0,
  due_day             integer check (due_day between 1 and 31),
  is_active           boolean not null default true,
  created_at          timestamptz not null default now(),
  unique (user_id, name)
);

-- ─── invoices ─────────────────────────────────────────────────
create table invoices (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  service_id      uuid not null references services(id) on delete cascade,
  month           integer not null check (month between 1 and 12),
  year            integer not null check (year >= 2000),
  amount          numeric(12, 2) not null check (amount > 0),
  due_date        date,
  paid            boolean not null default false,
  paid_at         timestamptz,
  transaction_id  uuid references transactions(id) on delete set null,
  cancelled       boolean not null default false,
  cancelled_at    timestamptz,
  created_at      timestamptz not null default now(),
  unique (service_id, month, year),
  check (not (paid and cancelled))
);

-- ─── monthly_account_balances ─────────────────────────────
create table monthly_account_balances (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  account_id      uuid not null references accounts(id) on delete cascade,
  month           integer not null check (month between 1 and 12),
  year            integer not null check (year >= 2000),
  opening_balance numeric(12, 2) not null,
  unique (account_id, month, year)
);

-- ─── RLS (Row Level Security) ────────────────────────────
alter table accounts enable row level security;
alter table categories enable row level security;
alter table transactions enable row level security;
alter table services enable row level security;
alter table invoices enable row level security;
alter table monthly_account_balances enable row level security;

create policy "users manage own accounts"
  on accounts for all using (auth.uid() = user_id);

create policy "users manage own categories"
  on categories for all using (auth.uid() = user_id);

create policy "users manage own transactions"
  on transactions for all using (auth.uid() = user_id);

create policy "users manage own services"
  on services for all using (auth.uid() = user_id);

create policy "users manage own invoices"
  on invoices for all using (auth.uid() = user_id);

create policy "users manage own monthly account balances"
  on monthly_account_balances for all using (auth.uid() = user_id);

  -- ─── create_transaction (RPC) ──────────────────────────────
-- Inserta la fila en `transactions` y actualiza `accounts.balance` en la
-- misma transacción de Postgres: si algo falla (constraint, cuenta
-- inexistente, etc.) toda la función se revierte y no queda ni la
-- transacción ni el ajuste de saldo a medias.
--
-- security invoker (default): corre con los permisos del usuario que
-- llama, así que las policies de RLS de `transactions` y `accounts`
-- siguen aplicando igual que con un insert/update directo.
create or replace function public.create_transaction(
  p_user_id     uuid,
  p_account_id  uuid,
  p_category_id uuid,
  p_type        text,
  p_amount      numeric,
  p_description text,
  p_date        date
)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_id    uuid;
  v_delta numeric(12, 2);
begin
  if p_type = 'income' then
    v_delta := p_amount;
  elsif p_type = 'expense' then
    v_delta := -p_amount;
  else
    raise exception 'Tipo de transacción inválido: %', p_type;
  end if;

  insert into transactions (
    user_id, account_id, category_id, type, amount, description, date
  )
  values (
    p_user_id, p_account_id, p_category_id, p_type, p_amount, p_description, p_date
  )
  returning id into v_id;

  update accounts
  set balance = balance + v_delta
  where id = p_account_id
    and user_id = p_user_id;

  if not found then
    raise exception 'Cuenta % no encontrada para este usuario', p_account_id;
  end if;

  return v_id;
end;
$$;

grant execute on function public.create_transaction(
  uuid, uuid, uuid, text, numeric, text, date
) to authenticated;
