"use client";

import { useEffect, useMemo, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import {
  BarChart3,
  BookOpen,
  Calendar,
  CheckCircle2,
  ChevronRight,
  CircleAlert,
  GraduationCap,
  LayoutDashboard,
  LineChart,
  LogOut,
  Plus,
  RefreshCw,
  Settings,
  Sparkles,
  Trash2,
} from "lucide-react";
import { supabase } from "../src/lib/supabase";
import {
  deleteBoundary,
  deleteMark,
  deleteMistake,
  deleteSubject,
  loadAppData,
  newId,
  nowIso,
  upsertBoundary,
  upsertMark,
  upsertMistake,
  upsertSubject,
} from "../src/lib/data";
import {
  canonicalSubjectKey,
  generatedPaperName,
  percentage,
  resolvedGrade,
  scoreColor,
  shortDate,
  sortByDateDesc,
  subjectName,
} from "../src/lib/format";
import type { AppData, GradeBoundarySet, MarkEntry, MistakeEntry, Subject } from "../src/lib/types";
import type { Session } from "@supabase/supabase-js";

type Tab = "dashboard" | "tests" | "mistakes" | "settings";
type AuthMode = "signin" | "signup" | "reset";

const emptyData: AppData = {
  subjects: [],
  marks: [],
  mistakes: [],
  boundaries: [],
  sharedSubjects: [],
  sharedBoundaries: [],
};

const spring = {
  initial: { opacity: 0, y: 14 },
  animate: { opacity: 1, y: 0 },
  exit: { opacity: 0, y: -8 },
  transition: { duration: 0.22 },
};

export default function Page() {
  const [session, setSession] = useState<Session | null>(null);
  const [data, setData] = useState<AppData>(emptyData);
  const [tab, setTab] = useState<Tab>("dashboard");
  const [filter, setFilter] = useState("all");
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");
  const ownerId = session?.user.id ?? "";

  useEffect(() => {
    let mounted = true;
    supabase.auth.getSession().then(({ data: authData }) => {
      if (!mounted) return;
      setSession(authData.session);
      setLoading(false);
    });
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      if (!nextSession) setData(emptyData);
    });
    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  async function refresh() {
    if (!ownerId) return;
    setMessage("");
    setLoading(true);
    try {
      setData(await loadAppData(ownerId));
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Could not load your study data.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ownerId]);

  if (!session) {
    return <AuthScreen loading={loading} message={message} setMessage={setMessage} />;
  }

  const visibleMarks = filter === "all" ? data.marks : data.marks.filter((entry) => entry.subject_id === filter);
  const visibleMistakes =
    filter === "all" ? data.mistakes : data.mistakes.filter((entry) => entry.subject_id === filter);

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand-block">
          <img src="/brand-logo.png" alt="" />
          <div>
            <p>Past Paper</p>
            <strong>Tracker</strong>
          </div>
        </div>
        <nav className="nav-list" aria-label="Main navigation">
          <NavButton active={tab === "dashboard"} icon={<LayoutDashboard />} label="Dashboard" onClick={() => setTab("dashboard")} />
          <NavButton active={tab === "tests"} icon={<BookOpen />} label="Tests" onClick={() => setTab("tests")} />
          <NavButton active={tab === "mistakes"} icon={<CircleAlert />} label="Mistakes" onClick={() => setTab("mistakes")} />
          <NavButton active={tab === "settings"} icon={<Settings />} label="Settings" onClick={() => setTab("settings")} />
        </nav>
        <div className="sidebar-footer">
          <button className="ghost-button" onClick={refresh}>
            <RefreshCw size={16} />
            Sync
          </button>
          <button className="ghost-button" onClick={() => supabase.auth.signOut()}>
            <LogOut size={16} />
            Sign out
          </button>
        </div>
      </aside>

      <section className="workspace">
        <header className="topbar">
          <div>
            <p className="eyebrow">Cloud workspace</p>
            <h1>{tabTitle(tab)}</h1>
          </div>
          <SubjectFilter subjects={data.subjects} value={filter} onChange={setFilter} />
        </header>

        {message ? <StatusBanner tone="error" message={message} /> : null}
        {loading ? <StatusBanner tone="neutral" message="Loading the latest Supabase data..." /> : null}

        <AnimatePresence mode="wait">
          {tab === "dashboard" && (
            <motion.div key="dashboard" {...spring}>
              <Dashboard data={data} marks={visibleMarks} mistakes={visibleMistakes} filter={filter} />
            </motion.div>
          )}
          {tab === "tests" && (
            <motion.div key="tests" {...spring}>
              <Tests
                ownerId={ownerId}
                data={data}
                marks={visibleMarks}
                onSaved={refresh}
                setMessage={setMessage}
              />
            </motion.div>
          )}
          {tab === "mistakes" && (
            <motion.div key="mistakes" {...spring}>
              <Mistakes
                ownerId={ownerId}
                data={data}
                mistakes={visibleMistakes}
                onSaved={refresh}
                setMessage={setMessage}
              />
            </motion.div>
          )}
          {tab === "settings" && (
            <motion.div key="settings" {...spring}>
              <SettingsPanel ownerId={ownerId} data={data} onSaved={refresh} setMessage={setMessage} />
            </motion.div>
          )}
        </AnimatePresence>
      </section>
    </main>
  );
}

