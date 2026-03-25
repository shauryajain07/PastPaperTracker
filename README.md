# Past Paper Tracker

A native SwiftUI iPhone app for logging past paper marks, tracking mistakes, attaching question photos, and syncing through Supabase.

## Local Setup

1. Copy [SupabaseConfig.plist.example](/Users/shauryajain/work/PastPaperTracker/Resources/SupabaseConfig.plist.example) to `PastPaperTracker/Resources/SupabaseConfig.plist`.
2. Fill in your Supabase project URL, anon key, and storage bucket.
3. Run the SQL in [schema.sql](/Users/shauryajain/work/supabase/schema.sql) inside the Supabase SQL editor.
4. Generate the Xcode project:

```bash
xcodegen generate
```

5. Open `PastPaperTracker.xcodeproj` in Xcode and run the `PastPaperTracker` scheme.

If `SupabaseConfig.plist` is missing, the app still supports an offline-only mode for local testing.
