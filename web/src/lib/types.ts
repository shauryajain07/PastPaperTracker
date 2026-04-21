export type Subject = {
  id: string;
  owner_id: string;
  name: string;
  catalog_key: string | null;
  created_at: string;
  updated_at: string;
};

export type MarkEntry = {
  id: string;
  owner_id: string;
  subject_id: string | null;
  paper_name: string;
  exam_date: string;
  scored_marks: number;
  total_marks: number;
  notes: string;
  created_at: string;
  updated_at: string;
};

export type MistakeEntry = {
  id: string;
  owner_id: string;
  subject_id: string | null;
  mark_entry_id: string | null;
  title: string;
  marks_lost: number | null;
  note: string;
  photo_path: string | null;
  created_at: string;
  updated_at: string;
};

export type GradeBoundarySet = {
  id: string;
  owner_id: string;
  subject_id: string | null;
  title: string;
  kind: "manualDefault" | "sessionImport";
  session_code: string | null;
  source_image_hash: string | null;
  source_subject_title: string | null;
  source_ocr_text: string | null;
  boundary_1: number;
  boundary_2: number;
  boundary_3: number;
  boundary_4: number;
  boundary_5: number;
  boundary_6: number;
  boundary_7: number;
  created_at: string;
  updated_at: string;
};

export type SharedSubject = {
  id: string;
  title: string;
  created_at: string;
  updated_at: string;
};

export type SharedGradeBoundarySet = {
  id: string;
  contributor_id: string | null;
  subject_key: string;
  subject_title: string;
  title: string;
  session_code: string;
  source_image_hash: string | null;
  source_subject_title: string | null;
  boundary_1: number;
  boundary_2: number;
  boundary_3: number;
  boundary_4: number;
  boundary_5: number;
  boundary_6: number;
  boundary_7: number;
  created_at: string;
  updated_at: string;
};

export type AppData = {
  subjects: Subject[];
  marks: MarkEntry[];
  mistakes: MistakeEntry[];
  boundaries: GradeBoundarySet[];
  sharedSubjects: SharedSubject[];
  sharedBoundaries: SharedGradeBoundarySet[];
};