function AuthScreen({
  loading,
  message,
  setMessage,
}: {
  loading: boolean;
  message: string;
  setMessage: (message: string) => void;
}) {
  const [mode, setMode] = useState<AuthMode>("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [working, setWorking] = useState(false);

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setWorking(true);
    setMessage("");
    const action =
      mode === "signin"
        ? supabase.auth.signInWithPassword({ email, password })
        : mode === "signup"
          ? supabase.auth.signUp({ email, password })
          : supabase.auth.resetPasswordForEmail(email, { redirectTo: window.location.origin });
    const { error } = await action;
    setWorking(false);
    if (error) {
      setMessage(error.message);
      return;
    }
    if (mode === "reset") setMessage("Password reset email sent.");
    if (mode === "signup") setMessage("Account created. Check email if confirmation is enabled.");
  }

  return (
    <main className="auth-shell">
      <motion.section className="auth-visual" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.35 }}>
        <div className="auth-copy">
          <img src="/brand-logo.png" alt="" />
          <p>Past Paper Tracker</p>
          <h1>Track every paper without the weekly dev-build logout.</h1>
          <span>Browser sessions stay refreshed while Supabase keeps each account separated.</span>
        </div>
      </motion.section>
      <motion.form className="auth-panel" onSubmit={submit} initial={{ opacity: 0, x: 18 }} animate={{ opacity: 1, x: 0 }}>
        <div className="segmented">
          <button type="button" className={mode === "signin" ? "active" : ""} onClick={() => setMode("signin")}>
            Sign in
          </button>
          <button type="button" className={mode === "signup" ? "active" : ""} onClick={() => setMode("signup")}>
            Sign up
          </button>
          <button type="button" className={mode === "reset" ? "active" : ""} onClick={() => setMode("reset")}>
            Reset
          </button>
        </div>
        <div>
          <p className="eyebrow">Study sync</p>
          <h2>{mode === "signin" ? "Welcome back." : mode === "signup" ? "Create your workspace." : "Reset password."}</h2>
        </div>
        <label>
          Email
          <input type="email" value={email} onChange={(event) => setEmail(event.target.value)} required />
        </label>
        {mode !== "reset" ? (
          <label>
            Password
            <input type="password" value={password} onChange={(event) => setPassword(event.target.value)} required />
          </label>
        ) : null}
        <button className="primary-button" disabled={working || loading}>
          {working ? "Working..." : mode === "signin" ? "Sign in" : mode === "signup" ? "Create account" : "Send reset link"}
        </button>
        {message ? <StatusBanner tone={message.includes("sent") || message.includes("created") ? "success" : "error"} message={message} /> : null}
      </motion.form>
    </main>
  );
}

