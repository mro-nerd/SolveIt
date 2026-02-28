# ACE Mobile - Developer Documentation

## 🚀 Overview
ACE (Autism Care & Engagement) is a clinical companion app designed to empower families through early screening, therapy integration, and clinical data management. Built with Flutter, it features a premium design system, reactive state management, and robust on-device ML processing.

---

## 🛠 Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** `Provider` (ChangeNotifier)
- **Persistence:** `SharedPreferences`
- **Backend/Auth:** Firebase (Core, Auth), Google Sign-In
- **UI Components:** `PersistentBottomNavBar`, `GoogleFonts`, `flutter_animate`
- **On-Device ML:** `tflite_flutter` (MoveNet), `google_mlkit_face_detection`
- **API Provider:** **OpenRouter** (Unified LLM access)

---

## 🏗 Core Architecture & Flow logic

### 1. App Entry (`main.dart`)
- Initializes Firebase and Environment variables.
- Locks device orientation to Portrait.
- Injects global providers (`ProfileProvider`, `AssessmentProvider`, `MchatAiProvider`).
- Entry point is **`SplashScreen`**.

### 2. Navigation Flow & Auth State (`AuthWrapper.dart`)
We use a reactive **Auth State Machine** approach:
- **Phase 1 (Splash):** Animated intro (~3s) + Background pre-loading of user preferences.
- **Phase 2 (Auth Check):** `AuthWrapper` listens to `FirebaseAuth.authStateChanges()`.
  - **Null User:** Redirects to `loginPage`.
  - **Authenticated User:** Checks `shared_preferences` for the `onboarding_done` flag.
- **Phase 3 (Onboarding):** If `onboarding_done` is false, shows `OnboardingScreen`.
- **Phase 4 (Main App):** Once onboarding is complete or if already seen, loads `CustomBottomNavBar`.

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
  - Integrated into the `AuthWrapper` so it survives app restarts but resets on explicit sign-out.

### 🟣 Global Profile State (`ProfileProvider`)
- **Path:** `lib/features/profile/profile_provider.dart`
- **Details:** The central "source of truth" for user data.
  - **Fields:** Parent Name/Email, Child Name/DOB/Gender/Diagnosis, Photo Path.
  - **Persistence:** Every setter (e.g., `updateChildName`) automatically commits the change to `SharedPreferences`.
  - **Reactivity:** Calls `notifyListeners()` to update the UI across the app (Home Screen greeting, Profile Header, etc.) instantly.

### 👤 Profile & Settings
- **Path:** `lib/features/profile/profile_screen.dart`
- **Details:** 
  - **Hero Header:** Displays user avatar with local file support via `ImagePicker`.
  - **Editable Forms:** Toggles between "View" and "Edit" modes using standard `TextFormFields`.
  - **Stack Clearing:** Uses a "Navigator Capture" pattern to safely clear the navigation stack during sign-out, avoiding unmounted context errors.
  - **Sign Out:** Resets the onboarding flag and clears both Firebase and Google Sign-In sessions.

### 🛡 Data & Privacy Center
- **Path:** `lib/features/profile/privacy_screen.dart`
- **Details:** 
  - **HIPAA Compliance:** Styled section with clinical protection badges.
  - **Accordions:** Implemented via `AnimatedCrossFade` for a performant, dependency-free expand/collapse effect.
  - **Sharing Toggles:** Local state toggles for "Research Participation" and "Therapy Partners".
  - **Danger Zone:** Permanent account/data deletion flow with confirmation dialogs and pref-clearing.

---

## 🧪 Implementation Notes for Developers

### Navigation Contexts
Since the app uses a `PersistentBottomNavBar`, it creates a nested Navigation stack.
- To push a screen that **covers the entire UI** (like Profile or Privacy), always use:
  ```dart
  Navigator.of(context, rootNavigator: true).push(...)
  ```

### Handling Unmounted States
When using `await` with `Navigator`, the widget might unmount during the await (e.g., Firebase signing out). Always capture the navigator state *before* the await:
```dart
final navigator = Navigator.of(context, rootNavigator: true);
await someAsyncAction();
navigator.pushReplacement(...);
```

### Assets Requirements
- Ensure `assets/images/poster.png` exists for the login screen.
- Ensure `GoogleFonts` is added to `pubspec.yaml` for typography.
