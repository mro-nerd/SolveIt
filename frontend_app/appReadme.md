# ACE Mobile - Developer Documentation

## 🚀 Overview
ACE (Autism Care & Engagement) is a clinical companion app designed to empower families through early screening, therapy integration, and clinical data management. Built with Flutter, it features a premium design system, reactive state management, on-device ML processing, and a cloud-native Supabase backend.

---

## 🛠 Tech Stack
- **Framework:** Flutter (Dart, SDK ^3.11.0)
- **State Management:** `Provider` (ChangeNotifier) — 7 global providers
- **Persistence:** `SharedPreferences` (Local), **Supabase** (Cloud Database + Realtime)
- **Backend/Auth:** Supabase Auth (Email/Password, Google Sign-In), session restoration
- **UI Components:** `PersistentBottomNavBar`, `GoogleFonts`, `flutter_animate`, `fl_chart`
- **On-Device ML:** `tflite_flutter` (MoveNet), `google_mlkit_face_detection`
- **API Provider:** **OpenRouter** (Unified LLM access for AI Chat & M-CHAT Interviewer)

---

## 🔐 Environment Setup

To run the app locally, you must create a `.env` file in the `frontend_app/ace_mobile/` directory:
```env
GENAI_KEY=your_openrouter_key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
```
This ensures no API keys are checked into version control.

---

## 🏗 Core Architecture & Flow Logic

### 1. App Entry (`main.dart`)
- Loads environment variables via `flutter_dotenv`.
- Initializes `SupabaseClientManager` (reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from `.env`).
- Locks device orientation to Portrait.
- Injects 7 global providers: `ProfileProvider`, `ProgressProvider`, `AssessmentProvider`, `MchatAiProvider`, `EyeContactProvider`, `EmotionAssessmentProvider`, `ImitationProvider`.
- Entry point is **`SplashScreen`**.

### 2. Navigation Flow & Auth State (`AuthWrapper.dart`)
We use a reactive **Auth State Machine** approach:
- **Phase 1 (Splash):** Animated intro (~3s) + Background pre-loading of user preferences via `ProfileProvider.loadFromPrefs()`.
- **Phase 2 (Auth Check):** `AuthWrapper` checks `SupabaseClientManager.isLoggedIn` (active Supabase session).
  - **No Session:** Redirects to `loginPage`.
  - **Active Session:** Reads saved `user_role` from SharedPreferences.
- **Phase 3 (Role Routing):** Based on saved role:
  - `'doctor'` → `DoctorBottomNavBar` (Doctor dashboard navigation shell).
  - `'parent'` → `CustomBottomNavBar` (Parent dashboard navigation shell).
  - No saved role → `loginPage` (role selection not yet completed).
- **Phase 4 (Profile Hydration):** `ProfileProvider.initializeFromSupabase()` fetches full profile data from the cloud.
- **Error Handling:** Displays a user-friendly error scaffold with "Go to Login" retry option if profile initialization fails.

---

## ✨ Features & Implementation Details

### 🟢 Animated Splash Screen
- **Path:** `lib/features/splash/splash_screen.dart`
- **Details:** Uses multiple staggered `AnimationControllers` to orchestrate a premium reveal sequence:
  - Background Gradient fade.
  - Logo spring scale + Shimmer ring rotation (`CustomPainter`).
  - Text slide-up.
  - Concurrent `loadFromPrefs()` call during the 2s loading bar animation.

### 🔵 User Onboarding
- **Path:** `lib/features/onboarding/onboarding_screen.dart`
- **Details:** A 5-page walkthrough using `PageView`. 
  - Each page features unique glassmorphism cards and custom icons.
  - Final page sets `onboarding_done: true` in SharedPreferences.
  - Integrated into the auth flow so it survives app restarts but resets on explicit sign-out.

### 🔑 Authentication
- **Path:** `lib/features/auth/`
- **Components:**
  - `loginPage.dart` — Email/Password login UI with Supabase Auth.
  - `role_selection_screen.dart` — First-time role selection (Parent/Caregiver vs. Doctor/Therapist). Handles and displays errors during profile initialization.
  - `auth_wrapper.dart` — Reactive auth state machine routing to the correct dashboard.
  - `signInService.dart` — Google Sign-In integration.

### 🟣 Global Profile State (`ProfileProvider`)
- **Path:** `lib/features/profile/profile_provider.dart`
- **Details:** The central "source of truth" for user data.
  - **Fields:** Parent Name/Email, Child Name/DOB/Gender/Diagnosis, Photo Path, Role.
  - **Persistence:** Every setter (e.g., `updateChildName`) automatically commits the change to `SharedPreferences`.
  - **Cloud Sync:** Uses `ProfileService`, `ChildService`, and `SessionService` to keep the cloud PostgreSQL database in sync with local state.
  - **Reactivity:** Calls `notifyListeners()` to update the UI across the app (Home Screen greeting, Profile Header, etc.) instantly.

### 🧠 AI Assessment Modules
- **Paths:** `lib/features/assessment/`, `lib/features/eye_contact/`, `lib/features/imitation/`, `lib/features/emotion_assessment/`
- **Details:**
  - **M-CHAT AI Interviewer** (`MchatAiProvider`): LLM-driven dynamic questionnaire, not a static form.
  - **Eye Contact** (`EyeContactProvider`): Real-time gaze vector tracking via Google ML Kit with animated butterfly stimuli.
  - **Pose Imitation** (`ImitationProvider`): TensorFlow Lite MoveNet, 17-joint tracking, cosine similarity scoring.
  - **Emotion Assessment** (`EmotionAssessmentProvider`): 46-point facial landmark detection, smile & eye-open probability measurement.
  - All providers have explicit `dispose()` overrides to cancel timers and prevent resource leaks.
  - Session results are persisted to Supabase via `SessionService` with `_sessionSaved` flags to prevent double-writes.

