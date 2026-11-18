// zeroHungerApi.ts
// The callable API: functions zerohungerr Flutter app calls.

//   app ──calls  -> api-postFood - PostFood  -> post-food topic -> ListingProcessor.onPostFood

// Every method does the same 4 things:
//   1 checks someone is signed in, and uses their user ID(signInAnonymously for guests)
//   2 checks the request has the right shape (text where text goes, a list where a list goes)
//   3 publishes an initiating event to its topic
//   4 answers the app straight away

// The processor does the real work a moment later, so the app should show "Submitted" not "Live". The app never talks to Pub/Sub or the database itself.

// Who checks what:
//   - this API: the shape, so a broken request never reaches a processor
//   - the Listing processor: the rules (postal code format, pickup times, quantity of 1 or more).(TODO:might remove quantity later, confirm with team)
//     Bad data there is reported to the workflow processor (the workflow event pattern).

import {randomUUID} from "crypto";
import {CallableRequest, HttpsError} from "firebase-functions/https";
import {createEvent, EventEnvelope} from "../events/envelope";
import {publishEvent} from "../events/publisher";
import {Topic, Topics} from "../events/topics";
import {
  Address,
  ALLERGENS,
  CancelOrRescheduleDonation,
  ClaimFoodRequest,
  ClaimItem,
  ClaimResult,
  FOOD_CATEGORIES,
  ItemInput,
  PostFood,
  UpdateQuantity,
} from "../events/types";
import {Claimant, ClaimProcessor, ClaimRefused} from "../processors/claim";
import {PublishFn} from "../processors/eventProcessor";

// What the app sends and what it gets back


// The app sends an event's fields, minus the ones the API fills in itself.
// Omit<A, "x"> means "A without the field x".

// postFood: PostFood without donationId (the API makes a new one)and donorId (the signed-in user).
// The app sends items without IDs; the API gives each one an ID ("&" adds the items field back as ItemInput[]).
export type PostFoodRequest = Omit<PostFood, "donationId" | "donorId" | "items"> & {items: ItemInput[]};

// updateQuantity: UpdateQuantity without donorId.
export type UpdateQuantityRequest = Omit<UpdateQuantity, "donorId">;

// cancelOrRescheduleDonation: CancelOrRescheduleDonation without donorId.
export type CancelOrRescheduleRequest = Omit<CancelOrRescheduleDonation, "donorId">;

// What every method answers.
export interface Submitted {
  donationId: string;     // the donation this is about (a new one for postFood)
  correlationId: string;  // search the logs for this to follow what happened next
  itemIds?: string[];     // postFood only: the new item IDs, in the order the items were sent
}


// The API. index.ts turns each method into its own callable Cloud Function.
export class ZeroHungerApi {
  // publish: the function used to send events. Normally publishEvent.
  // claims: the Claim processor. api-claimFood calls it directly and waits (request-reply).

  constructor(
    private readonly publish: PublishFn = publishEvent,
    private readonly claims: ClaimProcessor = new ClaimProcessor(publish),
  ) {}

  // api-postFood: a donor posts food.
  // Sends PostFood to post-food → ListingProcessor.onPostFood
  async postFood(request: CallableRequest<PostFoodRequest>): Promise<Submitted> {
    const donorId = accountHolder(request); // guests can't do this

    // Partial<...> means any field might be missing: the app could send anything.
    // "?? {}" means: use an empty object if the app sent nothing at all.
    const d: Partial<PostFoodRequest> = request.data ?? {};

// TODO: Review when database is complete. Check this account is allowed to
//   donate (e.g. its role) before accepting a listing.

    // Build the event from checked fields only, so nothing extra the app sent gets through.
    const post: PostFood = {
      donationId: randomUUID(), // a new ID for this donation
      donorId,
      title: needText(d.title, "title"),
      description: optionalText(d.description, "description"),
      // Each item gets a new ID. "...checkItem(...)" copies the checked item's fields in after it.
      items: needList(d.items, "items").map((item, i) => ({itemId: randomUUID(), ...checkItem(item, i + 1)})),
      address: checkAddress(d.address),
      pickupStart: needText(d.pickupStart, "pickupStart"),
      pickupEnd: needText(d.pickupEnd, "pickupEnd"),
    };
    const sent = await this.send(Topics.postFood, createEvent("PostFood", post), post.donationId);
    // Answer with the item IDs too, so the app has them straight away (our claim test uses them).
    return {...sent, itemIds: post.items.map((item) => item.itemId)};
  }

