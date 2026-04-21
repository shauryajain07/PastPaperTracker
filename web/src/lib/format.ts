import type { GradeBoundarySet, MarkEntry, Subject } from "./types";

export const shortDate = new Intl.DateTimeFormat(undefined, {
  month: "short",
  day: "numeric",
  year: "numeric",
});

export function percentage(entry: Pick<MarkEntry, "scored_marks" | "total_marks">) {
  if (!entry.total_marks) return 0;
  return (entry.scored_marks / entry.total_marks) * 100;
}

export function scoreColor(value: number) {
  if (value < 45) return "var(--rose)";
  if (value < 70) return "var(--warm)";
  return "var(--accent)";
}

export function canonicalSubjectKey(name: string) {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");
}

export function generatedPaperName(fields: {
  year: string;
  session: "M" | "N";
  paperNumber: string;
  timezone: string;
}) {
  if (!fields.year || !fields.paperNumber || !fields.timezone) return "";
  return `${fields.year}-${fields.session}-${fields.paperNumber}-TZ${fields.timezone}`;
}

export function sessionCodeFromPaperName(paperName: string) {
  const match = paperName.match(/^(\d{4})-(M|N)-(\d+)-TZ(\d+)$/);
  if (!match) return null;
  const [, year, session, , timezone] = match;
  return canonicalSessionCode(`${session}${year.slice(-2)} TZ${timezone}`);
}

export function canonicalSessionCode(rawValue: string | null) {
  if (!rawValue) return null;
  const uppercased = rawValue.trim().toUpperCase().replace(/[-_]/g, " ");
  if (!uppercased) return null;

  const match = uppercased.match(/([MN])\s*(\d{2,4})\s*TZ\s*(\d+)/);
  if (!match) return uppercased.replace(/\s+/g, " ");

  const [, session, yearToken, timezone] = match;
  const year = yearToken.length === 4 ? yearToken.slice(-2) : yearToken;
  return `${session}${year} TZ${timezone}`;
}

function thresholdsAreAscending(set: GradeBoundarySet) {
  const values = [
    set.boundary_1,
    set.boundary_2,
    set.boundary_3,
    set.boundary_4,
    set.boundary_5,
    set.boundary_6,
    set.boundary_7,
  ];
  return values.every((value, index) => index === 0 || values[index - 1] <= value);
}

export function resolvedGrade(entry: MarkEntry, boundaries: GradeBoundarySet[]) {
  const sessionCode = sessionCodeFromPaperName(entry.paper_name);
  const matching =
    (sessionCode &&
      boundaries.find(
        (set) =>
          set.kind === "sessionImport" &&
          set.subject_id === entry.subject_id &&
          canonicalSessionCode(set.session_code) === sessionCode,
      )) ||
    boundaries.find((set) => set.kind === "manualDefault" && set.subject_id === entry.subject_id);

  if (!matching || !thresholdsAreAscending(matching)) return null;

  const entryPercentage = percentage(entry);
  const thresholdPairs = [
    { grade: 7, minimum: matching.boundary_7 },
    { grade: 6, minimum: matching.boundary_6 },
    { grade: 5, minimum: matching.boundary_5 },
    { grade: 4, minimum: matching.boundary_4 },
    { grade: 3, minimum: matching.boundary_3 },
    { grade: 2, minimum: matching.boundary_2 },
    { grade: 1, minimum: matching.boundary_1 },
  ];

  return thresholdPairs.find((pair) => entryPercentage >= pair.minimum)?.grade ?? 1;
}

export function subjectName(subjects: Subject[], subjectId: string | null) {
  return subjects.find((subject) => subject.id === subjectId)?.name ?? "No subject";
}

export function sortByDateDesc<T extends { exam_date?: string; created_at: string }>(rows: T[]) {
  return [...rows].sort((a, b) => {
    const left = a.exam_date ?? a.created_at;
    const right = b.exam_date ?? b.created_at;
    return new Date(right).getTime() - new Date(left).getTime();
  });
}
