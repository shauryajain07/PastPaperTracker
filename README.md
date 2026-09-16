# Past Paper Tracker

Past Paper Tracker is a native SwiftUI iPhone app for turning past-paper practice into feedback. It records marks, keeps a history of mistakes, attaches the question photos that explain those mistakes, and syncs the workspace when the user wants it available across devices.

## Why it exists

Revision data is only useful when it changes what you do next. Past Paper Tracker keeps attempts, marks, mistakes, subjects, and grade-boundary context close together so a student can see both performance and the gaps behind it.

## Core workflow

1. Add a subject and log a past-paper attempt.
2. Record the marks earned and the questions that went wrong.
3. Attach photos and notes to each mistake.
4. Review dashboard summaries, subject trends, and grade-boundary context.
5. Use revision reminders and widgets to make the history visible outside the app.

## Highlights

- SwiftUI interface for iPhone.
- Local persistence for marks, subjects, and mistakes.
- Optional Supabase authentication and sync.
- Photo attachments for mistake entries.
- Grade-boundary sets and subject catalogues.
- Dashboard analytics and study-summary widgets.
- Offline-friendly behavior when the Supabase configuration is not present.
- Unit and UI test targets included in the project.

## Stack

- SwiftUI and Swift 6
- iOS 17+
- Supabase Swift SDK
- XcodeGen for project generation
- Supabase Postgres and Storage when sync is enabled

## Local setup

1. Install XcodeGen and open a terminal at the repository root.
2. Create a local Supabase configuration from the example:

   ```bash
   cp PastPaperTracker/Resources/SupabaseConfig.plist.example \
     PastPaperTracker/Resources/SupabaseConfig.plist
   ```

3. Fill in the local Supabase URL, anon key, and storage bucket.
4. Generate the Xcode project:

   ```bash
   xcodegen generate
   ```

5. Open `PastPaperTracker.xcodeproj` in Xcode and run the `PastPaperTracker` scheme.

The app can still be explored in an offline-only mode when the configuration file is missing. Never commit the real `SupabaseConfig.plist`.
