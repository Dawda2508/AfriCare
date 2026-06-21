-- ═══════════════════════════════════════════════════════
-- AfriCare Health Gambia — Supabase Database Schema
-- Paste this entire file into: Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════════

-- Enable UUID generation
create extension if not exists "uuid-ossp";

-- ─── DOCTORS ────────────────────────────────────────────
create table public.doctors (
  id                      uuid primary key default uuid_generate_v4(),
  full_name               text not null,
  phone                   text unique not null,
  email                   text,
  specialty               text not null,
  location                text not null,
  country                 text not null default 'Gambia',
  is_diaspora             boolean not null default false,
  is_approved             boolean not null default false,
  is_active               boolean not null default true,
  is_available_now        boolean not null default false,
  availability_updated_at timestamptz,
  consultation_fee        numeric(10,2) not null,
  rating                  numeric(3,1) default 0,
  avatar_initials         text,
  bio                     text,
  gmc_number              text,
  years_experience        integer,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

-- ─── PATIENTS ───────────────────────────────────────────
create table public.patients (
  id                  uuid primary key default uuid_generate_v4(),
  full_name           text not null,
  phone               text unique not null,
  email               text,
  date_of_birth       date,
  subscription_plan   text not null default 'basic' check (subscription_plan in ('basic','silver','gold','platinum')),
  subscription_active boolean not null default true,
  subscription_end    timestamptz,
  medical_notes       text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ─── BOOKINGS ───────────────────────────────────────────
create table public.bookings (
  id              uuid primary key default uuid_generate_v4(),
  booking_ref     text unique not null default 'AC-' || extract(epoch from now())::bigint || '-' || substr(md5(random()::text), 1, 5),
  patient_id      uuid not null references public.patients(id),
  doctor_id       uuid not null references public.doctors(id),
  booking_type    text not null check (booking_type in ('instant', 'instant_urgent', 'scheduled')),
  status          text not null default 'pending' check (status in ('pending','paid','in_progress','completed','cancelled')),
  scheduled_at    timestamptz,
  completed_at    timestamptz,
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ─── PAYMENTS ───────────────────────────────────────────
create table public.payments (
  id                    uuid primary key default uuid_generate_v4(),
  booking_id            uuid not null references public.bookings(id),
  tx_ref                text unique not null,
  flw_transaction_id    text,
  amount                numeric(10,2) not null,
  currency              text not null default 'GMD',
  status                text not null default 'pending' check (status in ('pending','completed','failed','refunded')),
  payment_method        text,
  created_at            timestamptz not null default now()
);

-- ─── REVENUE SPLITS ─────────────────────────────────────
create table public.revenue_splits (
  id                uuid primary key default uuid_generate_v4(),
  booking_id        uuid not null references public.bookings(id),
  doctor_id         uuid not null references public.doctors(id),
  total_amount      numeric(10,2) not null,
  africare_share    numeric(10,2) not null,
  doctor_share      numeric(10,2) not null,
  status            text not null default 'pending_payout' check (status in ('pending_payout','paid_out')),
  paid_out_at       timestamptz,
  created_at        timestamptz not null default now()
);

-- ─── LAB REFERRALS ──────────────────────────────────────
create table public.lab_referrals (
  id              uuid primary key default uuid_generate_v4(),
  booking_id      uuid references public.bookings(id),
  patient_id      uuid not null references public.patients(id),
  doctor_id       uuid not null references public.doctors(id),
  lab_name        text not null,
  tests           text[] not null,
  referral_code   text unique not null,
  status          text not null default 'pending' check (status in ('pending','redeemed','commission_paid')),
  commission_rate numeric(4,2) default 7.5,
  commission_paid numeric(10,2),
  created_at      timestamptz not null default now()
);

-- ─── RATINGS ────────────────────────────────────────────
create table public.ratings (
  id          uuid primary key default uuid_generate_v4(),
  booking_id  uuid not null references public.bookings(id),
  doctor_id   uuid not null references public.doctors(id),
  rating      integer not null check (rating between 1 and 5),
  created_at  timestamptz not null default now()
);

-- ─── INDEXES ────────────────────────────────────────────
create index idx_doctors_available on public.doctors(is_available_now) where is_approved = true and is_active = true;
create index idx_doctors_specialty  on public.doctors(specialty);
create index idx_bookings_patient   on public.bookings(patient_id);
create index idx_bookings_doctor    on public.bookings(doctor_id);
create index idx_bookings_status    on public.bookings(status);
create index idx_payments_tx_ref    on public.payments(tx_ref);
create index idx_lab_ref_code       on public.lab_referrals(referral_code);

-- ─── ROW LEVEL SECURITY ─────────────────────────────────
alter table public.doctors       enable row level security;
alter table public.patients      enable row level security;
alter table public.bookings      enable row level security;
alter table public.payments      enable row level security;
alter table public.revenue_splits enable row level security;
alter table public.lab_referrals enable row level security;
alter table public.ratings       enable row level security;

-- Doctors: public can read approved doctors
create policy "public read approved doctors" on public.doctors
  for select using (is_approved = true and is_active = true);

-- Service role (admin) can do everything
create policy "service role full access doctors"     on public.doctors      using (auth.role() = 'service_role');
create policy "service role full access patients"    on public.patients     using (auth.role() = 'service_role');
create policy "service role full access bookings"    on public.bookings     using (auth.role() = 'service_role');
create policy "service role full access payments"    on public.payments     using (auth.role() = 'service_role');
create policy "service role full access splits"      on public.revenue_splits using (auth.role() = 'service_role');
create policy "service role full access lab_refs"    on public.lab_referrals using (auth.role() = 'service_role');
create policy "service role full access ratings"     on public.ratings      using (auth.role() = 'service_role');

-- ─── SEED DATA — remove before production ───────────────
insert into public.doctors (full_name, phone, specialty, location, country, is_diaspora, is_approved, is_available_now, consultation_fee, rating, avatar_initials, gmc_number)
values
  ('Dr. Jainaba Njie',   '2203001001', 'General Practitioner', 'Banjul',          'Gambia',  false, true, true,  375.00, 5.0, 'JN', 'GMC-001'),
  ('Dr. Fatou Darboe',   '2203001002', 'Paediatrician',        'Serrekunda',       'Gambia',  false, true, true,  500.00, 4.5, 'FD', 'GMC-002'),
  ('Dr. Bakary Jallow',  '4407000001', 'Cardiologist',         'London, UK',       'UK',      true,  true, false, 875.00, 5.0, 'BJ', 'GMC-003'),
  ('Dr. Mariama Kah',    '2203001003', 'OB/GYN Specialist',    'Westfield Clinic', 'Gambia',  false, true, true,  625.00, 5.0, 'MK', 'GMC-004'),
  ('Dr. Alieu Sanneh',   '1416000001', 'Internal Medicine',    'Toronto, Canada',  'Canada',  true,  true, false, 1000.00, 5.0, 'AS', 'GMC-005'),
  ('Dr. Lamin Jawara',   '4915000001', 'Dermatologist',        'Berlin, Germany',  'Germany', true,  true, false, 812.00, 4.5, 'LJ', 'GMC-006');

-- ─── DONE ────────────────────────────────────────────────
-- Your AfriCare database is ready.
-- Next step: run the app with `npm run dev` or deploy to Vercel.