### 👨‍⚕️ Doctor Module
- **Path:** `lib/features/doctor/`
- **Components:**
  - `doctor_dashboard_provider.dart` — Live statistics, patient fetching via doctor UUID, `StreamSubscription` on `therapy_actions` for real-time updates.
  - `clinical_notes_provider.dart` — State management for clinical notes.
  - `doctor_bottom_navbar.dart` — Doctor-specific navigation shell.
  - **Screens** (`screens/`):
    - `doctor_dashboard_screen.dart` — Summary stats (total patients, risk flags, daily sessions, avg scores), recent patients feed.
    - `doctor_patients_screen.dart` — Full patient roster, sorted by risk level (high → medium → low → pending).
    - `patient_detail_screen.dart` — Session history, `fl_chart` interactive progress graphs, `SessionMetricsCard` with type-aware formatting.
    - `doctor_therapy_plan_screen.dart` — Assign actions with titles, descriptions, due dates. Inline toggle completion.
    - `doctor_progress_screen.dart` — Aggregate analytics across all patients.
    - `doctor_profile_screen.dart` — Doctor account settings & profile management.

### 🧘 Therapy & Grounding Tools
- **Path:** `lib/features/Therapy/`
- **Details:**
  - **Breathing Pacer**: Animated 4-2-6 breathing cycle (4s inhale, 2s hold, 6s exhale) with expanding/contracting visual cues and phase-aware colors.
  - **5-4-3-2-1 Sensory Grounding**: Interactive checklist cards.
  - **Live Monitor Dashboard**: Designed for wearable integration (heart rate, skin conductance) and meltdown prediction.

### 💬 AI Chat Assistant
- **Path:** `lib/features/AI_Chat_Assistant/`
- **Details:** Role-aware LLM-powered chat via OpenRouter API.
  - Parent mode: Empathetic pediatric advisor with child-specific context.
  - Doctor mode: Clinical data retrieval assistant.
  - Chat FAB visibility is scoped — hidden on sub-screens (patient detail, therapy plan), visible only on main tabs.

### 📈 Progress Dashboard
- **Path:** `lib/features/progress/`
- **Details:** 
  - Real-time fetching of historical game sessions from the Supabase `sessions` table.
  - Displays aggregated scores and LLM-generated summaries for each completed session.
  - Managed by `ProgressProvider`.

### 👤 Profile & Settings
- **Path:** `lib/features/profile/profile_screen.dart`
- **Details:** 
  - **Hero Header:** Displays user avatar with local file support via `ImagePicker`.
  - **Editable Forms:** Toggles between "View" and "Edit" modes using standard `TextFormFields`.
  - **Stack Clearing:** Uses a "Navigator Capture" pattern to safely clear the navigation stack during sign-out, avoiding unmounted context errors.
  - **Sign Out:** Resets the onboarding flag and clears the Supabase session.

### 🛡 Data & Privacy Center
- **Path:** `lib/features/profile/privacy_screen.dart`
- **Details:** 
  - **HIPAA Compliance:** Styled section with clinical protection badges.
  - **Accordions:** Implemented via `AnimatedCrossFade` for a performant, dependency-free expand/collapse effect.
  - **Sharing Toggles:** Local state toggles for "Research Participation" and "Therapy Partners".
  - **Danger Zone:** Permanent account/data deletion flow with confirmation dialogs and pref-clearing.

---

## 🔧 Service Layer (`lib/backend/services/`)

All cloud operations are abstracted into dedicated, domain-specific services:

| Service | Key Methods |
|---------|-------------|
| `AuthService` | `signUp()`, `signIn()`, `signInWithGoogle()`, `signOut()`, `restoreSession()` |
| `ProfileService` | `upsertProfile()`, `fetchProfile()` |
| `ChildService` | `saveChild()`, `fetchChild()`, `linkDoctorByJoinCode()` |
| `SessionService` | `saveSession()`, `fetchSessions()`, `fetchSessionsByChild()` |
| `TherapyService` | `upsertPlan()`, `fetchPlan()`, `addAction()`, `toggleAction()`, `streamActions()` |
| `ClinicalNotesService` | `sendNote()`, `fetchNotes()`, `fetchNotesForParent()` |

---

## 🧪 Implementation Notes for Developers

### Navigation Contexts
Since the app uses a `PersistentBottomNavBar`, it creates a nested Navigation stack.
- To push a screen that **covers the entire UI** (like Profile or Privacy), always use:
  ```dart
  Navigator.of(context, rootNavigator: true).push(...)
  ```

### Handling Unmounted States
When using `await` with `Navigator`, the widget might unmount during the await (e.g., Supabase signing out). Always capture the navigator state *before* the await:
```dart
final navigator = Navigator.of(context, rootNavigator: true);
await someAsyncAction();
navigator.pushReplacement(...);
```

### Resource Lifecycle
All assessment providers (`ImitationProvider`, `EyeContactProvider`, `EmotionAssessmentProvider`) implement explicit `dispose()` overrides to cancel timers and stream subscriptions. `DoctorDashboardProvider` cancels its `_therapyStreamSub` on dispose.

### Assets Requirements
- Ensure `assets/images/appLogo.png` exists for the splash and login screens.
- Ensure `assets/models/movenet.tflite` exists for pose estimation.
- Ensure `GoogleFonts` is added to `pubspec.yaml` for typography (Poppins, Space Grotesk, DM Mono).
