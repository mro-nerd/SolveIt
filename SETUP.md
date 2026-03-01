# 📥 Setup & Installation Guide

Follow these steps to get the ACE Mobile project running locally.

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
    # API Keys & Endpoints
    GEMINI_API_KEY=your_key_here
    OPENROUTER_API_KEY=your_key_here
    ```

4.  **Firebase Configuration:**
    - Place `google-services.json` in `android/app/`.
    - Place `GoogleService-Info.plist` in `ios/Runner/`.

5.  **Build & Run:**
    ```bash
    # Run on connected device
    flutter run

    # Build optimized Release APK
    flutter build apk --release --split-per-abi
    ```

---
<p align="center"><i>ACE (Autism Care Ecosystem) - Setup Guide</i></p>
