// listing.ts
// The Listing processor: creates and updates donation listings and their status.
//
// Tables it owns (Table 1): Donation, DonationItem, DonationStatus, Location.
//   Only this processor writes to them.
//
// Topics it listens to (Table 2), one method each:
//   post-food                      → onPostFood
//   update-quantity                → onUpdateQuantity
//   cancel-or-reschedule-donation  → onCancelOrReschedule
//   food-claimed                   → onFoodClaimed
//   expiry-check                   → onExpiryCheck
//
// Events it sends: FoodAvailable, QuantityUpdated, DonationCancelled,
//   DonationRescheduled, DonationStatusChanged.
//
// Every method works the same way: check the event, update the tables (TODO for now),
// then return the events to send. handle(), from EventProcessor, sends them.

import {randomUUID} from "crypto";
import {createEvent, EventEnvelope} from "../events/envelope";
import {Topic, Topics} from "../events/topics";
import {
  CancelOrRescheduleDonation,
  DonationCancelled,
  DonationRescheduled,
  DonationStatusChanged,
  ExpiryCheck,
  FoodAvailable,
  FoodClaimed,
  PostFood,
  QuantityUpdated,
  UpdateQuantity,
} from "../events/types";
import {EventProcessor, InvalidEvent, Outgoing} from "./eventProcessor";

// "extends EventProcessor" means ListingProcessor gets handle() and reportError()
// from the parent class, and only adds its own methods.
export class ListingProcessor extends EventProcessor {
  protected readonly name = "listing"; // shows up in the logs

  // post-food: a donor posted food.
  // Check the listing, save it as AVAILABLE, then send FoodAvailable.
  async onPostFood(e: EventEnvelope<PostFood>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;   // the PostFood details
      checkPostFood(d);   // throws InvalidEvent if something is wrong

      // Add up the quantities of all the items, e.g. 6 + 4 = 10.
      const quantity = d.items.reduce((sum, item) => sum + item.quantity, 0);

      // TODO: Review when database is complete. Find or create the Location for d.address
      //   (look up its coordinates from the postal code) and use its ID instead of this one.
      const locationId = randomUUID();

      // TODO: Review when database is complete. In one transaction, save:
      //   - the Donation: state AVAILABLE, quantity and remainingQuantity = quantity,
      //     the pickup times and locationId
      //   - one DonationItem per item in d.items
      //   - the first DonationStatus row (AVAILABLE)
      //   If a Donation with d.donationId already exists, this event came twice: return [].

      // Build the FoodAvailable event from the PostFood details.
      const available: FoodAvailable = {
        donationId: d.donationId,
        donorId: d.donorId,
        title: d.title,
        categories: unique(d.items.flatMap((item) => item.categories)), // every item's categories, no repeats
        allergens: unique(d.items.flatMap((item) => item.allergens)),   // every item's allergens, no repeats
        quantity,
        pickupStart: d.pickupStart,
        pickupEnd: d.pickupEnd,
        locationId,
        gridCell: areaOf(d.address.postalCode),
      };

      // Send it to food-available. Passing `e` keeps the same correlationId and adds one hop.
      return [out(Topics.foodAvailable, createEvent("FoodAvailable", available, e))];
    });
  }

  // update-quantity: a donor changed how much food is left.
  // Save the new amount, then send QuantityUpdated.
  async onUpdateQuantity(e: EventEnvelope<UpdateQuantity>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;
      if (!Number.isInteger(d.newQuantity) || d.newQuantity < 0) {
        throw new InvalidEvent("newQuantity must be a whole number, 0 or more");
      }

      // TODO: Review when database is complete. Load the Donation. Throw InvalidEvent if it
      //   doesn't exist or isn't d.donorId's; return [] if it isn't AVAILABLE.
      //   Then save remainingQuantity = d.newQuantity.

      const updated: QuantityUpdated = {
        donationId: d.donationId,
        donorId: d.donorId,
        // TODO: Review when database is complete. Use the saved Donation.quantity.
        quantity: d.newQuantity,
        remainingQuantity: d.newQuantity,
      };
      return [out(Topics.quantityUpdated, createEvent("QuantityUpdated", updated, e))];
    });
  }

  // cancel-or-reschedule-donation: a donor cancelled a donation or moved its pickup time.
  // Send DonationCancelled or DonationRescheduled.
  async onCancelOrReschedule(e: EventEnvelope<CancelOrRescheduleDonation>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;

      // TODO: Review when database is complete. Load the Donation. Throw InvalidEvent if it
      //   doesn't exist or isn't d.donorId's; return [] if it is already CANCELLED,
      //   COMPLETED or EXPIRED.

      if (d.action === "CANCEL") {
        // TODO: Review when database is complete. Set state CANCELLED and add a DonationStatus row.
        const cancelled: DonationCancelled = {donationId: d.donationId, donorId: d.donorId, reason: d.reason};
        return [out(Topics.donationCancelled, createEvent("DonationCancelled", cancelled, e))];
      }

      if (d.action === "RESCHEDULE") {
        checkPickupWindow(d.newPickupStart, d.newPickupEnd); // throws InvalidEvent if the times are wrong
        // TODO: Review when database is complete. Save the new pickupStart and pickupEnd.
        const moved: DonationRescheduled = {
          donationId: d.donationId,
          donorId: d.donorId,
          pickupStart: d.newPickupStart as string, // "as string": checkPickupWindow has made sure it's there
          pickupEnd: d.newPickupEnd as string,
        };
        return [out(Topics.donationRescheduled, createEvent("DonationRescheduled", moved, e))];
      }

      throw new InvalidEvent(`action must be CANCEL or RESCHEDULE, not "${d.action}"`);
    });
  }

  // food-claimed: a recipient claimed some of this donation.
  // Save how much is left. If nothing is left, mark it CLAIMED and send DonationStatusChanged.
  async onFoodClaimed(e: EventEnvelope<FoodClaimed>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;

      // TODO: Review when database is complete. Save remainingQuantity = d.remainingQuantity
      //   on the Donation.

      if (d.remainingQuantity > 0) return []; // food still left: nothing else changes, send nothing

      // TODO: Review when database is complete. Set state CLAIMED and add a DonationStatus row.
      //   If the Donation is already CLAIMED, return [] (nothing changed, so send nothing).
      const changed: DonationStatusChanged = {
        donationId: d.donationId,
        donorId: d.donorId,
        from: "AVAILABLE", // TODO: Review when database is complete. Use the saved state.
        to: "CLAIMED",
        changedAt: new Date().toISOString(),
      };
      return [out(Topics.donationStatusChanged, createEvent("DonationStatusChanged", changed, e))];
    });
  }

  // expiry-check: the expiry scheduler asked for old listings to be expired.
  // Mark every listing whose pickup time has passed as EXPIRED, and send one
  // DonationStatusChanged for each.
  async onExpiryCheck(e: EventEnvelope<ExpiryCheck>): Promise<void> {
    await this.handle(e, async () => {
      // TODO: Review when database is complete. Load the AVAILABLE donations whose pickupEnd
      //   is before e.data.asOf, set each one's state to EXPIRED and add a DonationStatus row.
      //   (Gap 3 in the PDF: CLAIMED donations past pickupEnd could become COMPLETED here.)
      const expired: Array<{donationId: string; donorId: string}> = []; // empty until the database exists

      // One DonationStatusChanged per expired listing.
      return expired.map((x) => {
        const changed: DonationStatusChanged = {
          donationId: x.donationId,
          donorId: x.donorId,
          from: "AVAILABLE",
          to: "EXPIRED",
          changedAt: new Date().toISOString(),
        };
        return out(Topics.donationStatusChanged, createEvent("DonationStatusChanged", changed, e));
      });
    });
  }
}