function Dashboard({ data, marks, mistakes, filter }: { data: AppData; marks: MarkEntry[]; mistakes: MistakeEntry[]; filter: string }) {
  const sortedMarks = sortByDateDesc(marks);
  const average = sortedMarks.length ? sortedMarks.reduce((sum, entry) => sum + percentage(entry), 0) / sortedMarks.length : 0;
  const grades = sortedMarks.map((entry) => resolvedGrade(entry, data.boundaries)).filter((grade): grade is number => grade !== null);
  const totalLost = mistakes.reduce((sum, entry) => sum + (entry.marks_lost ?? 0), 0);
  const latest = sortedMarks[0];
  const best = sortedMarks.reduce<MarkEntry | null>((current, entry) => (!current || percentage(entry) > percentage(current) ? entry : current), null);
  const title = filter === "all" ? "All subjects" : subjectName(data.subjects, filter);

  return (
    <div className="stack">
      <section className="hero-band">
        <div>
          <p className="eyebrow">{title}</p>
          <h2>{sortedMarks.length ? `${Math.round(average)}% average score` : "Log your first paper"}</h2>
          <p>{latest ? `${latest.paper_name} is your latest saved paper.` : "Your web dashboard will fill with the same Supabase data as the iOS app."}</p>
        </div>
        <Sparkline marks={sortedMarks} />
      </section>

      <div className="metric-grid">
        <Metric label="Visible tests" value={sortedMarks.length.toString()} icon={<BookOpen />} />
        <Metric label="Best result" value={best ? `${Math.round(percentage(best))}%` : "--"} icon={<CheckCircle2 />} />
        <Metric label="Avg IB grade" value={grades.length ? `${(grades.reduce((a, b) => a + b, 0) / grades.length).toFixed(1)}/7` : "--"} icon={<GraduationCap />} />
        <Metric label="Mistake load" value={totalLost ? `${Math.round(totalLost)} marks` : `${mistakes.length} items`} icon={<CircleAlert />} />
      </div>

      <section className="two-column">
        <div className="plain-section">
          <SectionHeading title="Recent tests" detail="Newest papers across the selected subject lens." />
          <EntryList
            rows={sortedMarks.slice(0, 6).map((entry) => ({
              id: entry.id,
              title: entry.paper_name,
              meta: subjectName(data.subjects, entry.subject_id),
              value: `${Math.round(percentage(entry))}%`,
              accent: scoreColor(percentage(entry)),
            }))}
          />
        </div>
        <div className="plain-section">
          <SectionHeading title="Review queue" detail="Mistakes that still deserve a second look." />
          <EntryList
            rows={mistakes.slice(0, 6).map((entry) => ({
              id: entry.id,
              title: entry.title,
              meta: subjectName(data.subjects, entry.subject_id),
              value: entry.marks_lost ? `${entry.marks_lost} marks` : "Review",
              accent: "var(--rose)",
            }))}
          />
        </div>
      </section>
    </div>
  );
}

