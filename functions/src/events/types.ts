// types.ts
// The fields inside each event: the `data` part of the envelope.
// For now only the events the Listing processor receives or sends are here.
// We'll add the others as we build each processor.
//
// How to read this file:
//   - Dates are text in ISO 8601 format, e.g. "2026-11-06T17:00:00-07:00".
//   - "A" | "B" means the value can only be one of those words.
//   - A "?" after a field name means the field is optional.
//   - [] after a type means a list, e.g. FoodCategory[] could be ["HALAL", "VEGAN"].

// ---------------------------------------------------------------------------
// Values used inside events
// ---------------------------------------------------------------------------

// Where a donation is in its life (FR14).
export type DonationState = "AVAILABLE" | "CLAIMED" | "COMPLETED" | "CANCELLED" | "EXPIRED";

//Food categories (FR9, FR11).
//Types disappear when TypeScript turns into JavaScript, so the running code can't
//check a value against a type. It can check against a real list, so we keep one:
//FOOD_CATEGORIES : the list, used by the API to check what the app sends
// FoodCategory    : the type made from that list
export const FOOD_CATEGORIES = ["HALAL", "VEGAN", "VEGETARIAN", "UNCOOKED", "GRAIN"] as const;
export type FoodCategory = (typeof FOOD_CATEGORIES)[number];


//Health Canadas priority food allergens
//ALLERGENS is list, Allergen is the type made from it.
export const ALLERGENS = [
  "PEANUTS", "TREE_NUTS", "MILK", "EGGS", "WHEAT", "SOY",
  "SESAME", "FISH", "SHELLFISH", "MUSTARD", "SULPHITES",
] as const;
export type Allergen = (typeof ALLERGENS)[number];


// A pickup address.
export interface Address {
  line1: string;       // street, e.g. "2500 University Dr NW"
  city: string;        // e.g. "Calgary"
  province: string;    // e.g. "AB"
  postalCode: string;  // Canadian format, e.g. "T2N 1N4"
}

// One food item in a donation, e.g. 6 portions of rice.
export interface ItemInput {
  name: string;                // e.g. "Rice"
  categories: FoodCategory[];  // e.g. ["HALAL", "VEGAN"]
  allergens: Allergen[];       // e.g. ["SOY"], or [] if none
  quantity: number;            // e.g. 6
  unit: string;                // e.g. "portions" or "kg"
}

// ---------------------------------------------------------------------------
// Initiating events: sent by the app (through a callable function) or a scheduler
// ---------------------------------------------------------------------------

// PostFood: a donor posts food.
// ZeroHungerApi.postFood → ListingProcessor.onPostFood
export interface PostFood {
  donationId: string;   // made by the API, so the app can track it and a repeat can't create a second listing
  donorId: string;      // the signed-in donor
  title: string;
  description: string;
  items: ItemInput[];
  address: Address;
  pickupStart: string;  // when pickup opens
  pickupEnd: string;    // when pickup closes
}

// UpdateQuantity: a donor sets how much food is left.
// ZeroHungerApi.updateQuantity → ListingProcessor.onUpdateQuantity
export interface UpdateQuantity {
  donationId: string;
  donorId: string;
  newQuantity: number;  // how much is left now
}

// CancelOrRescheduleDonation: a donor cancels a donation or moves its pickup time.
// ZeroHungerApi.cancelOrRescheduleDonation → ListingProcessor.onCancelOrReschedule
export interface CancelOrRescheduleDonation {
  donationId: string;
  donorId: string;
  action: "CANCEL" | "RESCHEDULE";
  newPickupStart?: string;  // only needed to RESCHEDULE
  newPickupEnd?: string;    // only needed to RESCHEDULE
  reason?: string;
}

// ExpiryCheck: the expiry scheduler asks Listing to expire old listings.
// ExpiryScheduler.run → ListingProcessor.onExpiryCheck
export interface ExpiryCheck {
  asOf: string;  // expire listings whose pickup ended before this time
}

// ---------------------------------------------------------------------------
// Derived events: sent by processors
// ---------------------------------------------------------------------------

// FoodClaimed: a recipient claimed some food. Fields from the project description's example.
// ClaimProcessor.claimFood → ListingProcessor.onFoodClaimed (also Messaging, Notification, Activity)
export interface FoodClaimed {
  reservationId: string;
  donationId: string;
  donorId: string;
  recipientId: string;
  quantityClaimed: number;    // how much this recipient took
  remainingQuantity: number;  // how much is left after this claim
  pickupStart: string;
  pickupEnd: string;
  pickupLocationId: string;
}

// FoodAvailable: a listing is live.
// ListingProcessor.onPostFood → NotificationProcessor.onFoodAvailable, ActivityProcessor.onFoodAvailable
export interface FoodAvailable {
  donationId: string;
  donorId: string;
  title: string;
  categories: FoodCategory[];  // all the categories of its items, so Notification can match preferences
  allergens: Allergen[];       // all the allergens of its items
  quantity: number;            // total of all its items
  pickupStart: string;
  pickupEnd: string;
  locationId: string;
  gridCell: string;            // the area, used to notify users nearby
}

// QuantityUpdated: a donor changed how much food is left.
// ListingProcessor.onUpdateQuantity → NotificationProcessor.onQuantityUpdated
export interface QuantityUpdated {
  donationId: string;
  donorId: string;
  quantity: number;           // the donation's total
  remainingQuantity: number;  // how much is left now
}

// DonationStatusChanged: a donation moved to a new state, e.g. AVAILABLE → CLAIMED.
// ListingProcessor.onFoodClaimed and onExpiryCheck
//   → NotificationProcessor.onDonationStatusChanged, ActivityProcessor.onDonationStatusChanged
export interface DonationStatusChanged {
  donationId: string;
  donorId: string;
  from: DonationState;  // the old state
  to: DonationState;    // the new state
  changedAt: string;
  // TODO: Review when database is complete. Add `quantity` (the donation's total, from the
  //   Donation table) so Activity can update the donor's totals without a lookup.
}

// DonationCancelled: a donor cancelled a donation.
// ListingProcessor.onCancelOrReschedule → ClaimProcessor.onDonationCancelled, NotificationProcessor.onDonationCancelled
export interface DonationCancelled {
  donationId: string;
  donorId: string;
  reason?: string;
}

// DonationRescheduled: a donor moved the pickup time.
// ListingProcessor.onCancelOrReschedule → ClaimProcessor.onDonationRescheduled, NotificationProcessor.onDonationRescheduled
export interface DonationRescheduled {
  donationId: string;
  donorId: string;
  pickupStart: string;  // the new pickup start
  pickupEnd: string;    // the new pickup end
}