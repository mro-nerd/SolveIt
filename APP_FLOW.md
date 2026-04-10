# 📱 ACE Mobile - App Flow & Visual Gallery

This document provides a detailed walkthrough of the ACE Mobile user experience, showcasing the logic and design of each screen.

---

## 🚀 1. App Entry & Onboarding

### 🟢 Welcome
- **Logic**: Entry point introducing the ACE application to new and returning users.
- **Visuals**: Features a premium layout and branding to welcome the user.

<div align="center">
  <img src="docs/screenshots/welcome_page.jpeg" width="280" alt="Welcome Screen"/>
</div>

### 🟡 Onboarding Walkthrough
- **Logic**: A multi-page introduction for new users detailing features and value propositions. Sets a persistent flag (`onboarding_done`) upon completion.
- **Visuals**: High-quality informative cards and descriptive imagery.

<div align="center">
  <img src="docs/screenshots/onboarding_screen3.jpeg" width="200" alt="Onboarding 1"/>
  <img src="docs/screenshots/onboarding_screen0.jpeg" width="200" alt="Onboarding 2"/>
  <img src="docs/screenshots/onboarding_screen1.jpeg" width="200" alt="Onboarding 3"/>
  <img src="docs/screenshots/onboarding_screen2.jpeg" width="200" alt="Onboarding 4"/>
  <img src="docs/screenshots/onboarding_screen.jpeg" width="200" alt="Onboarding 5"/>
</div>

---

## 🏠 2. The Main Dashboard

### 👨‍👩‍👧 Parent Home Screen
- **Logic**: Dynamic state-driven greeting and daily goal tracker. Fetches child profile data and quick access to tools.
- **Visuals**: Clean card-based layout with quick action buttons for assessments.

<div align="center">
  <img src="docs/screenshots/home_screen1.jpeg" width="280" alt="Parent Dashboard 1"/>
  <img src="docs/screenshots/home_screen.jpeg" width="280" alt="Parent Dashboard 2"/>
</div>

### 👨‍⚕️ Doctor Dashboard
- **Logic**: Dashboard for medical professionals to monitor patient progress, review screening results, and manage linked patients.
- **Visuals**: Summary list of registered patients, insightful statistics, and simple navigation.

<div align="center">
  <img src="docs/screenshots/Doctor_dashboard1.jpeg" width="280" alt="Doctor Dashboard 1"/>
  <img src="docs/screenshots/Doctor_dashboard2.jpeg" width="280" alt="Doctor Dashboard 2"/>
  <img src="docs/screenshots/doctor_dashboard3.jpeg" width="280" alt="Doctor Dashboard 3"/>
</div>

---

## 🔗 3. Patient Management & Linking

### ➕ Adding & Linking Patients
- **Logic**: Allows doctors to link new patients using a join code or by adding child details. Parents can view their child's join code for seamless connect.
- **Visuals**: Form-based screens and informative UI for securely linking accounts.

<div align="center">
  <img src="docs/screenshots/link_new_patient_screen.jpeg" width="200" alt="Link New Patient"/>
  <img src="docs/screenshots/child_details_screen.jpeg" width="200" alt="Child Details"/>
  <img src="docs/screenshots/patients_porfile_join_code .jpeg" width="200" alt="Patient Join Code"/>
  <img src="docs/screenshots/chid_added_message .jpeg" width="200" alt="Child Added"/>
  <img src="docs/screenshots/added_patients .jpeg" width="200" alt="Added Patients Review"/>
</div>

---

## 🧠 4. AI Screening & Assessment Games

### 🦋 Eye Contact (Butterfly Exercise)
- **Logic**: Real-time gaze vector tracking using Google ML Kit. Rewards the child when they maintain eye contact with the moving butterfly.
- **Visuals**: Animated butterfly stimuli overlaying a camera feed.

<div align="center">
  <img src="docs/screenshots/eye_contact.png" width="280" alt="Eye Contact Game"/>
</div>

### 🤸 Physical Imitation (Pose Match)
- **Logic**: On-device single-pose estimation using TensorFlow Lite (MoveNet). Calculates cosine similarity between the user's pose and a target pose.
- **Visuals**: Live camera feed with skeleton overlay (17 key joints).

<div align="center">
  <img src="docs/screenshots/pose_imitation.png" width="280" alt="Pose Imitation"/>
</div>

### 😊 Emotion Assessment
- **Logic**: Facial landmark detection (46 points) to analyze smile and eye-open probabilities during evoked stimuli.
- **Visuals**: Emotional stimuli reaction capture.

<div align="center">
  <img src="docs/screenshots/emotion_assessment.png" width="280" alt="Emotion Assessment"/>
</div>

### 📋 Standard Assessments (M-CHAT)
- **Logic**: Guided questionnaires for early detection and developmental tracking.
- **Visuals**: Easy-to-read questions, descriptive choices, and progress indicators.

<div align="center">
  <img src="docs/screenshots/assessment .jpeg" width="280" alt="Assessment Overview"/>
  <img src="docs/screenshots/M-chat assesmeent .jpeg" width="280" alt="M-CHAT Assessment"/>
</div>

---

## 🧘‍♀️ 5. Therapy & Grounding Tools

### 🫂 Therapy Screen & ACE Assistance
- **Logic**: AI-driven and structured therapy modules for continued progress. Direct access to ACE AI Assistant for guidance.
- **Visuals**: Interactive cards and conversational AI interfaces.

<div align="center">
  <img src="docs/screenshots/Therapy-screen.jpeg" width="280" alt="Therapy Screen"/>
  <img src="docs/screenshots/ace_assistance.jpeg" width="280" alt="ACE Assistance"/>
</div>

### 🫁 Breathing Pacer
- **Logic**: Animated 4-2-6 breathing cycle (Inhale, Hold, Exhale) designed to lower anxiety.
- **Visuals**: Rhythmic pulsing circle with phase-aware textual cues.

<div align="center">
  <img src="docs/screenshots/breathing_pacer.png" width="280" alt="Breathing Pacer"/>
</div>

### 🖐 5-4-3-2-1 Grounding
- **Logic**: Interactive sensory checklist to bring a user back to the present moment during high stress.
- **Visuals**: Icon-rich step-by-step guidance.

<div align="center">
  <img src="docs/screenshots/grounding_54321.png" width="280" alt="Grounding Exercise"/>
</div>

---

## 📊 6. Progress & Community

### 📈 Progress Tracking
- **Logic**: Visualizes completed assessments, therapy sessions, and milestones to show developmental trends over time.
- **Visuals**: Intuitive layout highlighting achievements.

<div align="center">
  <img src="docs/screenshots/progress_screen.jpeg" width="280" alt="Progress Screen"/>
</div>

### 🤝 Community
- **Logic**: Connects parents and caregivers with community support, allowing them to share experiences and find resources.
- **Visuals**: Discussion threads, articles, and community highlights.

<div align="center">
  <img src="docs/screenshots/community.jpeg" width="280" alt="Community Screen"/>
</div>

---

## 👤 7. Profile & Settings

### ⚙️ User Profiles (Doctor/Parent)
- **Logic**: Allows editing of account information, viewing associated settings, and managing app preferences.
- **Visuals**: Clean layouts presenting relevant user data clearly.

<div align="center">
  <img src="docs/screenshots/profile_doctor.jpeg" width="280" alt="Doctor Profile"/>
</div>