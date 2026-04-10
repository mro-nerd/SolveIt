# 📥 Setup & Installation Guide

Follow these steps to get the ACE Mobile project running locally.

## 📋 Prerequisites

- **Flutter SDK** — Version 3.11.0 or higher
- **Dart SDK** — Bundled with Flutter
- **Android Studio** or **VS Code** with Flutter/Dart extensions
- A physical Android device or emulator (API 21+)
- A **Supabase** project ([supabase.com](https://supabase.com))
- An **OpenRouter** API key ([openrouter.ai](https://openrouter.ai))

---

## 📱 Mobile - Flutter App

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/mro-nerd/SolveIt.git
    cd SolveIt/frontend_app/ace_mobile
    ```

2.  **Install Dependencies:**
    ```bash
    flutter clean
    flutter pub get
    ```

3.  **Environment Variables (`.env`):**
    Create a `.env` file in `frontend_app/ace_mobile/` and add your required keys:
    ```env
    GENAI_KEY=your_openrouter_api_key
    SUPABASE_URL=https://your-project.supabase.co
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```
    > ⚠️ The app will throw an initialization error if these keys are missing.

4.  **Database Setup (Supabase):**
    - Create the required tables in your Supabase project. Refer to [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) for the full schema.
    - Run the migration scripts from the `backend/` directory in your Supabase SQL editor:
      - `add_join_code_trigger.sql` — Enables auto-generated join codes for child records.
      - `add_therapy_plan_unique_constraint.sql` — Adds unique constraint for therapy plan upserts.
    - Enable **Row-Level Security (RLS)** on all tables.

5.  **Build & Run:**
    ```bash
    # Run on connected device
    flutter run

    # Build optimized Release APK
    flutter build apk --release --split-per-abi
    ```

---

## 👥 How to Install (Pre-built APK)

1. Download the `app-release.apk` from the latest GitHub release.
2. Open the file on your Android device.
3. *Note: You may need to grant permission to "Install from Unknown Sources" in your device settings.*
4. Install, launch, and choose your role (Parent or Doctor) to begin!

---
<p align="center"><i>ACE (Autism Care Ecosystem) - Setup Guide</i></p>
