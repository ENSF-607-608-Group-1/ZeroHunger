#  ZeroHunger
Share Food, End Hunger
### ENSF 607 | Group #1 — Project Check-In 1 Documentation
**Academic Lead:** Dr. Ronnie de Souza Santos, PhD.

---

## Project Overview
**ZeroHunger** is a fully functional, cross-platform mobile application engineered to directly operationalize **United Nations Sustainable Development Goal 2: Zero Hunger**. Built using an asynchronous, **Event-Driven Architecture (EDA)** backed by a relational database, the platform mitigates urban food waste by connecting surplus food Donors (restaurants, bakeries) with community Recipients and local Food Bank Organizations in real-time.

---

## Team Members & Contribution Directory

| Name | UCID | Core Check-In 1 Responsibility Area |
| :--- | :--- | :--- |
| **Dominic Choi** | 30109955 | Flutter Application Workspace Setup & UI Flow Simulation |
| **Iruobe Akpatason** | 30336389 | Relational Database Schema Design & Migrations Setup |
| **Anh Kiet Nguyen** | 30303634 | Backend Express API Setup & DB Event Handlers |
| **Avik Singh** | 30303496 | Firebase Cloud Messaging Topic Integration & Security |
| **Deepinder Singh Brar** | 30303780 | Architecture Modeling & Use Case Alignment |
| **Riyaz Agha** | 30305553 | Verification Test Scripts & Client Logging Interfaces |

---

## System Prerequisites & Environment Setup

### 1. Client App Layer (Flutter & Mobile SDKs)
* **Flutter SDK:** Stable Channel `v3.19.x` or higher
* **Dart SDK:** Bundle Version `v3.3.x` or higher
* **Android Tools:** Android Studio (latest stable) + Android SDK Platform Tools (v34+)
* **iOS Tools (macOS Only):** Xcode (v15.0+) + Cocoapods (v1.15+)

### 2. Relational Database Layer
* **Database Engine:** PostgreSQL `v15.x` or `v16.x`
* **Local GUI Client:** pgAdmin 4 or DBeaver (for visual verification of table records)

### 3. Event Broker & Backend Runtime
* **Runtime Environment:** Node.js `v18.x` or `v20.x` (LTS)
* **Global CLI Utilities:** 
  * Firebase CLI: `npm install -g firebase-tools`
  * FlutterFire CLI: `dart pub global activate flutterfire_cli`

---

## Local Configuration & Boot Guide

### Step 1: Clone and Stage the Workspace
```bash
git clone <your-repository-ssh-or-http-url>
cd zerohunger
```

### Step 2: Establish the Relational Database
1. Initialize your local PostgreSQL server instance.
2. Create a target database named `zero_hunger`.
3. Populate the relational schema tables using our migration script:
```bash
psql -U postgres -d zero_hunger -f database/schema.sql
```

### Step 3: Configure Environment Credentials
Create an `.env` file in your backend runtime subdirectory folder:
```env
PORT=5000
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/zero_hunger
FIREBASE_CREDENTIALS_JSON={"type": "service_account", ...}
```

### Step 4: Launch the System Layers (Split-Terminal Verification)

**Terminal Window 1: Fire up the Backend API Node Server**
```bash
cd backend
npm install
npm run dev
```

**Terminal Window 2: Execute the Flutter Mobile Target Client**
```bash
# Get Flutter dependencies
flutter pub get

# Launch on active Android Emulator or iOS Simulator
flutter run
```

---

## Verified Check-In 1 Event Flow: `FoodAvailable`

To satisfy Section 5 of the project attributes guidelines, we have operationalized one complete end-to-end event:

