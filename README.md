# Relationship Intelligence App

An AI-powered Flutter app that helps users track relationship facts and get personalized suggestions for gifts, dates, and relationship insights.

## Project Structure

```
rel_intel_app/
├── app/              # Flutter frontend application
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
├── backend/          # Firebase Cloud Functions (Python)
│   ├── functions/
│   │   ├── main.py
│   │   ├── ai_service.py
│   │   └── requirements.txt
│   └── firebase.json
└── README.md
```

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Cloud Functions (Python)
- **Database**: Cloud Firestore
- **AI**: LangChain + OpenAI (planned)
- **Authentication**: Firebase Auth

## Development Setup

### Flutter App
```bash
cd app/
flutter pub get
flutter run -d chrome
```

### Backend (Cloud Functions)
```bash
cd backend/
firebase emulators:start
```

## Features (MVP)

- [x] Project setup and structure
- [ ] Onboarding quiz
- [ ] Chat interface for fact input
- [ ] AI-powered suggestions
- [ ] Swipeable insight cards
- [ ] Firebase integration

## Getting Started

1. Install Flutter SDK
2. Install Firebase CLI
3. Run `flutter pub get` in the app directory
4. Configure Firebase project
5. Start development with `flutter run`
