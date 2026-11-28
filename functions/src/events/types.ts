// types.ts
// The fields inside each event: the `data` part of the envelope.
// For now only the events the Listing processor receives or sends are here.
// We'll add the others as we build each processor.
//
// How to read  file
//"A" | "B" means the value can only be one of those words.
//"?" after a field name means the field is optional.

import {EventEnvelope} from "./envelope";



// Values used inside events

// Where a donation is in its life (FR14)
export type DonationState = "AVAILABLE" | "CLAIMED" | "COMPLETED" | "CANCELLED" | "EXPIRED";



// Where a reservation is in its life (ReservationStatus in the class diagram).
export type ReservationStatus = "ACTIVE" | "RESCHEDULED" | "PICKED_UP" | "CANCELLED" | "EXPIRED";
// Who wrote a message: a person (USER) or the app itself (SYSTEM), like "Pickup chat opened"
export type MessageKind = "USER" | "SYSTEM";
// What's being posted: a food distribution (FR16) or a donation event someone hosts (FR15)
export type DistributionKind = "DISTRIBUTION" | "DONATION_EVENT";
// What a notification is about, so the app knows which screen to open when it's tapped
export type NotificationKind =
  "FOOD_AVAILABLE" | "FOOD_CLAIMED" | "QUANTITY_UPDATED" | "STATUS_CHANGED" | "DONATION_CANCELLED" |
  "DONATION_RESCHEDULED" | "DISTRIBUTION_SCHEDULED" | "NEW_MESSAGE" | "DONATION_DUE";
// What went in someone's history (FR13)
export type ActivityKind = "FOOD_POSTED" | "FOOD_CLAIMED" | "STATUS_CHANGED" | "EVENT_POSTED";


//Food categories
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
// A donated item once the API has given it an ID, so a recipient can say which item they want "extends ItemInput" means it has all of ItemInput's fields, plus itemId
export interface DonatedItem extends ItemInput {
  itemId: string;  // made by the API
}



// Initiating events: sent by the app (through a callable function) or a scheduler


