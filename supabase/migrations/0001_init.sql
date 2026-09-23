-- Pime Engineering — Accounts schema
--
-- Double-entry bookkeeping backing store: every invoice, receipt and
-- expense posts a balanced journal_entry (a set of journal_lines whose
-- debits equal its credits). The Ledger, Trial Balance, Income Statement
-- and Balance Sheet in the app are all computed FROM journal_lines at
-- read time — this schema only needs to store the journal faithfully.
--
-- Access model: this is a single-tenant, single-company tool. Anyone
-- who successfully authenticates (i.e. has logged in with the Accounts
-- email/password) can read and write everything — there is no per-row
-- ownership because there is only one "company" in this database. The
-- login gate itself is what keeps this private, not row-level filtering.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- Settings (single row) — VAT configuration, opening-balances flag.
-- ---------------------------------------------------------------------
create table settings (
  id boolean primary key default true,
  constraint settings_singleton check (id),
  vat_enabled boolean not null default false,
  vat_rate numeric not null default 15,
  opening_done boolean not null default false,
  updated_at timestamptz not null default now()
);
insert into settings (id) values (true);

-- ---------------------------------------------------------------------
-- Journal — the authoritative double-entry ledger.
-- ---------------------------------------------------------------------
create table journal_entries (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  ref text not null default '',
  type text not null,               -- invoice | receipt | cash_sale | expense | payable_payment | owner_contribution | owner_drawing | opening
  party text not null default '',
  memo text not null default '',
  note text not null default '',    -- the plain-English "why this entry exists" explanation
  created_at timestamptz not null default now()
);
create index journal_entries_date_idx on journal_entries(date);

create table journal_lines (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references journal_entries(id) on delete cascade,
  account text not null,            -- chart-of-accounts code, e.g. '1000' (see accounts.js CHART)
  debit bigint not null default 0,  -- cents
  credit bigint not null default 0, -- cents
  constraint journal_lines_one_sided check (
    (debit > 0 and credit = 0) or (credit > 0 and debit = 0)
  )
);
create index journal_lines_entry_idx on journal_lines(entry_id);
create index journal_lines_account_idx on journal_lines(account);

-- ---------------------------------------------------------------------
-- Invoices — the printable documents; paidTotal/status are a cache kept
-- in sync by the app when a receipt is recorded against one (see
-- accounts/app.js recordInvoicePayment). The journal is still the
-- source of truth for the accounting; this table is for the UI list
-- and the printable invoice layout.
-- ---------------------------------------------------------------------
create table invoices (
  id uuid primary key default gen_random_uuid(),
  number text not null unique,
  date date not null,
  due_date date,
  client text not null,
  client_contact text not null default '',
  lines jsonb not null,              -- [{desc, qty, unitPrice, amount}]
  subtotal bigint not null,
  vat bigint not null default 0,
  total bigint not null,
  status text not null default 'unpaid',  -- unpaid | partial | paid
  paid_total bigint not null default 0,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Receipts — either an invoice payment or a standalone cash sale.
-- ---------------------------------------------------------------------
create table receipts (
  id uuid primary key default gen_random_uuid(),
  number text not null unique,
  date date not null,
  client text not null default '',
  amount bigint not null,
  method text not null default '',
  kind text not null,                -- invoice_payment | cash_sale
  linked_invoice_id uuid references invoices(id),
  linked_invoice_number text,
  lines jsonb,                       -- only for cash_sale
  subtotal bigint,
  vat bigint,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Expenses
-- ---------------------------------------------------------------------
create table expenses (
  id uuid primary key default gen_random_uuid(),
  number text not null unique,
  date date not null,
  category text not null,            -- chart-of-accounts expense code, e.g. '5000'
  payee text not null default '',
  amount bigint not null,
  paid_via text not null,            -- bank | payable
  memo text not null default '',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Row Level Security — locked to authenticated users only. The Accounts
-- app requires a Supabase Auth login before it ever touches these
-- tables (see accounts/app.js), so "authenticated" here effectively
-- means "the one person who knows the Accounts login".
-- ---------------------------------------------------------------------
alter table settings enable row level security;
alter table journal_entries enable row level security;
alter table journal_lines enable row level security;
alter table invoices enable row level security;
alter table receipts enable row level security;
alter table expenses enable row level security;

create policy "authenticated full access" on settings for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated full access" on journal_entries for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated full access" on journal_lines for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated full access" on invoices for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated full access" on receipts for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated full access" on expenses for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