function Tests({
  ownerId,
  data,
  marks,
  onSaved,
  setMessage,
}: {
  ownerId: string;
  data: AppData;
  marks: MarkEntry[];
  onSaved: () => Promise<void>;
  setMessage: (message: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const sorted = sortByDateDesc(marks);

  return (
    <div className="stack">
      <ActionHeader
        eyebrow="Results library"
        title="Test history"
        detail={sorted.length ? `${sorted.length} papers in this view.` : "Save completed papers with score, subject, date, and notes."}
        action="Log New Test"
        onAction={() => setOpen(true)}
      />
      <EntryList
        rows={sorted.map((entry) => ({
          id: entry.id,
          title: entry.paper_name,
          meta: `${subjectName(data.subjects, entry.subject_id)} - ${shortDate.format(new Date(entry.exam_date))}`,
          value: `${entry.scored_marks}/${entry.total_marks} (${Math.round(percentage(entry))}%)`,
          accent: scoreColor(percentage(entry)),
          onDelete: async () => {
            await deleteMark(entry.id);
            await onSaved();
          },
        }))}
      />
      <Modal open={open} title="Log a past paper" onClose={() => setOpen(false)}>
        <TestForm ownerId={ownerId} data={data} onSaved={onSaved} onClose={() => setOpen(false)} setMessage={setMessage} />
      </Modal>
    </div>
  );
}

function Mistakes({
  ownerId,
  data,
  mistakes,
  onSaved,
  setMessage,
}: {
  ownerId: string;
  data: AppData;
  mistakes: MistakeEntry[];
  onSaved: () => Promise<void>;
  setMessage: (message: string) => void;
}) {
  const [open, setOpen] = useState(false);
  return (
    <div className="stack">
      <ActionHeader
        eyebrow="Review queue"
        title="Mistake review"
        detail={mistakes.length ? `${mistakes.length} review items in this lens.` : "Capture misses and connect them to subjects or papers."}
        action="Capture Mistake"
        onAction={() => setOpen(true)}
      />
      <EntryList
        rows={mistakes.map((entry) => ({
          id: entry.id,
          title: entry.title,
          meta: `${subjectName(data.subjects, entry.subject_id)}${entry.note ? ` - ${entry.note}` : ""}`,
          value: entry.marks_lost ? `${entry.marks_lost} marks` : "Review",
          accent: "var(--rose)",
          onDelete: async () => {
            await deleteMistake(entry.id);
            await onSaved();
          },
        }))}
      />
      <Modal open={open} title="Capture mistake" onClose={() => setOpen(false)}>
        <MistakeForm ownerId={ownerId} data={data} onSaved={onSaved} onClose={() => setOpen(false)} setMessage={setMessage} />
      </Modal>
    </div>
  );
}

function SettingsPanel({
  ownerId,
  data,
  onSaved,
  setMessage,
}: {
  ownerId: string;
  data: AppData;
  onSaved: () => Promise<void>;
  setMessage: (message: string) => void;
}) {
  const [subjectOpen, setSubjectOpen] = useState(false);
  const [boundaryOpen, setBoundaryOpen] = useState(false);
  return (
    <div className="stack">
      <ActionHeader
        eyebrow="Library setup"
        title="Subjects and grade boundaries"
        detail="Manage the shared structure used by tests, mistakes, and IB previews."
        action="Add Subject"
        onAction={() => setSubjectOpen(true)}
      />
      <section className="two-column">
        <div className="plain-section">
          <SectionHeading title="Subjects" detail="Local subjects synced to Supabase." />
          <EntryList
            rows={data.subjects.map((subject) => ({
              id: subject.id,
              title: subject.name,
              meta: subject.catalog_key ?? canonicalSubjectKey(subject.name),
              value: "Subject",
              accent: "var(--accent)",
              onDelete: async () => {
                await deleteSubject(subject.id);
                await onSaved();
              },
            }))}
          />
        </div>
        <div className="plain-section">
          <div className="section-title-row">
            <SectionHeading title="Grade boundaries" detail="Manual defaults and session imports." />
            <button className="icon-button" onClick={() => setBoundaryOpen(true)} aria-label="Add grade boundary">
              <Plus size={18} />
            </button>
          </div>
          <EntryList
            rows={data.boundaries.map((set) => ({
              id: set.id,
              title: set.title,
              meta: `${subjectName(data.subjects, set.subject_id)} - ${set.session_code ?? "Default"}`,
              value: set.kind === "manualDefault" ? "Manual" : "Session",
              accent: "var(--sky)",
              onDelete: async () => {
                await deleteBoundary(set.id);
                await onSaved();
              },
            }))}
          />
        </div>
      </section>
      <Modal open={subjectOpen} title="Create subject" onClose={() => setSubjectOpen(false)}>
        <SubjectForm ownerId={ownerId} data={data} onSaved={onSaved} onClose={() => setSubjectOpen(false)} setMessage={setMessage} />
      </Modal>
      <Modal open={boundaryOpen} title="Add grade boundary" onClose={() => setBoundaryOpen(false)}>
        <BoundaryForm ownerId={ownerId} data={data} onSaved={onSaved} onClose={() => setBoundaryOpen(false)} setMessage={setMessage} />
      </Modal>
    </div>
  );
}

function SubjectForm(props: FormProps) {
  const { ownerId, data, onSaved, onClose, setMessage } = props;
  const [name, setName] = useState("");
  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      const shared = data.sharedSubjects.find((subject) => subject.title.toLowerCase() === name.trim().toLowerCase());
      await upsertSubject({
        id: newId(),
        owner_id: ownerId,
        name: name.trim(),
        catalog_key: shared?.id ?? canonicalSubjectKey(name),
        created_at: nowIso(),
        updated_at: nowIso(),
      });
      await onSaved();
      onClose();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Could not save subject.");
    }
  }
  return (
    <form className="form-grid" onSubmit={submit}>
      <label>
        Name
        <input value={name} onChange={(event) => setName(event.target.value)} placeholder="Mathematics" required />
      </label>
      <div className="suggestions">
        {data.sharedSubjects.slice(0, 6).map((subject) => (
          <button type="button" key={subject.id} onClick={() => setName(subject.title)}>
            {subject.title}
          </button>
        ))}
      </div>
      <button className="primary-button">Save subject</button>
    </form>
  );
}

