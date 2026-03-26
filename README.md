# Medisense 🏥

Medisense is a modern, AI-powered health assistant application built with Flutter. It helps users manage their medications, track appointments, and find nearby healthcare facilities with real-time insights.

## ✨ Key Features

### 🤖 AI Health Assistant
- **Gemini-Powered Chatbot**: Get answers to health queries and symptom analysis using Google's Gemini 2.5 Flash.
- **AI Medication Scanner**: Scan medicine labels using your camera to automatically extract medication names, dosages, and instructions.
- **Voice Support**: Integrated speech-to-text for hands-free interaction with the AI assistant.

### 💊 Medication Tracker
- **Smart Reminders**: Set up schedules for your medications and receive local notifications when it's time to take them.
- **Daily Intake Log**: Track your daily progress and mark doses as taken.
- **History Tracking**: Keep a record of your past and current prescriptions.

### 🏥 Hospital Finder & Map
- **Nearby Facilities**: Locate hospitals and clinics on an interactive Google Map.
- **Busyness Score**: A unique algorithm that estimates how busy a facility is based on the day, peak hours, facility type, and user ratings.
- **Navigation**: One-tap navigation to any selected healthcare provider.

### 🗓️ Health Management
- **Appointment Booking**: Manage your medical appointments with date and time pickers.
- **Secure Profile**: Firebase-backed authentication with optional Biometric (Fingerprint/FaceID) login.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend**: [Firebase](https://firebase.google.com) (Auth, Firestore)
- **AI**: [Google Generative AI](https://ai.google.dev) (Gemini API)
- **Maps**: [Google Maps SDK for Flutter](https://pub.dev/packages/google_maps_flutter)
- **State Management**: Provider / RxDart
- **Local Storage**: SharedPreferences

## ⚙️ How It Works

### Smart Busyness Algorithm
The app calculates the "Busyness" of a hospital by scoring several factors:
- **Peak Hours**: 8 AM - 11 AM (+4) and 6 PM - 9 PM (+3).
- **Day Factor**: Mondays (+2) and Weekends (+1).
- **Facility Type**: Hospitals are weighted higher (+3) than clinics.
- **Rating Proxy**: High user ratings act as a proxy for popularity/volume.

### AI Label Scanning
Using the camera, the app captures medication labels and sends them to Gemini. The AI identifies key entities and returns structured data (Name, Dosage, Instructions) which is then used to pre-fill the medication entry form.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- A Google Maps API Key
- A Gemini AI API Key
- A Firebase Project

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/medisense.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure API Keys:
   - Start the app with `--dart-define` values instead of hardcoding keys in source files.
   - Use the same Google Maps key for both the Places API calls and the Android map manifest injection.
4. Run the app:
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_gemini_key --dart-define=GOOGLE_MAPS_API_KEY=your_google_maps_key
   ```

## 📄 License
This project is for educational purposes.
