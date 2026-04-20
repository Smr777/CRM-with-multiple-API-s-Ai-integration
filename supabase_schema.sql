-- Supabase Schema for ART CRM
-- Safe to re-run in Supabase SQL Editor.

-- Extensions
create extension if not exists pgcrypto;

-- REPAIR SECTION FOR EXISTING PROJECTS
alter table if exists public.users
  add column if not exists email text,
  add column if not exists display_name text,
  add column if not exists role text default 'client',
  add column if not exists client_type text default 'individual',
  add column if not exists welcome_packet_url text,
  add column if not exists welcome_instructions text,
  add column if not exists created_at timestamptz default now();

alter table if exists public.invoices
  add column if not exists amount decimal(12,2),
  add column if not exists status text default 'unpaid',
  add column if not exists date timestamptz default now(),
  add column if not exists description text,
  add column if not exists pdf_url text,
  add column if not exists proof_of_payment_url text,
  add column if not exists proof_history jsonb default '[]'::jsonb,
  add column if not exists created_at timestamptz default now();

alter table if exists public.contracts
  add column if not exists content text,
  add column if not exists signature text,
  add column if not exists signed_at timestamptz,
  add column if not exists status text default 'pending',
  add column if not exists duration_days integer,
  add column if not exists session_duration text,
  add column if not exists session_date_time timestamptz,
  add column if not exists sessions jsonb default '[]'::jsonb,
  add column if not exists created_at timestamptz default now();

alter table if exists public.assessment_templates
  add column if not exists title text,
  add column if not exists description text,
  add column if not exists questions jsonb default '[]'::jsonb,
  add column if not exists created_at timestamptz default now();

alter table if exists public.client_assessments
  add column if not exists title text,
  add column if not exists description text,
  add column if not exists questions jsonb default '[]'::jsonb,
  add column if not exists status text default 'pending',
  add column if not exists submitted_at timestamptz,
  add column if not exists updated_at timestamptz default now(),
  add column if not exists report_url text,
  add column if not exists created_at timestamptz default now();

alter table if exists public.notices
  add column if not exists title text,
  add column if not exists content text,
  add column if not exists target text default 'all',
  add column if not exists created_at timestamptz default now();

alter table if exists public.invites
  add column if not exists name text,
  add column if not exists email text,
  add column if not exists client_type text default 'individual',
  add column if not exists status text default 'pending',
  add column if not exists accepted_at timestamptz,
  add column if not exists created_at timestamptz default now();

alter table if exists public.feedback_forms
  add column if not exists title text,
  add column if not exists questions jsonb default '[]'::jsonb,
  add column if not exists active boolean default true,
  add column if not exists created_at timestamptz default now();

alter table if exists public.feedback_responses
  add column if not exists responses jsonb default '[]'::jsonb,
  add column if not exists submitted_at timestamptz default now(),
  add column if not exists ai_analysis jsonb;

alter table if exists public.messages
  add column if not exists subject text,
  add column if not exists body text,
  add column if not exists status text default 'new',
  add column if not exists reply text,
  add column if not exists replied_at timestamptz,
  add column if not exists created_at timestamptz default now();

alter table if exists public.file_uploads
  add column if not exists type text,
  add column if not exists context_id text,
  add column if not exists file_name text,
  add column if not exists file_type text,
  add column if not exists storage_path text,
  add column if not exists download_url text,
  add column if not exists created_at timestamptz default now();

-- TABLES
create table if not exists public.users (
  id uuid references auth.users(id) primary key,
  email text unique not null,
  display_name text,
  role text default 'client',
  client_type text default 'individual',
  welcome_packet_url text,
  welcome_instructions text,
  created_at timestamptz default now()
);