type FormProps = {
  ownerId: string;
  data: AppData;
  onSaved: () => Promise<void>;
  onClose: () => void;
  setMessage: (message: string) => void;
};

function TestForm({ ownerId, data, onSaved, onClose, setMessage }: FormProps) {
  const [subjectId, setSubjectId] = useState(data.subjects[0]?.id ?? "");
  const [year, setYear] = useState(new Date().getFullYear().toString());
  const [session, setSession] = useState<"M" | "N">("M");
  const [paperNumber, setPaperNumber] = useState("");
  const [timezone, setTimezone] = useState("1");
  const [examDate, setExamDate] = useState(new Date().toISOString().slice(0, 10));
  const [scored, setScored] = useState("");
  const [total, setTotal] = useState("");
  const [notes, setNotes] = useState("");
  const paperName = generatedPaperName({ year, session, paperNumber, timezone });
  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      await upsertMark({
        id: newId(),
        owner_id: ownerId,
        subject_id: subjectId,
        paper_name: paperName,
        exam_date: new Date(examDate).toISOString(),
        scored_marks: Number(scored),
        total_marks: Number(total),
        notes,
        created_at: nowIso(),
        updated_at: nowIso(),
      });
      await onSaved();
      onClose();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Could not save test.");
    }
  }
  return (
    <form className="form-grid" onSubmit={submit}>
      <SelectSubject subjects={data.subjects} value={subjectId} onChange={setSubjectId} />
      <div className="four-grid">
        <label>
          Year
          <input value={year} onChange={(event) => setYear(event.target.value)} required />
        </label>
        <label>
          Session
          <select value={session} onChange={(event) => setSession(event.target.value as "M" | "N")}>
            <option value="M">M</option>
            <option value="N">N</option>
          </select>
        </label>
        <label>
          Paper
          <input value={paperNumber} onChange={(event) => setPaperNumber(event.target.value)} required />
        </label>
        <label>
          TZ
          <input value={timezone} onChange={(event) => setTimezone(event.target.value)} required />
        </label>
      </div>
      <p className="preview-line">{paperName || "Paper name preview"}</p>
      <div className="three-grid">
        <label>
          Exam date
          <input type="date" value={examDate} onChange={(event) => setExamDate(event.target.value)} required />
        </label>
        <label>
          Scored
          <input type="number" step="0.1" value={scored} onChange={(event) => setScored(event.target.value)} required />
        </label>
        <label>
          Total
          <input type="number" step="0.1" value={total} onChange={(event) => setTotal(event.target.value)} required />
        </label>
      </div>
      <label>
        Notes
        <textarea value={notes} onChange={(event) => setNotes(event.target.value)} />
      </label>
      <button className="primary-button" disabled={!data.subjects.length}>
        Save test
      </button>
    </form>
  );
}