// PostFood: a donor posts food.
// ZeroHungerApi.postFood → ListingProcessor.onPostFood
export interface PostFood {
  donationId: string;   // made by the API, so the app can track it and a repeat can't create a second listing
  donorId: string;      // the signed-in donor
  title: string;
  description: string;
  address: Address;
  pickupStart: string;  // when pickup opens
  pickupEnd: string;    // when pickup closes
  items: DonatedItem[];  // each item with its own itemId
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

// DonationDueDate: the reminder scheduler says it's time to remind a donor to donate again
// ReminderScheduler.run → NotificationProcessor.onDonationDueDate
export interface DonationDueDate {
  donorId: string;
  dueAt: string;  // when the donor meant to donate next
}

// SendMessage: someone sends a message in a chat
// ZeroHungerApi.sendMessage → MessagingProcessor.onSendMessage
export interface SendMessage {
  messageId: string;       // made by the API, so a repeat isn't saved twice
  conversationId: string;  // the chat it goes in (a pickup chat uses the reservation's ID)
  senderId: string;        // whoever is signed in
  senderIsGuest: boolean;  // guests can only write in their own pickup chat
  text: string;
  donationId?: string;     // optional donation linked to this pickup chat
  receiverId?: string;     // optional other participant's userId for push routing
}

// PostDistribution: an organization or donor posts a distribution or a donation event
// ZeroHungerApi.postDistribution → DistributionProcessor.onPostDistribution
export interface PostDistribution {
  distributionId: string;   // made by the API, so a repeat can't create a second event
  hostId: string;           // the signed-in user posting it
  organizationId?: string;  // the organization it's posted for, if any
  kind: DistributionKind;
  title: string;            // e.g. "Saturday hamper day"
  comments: string;         // anything people should know, or "" (FR24)
  address: Address;         // where it happens
  startTime: string;        // when it starts (FR23)
  endTime: string;          // when it ends
}


// Claiming food: request-reply, not an event.
// The app calls api-claimFood and waits for the answer, because the recipient
// needs to know straight away whether they got the food.


// One item a recipient wants, e.g. 2 portions of the rice.
export interface ClaimItem {
  itemId: string;    // one of the donation's items
  quantity: number;  // how many of it
}

// What the app sends to api-claimFood.
export interface ClaimFoodRequest {
  donationId: string;
  items: ClaimItem[];
  note?: string;          // optional message for the donor
  donorId?: string;       // optional donor authUid so FoodClaimed reaches the donor
  donationTitle?: string; // optional title included in the opening pickup chat message
}

// What the app gets back when the claim worked.
export interface ClaimResult {
  reservationId: string;
  donationId: string;
  quantityReserved: number;  // total across the items
  pickupStart: string;
  pickupEnd: string;
  pickupCode: string;        // the recipient shows this to the donor at pickup
  correlationId: string;     // search the logs for this to follow what happened next
}



// Derived events: sent by processors




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
  pickupCode?: string;        // unique 6-digit code shown at the top of the pickup chat
  donationTitle?: string;
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

// ReservationUpdated: a reservation changed because its donation was cancelled or rescheduled.
// ClaimProcessor.onDonationCancelled and onDonationRescheduled → no listeners yet (Table 2)
export interface ReservationUpdated {
  reservationId: string;
  donationId: string;
  recipientId: string;
  status: ReservationStatus;  // CANCELLED or RESCHEDULED
  pickupStart: string;        // the pickup times now
  pickupEnd: string;
  reason?: string;            // the donor's reason, if they gave one
}

// MessageSent: a message was saved in a chat
// MessagingProcessor.onSendMessage and onFoodClaimed → NotificationProcessor.onMessageSent
export interface MessageSent {
  messageId: string;
  conversationId: string;
  donationId: string;     // the donation the chat is about
  senderId: string;       // "system" when the app wrote it
  receiverIds: string[];  // who should be told about it
  kind: MessageKind;
  text: string;
  sentAt: string;
}

// DistributionScheduled: a distribution or donation event was saved and is on
// DistributionProcessor.onPostDistribution → NotificationProcessor.onDistributionScheduled, ActivityProcessor.onDistributionScheduled
export interface DistributionScheduled {
  distributionId: string;
  hostId: string;
  organizationId?: string;  // so Notification can tell the organization's followers
  kind: DistributionKind;
  title: string;
  address: Address;         // so the notification can say where
  startTime: string;
  endTime: string;
  locationId: string;
  gridCell: string;         // the area, used to notify users nearby
}

// UsersNotified: a notification was made and sent to phones
// NotificationProcessor (every handler) → no listeners yet (Table 2)
export interface UsersNotified {
  notificationId: string;        // made by Notification
  kind: NotificationKind;
  fcmTopics: string[];           // who it went to, e.g. ["area-T2N"] or ["user-abc123"]
  title: string;                 // what the phone shows, e.g. "Your food was claimed"
  body: string;
  data: Record<string, string>;  // the IDs the app needs to open the right screen (FCM only takes text)
  sentAt: string;
}

// ActivityRecorded: something went in one or more people's history
// ActivityProcessor (every handler) → no listeners yet (Table 2), a future impact dashboard could use it
export interface ActivityRecorded {
  activityId: string;       // made by Activity
  kind: ActivityKind;
  userIds: string[];        // whose history it goes in, e.g. the donor and the recipient for a claim
  donationId?: string;      // the donation it's about, if any
  distributionId?: string;  // the event it's about, if any
  organizationId?: string;  // the organization an event was posted for, if any
  quantity?: number;        // how much food, if any
  status?: DonationState;   // the donation's new state, for STATUS_CHANGED
  recordedAt: string;
}

// ProcessingError: a processor couldn't use an event's data, so it hands the event to Workflow
// Any processor's reportError → WorkflowProcessor.onProcessingError (the workflow event pattern)
export interface ProcessingError {
  failedEvent: EventEnvelope;  // the whole event that failed, so Workflow can fix it and send it again
  processor: string;           // where it failed, e.g. "listing"
  reason: string;              // what was wrong, e.g. a postal code typed as "t2n1n4"
}