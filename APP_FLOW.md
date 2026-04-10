# 📱 ACE Mobile - App Flow & Visual Gallery

This document provides a detailed walkthrough of the ACE Mobile user experience, showcasing the logic and design of each screen.

---

## 🚀 1. App Entry & Onboarding

### 🟢 Welcome
- **Logic**: Entry point introducing the ACE application to new and returning users.
- **Visuals**: Features a premium layout and branding to welcome the user.
![Welcome Screen](docs/screenshots/welcome_page.jpeg)

### 🟡 Onboarding Walkthrough
- **Logic**: A multi-page introduction for new users detailing features and value propositions. Sets a persistent flag (`onboarding_done`) upon completion.
- **Visuals**: High-quality informative cards and descriptive imagery.
![Onboarding 1](docs/screenshots/onboarding_screen3.jpeg)
![Onboarding 2](docs/screenshots/onboarding_screen0.jpeg)
![Onboarding 3](docs/screenshots/onboarding_screen1.jpeg)
![Onboarding 4](docs/screenshots/onboarding_screen2.jpeg)
![Onboarding 5](docs/screenshots/onboarding_screen.jpeg)

---

## 🏠 2. The Main Dashboard

### 👨‍👩‍👧 Parent Home Screen
- **Logic**: Dynamic state-driven greeting and daily goal tracker. Fetches child profile data and quick access to tools.
- **Visuals**: Clean card-based layout with quick action buttons for assessments.
![Parent Dashboard 1](docs/screenshots/home_screen1.jpeg)
![Parent Dashboard 2](docs/screenshots/home_screen.jpeg)

### 👨‍⚕️ Doctor Dashboard
- **Logic**: Dashboard for medical professionals to monitor patient progress, review screening results, and manage linked patients.
- **Visuals**: Summary list of registered patients, insightful statistics, and simple navigation.
![Doctor Dashboard 1](docs/screenshots/Doctor_dashboard1.jpeg)
![Doctor Dashboard 2](docs/screenshots/Doctor_dashboard2.jpeg)
![Doctor Dashboard 3](docs/screenshots/doctor_dashboard3.jpeg)

---

## 🔗 3. Patient Management & Linking

### ➕ Adding & Linking Patients
- **Logic**: Allows doctors to link new patients using a join code or by adding child details. Parents can view their child's join code for seamless connect.
- **Visuals**: Form-based screens and informative UI for securely linking accounts.
![Link New Patient](docs/screenshots/link_new_patient_screen.jpeg)
![Child Details](docs/screenshots/child_details_screen.jpeg)
![Patient Join Code](docs/screenshots/patients_porfile_join_code%20.jpeg)
![Child Added](docs/screenshots/chid_added_message%20.jpeg)
![Added Patients Review](docs/screenshots/added_patients%20.jpeg)

---

## 🧠 4. AI Screening & Assessment Games

### 🦋 Eye Contact (Butterfly Exercise)
- **Logic**: Real-time gaze vector tracking using Google ML Kit. Rewards the child when they maintain eye contact with the moving butterfly.
- **Visuals**: Animated butterfly stimuli overlaying a camera feed.
![Eye Contact Game](docs/screenshots/eye_contact.png)

### 🤸 Physical Imitation (Pose Match)
- **Logic**: On-device single-pose estimation using TensorFlow Lite (MoveNet). Calculates cosine similarity between the user's pose and a target pose.
- **Visuals**: Live camera feed with skeleton overlay (17 key joints).
![Pose Imitation](docs/screenshots/pose_imitation.png)

### 😊 Emotion Assessment
- **Logic**: Facial landmark detection (46 points) to analyze smile and eye-open probabilities during evoked stimuli.
- **Visuals**: Emotional stimuli reaction capture.
![Emotion Assessment](docs/screenshots/emotion_assessment.png)

### 📋 Standard Assessments (M-CHAT)
- **Logic**: Guided questionnaires for early detection and developmental tracking.
- **Visuals**: Easy-to-read questions, descriptive choices, and progress indicators.
![Assessment Overview](docs/screenshots/assessment%20.jpeg)
![M-CHAT Assessment](docs/screenshots/M-chat%20assesmeent%20.jpeg)

---

## 🧘‍♀️ 5. Therapy & Grounding Tools

### 🫂 Therapy Screen & ACE Assistance
- **Logic**: AI-driven and structured therapy modules for continued progress. Direct access to ACE AI Assistant for guidance.
- **Visuals**: Interactive cards and conversational AI interfaces.
![Therapy Screen](docs/screenshots/Therapy-screen.jpeg)
![ACE Assistance](docs/screenshots/ace_assistance.jpeg)

### 🫁 Breathing Pacer
- **Logic**: Animated 4-2-6 breathing cycle (Inhale, Hold, Exhale) designed to lower anxiety.
- **Visuals**: Rhythmic pulsing circle with phase-aware textual cues.
![Breathing Pacer](docs/screenshots/breathing_pacer.png)

### 🖐 5-4-3-2-1 Grounding
- **Logic**: Interactive sensory checklist to bring a user back to the present moment during high stress.
- **Visuals**: Icon-rich step-by-step guidance.
![Grounding Exercise](docs/screenshots/grounding_54321.png)

---

## 📊 6. Progress & Community

### 📈 Progress Tracking
- **Logic**: Visualizes completed assessments, therapy sessions, and milestones to show developmental trends over time.
- **Visuals**: Intuitive layout highlighting achievements.
![Progress Screen](docs/screenshots/progress_screen.jpeg)

### 🤝 Community
- **Logic**: Connects parents and caregivers with community support, allowing them to share experiences and find resources.
- **Visuals**: Discussion threads, articles, and community highlights.
![Community Screen](docs/screenshots/community.jpeg)

---

## 👤 7. Profile & Settings

### ⚙️ User Profiles (Doctor/Parent)
- **Logic**: Allows editing of account information, viewing associated settings, and managing app preferences.
- **Visuals**: Clean layouts presenting relevant user data clearly.
![Doctor Profile](docs/screenshots/profile_doctor.jpeg)