  // api-updateQuantity: a donor sets how much food is left.
  // Sends UpdateQuantity to update-quantity → ListingProcessor.onUpdateQuantity
  async updateQuantity(request: CallableRequest<UpdateQuantityRequest>): Promise<Submitted> {
    const donorId = accountHolder(request); // guests can't do this
    const d: Partial<UpdateQuantityRequest> = request.data ?? {};

    const update: UpdateQuantity = {
      donationId: needText(d.donationId, "donationId"),
      donorId,
      newQuantity: needNumber(d.newQuantity, "newQuantity"),
    };
    return this.send(Topics.updateQuantity, createEvent("UpdateQuantity", update), update.donationId);
  }

  // api-cancelOrRescheduleDonation: a donor cancels a donation or moves its pickup time.
  // Sends CancelOrRescheduleDonation to cancel-or-reschedule-donation → ListingProcessor.onCancelOrReschedule
  async cancelOrRescheduleDonation(request: CallableRequest<CancelOrRescheduleRequest>): Promise<Submitted> {
    const donorId = accountHolder(request); // guests can't do this
    const d: Partial<CancelOrRescheduleRequest> = request.data ?? {};

    if (d.action !== "CANCEL" && d.action !== "RESCHEDULE") {
      throw invalid("action must be CANCEL or RESCHEDULE");
    }
    const reschedule = d.action === "RESCHEDULE";

    const change: CancelOrRescheduleDonation = {
      donationId: needText(d.donationId, "donationId"),
      donorId,
      action: d.action,
      // The new pickup times are only needed (and only sent) to reschedule.
      newPickupStart: reschedule ? needText(d.newPickupStart, "newPickupStart") : undefined,
      newPickupEnd: reschedule ? needText(d.newPickupEnd, "newPickupEnd") : undefined,
      reason: optionalText(d.reason, "reason") || undefined, // left out if empty
    };
    return this.send(
      Topics.cancelOrRescheduleDonation,
      createEvent("CancelOrRescheduleDonation", change),
      change.donationId,
    );
  }

  // api-claimFood: a recipient (guests too) claims some of a donation's items.
  // Request-reply: unlike the methods above, this one waits for the Claim processor,
  // because the recipient needs to know straight away whether they got the food.
  async claimFood(request: CallableRequest<ClaimFoodRequest>): Promise<ClaimResult> {
    const who: Claimant = {
      userId: signedInUser(request), // guests can claim (decided), so not accountHolder
      isGuest: request.auth?.token.firebase.sign_in_provider === "anonymous",
    };
    const d: Partial<ClaimFoodRequest> = request.data ?? {};

    // Build the claim from checked fields only, like postFood.
    const claim: ClaimFoodRequest = {
      donationId: needText(d.donationId, "donationId"),
      items: needList(d.items, "items").map((item, i) => checkClaimItem(item, i + 1)),
      note: optionalText(d.note, "note") || undefined, // left out if empty
    };

    try {
      return await this.claims.claimFood(who, claim);
    } catch (err) {
      // A refused claim becomes an error the app receives, e.g. "not enough left".
      if (err instanceof ClaimRefused) throw new HttpsError(err.code, err.message);
      throw err; // anything else: the app gets "internal" and can try again
    }
  }

  // Publishes the event, then tells the app it was accepted
  // If publishing fails, the app gets an error and can try again
  private async send(topic: Topic, event: EventEnvelope, donationId: string): Promise<Submitted> {
    await this.publish(topic, event);
    return {donationId, correlationId: event.correlationId};
  }
}

