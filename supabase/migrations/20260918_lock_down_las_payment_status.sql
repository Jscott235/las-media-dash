-- Security fix: the dashboard reads las_payment_status straight from the
-- browser using the public (anon/authenticated) Supabase key. If this table
-- doesn't already have row-level security locked down, anyone signed in
-- could open devtools and run:
--
--   sb.from('las_payment_status').update({ payment_paid: true }).eq('id','lewis')
--
-- ...and mark their own account as paid, regardless of what's actually
-- owed. This migration makes sure that's not possible: the dashboard can
-- still READ the row (it needs to, to decide what to show), but only the
-- service role (Launchpad's own backend/admin tooling, never the browser)
-- can change it.
--
-- NOTE: this file could not be applied directly to the live database from
-- this session (the Supabase project connection kept timing out). It must
-- be run against the `las-media` Supabase project (ref: zwndffsorkqsjykauepp)
-- before this fix is considered complete — either via `supabase db push`,
-- the SQL editor in the Supabase dashboard, or the Supabase MCP tools once
-- the connection is working.

alter table if exists public.las_payment_status enable row level security;

drop policy if exists "las_payment_status_read" on public.las_payment_status;
create policy "las_payment_status_read"
  on public.las_payment_status
  for select
  to authenticated
  using (true);

-- Only the service role may write. Browser clients (anon + authenticated)
-- get read-only access from here on.
revoke insert, update, delete on public.las_payment_status from authenticated, anon;