create table if not exists public.invoices (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references public.users(id) on delete cascade not null,
  amount decimal(12,2) not null,
  status text default 'unpaid',
  date timestamptz default now(),
  description text,
  pdf_url text,
  proof_of_payment_url text,
  proof_history jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.contracts (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references public.users(id) on delete cascade not null,
  content text not null,
  signature text,
  signed_at timestamptz,
  status text default 'pending',
  duration_days integer,
  session_duration text,
  session_date_time timestamptz,
  sessions jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.assessment_templates (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text,
  questions jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

create table if not exists public.client_assessments (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references public.users(id) on delete cascade not null,
  template_id uuid references public.assessment_templates(id) on delete set null,
  title text not null,
  description text,
  questions jsonb default '[]'::jsonb,
  status text default 'pending',
  submitted_at timestamptz,
  updated_at timestamptz default now(),
  report_url text,
  created_at timestamptz default now()
);

create table if not exists public.notices (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  content text not null,
  target text default 'all',
  created_at timestamptz default now()
);

create table if not exists public.invites (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  email text unique not null,
  client_type text default 'individual',
  status text default 'pending',
  accepted_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.feedback_forms (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  questions jsonb default '[]'::jsonb,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.feedback_responses (
  id uuid default gen_random_uuid() primary key,
  form_id uuid references public.feedback_forms(id) on delete cascade not null,
  client_id uuid references public.users(id) on delete cascade not null,
  responses jsonb default '[]'::jsonb,
  submitted_at timestamptz default now(),
  ai_analysis jsonb
);

create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  client_id uuid references public.users(id) on delete cascade not null,
  subject text not null,
  body text not null,
  status text default 'new',
  reply text,
  replied_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists public.file_uploads (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  type text not null,
  context_id text,
  file_name text,
  file_type text,
  storage_path text,
  download_url text,
  created_at timestamptz default now()
);

-- BACKFILL MISSING USER PROFILES
insert into public.users (id, email, display_name, role, created_at)
select
  au.id,
  lower(au.email),
  coalesce(au.raw_user_meta_data->>'full_name', split_part(lower(au.email), '@', 1)),
  case
    when lower(au.email) = 'sidharthamishra6@gmail.com' then 'admin'
    else 'client'
  end,
  now()
from auth.users au
left join public.users pu on pu.id = au.id
where pu.id is null;

update public.users
set email = lower(email)
where email <> lower(email);

update public.invites
set email = lower(email)
where email <> lower(email);

-- RLS
alter table public.users enable row level security;
alter table public.invoices enable row level security;
alter table public.contracts enable row level security;
alter table public.assessment_templates enable row level security;
alter table public.client_assessments enable row level security;
alter table public.notices enable row level security;
alter table public.invites enable row level security;
alter table public.feedback_forms enable row level security;
alter table public.feedback_responses enable row level security;
alter table public.messages enable row level security;
alter table public.file_uploads enable row level security;

-- HELPER FUNCTION
create or replace function public.is_admin()
returns boolean as $$
begin
  return (
    (select role from public.users where id = auth.uid()) = 'admin' or
    (select email from auth.users where id = auth.uid()) = 'sidharthamishra6@gmail.com'
  );
end;
$$ language plpgsql security definer;

create or replace function public.check_invite(invite_email text)
returns boolean as $$
begin
  return exists (
    select 1
    from public.invites
    where email = lower(invite_email)
  );
end;
$$ language plpgsql security definer;

create or replace function public.accept_invite(invite_email text)
returns void as $$
begin
  update public.invites
  set
    status = 'accepted',
    accepted_at = now()
  where email = lower(invite_email);
end;
$$ language plpgsql security definer;

-- POLICIES
drop policy if exists "Allow public read of profiles" on public.users;
create policy "Allow public read of profiles" on public.users
  for select using (true);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile" on public.users
  for update using (auth.uid() = id);

drop policy if exists "Admin manage all profiles" on public.users;
create policy "Admin manage all profiles" on public.users
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admin can manage invites" on public.invites;
create policy "Admin can manage invites" on public.invites
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Anyone can read notices" on public.notices;
create policy "Anyone can read notices" on public.notices
  for select using (true);

drop policy if exists "Admin can manage notices" on public.notices;
create policy "Admin can manage notices" on public.notices
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Admin can manage invoices" on public.invoices;
create policy "Admin can manage invoices" on public.invoices
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Clients can read own invoices" on public.invoices;
create policy "Clients can read own invoices" on public.invoices
  for select using (client_id = auth.uid() or public.is_admin());

drop policy if exists "Clients can update own invoices for adding proof" on public.invoices;
create policy "Clients can update own invoices for adding proof" on public.invoices
  for update using (client_id = auth.uid() or public.is_admin())
  with check (client_id = auth.uid() or public.is_admin());

drop policy if exists "Admin can manage contracts" on public.contracts;
create policy "Admin can manage contracts" on public.contracts
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Clients can read own contracts" on public.contracts;
create policy "Clients can read own contracts" on public.contracts
  for select using (client_id = auth.uid() or public.is_admin());

drop policy if exists "Clients can sign own contracts" on public.contracts;
create policy "Clients can sign own contracts" on public.contracts
  for update using (client_id = auth.uid() or public.is_admin())
  with check (client_id = auth.uid() or public.is_admin());

drop policy if exists "Admin can manage assessment templates" on public.assessment_templates;
create policy "Admin can manage assessment templates" on public.assessment_templates
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Anyone can read templates" on public.assessment_templates;
create policy "Anyone can read templates" on public.assessment_templates
  for select using (true);

drop policy if exists "Admin can manage client assessments" on public.client_assessments;
create policy "Admin can manage client assessments" on public.client_assessments
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Clients can access own assessments" on public.client_assessments;
create policy "Clients can access own assessments" on public.client_assessments
  using (client_id = auth.uid() or public.is_admin());

drop policy if exists "Anyone can read active feedback forms" on public.feedback_forms;
create policy "Anyone can read active feedback forms" on public.feedback_forms
  for select using (active = true or public.is_admin());

drop policy if exists "Admin manage feedback forms" on public.feedback_forms;
create policy "Admin manage feedback forms" on public.feedback_forms
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Clients can manage own responses" on public.feedback_responses;
create policy "Clients can manage own responses" on public.feedback_responses
  using (client_id = auth.uid() or public.is_admin())
  with check (client_id = auth.uid() or public.is_admin());

drop policy if exists "Users can manage own messages" on public.messages;
create policy "Users can manage own messages" on public.messages
  using (client_id = auth.uid() or public.is_admin())
  with check (client_id = auth.uid() or public.is_admin());

drop policy if exists "Users can manage own file uploads" on public.file_uploads;
create policy "Users can manage own file uploads" on public.file_uploads
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

-- SIGNUP TRIGGER
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, display_name, role)
  values (new.id, lower(new.email), new.raw_user_meta_data->>'full_name', 'client')
  on conflict (id) do update set
    email = excluded.email,
    display_name = excluded.display_name;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- STORAGE BUCKET (optional for older app flows)
insert into storage.buckets (id, name, public)
values ('documents', 'documents', true)
on conflict (id) do nothing;

drop policy if exists "Authenticated users can upload documents" on storage.objects;
drop policy if exists "Public can view documents" on storage.objects;
drop policy if exists "Authenticated users can manage documents" on storage.objects;

create policy "Public can view documents" on storage.objects
  for select to public
  using (bucket_id = 'documents');

create policy "Authenticated users can upload documents" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'documents');

create policy "Authenticated users can manage documents" on storage.objects
  for all to authenticated
  using (bucket_id = 'documents')
  with check (bucket_id = 'documents');
