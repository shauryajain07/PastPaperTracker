create extension if not exists pgcrypto;

create table if not exists public.subjects (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mark_entries (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  paper_name text not null,
  exam_date timestamptz not null,
  scored_marks double precision not null,
  total_marks double precision not null,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mistake_entries (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  mark_entry_id uuid references public.mark_entries(id) on delete set null,
  title text not null,
  marks_lost double precision,
  note text not null,
  photo_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists subjects_owner_id_idx on public.subjects(owner_id);
create index if not exists mark_entries_owner_id_idx on public.mark_entries(owner_id);
create index if not exists mark_entries_subject_id_idx on public.mark_entries(subject_id);
create index if not exists mistake_entries_owner_id_idx on public.mistake_entries(owner_id);
create index if not exists mistake_entries_subject_id_idx on public.mistake_entries(subject_id);
create index if not exists mistake_entries_mark_entry_id_idx on public.mistake_entries(mark_entry_id);

alter table public.subjects enable row level security;
alter table public.mark_entries enable row level security;
alter table public.mistake_entries enable row level security;

drop policy if exists "subjects_owner_all" on public.subjects;
create policy "subjects_owner_all"
on public.subjects
for all
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "mark_entries_owner_all" on public.mark_entries;
create policy "mark_entries_owner_all"
on public.mark_entries
for all
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "mistake_entries_owner_all" on public.mistake_entries;
create policy "mistake_entries_owner_all"
on public.mistake_entries
for all
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

insert into storage.buckets (id, name, public)
values ('mistake-photos', 'mistake-photos', false)
on conflict (id) do nothing;

drop policy if exists "mistake_photos_owner_select" on storage.objects;
create policy "mistake_photos_owner_select"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'mistake-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "mistake_photos_owner_insert" on storage.objects;
create policy "mistake_photos_owner_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'mistake-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "mistake_photos_owner_update" on storage.objects;
create policy "mistake_photos_owner_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'mistake-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'mistake-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "mistake_photos_owner_delete" on storage.objects;
create policy "mistake_photos_owner_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'mistake-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);
