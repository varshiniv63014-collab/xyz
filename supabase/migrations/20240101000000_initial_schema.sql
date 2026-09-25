-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Drop existing tables if they exist to avoid conflicts during initial setup
drop table if exists public.ai_messages cascade;
drop table if exists public.ai_conversations cascade;
drop table if exists public.appointment_events cascade;
drop table if exists public.appointments cascade;
drop table if exists public.doctor_availability cascade;
drop table if exists public.doctors cascade;
drop table if exists public.hospital_departments cascade;
drop table if exists public.departments cascade;
drop table if exists public.hospitals cascade;
drop table if exists public.profiles cascade;

-- Profiles
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  date_of_birth date,
  gender text,
  address text,
  city text,
  state text,
  postal_code text,
  emergency_contact_name text,
  emergency_contact_phone text,
  preferred_language text default 'en',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Hospitals
create table public.hospitals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  hospital_type text not null default 'hospital',
  address text not null,
  city text not null,
  state text not null,
  postal_code text,
  phone text,
  email text,
  website text,
  latitude double precision,
  longitude double precision,
  emergency_available boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Departments
create table public.departments (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Hospital Departments
create table public.hospital_departments (
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  department_id uuid not null references public.departments(id) on delete cascade,
  primary key (hospital_id, department_id)
);

-- Doctors
create table public.doctors (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  department_id uuid not null references public.departments(id) on delete restrict,
  full_name text not null,
  bio text,
  qualifications text,
  years_experience integer,
  languages text[] not null default '{}',
  consultation_fee numeric(10,2),
  consultation_type text not null default 'in_person',
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (years_experience >= 0),
  check (consultation_fee >= 0)
);

-- Doctor Availability
create table public.doctor_availability (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  day_of_week integer not null,
  start_time time not null,
  end_time time not null,
  slot_duration_minutes integer not null default 30,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  check (day_of_week between 0 and 6),
  check (end_time > start_time),
  check (slot_duration_minutes > 0)
);

-- Appointments
create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete restrict,
  hospital_id uuid not null references public.hospitals(id) on delete restrict,
  appointment_date date not null,
  start_time time not null,
  end_time time not null,
  appointment_type text not null default 'in_person',
  patient_name text not null,
  patient_phone text,
  reason_for_visit text,
  notes text,
  status text not null default 'confirmed',
  booking_reference text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  cancelled_at timestamptz,
  check (end_time > start_time),
  check (
    status in (
      'confirmed',
      'completed',
      'cancelled',
      'no_show'
    )
  )
);

-- Prevent double booking
create unique index appointments_active_doctor_slot_unique
on public.appointments (
  doctor_id,
  appointment_date,
  start_time
)
where status = 'confirmed';

-- Appointment Audit Events
create table public.appointment_events (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- AI Conversations
create table public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- AI Messages
create table public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  structured_response jsonb,
  created_at timestamptz not null default now()
);

-- Indexes
create index idx_hospitals_city on public.hospitals(city);
create index idx_hospitals_is_active on public.hospitals(is_active);
create index idx_hospitals_location on public.hospitals(latitude, longitude);
create index idx_doctors_hospital_id on public.doctors(hospital_id);
create index idx_doctors_department_id on public.doctors(department_id);
create index idx_doctors_is_active on public.doctors(is_active);
create index idx_doctor_availability_doctor_id on public.doctor_availability(doctor_id);
create index idx_appointments_user_id on public.appointments(user_id);
create index idx_appointments_doc_date on public.appointments(doctor_id, appointment_date);
create index idx_appointments_hospital_id on public.appointments(hospital_id);
create index idx_appointments_status on public.appointments(status);
create index idx_appointment_events_appointment_id on public.appointment_events(appointment_id);
create index idx_ai_conversations_user_id on public.ai_conversations(user_id);
create index idx_ai_messages_conversation_id on public.ai_messages(conversation_id);

-- Row Level Security (RLS)

alter table public.profiles enable row level security;
create policy "Users can view their own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles for update using (auth.uid() = id);

alter table public.appointments enable row level security;
create policy "Users can view their own appointments" on public.appointments for select using (auth.uid() = user_id);
create policy "Users can insert their own appointments" on public.appointments for insert with check (auth.uid() = user_id);
create policy "Users can update their own appointments" on public.appointments for update using (auth.uid() = user_id);

alter table public.appointment_events enable row level security;
create policy "Users can view their own appointment events" on public.appointment_events for select using (
  exists (
    select 1 from public.appointments
    where appointments.id = appointment_events.appointment_id
    and appointments.user_id = auth.uid()
  )
);

alter table public.ai_conversations enable row level security;
create policy "Users can manage their own conversations" on public.ai_conversations for all using (auth.uid() = user_id);

alter table public.ai_messages enable row level security;
create policy "Users can manage their own messages" on public.ai_messages for all using (auth.uid() = user_id);

-- Read access for public tables
alter table public.hospitals enable row level security;
create policy "Public can view active hospitals" on public.hospitals for select using (is_active = true);

alter table public.departments enable row level security;
create policy "Public can view active departments" on public.departments for select using (is_active = true);

alter table public.hospital_departments enable row level security;
create policy "Public can view hospital departments" on public.hospital_departments for select using (true);

alter table public.doctors enable row level security;
create policy "Public can view active doctors" on public.doctors for select using (is_active = true);

alter table public.doctor_availability enable row level security;
create policy "Public can view doctor availability" on public.doctor_availability for select using (is_active = true);
