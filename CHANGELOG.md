# Changelog

All notable changes to the ACE Mobile project will be documented in this file.

## [4.2.1+6] - 2026-04-10

### ✨ Features
- **feat:** AI-powered session summaries — auto-generates a 2-3 sentence plain-English summary after every assessment (M-CHAT, Emotion, Eye Contact, Imitation) via OpenRouter LLM
- **feat:** Backfill utility on Doctor Dashboard to generate summaries for all past sessions with a single tap
- **feat:** Home screen status card now displays the latest AI summary with child-specific context

### 🐛 Bug Fixes
- **fix:** AI summaries no longer produce placeholder text like `[child's name]` — child name is resolved from Supabase and injected directly into the prompt
- **fix:** Improved summary fallback states — shows "generating..." while LLM responds, child-name-specific prompt when no sessions exist

---

## [4.2.0+5] - 2026-04-10

### ✨ Features
- **feat:** Dynamic home screen with child-scoped assessment summaries and risk levels
- **feat:** Clinical notes system — doctors can send notes to specific or all parents
- **feat:** Doctor Dashboard redesign with message composer, patient activity feed, and quick stats

### 🐛 Bug Fixes
- **fix:** Data synchronization and UI consistency bugs resolved
- **fix:** Improved error handling across providers

---

## [4.1.0+4] - 2026-04-10

### ✨ Features
- **feat:** Full Supabase migration — removed all Firebase dependencies
- **feat:** Redesigned Doctor Dashboard with live patient data and realtime therapy updates
- **feat:** Formatted session metrics card (replaces raw JSON display)
- **feat:** Interactive progress graph with `fl_chart` (color-coded lines per session type)
- **feat:** Therapy plan system with join codes, prescriptive actions, and inline toggles

### 🐛 Bug Fixes
- **fix:** Multi-session support — removed duplicate guards blocking 2+ sessions per day
- **fix:** State-based save guards to prevent double-writes
- **fix:** Chat FAB visibility hidden on sub-screens
- **fix:** Resource lifecycle hardening — all providers dispose correctly

### 📝 Documentation
- **docs:** Added DATABASE_SCHEMA.md, updated README, created APP_FLOW docs

---

## [3.0.0]- 2026-04-10

### ✨ Features
- **feat:** Added placeholder and formatted MP4 video size for mobile preview
- **feat:** Updated dependencies for AMD compatibility

### 📝 Documentation
- **docs:** Updated Supabase and Progress Dashboard architecture details

---

## [2.0.0] - 2026-04-09

### ✨ Features
- **feat:** Added Progress Dashboard screen to track session history
- **feat:** Connected game sessions to Supabase
- **feat:** Realtime therapy checklist on parent home
- **feat:** Doctor Therapy Plan Screen and Join Code Card
- **feat:** Parent foreign key to Child table and multiple child saving with single parent id

### 🐛 Bug Fixes
- **fix:** Handled duplicate child profiles and ensured session sync
- **fix:** Resolved race conditions in profile save and added missing onConflict constraints
- **fix:** ProGuard keep rules for flutter_dotenv and Supabase to fix release build crashes

### 📝 Documentation
- **docs:** Added SECURITY.md and synced CI/CD infrastructure docs

---

## [1.0.0] - 2026-04-05

### ✨ Features
- **feat:** Initial release of ACE Mobile app
- **feat:** Basic role selection (Parent / Doctor)
- **feat:** Local machine learning assessment modules integration

---

Developed with ❤️ by **Akarsh Solanky**, **Aditya Mishra**, and **Khushneet Singh**.
