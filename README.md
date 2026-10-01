# 🚀 PlanIt - Modern Task & Notes Management App

**PlanIt** is a clean, modular, and cross-platform productivity application built with **Flutter** and **Firebase**. 

Originally built as a basic To-Do app, the codebase has been **completely refactored, modernized, and upgraded using AI-driven architecture patterns** to deliver an enterprise-grade modular structure, mandatory security flows, and seamless real-time database integration.

---

## ✨ What's New in the Modern Version

### 🤖 AI-Powered Architecture & Code Refactoring
* **Complete Codebase Audit:** Identified and purged legacy code, redundant screens, orphaned widgets, and unused assets.
* **Modular Architecture:** Clean separation of concerns into distinct directories:
  * `lib/models/` — Data models for Tasks and Notes.
  * `lib/services/` — Clean handlers for Firebase Auth and Firestore CRUD.
  * `lib/screens/` — Isolated UI views (Auth, Dashboard, Verification, Tabs).
  * `lib/widgets/` — Reusable, atomic UI components.
* **Strict Type Safety & Path Imports:** Streamlined import statements and fixed dependency paths across the entire project graph.

---

## 🔑 Key Features

### 🔒 Enhanced Authentication & Security
* **Mandatory Email Verification:** Enforces email verification upon user sign-up using `user.sendEmailVerification()`.
* **Smart Verification Screen:** 
  * Displays user email with spam folder instructions.
  * 30-second resend cooldown timer.
  * Polling mechanism (`Timer.periodic`) and manual status reload (`user.reload()`).
* **Protected Routing (`AuthWrapper`):** Automatically routes unverified users to the verification screen and verified users directly to the Dashboard.

### 📝 Cloud Synchronization & CRUD Operations
* **Firebase Cloud Firestore:** Isolated per-user data collections (`users/{userId}/tasks` and `users/{userId}/notes`).
* **Hybrid Dashboard:** Tabbed navigation separating real-time Task tracking from Notes management.
* **Modernized Configuration:** Fully configured with the latest `firebase_options.dart` targeting the `planit-d7d7b` Firebase project.

---

## 🛠️ Tech Stack & Dependencies

* **Framework:** [Flutter](https://flutter.dev/) (Dart 3+)
* **Backend:** [Firebase Authentication](https://firebase.google.com/docs/auth), [Cloud Firestore](https://firebase.google.com/docs/firestore)
* **Configuration:** FlutterFire CLI & Firebase CLI
* **Platforms Supported:** Android, Windows, Web

---

## 📂 Project Structure

```text
lib/
├── firebase_options.dart               # Auto-generated Firebase configuration (planit-d7d7b)
├── main.dart                           # Application entry point & AuthWrapper routing
├── models/
│   ├── note_model.dart                 # Data model for notes
│   └── task_model.dart                 # Data model for tasks
├── screens/
│   ├── auth/
│   │   ├── email_verification_screen.dart # Verification handling & resend screen
│   │   ├── sign_in_screen.dart          # Sign in workflow
│   │   └── sign_up_screen.dart          # Sign up workflow
│   ├── dashboard/
│   │   ├── dashboard_screen.dart        # Main dashboard wrapper
│   │   ├── notes_tab.dart              # Firestore notes tab
│   │   └── tasks_tab.dart              # Firestore tasks tab
│   └── splash_screen.dart               # Initial splash/auth loader
├── services/
│   ├── auth_service.dart               # Authentication service handler
│   └── firestore_service.dart          # Real-time Firestore CRUD service
└── widgets/
    ├── custom_text_field.dart          # Reusable input fields
    ├── note_card.dart                  # Custom card UI for notes
    └── task_tile.dart                  # Custom list tile UI for tasks