function MistakeForm({ ownerId, data, onSaved, onClose, setMessage }: FormProps) {
  const [subjectId, setSubjectId] = useState(data.subjects[0]?.id ?? "");
  const [markId, setMarkId] = useState("");
  const [title, setTitle] = useState("");
  const [marksLost, setMarksLost] = useState("");
  const [note, setNote] = useState("");
  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      await upsertMistake({
        id: newId(),
        owner_id: ownerId,
        subject_id: subjectId,
        mark_entry_id: markId || null,
        title,
        marks_lost: marksLost ? Number(marksLost) : null,
        note,
        photo_path: null,
        created_at: nowIso(),
        updated_at: nowIso(),
      });
      await onSaved();
      onClose();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Could not save mistake.");
    }
  }
  return (
    <form className="form-grid" onSubmit={submit}>
      <SelectSubject subjects={data.subjects} value={subjectId} onChange={setSubjectId} />
      <label>
        Linked test
        <select value={markId} onChange={(event) => setMarkId(event.target.value)}>
          <option value="">None</option>
          {data.marks.map((entry) => (
            <option key={entry.id} value={entry.id}>
              {entry.paper_name}
            </option>
          ))}
        </select>
      </label>
      <label>
        Title
        <input value={title} onChange={(event) => setTitle(event.target.value)} required />
      </label>
      <label>
        Marks lost
        <input type="number" step="0.1" value={marksLost} onChange={(event) => setMarksLost(event.target.value)} />
      </label>
      <label>
        Note
        <textarea value={note} onChange={(event) => setNote(event.target.value)} required />
      </label>
      <button className="primary-button" disabled={!data.subjects.length}>
        Save mistake
      </button>
    </form>
  );
}

function BoundaryForm({ ownerId, data, onSaved, onClose, setMessage }: FormProps) {
  const [subjectId, setSubjectId] = useState(data.subjects[0]?.id ?? "");
  const [kind, setKind] = useState<GradeBoundarySet["kind"]>("manualDefault");
  const [title, setTitle] = useState("Default boundaries");
  const [sessionCode, setSessionCode] = useState("");
  const [values, setValues] = useState(["0", "12", "24", "35", "49", "63", "75"]);
  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      await upsertBoundary({
        id: newId(),
        owner_id: ownerId,
        subject_id: subjectId,
        title,
        kind,
        session_code: kind === "sessionImport" ? sessionCode : null,
        source_image_hash: null,
        source_subject_title: null,
        source_ocr_text: null,
        boundary_1: Number(values[0]),
        boundary_2: Number(values[1]),
        boundary_3: Number(values[2]),
        boundary_4: Number(values[3]),
        boundary_5: Number(values[4]),
        boundary_6: Number(values[5]),
        boundary_7: Number(values[6]),
        created_at: nowIso(),
        updated_at: nowIso(),
      });
      await onSaved();
      onClose();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "Could not save boundary.");
    }
  }
  return (
    <form className="form-grid" onSubmit={submit}>
      <SelectSubject subjects={data.subjects} value={subjectId} onChange={setSubjectId} />
      <div className="two-fields">
        <label>
          Kind
          <select value={kind} onChange={(event) => setKind(event.target.value as GradeBoundarySet["kind"])}>
            <option value="manualDefault">Manual default</option>
            <option value="sessionImport">Session import</option>
          </select>
        </label>
        <label>
          Title
          <input value={title} onChange={(event) => setTitle(event.target.value)} required />
        </label>
      </div>
      {kind === "sessionImport" ? (
        <label>
          Session code
          <input value={sessionCode} onChange={(event) => setSessionCode(event.target.value)} placeholder="M25 TZ1" required />
        </label>
      ) : null}
      <div className="grade-grid">
        {values.map((value, index) => (
          <label key={index}>
            G{index + 1}
            <input
              type="number"
              step="0.1"
              value={value}
              onChange={(event) => setValues(values.map((item, itemIndex) => (itemIndex === index ? event.target.value : item)))}
            />
          </label>
        ))}
      </div>
      <button className="primary-button" disabled={!data.subjects.length}>
        Save boundaries
      </button>
    </form>
  );
}

function SelectSubject({ subjects, value, onChange }: { subjects: Subject[]; value: string; onChange: (value: string) => void }) {
  return (
    <label>
      Subject
      <select value={value} onChange={(event) => onChange(event.target.value)} required>
        {subjects.map((subject) => (
          <option key={subject.id} value={subject.id}>
            {subject.name}
          </option>
        ))}
      </select>
    </label>
  );
}

