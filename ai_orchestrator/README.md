# 🤖 ACE AI Orchestrator

This directory is dedicated to the AI and machine learning components that power the ACE ecosystem's intelligent features.

## 🧠 Current Implementation

ACE currently leverages AI through two primary channels integrated directly into the Flutter mobile application:

### On-Device ML (Edge Computing)
All behavioral assessment ML models run **entirely on-device** — no data is sent to external servers for inference.

| Model | Technology | Purpose |
|-------|-----------|---------|
| **MoveNet Lightning** | TensorFlow Lite (`tflite_flutter`) | Single-pose estimation tracking 17 body joints at 30+ FPS for the Physical Imitation assessment |
| **Face Detection** | Google ML Kit (`google_mlkit_face_detection`) | 46-point facial landmark tracking, gaze vector analysis, smile probability, and eye-open probability for Eye Contact and Emotion assessments |

### Cloud-Based LLM (OpenRouter)
*   **ACE AI Chat Assistant**: A role-aware conversational agent powered via the OpenRouter API. Automatically adapts its persona based on the user's role:
    *   *Parent mode*: Empathetic pediatric advisor using the child's name, age, and recent assessment data.
    *   *Doctor mode*: Clinical data retrieval assistant providing patient metric summaries.
*   **M-CHAT AI Interviewer**: Dynamically administers the Modified Checklist for Autism in Toddlers. Instead of a static form, an LLM interviewer adapts questions and scores responses in real-time.

## 🗺️ Future Roadmap
- **Agent Orchestrator**: Multi-agent system for coordinating specialized screening, therapy, and support tasks.
- **Model Fine-Tuning**: Scripts for refining pose and emotion detection models on autism-specific behavioral datasets.
- **RAG Services**: Retrieval-Augmented Generation for grounding clinical support responses in published literature.
- **Wearable Integration**: Processing physiological data (heart rate, skin conductance) from wearable devices for meltdown prediction.