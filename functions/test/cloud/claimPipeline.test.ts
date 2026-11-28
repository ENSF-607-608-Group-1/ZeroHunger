// claimPipeline.test.ts
// Cloud pipeline test for a claim, with one test case per hop of the claim food diagram
//
// A new guest claims food through the real api-claimFood, then the test follows that claim's
// correlationId through each topic's -sub subscription:
//   claim → api-claimFood → food-claimed → Messaging, Listing, Notification, Activity
//                                        → donation-status-changed → Notification, Activity
//
// It tests what's deployed in zerohunger-bbd36, not the code in this repo
// Run it with: npm run test:cloud (GitHub runs it every day at 9:00 and on every push to main)
// It needs Google Cloud access to the -sub subscriptions, and the Web API key in ZH_API_KEY
//   (on your PC it uses the app's google-services.json instead, which is never committed)

import {afterAll, beforeAll, describe, expect, test} from "@jest/globals";
import {readFileSync} from "fs";
import {join} from "path";
import {Message, PubSub, Subscription} from "@google-cloud/pubsub";

const PROJECT = "zerohunger-bbd36";
const API = `https://us-central1-${PROJECT}.cloudfunctions.net`;
const ACCOUNTS = "https://identitytoolkit.googleapis.com/v1/accounts";
const WAIT_MS = 90_000; // the whole chain normally arrives within a few seconds

// Every hop we expect: the -sub it arrives on, the event, its kind if it has one, and its hopCount
interface Hop {
  sub: string;
  type: string;
  kind?: string;
  hop: number;
}
const HOPS: Hop[] = [
  {sub: "food-claimed-sub", type: "FoodClaimed", hop: 1},
  {sub: "message-sent-sub", type: "MessageSent", kind: "SYSTEM", hop: 2},
  {sub: "donation-status-changed-sub", type: "DonationStatusChanged", hop: 2},
  {sub: "users-notified-sub", type: "UsersNotified", kind: "FOOD_CLAIMED", hop: 2},
  {sub: "users-notified-sub", type: "UsersNotified", kind: "NEW_MESSAGE", hop: 3},
  {sub: "users-notified-sub", type: "UsersNotified", kind: "STATUS_CHANGED", hop: 3},
  {sub: "activity-recorded-sub", type: "ActivityRecorded", kind: "FOOD_CLAIMED", hop: 2},
  {sub: "activity-recorded-sub", type: "ActivityRecorded", kind: "STATUS_CHANGED", hop: 3},
];
const SUBS = [...new Set(HOPS.map((h) => h.sub))];

// The parts of an arrived event that the test cases check
interface Arrival {
  sub: string;
  type: string;
  kind?: string;
  hop: number;
  correlationId: string;
}

const pubsub = new PubSub({projectId: PROJECT});
const listening: Subscription[] = [];
const arrivals: Arrival[] = [];
const errors: string[] = [];
let idToken = "";
let reply: {pickupCode?: string; correlationId?: string} = {};

describe("Claim pipeline in the cloud", () => {
  beforeAll(async () => {
    // Check the Google Cloud sign-in first. Without this, a sign-in problem shows up a minute later
    // as a Pub/Sub timeout that hides the reason
    await signInToGoogleCloud();

    // 1. Listen on every -sub, skipping anything that was already waiting there
    for (const name of SUBS) {
      const sub = pubsub.subscription(name);
      const [exists] = await sub.exists();
      if (!exists) {
        throw new Error(`${name} is missing, create it with: gcloud pubsub subscriptions create ${name} --topic=${topic(name)}`);
      }
      await sub.seek(new Date());
      sub.on("message", (m: Message) => {
        record(name, m);
        m.ack();
      });
      sub.on("error", (err: Error) => errors.push(`${name}: ${err.message}`));
      listening.push(sub);
    }

    // 2. Sign in as a brand new guest, like the app does
    const signedIn = await post(`${ACCOUNTS}:signUp?key=${webApiKey()}`, {returnSecureToken: true});
    idToken = signedIn.idToken ?? "";
    if (!idToken) throw new Error(`couldn't sign in as a guest: ${JSON.stringify(signedIn)}`);

    // 3. Claim food through the real API. It's request-reply, so the pickup code comes straight back
    const answer = await post(`${API}/api-claimFood`, {
      data: {donationId: `test-donation-${Date.now()}`, items: [{itemId: "test-item", quantity: 1}]},
    }, idToken);
    reply = answer.result ?? {};
    if (!reply.correlationId) throw new Error(`api-claimFood answered: ${JSON.stringify(answer)}`);
    console.log(`Following correlationId ${reply.correlationId}`);

    // 4. Wait until every hop has arrived, or time runs out
    const deadline = Date.now() + WAIT_MS;
    while (Date.now() < deadline && HOPS.some((h) => !find(h))) await sleep(500);
  }, WAIT_MS + 60_000);

  afterAll(async () => {
    await Promise.all(listening.map((sub) => sub.close()));
    await pubsub.close();
    // The guest is deleted, so test runs don't pile up in Authentication
    if (idToken) await post(`${ACCOUNTS}:delete?key=${webApiKey()}`, {idToken}).catch(() => undefined);
  });

  test("api-claimFood gives the guest a 6-digit pickup code", () => {
    expect(reply.pickupCode).toMatch(/^\d{6}$/);
  });

  for (const h of HOPS) {
    test(`${h.type}${h.kind ? ` ${h.kind}` : ""} arrives on ${topic(h.sub)} at hop ${h.hop}`, () => {
      expect(errors).toEqual([]);
      if (!find(h)) {
        throw new Error(`it never arrived within ${WAIT_MS / 1000}s, search ${reply.correlationId} in Logs Explorer to see where it stopped`);
      }
    });
  }
});

// Keeps every event that arrives, so the test cases can look for this claim's ones
function record(sub: string, m: Message): void {
  try {
    const e = JSON.parse(m.data.toString("utf8"));
    arrivals.push({sub, type: e.eventType, kind: e.data?.kind, hop: e.hopCount, correlationId: e.correlationId});
  } catch {
    // not an event envelope, e.g. a message published by hand in the console
  }
}

// This claim's event for one hop, if it arrived
function find(h: Hop): Arrival | undefined {
  return arrivals.find((a) => a.correlationId === reply.correlationId &&
    a.sub === h.sub && a.type === h.type && a.kind === h.kind && a.hop === h.hop);
}

// Gets a Google Cloud token the same way the Pub/Sub calls do, and fails with Google's reason if it can't.
// Google's sign-in code uses import(), which Jest only allows because test:cloud starts Node with
// --experimental-vm-modules
async function signInToGoogleCloud(): Promise<void> {
  try {
    await pubsub.auth.getAccessToken();
  } catch (err) {
    throw new Error(`couldn't sign in to Google Cloud: ${(err as Error).message}`);
  }
}

// The Web API key: ZH_API_KEY on GitHub, or the app's google-services.json on your PC
function webApiKey(): string {
  if (process.env.ZH_API_KEY) return process.env.ZH_API_KEY;
  const file = join(__dirname, "../../../zerohunger/android/app/google-services.json");
  return JSON.parse(readFileSync(file, "utf8")).client[0].api_key[0].current_key;
}

// A JSON POST, with the guest's token when there is one
async function post(url: string, body: unknown, token?: string): Promise<any> {
  const res = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json", ...(token ? {Authorization: `Bearer ${token}`} : {})},
    body: JSON.stringify(body),
  });
  return res.json();
}

// The topic a test subscription listens to, e.g. food-claimed-sub is on food-claimed
function topic(sub: string): string {
  return sub.replace(/-sub$/, "");
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}