-- ─── accounts ───────────────────────────────────────────
create table accounts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  balance     numeric(12, 2) not null default 0,
  color       text,
  icon        text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
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
  created_at     timestamptz not null default now()
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
  category_id         uuid references categories(id) on delete set null,
  name                text not null,
  approximate_amount  numeric(12, 2) not null default 0,
  due_day             integer check (due_day between 1 and 31),
  is_active           boolean not null default true,
  created_at          timestamptz not null default now()
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
  created_at      timestamptz not null default now(),
  unique (service_id, month, year)
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

-- ─── monthly_budgets (instancia concreta por mes) ─────────
create table monthly_budgets (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  category_id  uuid not null references categories(id) on delete cascade,
  amount       numeric(12, 2) not null check (amount > 0),
  month        integer not null check (month between 1 and 12),
  year         integer not null check (year >= 2000),
  unique (user_id, category_id, month, year)
);

-- ─── RLS (Row Level Security) ────────────────────────────
alter table accounts enable row level security;
alter table categories enable row level security;
alter table transactions enable row level security;
alter table services enable row level security;
alter table invoices enable row level security;
alter table monthly_budgets enable row level security;
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

create policy "users manage own monthly budgets"
  on monthly_budgets for all using (auth.uid() = user_id);

create policy "users manage own monthly account balances"
  on monthly_account_balances for all using (auth.uid() = user_id);
