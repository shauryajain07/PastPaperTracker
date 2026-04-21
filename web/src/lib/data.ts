import { supabase } from "./supabase";
import type {
  AppData,
  GradeBoundarySet,
  MarkEntry,
  MistakeEntry,
  SharedGradeBoundarySet,
  SharedSubject,
  Subject,
} from "./types";

export async function loadAppData(ownerId: string): Promise<AppData> {
  const [
    subjectsResult,
    marksResult,
    mistakesResult,
    boundariesResult,
    sharedSubjectsResult,
    sharedBoundariesResult,
  ] = await Promise.all([
    supabase.from("subjects").select("*").eq("owner_id", ownerId).order("name"),
    supabase.from("mark_entries").select("*").eq("owner_id", ownerId).order("exam_date", { ascending: false }),
    supabase.from("mistake_entries").select("*").eq("owner_id", ownerId).order("created_at", { ascending: false }),
    supabase.from("grade_boundary_sets").select("*").eq("owner_id", ownerId).order("title"),
    supabase.from("shared_subjects").select("*").order("title"),
    supabase.from("shared_grade_boundary_sets").select("*").order("subject_title"),
  ]);

  const error =
    subjectsResult.error ||
    marksResult.error ||
    mistakesResult.error ||
    boundariesResult.error ||
    sharedSubjectsResult.error ||
    sharedBoundariesResult.error;
  if (error) throw error;

  return {
    subjects: (subjectsResult.data ?? []) as Subject[],
    marks: (marksResult.data ?? []) as MarkEntry[],
    mistakes: (mistakesResult.data ?? []) as MistakeEntry[],
    boundaries: (boundariesResult.data ?? []) as GradeBoundarySet[],
    sharedSubjects: (sharedSubjectsResult.data ?? []) as SharedSubject[],
    sharedBoundaries: (sharedBoundariesResult.data ?? []) as SharedGradeBoundarySet[],
  };
}

export function nowIso() {
  return new Date().toISOString();
}

export function newId() {
  return crypto.randomUUID();
}

export async function upsertSubject(row: Subject) {
  const { error } = await supabase.from("subjects").upsert(row);
  if (error) throw error;
}

export async function deleteSubject(id: string) {
  const { error } = await supabase.from("subjects").delete().eq("id", id);
  if (error) throw error;
}

export async function upsertMark(row: MarkEntry) {
  const { error } = await supabase.from("mark_entries").upsert(row);
  if (error) throw error;
}

export async function deleteMark(id: string) {
  const { error } = await supabase.from("mark_entries").delete().eq("id", id);
  if (error) throw error;
}

export async function upsertMistake(row: MistakeEntry) {
  const { error } = await supabase.from("mistake_entries").upsert(row);
  if (error) throw error;
}

export async function deleteMistake(id: string) {
  const { error } = await supabase.from("mistake_entries").delete().eq("id", id);
  if (error) throw error;
}

export async function upsertBoundary(row: GradeBoundarySet) {
  const { error } = await supabase.from("grade_boundary_sets").upsert(row);
  if (error) throw error;
}

export async function deleteBoundary(id: string) {
  const { error } = await supabase.from("grade_boundary_sets").delete().eq("id", id);
  if (error) throw error;
}
