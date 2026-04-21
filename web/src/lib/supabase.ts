import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "https://dgtqkcnfnxwaiauobuft.supabase.co";
const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRndHFrY25mbnh3YWlhdW9idWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NDIzMTIsImV4cCI6MjA5MDAxODMxMn0.My8Mqc5dPdkiCONo9_kSOzAKOC327EgpDhhFfuFXDD0";

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error("Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY");
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storageKey: "past-paper-tracker-web-session",
  },
});