//Checks. Each one stops the call with an error the app receives,
// saying what is wrong for example "title is missing"



// Returns the callers user ID. Guests have one too: the app signs them inanonymously, with no form Stops with "unauthenticated" only when the call
// has no user at all 
function signedInUser(request: CallableRequest): string {
  if (!request.auth) throw new HttpsError("unauthenticated", "sign in first");
  return request.auth.uid;
}


// Like signedInUser, but stops guests with "permission-denied",
// so the app can ask them to create an account. Used for donor actions.
function accountHolder(request: CallableRequest): string {
  const uid = signedInUser(request);
  // sign_in_provider says how the user signed in: "anonymous" (a guest), "password", "phone", ...
  if (request.auth?.token.firebase.sign_in_provider === "anonymous") {
    throw new HttpsError("permission-denied", "create an account first");
  }
  return uid;
}




// An "invalid-argument" error: the request itself is wrong.
function invalid(message: string): HttpsError {
  return new HttpsError("invalid-argument", message);
}

// Text that must be there, e.g. a title. Spaces at the ends are trimmed off.
function needText(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim() === "") throw invalid(`${field} is missing`);
  return value.trim();
}

// Text that can be left out, e.g. a description. "" if it's missing.
function optionalText(value: unknown, field: string): string {
  if (value === undefined || value === null) return "";
  if (typeof value !== "string") throw invalid(`${field} must be text`);
  return value.trim();
}

// A number, e.g. a quantity. (Listing checks it is a whole number.)
function needNumber(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isFinite(value)) throw invalid(`${field} must be a number`);
  return value;
}

// A list, e.g. the items.
function needList<T>(value: T[] | undefined, field: string): T[] {
  if (!Array.isArray(value)) throw invalid(`${field} must be a list`);
  return value;
}

// A list of tags that must all come from `allowed`, e.g. categories from FOOD_CATEGORIES.
// Missing means no tags.
function needTags<T extends string>(value: unknown, allowed: readonly T[], field: string): T[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) throw invalid(`${field} must be a list`);
  for (const tag of value) {
    if (!allowed.includes(tag)) {
      throw invalid(`${field}: "${tag}" is not one of ${allowed.join(", ")}`);
    }
  }
  return value as T[];
}

// One food item, e.g. {name: "Rice", categories: ["HALAL"], allergens: [], quantity: 6, unit: "portions"}.
// n is its place in the list (1, 2, ...), used in error messages.
function checkItem(item: Partial<ItemInput>, n: number): ItemInput {
  if (typeof item !== "object" || item === null) throw invalid(`item ${n} is not an item`);
  return {
    name: needText(item.name, `item ${n} name`),
    categories: needTags(item.categories, FOOD_CATEGORIES, `item ${n} categories`),
    allergens: needTags(item.allergens, ALLERGENS, `item ${n} allergens`),
    quantity: needNumber(item.quantity, `item ${n} quantity`),
    unit: needText(item.unit, `item ${n} unit`),
  };
}

// One claimed item, e.g. {itemId: "3f2a…", quantity: 2}.
// n is its place in the list (1, 2, ...), used in error messages.
function checkClaimItem(item: Partial<ClaimItem>, n: number): ClaimItem {
  if (typeof item !== "object" || item === null) throw invalid(`item ${n} is not an item`);
  return {
    itemId: needText(item.itemId, `item ${n} itemId`),
    quantity: needNumber(item.quantity, `item ${n} quantity`),
  };
}

// The pickup address. (Listing checks the postal code's format.)
function checkAddress(a: Partial<Address> | undefined): Address {
  if (typeof a !== "object" || a === null) throw invalid("address is missing");
  return {
    line1: needText(a.line1, "address line1"),
    city: needText(a.city, "address city"),
    province: needText(a.province, "address province"),
    postalCode: needText(a.postalCode, "address postalCode"),
  };
}