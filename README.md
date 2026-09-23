# Pime Engineering — website + Accounts

Two things live in this one repo:

- `/` — the public marketing site (`index.html`, `images/`)
- `/accounts` — the private bookkeeping app (invoices, receipts, expenses,
  ledger, trial balance, income statement, balance sheet), gated behind a
  login. Not linked from the public site on purpose.

Both are plain static HTML/CSS/JS — no build step, no framework, no
`npm install`. Vercel can deploy this as-is.

The Accounts app talks to a **Supabase** project (Postgres + Auth) for
storage. That project needs to be created once before Accounts will work —
the site will load and tell you it isn't configured yet until you do.

---

## 1. Create the Supabase project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard) → **New project**.
2. Name it `pime-engineering` (or anything), pick a region close to South
   Africa (e.g. `eu-west-1`), set a database password (save it somewhere —
   you won't need it day-to-day, but keep it), and create it. Free tier is
   fine for this.
3. Once it's ready, open **SQL Editor** → **New query**, paste in the
   entire contents of `supabase/migrations/0001_init.sql`, and run it.
   This creates all the tables (`journal_entries`, `journal_lines`,
   `invoices`, `receipts`, `expenses`, `settings`) with Row Level Security
   already locked down to logged-in users only.
4. Go to **Authentication → Users → Add user**, and create the login for
   the Accounts app:
   - Email: `gwezerel@gmail.com`
   - Password: `Mangito@gwez83`
   - Tick **Auto Confirm User** so it doesn't wait on a confirmation email.

   (Change this password once you're in, from the same screen, or add more
   users the same way if more than one person needs access.)
5. Go to **Project Settings → API**. You need two values from this page:
   - **Project URL** (looks like `https://xxxxxxxx.supabase.co`)
   - **anon / public** key (a long string starting `eyJ...`)

## 2. Plug those values into the app

Open `accounts/index.html` in a text editor, find this near the top of the
`<script>` block:

```js
var SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
var SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
```

Replace both with the values from step 1.5. Save the file.

(The anon key is safe to have sitting in a client-side file like this —
it's designed to be public. What actually protects your data is the Row
Level Security policies from the migration, plus the login gate itself.)

## 3. Push to GitHub

Create a new **empty** repository on GitHub (no README, no `.gitignore` —
just the bare repo), then either use the included script or do it by hand.

**Option A — the script (Windows/PowerShell):**

Download this whole folder plus `push-to-github.ps1` into the same place,
edit the `$RepoPath` and `$RemoteUrl` variables at the top of the script,
then run:

```
powershell -ExecutionPolicy Bypass -File push-to-github.ps1
```

**Option B — by hand, any OS:**

```bash
cd pime-engineering
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

## 4. Connect Vercel

1. Go to [vercel.com/new](https://vercel.com/new) and import the GitHub
   repo you just pushed.
2. Framework preset: **Other** (Vercel should auto-detect "no framework" —
   leave build command and output directory blank/default).
3. Deploy. That's it — no environment variables needed, since the Supabase
   URL/key are already in the file from step 2.
4. Once it's live, add your real domain under **Project → Settings →
   Domains** if you want `pimeengineering.co.za` (or similar) instead of
   the `*.vercel.app` address.

The marketing site will be at your domain root; Accounts will be at
`yourdomain.com/accounts`.

---

## Notes on how Accounts works

- Every invoice, receipt, and expense posts a balanced double-entry
  journal entry (see `supabase/migrations/0001_init.sql` and the posting
  functions in `accounts/index.html`) — the Ledger, Trial Balance, Income
  Statement and Balance Sheet are all *computed live* from that journal,
  nothing is hand-maintained.
- VAT is off by default. Turn it on in Accounts → Settings if you're
  VAT-registered.
- If you ever want a second person to have their own login, just add them
  the same way as step 1.4 — everyone with a login sees the same books
  (this is a single-company tool, not multi-tenant).
- Chart of accounts, company details (address/phone/email/reg. no.) are
  edited directly in `accounts/index.html` (search for `CHART` and
  `COMPANY` near the top of the script) — ask me for changes any time and
  I can edit and hand you an updated file.
