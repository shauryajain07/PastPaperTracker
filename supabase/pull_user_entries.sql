-- Pull score entries for a specific user UUID.
-- Update the UUID below before running if needed.

with target_user as (
  select '1cceed1e-9084-441d-88b9-107c2eefc140'::uuid as user_id
)
select
  me.id as mark_entry_id,
  me.owner_id as user_id,
  s.name as subject_name,
  me.paper_name,
  me.exam_date,
  me.scored_marks,
  me.total_marks,
  round((me.scored_marks / nullif(me.total_marks, 0)) * 100, 2) as percentage,
  me.notes,
  me.created_at,
  me.updated_at
from public.mark_entries me
left join public.subjects s on s.id = me.subject_id
cross join target_user tu
where me.owner_id = tu.user_id
order by me.exam_date desc, me.created_at desc;