// ---------------------------------------------------------------------------
// Checks and small helpers used by the methods above
// ---------------------------------------------------------------------------

// A Canadian postal code: letter, digit, letter, space, digit, letter, digit, e.g. "T2N 1N4".
const POSTAL_CODE = /^[A-Z]\d[A-Z] \d[A-Z]\d$/;

// Throws InvalidEvent if a PostFood is missing something or has a wrong value.
function checkPostFood(d: PostFood): void {
  if (!d.title?.trim()) throw new InvalidEvent("title is missing");
  if (!Array.isArray(d.items) || d.items.length === 0) {
    throw new InvalidEvent("a listing needs at least one item");
  }
  for (const item of d.items) {
    if (!item.name?.trim()) throw new InvalidEvent("an item has no name");
    if (!Number.isInteger(item.quantity) || item.quantity <= 0) {
      throw new InvalidEvent(`"${item.name}" needs a quantity of 1 or more`);
    }
  }
  const postalCode = d.address?.postalCode ?? ""; // "?? ''" means: use "" if there's no postal code
  if (!POSTAL_CODE.test(postalCode)) {
    // The workflow processor will be able to fix formatting like "t2n1n4" and send the event again.
    throw new InvalidEvent(`postal code "${postalCode}" is not in the form A1A 1A1`);
  }
  checkPickupWindow(d.pickupStart, d.pickupEnd);
}

// Throws InvalidEvent unless both times are real dates and pickup ends after it starts.
function checkPickupWindow(start?: string, end?: string): void {
  const from = Date.parse(start ?? ""); // turns the text into a number of milliseconds (NaN if it isn't a date)
  const to = Date.parse(end ?? "");
  if (Number.isNaN(from) || Number.isNaN(to)) {
    throw new InvalidEvent("pickup start and end must be ISO 8601 dates");
  }
  if (to <= from) throw new InvalidEvent("pickup must end after it starts");
}

// The area used to notify users nearby.
// TODO: For now this is the first part of the postal code (e.g. "T2N"). Swap it
//   for a map grid cell once locations have coordinates.
function areaOf(postalCode: string): string {
  return postalCode.slice(0, 3).toUpperCase();
}

// Removes repeats from a list, e.g. ["VEGAN", "HALAL", "VEGAN"] → ["VEGAN", "HALAL"].
function unique<T>(values: T[]): T[] {
  return [...new Set(values)];
}

// Pairs a topic with an event, ready for handle() to send.
function out(topic: Topic, event: EventEnvelope): Outgoing {
  return {topic, event};
}