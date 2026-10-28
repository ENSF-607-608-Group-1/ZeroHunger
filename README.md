# ZeroHunger
Share Food, End Hunger
# Zero Hunger Food Sharing Platform - ENSF 607 Group 1

## Project Overview
An event-driven platform connecting food donors, community groups, and recipients to eliminate food waste and operationalize UN Sustainable Development Goal 2 (Zero Hunger).

## Team Members
* Dominic Choi (30109955)
* Iruobe Akpatason (30336389)
* Anh Kiet Nguyen (30303634)
* Avik Singh (30303496)
* Deepinder Singh Brar (30303780)
* Riyaz Agha (30305553)

## System Prerequisites
* Node.js v18+ 
* PostgreSQL v14+ (or MySQL)
* Firebase CLI tools / Active Firebase Project Account

## Local Configuration & Setup
1. Clone the repository: `git clone <repo-url>`
2. Install dependencies: `npm install`
3. Configure environment variables in an `.env` file:
   ```env
   PORT=5000
   DATABASE_URL=postgresql://user:password@localhost:5432/zero_hunger
   FIREBASE_CREDENTIALS_JSON={"type": "service_account", ...}
   ```
4. Run Database Migrations: `npm run migrate`
5. Start the local server: `npm run dev`

## Check-In 1 Verified Event Flow
* **Event:** `FoodAvailable`
* **Trigger:** Donor submits a new surplus food item via API/Client endpoint.
* **Broker:** Firebase Cloud Messaging (FCM) topic subscription handler.
* **Consumer:** Subscribed Recipients / Nearby logs.
