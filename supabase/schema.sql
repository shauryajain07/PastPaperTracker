create extension if not exists pgcrypto;

create table if not exists public.subjects (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  catalog_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subjects
  add column if not exists catalog_key text;

update public.subjects
set catalog_key = lower(trim(regexp_replace(name, '[^a-zA-Z0-9]+', ' ', 'g')))
where catalog_key is null;

create table if not exists public.grade_boundary_sets (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete cascade,
  title text not null,
  kind text not null,
  session_code text,
  source_image_hash text,
  source_subject_title text,
  source_ocr_text text,
  boundary_1 double precision not null,
  boundary_2 double precision not null,
  boundary_3 double precision not null,
  boundary_4 double precision not null,
  boundary_5 double precision not null,
  boundary_6 double precision not null,
  boundary_7 double precision not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shared_subjects (
  id text primary key,
  title text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.shared_grade_boundary_sets (
  id text primary key,
  contributor_id uuid references auth.users(id) on delete set null,
  subject_key text not null,
  subject_title text not null,
  title text not null,
  session_code text not null,
  source_image_hash text,
  source_subject_title text,
  boundary_1 double precision not null,
  boundary_2 double precision not null,
  boundary_3 double precision not null,
  boundary_4 double precision not null,
  boundary_5 double precision not null,
  boundary_6 double precision not null,
  boundary_7 double precision not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.shared_subjects (id, title, created_at, updated_at)
select distinct
  subject_key,
  subject_title,
  min(created_at) over (partition by subject_key),
  max(updated_at) over (partition by subject_key)
from public.shared_grade_boundary_sets
where coalesce(subject_key, '') <> ''
on conflict (id) do update
set
  title = excluded.title,
  updated_at = greatest(public.shared_subjects.updated_at, excluded.updated_at);

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
create index if not exists subjects_catalog_key_idx on public.subjects(catalog_key);
create index if not exists grade_boundary_sets_owner_id_idx on public.grade_boundary_sets(owner_id);
create index if not exists grade_boundary_sets_subject_id_idx on public.grade_boundary_sets(subject_id);
create index if not exists grade_boundary_sets_session_code_idx on public.grade_boundary_sets(session_code);
create index if not exists shared_subjects_title_idx on public.shared_subjects(title);
create unique index if not exists shared_grade_boundary_sets_subject_session_idx on public.shared_grade_boundary_sets(subject_key, session_code);
create index if not exists shared_grade_boundary_sets_subject_key_idx on public.shared_grade_boundary_sets(subject_key);
create index if not exists mark_entries_owner_id_idx on public.mark_entries(owner_id);
create index if not exists mark_entries_subject_id_idx on public.mark_entries(subject_id);
create index if not exists mistake_entries_owner_id_idx on public.mistake_entries(owner_id);
create index if not exists mistake_entries_subject_id_idx on public.mistake_entries(subject_id);
create index if not exists mistake_entries_mark_entry_id_idx on public.mistake_entries(mark_entry_id);

alter table public.subjects enable row level security;
alter table public.grade_boundary_sets enable row level security;
alter table public.shared_subjects enable row level security;
alter table public.shared_grade_boundary_sets enable row level security;
alter table public.mark_entries enable row level security;
alter table public.mistake_entries enable row level security;

drop policy if exists "subjects_owner_all" on public.subjects;
create policy "subjects_owner_all"
on public.subjects
for all
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "grade_boundary_sets_owner_all" on public.grade_boundary_sets;
create policy "grade_boundary_sets_owner_all"
on public.grade_boundary_sets
for all
to authenticated
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "shared_subjects_read_all" on public.shared_subjects;
create policy "shared_subjects_read_all"
on public.shared_subjects
for select
to anon, authenticated
using (true);

drop policy if exists "shared_subjects_insert_authenticated" on public.shared_subjects;
create policy "shared_subjects_insert_authenticated"
on public.shared_subjects
for insert
to authenticated
with check (true);

drop policy if exists "shared_subjects_update_authenticated" on public.shared_subjects;
create policy "shared_subjects_update_authenticated"
on public.shared_subjects
for update
to authenticated
using (true)
with check (true);

drop policy if exists "shared_grade_boundary_sets_read_all" on public.shared_grade_boundary_sets;
create policy "shared_grade_boundary_sets_read_all"
on public.shared_grade_boundary_sets
for select
to anon, authenticated
using (true);

drop policy if exists "shared_grade_boundary_sets_insert_authenticated" on public.shared_grade_boundary_sets;
create policy "shared_grade_boundary_sets_insert_authenticated"
on public.shared_grade_boundary_sets
for insert
to authenticated
with check (auth.uid() = contributor_id);

drop policy if exists "shared_grade_boundary_sets_update_authenticated" on public.shared_grade_boundary_sets;
create policy "shared_grade_boundary_sets_update_authenticated"
on public.shared_grade_boundary_sets
for update
to authenticated
using (true)
with check (true);

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
