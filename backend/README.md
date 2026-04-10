# ⚙️ ACE Backend (Supabase Integration)

This directory houses the cloud database schema, migration scripts, and documentation for the ACE ecosystem's server-side infrastructure. The application relies on **Supabase** (hosted PostgreSQL) for data storage, authentication, and real-time synchronization.

## 🏗️ Architecture

The backend integration is structured as a dedicated **service layer** within the Flutter application (`lib/backend/`), providing a clean abstraction between UI features and cloud operations.

### Client & Core

*   **`supabase_client.dart`**: A singleton `SupabaseClientManager` responsible for establishing the connection to Supabase during `main()` initialization. Credentials are loaded from the `.env` file — no hardcoded secrets.
*   **`supabase_service.dart`**: Legacy business logic layer containing foundational functions (`upsertProfile`, `saveChild`, `saveSession`).
*   **`backend.dart`**: A barrel export file. UI files can simply `import 'package:ace_mobile/backend/backend.dart';` to access the entire data layer.

### Service Layer (`services/`)

Six dedicated data services, each owning a specific domain:

| Service | Responsibility |
|---------|---------------|
| `auth_service.dart` | Supabase Auth — Email/Password signup/login, Google Sign-In, session management, sign-out |
| `profile_service.dart` | User profile CRUD — display name, email, role |
| `child_service.dart` | Child records — creation, retrieval, join code management, doctor linking |
| `session_service.dart` | Assessment session persistence — save, fetch, metrics (JSONB), AI summaries |
| `therapy_service.dart` | Therapy plans & action items — creation, upsert, realtime subscriptions, completion toggles |
| `clinical_notes_service.dart` | Doctor-to-parent clinical messaging — broadcast and targeted notes |

## 🗄️ Database Schema (Supabase PostgreSQL)

The ACE backend interacts with **6 relational tables**. The full ER diagram and column-level details are documented in [`docs/DATABASE_SCHEMA.md`](../docs/DATABASE_SCHEMA.md).

| Table | Purpose |
|-------|---------|
| `profiles` | All authenticated users (parents & doctors). Linked to Supabase Auth UID. Contains `role` field (`parent` / `doctor`). |
| `children` | Patient/child records. Linked to a `parent_id` and optionally an `assigned_doctor_id`. Has an auto-generated `join_code` for secure doctor linking. |
| `sessions` | Assessment results log. Stores `session_type`, `score`, `raw_metrics` (JSONB), `ai_summary`, and `risk_flag` for each completed assessment. |
| `therapy_plans` | Doctor-prescribed therapy plans per child. Defines `therapy_level` and clinical `notes`. Unique constraint on `child_id`. |
| `therapy_actions` | Individual tasks within a therapy plan. Tracked via `is_completed` and synced to the parent's home screen in real-time. |
| `clinical_notes` | Doctor-to-parent messaging. Supports `target_type` of `'all'` (broadcast) or `'specific'` (single parent). |

## 📂 Migration Scripts

This directory contains SQL migration scripts to be run in the Supabase SQL editor:

*   **`add_join_code_trigger.sql`**: Creates a PostgreSQL trigger function that auto-generates a unique 6-character alphanumeric `join_code` for every new child record. Also retroactively assigns codes to existing records.
*   **`add_therapy_plan_unique_constraint.sql`**: Adds a `UNIQUE(child_id)` constraint on the `therapy_plans` table to enforce one active plan per child and enable `ON CONFLICT` upserts.

## 🔒 Security & Environment Variables

**Do not hardcode keys.** The backend requires a `.env` file in the `frontend_app/ace_mobile/` directory to function.

```env
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<your-anon-role-key>
GENAI_KEY=<your-openrouter-api-key>
```

### Row-Level Security (RLS)

All Supabase tables have **Row-Level Security** enabled. Each user can only read/write their own data based on their authenticated UID. Service-role access is scoped strictly to backend orchestration operations.