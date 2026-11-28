# ZeroHunger

**Share Food, End Hunger**

University of Calgary — Schulich School of Engineering  
ENSF 607/608 — Group 1

## 1. Project Overview

ZeroHunger is a mobile application designed to reduce food waste and fight hunger by connecting food donors, recipients and community organizations.

The project supports the United Nations Sustainable Development Goal 2 (SDG 2): Zero Hunger.

### Key Features

- User registration and login.
- Post and browse food donations.
- Reserve available food.
- Manage donations and reservations.
- Communicate through pickup chats.
- View community organizations and events.
- Receive notifications and track user activity.
- Manage account information and settings.

## 2. Team Members — Group 1

| Name | UCID |
|---|---|
| Dominic Choi | 30109955 |
| Iruobe Akpatason | 30336389 |
| Anh Kiet Nguyen | 30303634 |
| Avik Singh | 30303496 |
| Deepinder Singh Brar | 30303780 |
| Riyaz Agha | 30305553 |

## 3. Technology Stack

| Component | Technology |
|---|---|
| Frontend | Flutter, Dart |
| Backend | Node.js 24, TypeScript |
| Cloud Services | Firebase Cloud Functions |
| Database | Firebase Data Connect / PostgreSQL |
| Event Broker | Google Cloud Pub/Sub |
| Architecture | Event-Driven Architecture |
| Version Control | Git, GitHub |
| Testing | Flutter Test, Firebase Functions Test |

## 4. Project Structure

```text
ZeroHunger/
├── functions/
│   ├── src/
│   │   ├── api/
│   │   ├── events/
│   │   ├── processors/
│   │   └── index.ts
│   ├── package.json
│   ├── package-lock.json
│   └── tsconfig.json
├── zerohunger/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── theme/
│   │   ├── widgets/
│   │   └── main.dart
│   ├── test/
│   └── pubspec.yaml
├── .firebaserc
├── .gitignore
├── firebase.json
└── README.md
```

## 5. Prerequisites

Install the following software before running the project:

- [Git](https://git-scm.com/downloads)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js 24 and npm](https://nodejs.org/)
- [Android Studio](https://developer.android.com/studio) for Android development.
- Firebase CLI.
- Access to the team's GitHub repository and Firebase project.

Install Firebase CLI:

```bash
npm install -g firebase-tools
```

Verify the installation:

```bash
git --version
flutter --version
node --version
npm --version
firebase --version
flutter doctor
```

## 6. Installation and Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/ENSF-607-608-Group-1/ZeroHunger.git
cd ZeroHunger
```

GitHub authentication and repository access are required.

### Step 2: Configure Firebase

The application is configured to use the following Firebase project:

```text
Project ID: zerohunger-bbd36
```

Log in to Firebase:

```bash
firebase login
firebase projects:list
firebase use default
```

Ensure that you have access to the project and that the required cloud services are configured.

For Android, obtain the team's `google-services.json` file if required and place it inside:

```text
zerohunger/android/app/
```

For iOS, ensure that the required Firebase configuration is available.

Do not commit private credentials or service account keys to GitHub.


### Step 3: Set Up the Frontend

```bash
cd zerohunger
flutter pub get
```

This installs the Flutter application dependencies.

## 7. Running the Application

### Android

Open Android Studio, launch an Android emulator and execute the following commands from the `zerohunger` directory:

```bash
flutter devices
flutter run
```

### Running on a Specific Device

```bash
flutter run -d DEVICE_ID
```

Replace `DEVICE_ID` with the device identifier displayed by `flutter devices`.

Press `q` in the terminal to stop the application.

## 8. Database and System Architecture

ZeroHunger follows an event-driven architecture.

- Flutter provides the mobile user interface.
- Firebase Cloud Functions handles backend operations.
- Google Cloud Pub/Sub supports asynchronous event communication.
- Event processors handle food listing and claim-related events.
- Firebase Data Connect is configured for PostgreSQL database integration.

The Data Connect configuration references:

```text
zerohunger/dataconnect/
```

The required database configuration and deployed services must be available before testing database-dependent functionality.

## 10. How to Use the Application

A typical demonstration follows these steps:

1. Launch the ZeroHunger application.
2. Register or sign in using a test account.
3. Open the Donate Food section.
4. Enter food details and publish a donation.
5. Open the Claim Food section.
6. Browse available food and make a reservation.
7. View donations and reservations.
8. Explore pickup chats, notifications, organizations and community events.

## 11. Testing

From the `zerohunger` directory, run:

```bash
flutter analyze
flutter test
```

To generate a test coverage report:

```bash
flutter test --coverage
```

To verify backend compilation, run the following from the `functions` directory:

```bash
npm run build
```

## 12. Deployment

Deployment is only required when updating the shared Firebase backend.

Authorized team members can deploy Cloud Functions from the repository root:

```bash
firebase deploy --only functions
```

Coordinate with the team before deploying or modifying shared cloud resources.

## 13. Commmon problems

| Problem | Solution |
|---|---|
| Flutter command not found | Install Flutter and configure PATH. |
| Node.js version mismatch | Install Node.js 24. |
| Missing Flutter dependencies | Run `flutter pub get`. |
| Missing backend dependencies | Run `npm ci` inside `functions/`. |
| No device detected | Start an emulator or simulator. |
| Firebase permission error | Verify Firebase project access. |
| Database connection error | Verify Data Connect configuration and service availability. |
| Flutter build error | Run `flutter clean`, followed by `flutter pub get`. |

## 14. Repository

[ZeroHunger GitHub Repository](https://github.com/ENSF-607-608-Group-1/ZeroHunger)

Developed by Group 1 as part of ENSF 607/608 at the University of Calgary.

**Share Food, End Hunger.**