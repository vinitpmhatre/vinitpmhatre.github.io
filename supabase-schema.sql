-- ClinicVoice MVP database foundation for Supabase/Postgres
create extension if not exists pgcrypto;

create table if not exists public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text,
  phone text,
  email text,
  languages text[] default array['English'],
  created_at timestamptz not null default now()
);

create table if not exists public.demo_requests (
  id uuid primary key default gen_random_uuid(),
  clinic_name text not null,
  contact_name text not null,
  email text not null,
  phone text,
  city text,
  clinic_size text,
  message text,
  status text not null default 'new' check (status in ('new','contacted','qualified','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  full_name text not null,
  phone text,
  email text,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  doctor_name text,
  starts_at timestamptz not null,
  reason text,
  status text not null default 'requested' check (status in ('requested','confirmed','cancelled','completed')),
  source text not null default 'clinicvoice' check (source in ('clinicvoice','staff','website')),
  created_at timestamptz not null default now()
);

create table if not exists public.calls (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid references public.patients(id) on delete set null,
  caller_phone text,
  direction text not null default 'inbound',
  summary text,
  transcript text,
  outcome text,
  duration_seconds integer,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_events (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  event_type text not null,
  title text not null,
  detail text,
  created_at timestamptz not null default now()
);

alter table public.clinics enable row level security;
alter table public.demo_requests enable row level security;
alter table public.patients enable row level security;
alter table public.appointments enable row level security;
alter table public.calls enable row level security;
alter table public.ai_events enable row level security;

-- Public website visitors may submit a demo request, but cannot read requests.
drop policy if exists "public can submit demo requests" on public.demo_requests;
create policy "public can submit demo requests"
on public.demo_requests for insert
to anon, authenticated
with check (true);

-- All operational clinic data stays private until clinic authentication is added.
-- The authenticated dashboard will receive scoped policies in the next phase.
