# ⚙️ ACE Backend (Supabase Integration)

This directory houses the unified cloud database logic, API wrappers, and server-side connection management for the ACE ecosystem. We rely primarily on **Supabase** for PostgreSQL data storage and Real-Time capabilities.

## 🏗️ Architecture

The backend integration is structured to provide a single source of truth for database operations across the app:

*   **`supabase_client.dart`**: A singleton manager responsible for establishing the connection to Supabase during `main()` initialization. It automatically pulls credentials from the `.env` file to ensure hardcoded secrets are never pushed to GitHub.
*   **`supabase_service.dart`**: The core business logic layer. All UI features (like Profile editing or completing an Assessment) call this service. It contains isolated functions to query and mutate data (e.g., `upsertProfile`, `saveChild`, `saveSession`).
*   **`backend.dart`**: A barrel export file. UI files can simply `import 'package:ace_mobile/backend/backend.dart';` to get access to the entire data layer.

## 🗄️ Database Tables (Supabase)

The ACE backend currently interacts with the following PostgreSQL tables:

1.  **`profiles`**: Stores the parent/guardian's information (`parent_name`, `email`, tied to `firebase_uid`).
2.  **`children`**: Stores the child's context (`child_name`, `date_of_birth`, `gender`). Uses a `UNIQUE(parent_id)` constraint to guarantee a 1:1 relationship between a Parent app profile and the Child receiving therapy.
3.  **`sessions`**: The progress ledger. Every time a child completes an assessment (Eye Contact, Imitation), a row is inserted here containing the `score`, the raw ML `metrics` (as JSONB), and an `ai_summary`.

## 🔒 Security & Environment Variables

**Do not hardcode keys.** The backend requires a `.env` file in the `ace_mobile` root directory to function.

```env
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<your-anon-role-key>
```