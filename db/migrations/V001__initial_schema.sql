-- ─── accounts ───────────────────────────────────────────
create table accounts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  balance     numeric(12, 2) not null default 0,
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
  type           text not null check (type in ('income', 'expense')),
  amount         numeric(12, 2) not null check (amount > 0),
  description    text,
  date           date not null default current_date,
  -- true en las dos filas que arma una transferencia entre cuentas
  -- propias (una 'expense' en origen, una 'income' en destino, mismo
  -- monto): el dinero no entra ni sale de verdad, solo se mueve de una
  -- cuenta a otra, así que no debe contarse como ingreso/gasto real en
  -- ningún total ni en el desglose por categoría (ver
  -- TransactionViewModel._sumByType / _breakdownOf en el cliente).
  is_transfer    boolean not null default false,
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
  uncontrolled_expenses_total numeric(12, 2) not null default 0,
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

create or replace function public.create_transaction(
  p_user_id     uuid,
  p_account_id  uuid,
  p_category_id uuid,
  p_type        text,
  p_amount      numeric,
  p_description text,
  p_date        date,
  p_is_transfer boolean default false
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
    user_id, account_id, category_id, type, amount, description, date,
    is_transfer
  )
  values (
    p_user_id, p_account_id, p_category_id, p_type, p_amount, p_description,
    p_date, p_is_transfer
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
  uuid, uuid, uuid, text, numeric, text, date, boolean
) to authenticated;

create or replace function public.register_uncontrolled_adjustment(
  p_user_id     uuid,
  p_account_id  uuid,
  p_amount      numeric,
  p_month       integer,
  p_year        integer
)
returns void
language plpgsql
security invoker
as $$
begin
  update accounts
  set balance = balance + p_amount
  where id = p_account_id
    and user_id = p_user_id;

  if not found then
    raise exception 'Cuenta % no encontrada para este usuario', p_account_id;
  end if;

  update monthly_account_balances
  set uncontrolled_expenses_total = uncontrolled_expenses_total + p_amount
  where account_id = p_account_id
    and user_id = p_user_id
    and month = p_month
    and year = p_year;

  if not found then
    raise exception
      'No hay saldo de apertura cargado para la cuenta % en %/%',
      p_account_id, p_month, p_year;
  end if;
end;
$$;

grant execute on function public.register_uncontrolled_adjustment(
  uuid, uuid, numeric, integer, integer
) to authenticated;

create or replace function public.delete_transaction(
  p_user_id        uuid,
  p_transaction_id uuid
)
returns void
language plpgsql
security invoker
as $$
declare
  v_account_id uuid;
  v_type       text;
  v_amount     numeric(12, 2);
  v_delta      numeric(12, 2);
begin
  select account_id, type, amount
    into v_account_id, v_type, v_amount
    from transactions
   where id = p_transaction_id
     and user_id = p_user_id;

  if not found then
    raise exception
      'Transacción % no encontrada para este usuario', p_transaction_id;
  end if;

  if v_type = 'income' then
    v_delta := -v_amount;
  elsif v_type = 'expense' then
    v_delta := v_amount;
  else
    raise exception 'Tipo de transacción inválido: %', v_type;
  end if;

  delete from transactions
   where id = p_transaction_id
     and user_id = p_user_id;

  update accounts
     set balance = balance + v_delta
   where id = v_account_id
     and user_id = p_user_id;

  if not found then
    raise exception 'Cuenta % no encontrada para este usuario', v_account_id;
  end if;
end;
$$;