function Sparkline({ marks }: { marks: MarkEntry[] }) {
  const points = useMemo(() => sortByDateDesc(marks).slice(0, 10).reverse(), [marks]);
  if (points.length < 2) {
    return (
      <div className="spark-empty">
        <LineChart />
      </div>
    );
  }
  const path = points
    .map((entry, index) => {
      const x = (index / Math.max(points.length - 1, 1)) * 100;
      const y = 100 - percentage(entry);
      return `${index === 0 ? "M" : "L"} ${x.toFixed(2)} ${Math.max(0, Math.min(100, y)).toFixed(2)}`;
    })
    .join(" ");
  return (
    <svg className="sparkline" viewBox="0 0 100 100" preserveAspectRatio="none" role="img" aria-label="Score trend">
      <path d={path} fill="none" stroke="currentColor" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function Metric({ label, value, icon }: { label: string; value: string; icon: React.ReactNode }) {
  return (
    <div className="metric">
      {icon}
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function EntryList({
  rows,
}: {
  rows: { id: string; title: string; meta: string; value: string; accent: string; onDelete?: () => Promise<void> }[];
}) {
  if (!rows.length) return <div className="empty-state">Nothing here yet.</div>;
  return (
    <div className="entry-list">
      {rows.map((row) => (
        <motion.div className="entry-row" key={row.id} whileHover={{ x: 4 }}>
          <span className="entry-accent" style={{ background: row.accent }} />
          <div>
            <strong>{row.title}</strong>
            <p>{row.meta}</p>
          </div>
          <span className="entry-value">{row.value}</span>
          {row.onDelete ? (
            <button className="icon-button danger" onClick={row.onDelete} aria-label={`Delete ${row.title}`}>
              <Trash2 size={16} />
            </button>
          ) : (
            <ChevronRight size={16} />
          )}
        </motion.div>
      ))}
    </div>
  );
}

function ActionHeader({
  eyebrow,
  title,
  detail,
  action,
  onAction,
}: {
  eyebrow: string;
  title: string;
  detail: string;
  action: string;
  onAction: () => void;
}) {
  return (
    <section className="action-header">
      <div>
        <p className="eyebrow">{eyebrow}</p>
        <h2>{title}</h2>
        <p>{detail}</p>
      </div>
      <button className="primary-button" onClick={onAction}>
        <Plus size={18} />
        {action}
      </button>
    </section>
  );
}

function SectionHeading({ title, detail }: { title: string; detail: string }) {
  return (
    <div className="section-heading">
      <h3>{title}</h3>
      <p>{detail}</p>
    </div>
  );
}

function SubjectFilter({ subjects, value, onChange }: { subjects: Subject[]; value: string; onChange: (value: string) => void }) {
  return (
    <div className="filter-strip">
      <button className={value === "all" ? "active" : ""} onClick={() => onChange("all")}>
        All
      </button>
      {subjects.map((subject) => (
        <button key={subject.id} className={value === subject.id ? "active" : ""} onClick={() => onChange(subject.id)}>
          {subject.name}
        </button>
      ))}
    </div>
  );
}

function NavButton({ active, icon, label, onClick }: { active: boolean; icon: React.ReactNode; label: string; onClick: () => void }) {
  return (
    <button className={active ? "nav-button active" : "nav-button"} onClick={onClick}>
      {icon}
      {label}
    </button>
  );
}

function StatusBanner({ tone, message }: { tone: "neutral" | "success" | "error"; message: string }) {
  return <div className={`status-banner ${tone}`}>{message}</div>;
}

function Modal({ open, title, children, onClose }: { open: boolean; title: string; children: React.ReactNode; onClose: () => void }) {
  return (
    <AnimatePresence>
      {open ? (
        <motion.div className="modal-backdrop" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
          <motion.div className="modal-panel" initial={{ y: 24, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 16, opacity: 0 }}>
            <header>
              <h2>{title}</h2>
              <button className="ghost-button" onClick={onClose}>
                Close
              </button>
            </header>
            {children}
          </motion.div>
        </motion.div>
      ) : null}
    </AnimatePresence>
  );
}

function tabTitle(tab: Tab) {
  switch (tab) {
    case "dashboard":
      return "Dashboard";
    case "tests":
      return "Tests";
    case "mistakes":
      return "Mistakes";
    case "settings":
      return "Settings";
  }
}
