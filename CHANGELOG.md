# Changelog

All notable changes to the ACE Mobile project will be documented in this file.

## [4.0.0+4] - 2026-04-10

# 🚀 ACE Mobile v4.0.0 — The Cloud-Native Edition

Welcome to **Version 4.0** of ACE Mobile! This is our biggest architecture overhaul yet — we've **completely removed Firebase**, migrated everything to **Supabase**, rebuilt the Doctor Dashboard with live data, and introduced polished clinical-grade metric displays.

---

## 🌟 Major Highlights

### ⚡ Full Supabase Migration — Firebase is Gone

We've ripped out every last trace of Firebase (`firebase_core`, `firebase_auth`, `google-services.json`, `firebase_options.dart`) and replaced it with a unified **Supabase Auth + Database** stack.

- **Authentication:** Email/Password and session restoration now powered by `AuthService` backed by Supabase Auth. Login state persists seamlessly across app restarts.
- **Realtime Sync:** Therapy actions, session data, and patient updates stream instantly via Supabase Realtime channels — no polling, no lag.
- **Database Schema:** A clean, relational PostgreSQL schema with 5 core tables: `profiles`, `children`, `sessions`, `therapy_plans`, and `therapy_actions`. Full schema documented in [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md).

### 👨‍⚕️ Redesigned Doctor Dashboard — Real Data, Real Time

The entire Doctor experience has been rebuilt from the ground up with **live Supabase data** replacing all placeholder content.

- **Summary Statistics Cards:** Total patients, high-risk flags this week, sessions completed today, and average assessment scores — all computed live.
- **Patient Roster:** Fetches assigned children via the doctor's UUID, sorted by risk level (high → medium → low → pending).
- **Recent Patients Feed:** Top 3 most recently active patients displayed on the home dashboard for quick access.
- **Realtime Therapy Listener:** A `StreamSubscription` on the `therapy_actions` table ensures the dashboard reflects changes the moment a parent completes a task.

### 📊 Formatted Session Metrics — No More Raw JSON

Previously, expanding a session card on the patient detail screen dumped the `raw_metrics` JSONB field as an unreadable string. Now we have a beautiful, **type-aware `SessionMetricsCard`** widget that renders human-readable metrics:

- **M-CHAT:** Total flags, critical flags, questions answered
- **Copy the Pose:** Poses attempted, poses matched, average match %, best match %
- **Follow the Butterfly:** Tracking duration, contact frames, average gaze score
- **Emotion Check:** Dominant emotion, emotions detected, frames analyzed
- **Fallback:** Any unknown session type auto-formats all key-value pairs cleanly

### 📈 Interactive Progress Graph

The patient detail screen now features a full **`fl_chart` LineChart** with:

- Color-coded trend lines per session type (M-CHAT, Imitation, Eye Contact, Emotion)
- Date-based x-axis labels with smart interval spacing
- Inline legend with average scores
- Tooltip on touch showing exact values
- Graceful "Not enough data" fallback for < 2 sessions

---

## 🧹 Clinical-Grade Cleanup

### 🔒 Resource Lifecycle Hardening

Every provider now has an explicit `dispose()` override to prevent resource leaks:

| Provider | Fix |
|----------|-----|
| `ImitationProvider` | Cancels `_countdownTimer` |
| `EyeContactProvider` | Lifecycle override added |
| `EmotionAssessmentProvider` | Lifecycle override added |
| `DoctorDashboardProvider` | Already correct — cancels `_therapyStreamSub` |

### 🔬 Static Analysis — Zero Warnings

Ran `flutter analyze` and resolved **all 5 warnings**:

- Removed unused pose keypoint fields (`_kLeftHip`, `_kRightHip`)
- Eliminated 3 unnecessary type casts in MoveNet inference pipeline
- Replaced all 10 `print()` calls with `debugPrint()` for production safety
- Cleaned dead code: removed orphaned `formatKeyNicely` parameter chain

### 🛡️ Session Persistence & Navigation Fixes

- **Multi-session support:** Removed duplicate guards that blocked 2+ sessions of the same type per day
- **State-based save guards:** `EmotionAssessmentProvider` and `AssessmentResultsScreen` use `_sessionSaved` flags to prevent double-writes
- **Chat FAB visibility:** Hidden on sub-screens (patient detail, therapy plan) — only visible on Dashboard and Patients tabs
- **Profile hydration:** Background session refresh ensures role switches feel instantaneous

---

## 🏗️ Therapy Plan System

- **Join Code linking:** Parents share a unique `join_code` with their doctor to establish a clinical relationship
- **Prescriptive Actions:** Doctors assign tasks (e.g., "Complete Eye Contact for 30s") with titles, descriptions, and due dates
- **Inline Toggle:** Doctors can mark actions complete/incomplete directly from the patient detail screen
- **Realtime Delivery:** New actions appear on the parent's home screen within 3 seconds

---

## 🔧 Required Setup

To run this version locally, you must provide your own `.env` file in the `frontend_app/ace_mobile/` directory:

```env
GENAI_KEY=sk-or-v1-...
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
```

---

## 📦 Assets

- Attached the production-ready `app-release.apk` for Android.

---

## 👥 How to Install (Android)

1. Download the `app-release.apk` asset attached below.
2. Open the file on your Android device.
3. *Note: You may need to grant permission to "Install from Unknown Sources" in your device settings.*
4. Install, launch, and choose your role (Parent or Doctor) to begin!

---

Developed with ❤️ by **Akarsh Solanky**, **Aditya Mishra**, and **Khushneet Singh**.
