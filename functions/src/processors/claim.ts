// claim.ts
// The Claim processor: reserves food for recipients and manages their reservations.
//
// Tables it owns (class diagram, page 1): FoodRequest, RequestItem, FoodReservation.
//   Table 1 calls them Reservation. Only this processor writes to them.
//
// How it is reached:
//   api-claimFood          → claimFood              request-reply: the app waits for the answer
//   donation-cancelled     → onDonationCancelled    (Table 2)
//   donation-rescheduled   → onDonationRescheduled  (Table 2)
//
// Events it sends: FoodClaimed, ReservationUpdated

import {randomInt, randomUUID} from "crypto";
import {createEvent, EventEnvelope} from "../events/envelope";
import {Topic, Topics} from "../events/topics";
import {
  ClaimFoodRequest,
  ClaimResult,
  DonationCancelled,
  DonationRescheduled,
  FoodClaimed,
  ReservationUpdated,
} from "../events/types";
import {EventProcessor, Outgoing} from "./eventProcessor";

// Why a claim was turned down. The API turns it into an error the app receives.
//   invalid-argument    : the request breaks a rule, e.g. a quantity of 0
//   not-found           : the donation or one of its items doesn't exist
//   failed-precondition : it can't be claimed right now, e.g. not enough left
export class ClaimRefused extends Error {
  constructor(readonly code: "invalid-argument" | "not-found" | "failed-precondition", message: string) {
    super(message);
  }
}

// Who is claiming.
export interface Claimant {
  userId: string;
  isGuest: boolean;  // guests can have one active claim at a time
}

// The parts of a saved FoodReservation that the event handlers below need.
interface ReservationRow {
  reservationId: string;
  recipientId: string;
  pickupStart: string;
  pickupEnd: string;
}

export class ClaimProcessor extends EventProcessor {
  protected readonly name = "claim"; // shows up in the logs

  // api-claimFood: a recipient claims some of a donation's items.
  // Request-reply: check there is enough left, reserve it and save the reservation,
  // send FoodClaimed, then answer the app with the pickup details.
  async claimFood(who: Claimant, request: ClaimFoodRequest): Promise<ClaimResult> {
    checkClaim(request); // throws ClaimRefused if the request breaks a rule

    // Add up what was asked for, e.g. 2 + 1 = 3.
    const total = request.items.reduce((sum, item) => sum + item.quantity, 0);

    // TODO: Review when database is complete. If who.isGuest and they already have an ACTIVE
    //   reservation, refuse: failed-precondition, "guests can have one claim at a time".

    // TODO: Review when database is complete. Load the Donation and its DonationItems, then refuse:
    //   - not-found if the donation or one of the items doesn't exist
    //   - failed-precondition if it isn't AVAILABLE, if who.userId is its donor,
    //     or if an item has less left than asked for
    // Until then, these stand-in values let the whole flow run in the cloud:
    const donorId = "unknown-donor";                                  // Donation.donorId
    const remainingBefore = total;                                    // pretend exactly enough is left
    const pickupStart = new Date().toISOString();                     // Donation.pickupStart
    const pickupEnd = new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(); // 2 hours later
    const pickupLocationId = "unknown-location";                      // Donation.locationId

    const reservationId = randomUUID();
    const pickupCode = String(randomInt(100000, 1000000)); // 6 digits, shown to the donor at pickup

    // TODO: Review when database is complete. In one transaction, locking this donation's
    //   reservations so two claims at once can't both take the last portion, save:
    //   - the FoodRequest (status APPROVED) and one RequestItem per item asked for
    //   - the FoodReservation (status ACTIVE, the pickup times and pickupCode)
    //   - the FoodClaimed event below, in the outbox table

    const claimed: FoodClaimed = {
      reservationId,
      donationId: request.donationId,
      donorId,
      recipientId: who.userId,
      quantityClaimed: total,
      remainingQuantity: remainingBefore - total,
      pickupStart,
      pickupEnd,
      pickupLocationId,
    };

    // The claim request is the initiating event. It isn't published (the app waits for this answer),
    // but making it here starts a new correlationId, and FoodClaimed follows it with hopCount 1.
    const ask = createEvent("ClaimFood", request);
    const event = createEvent("FoodClaimed", claimed, ask);
    await this.publish(Topics.foodClaimed, event);

    return {
      reservationId,
      donationId: request.donationId,
      quantityReserved: total,
      pickupStart,
      pickupEnd,
      pickupCode,
      correlationId: event.correlationId,
    };
  }

  // donation-cancelled: a donor cancelled a donation.
  // Cancel its reservations and send one ReservationUpdated for each.
  async onDonationCancelled(e: EventEnvelope<DonationCancelled>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;

      // TODO: Review when database is complete. Load this donation's ACTIVE and RESCHEDULED
      //   reservations and set each one to CANCELLED.
      const affected: ReservationRow[] = []; // empty until the database exists

      // One ReservationUpdated per reservation that changed. None changed → nothing is sent.
      return affected.map((r) => {
        const updated: ReservationUpdated = {
          reservationId: r.reservationId,
          donationId: d.donationId,
          recipientId: r.recipientId,
          status: "CANCELLED",
          pickupStart: r.pickupStart,
          pickupEnd: r.pickupEnd,
          reason: d.reason,
        };
        return out(Topics.reservationUpdated, createEvent("ReservationUpdated", updated, e));
      });
    });
  }

  // donation-rescheduled: a donor moved the pickup time.
  // Move its reservations to the new time and send one ReservationUpdated for each.
  async onDonationRescheduled(e: EventEnvelope<DonationRescheduled>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;

      // TODO: Review when database is complete. Load this donation's ACTIVE and RESCHEDULED
      //   reservations, skip any that already have these pickup times (nothing changed, so
      //   nothing is sent: this stops two processors triggering each other), and save the
      //   new times with status RESCHEDULED.
      const affected: ReservationRow[] = []; // empty until the database exists

      return affected.map((r) => {
        const updated: ReservationUpdated = {
          reservationId: r.reservationId,
          donationId: d.donationId,
          recipientId: r.recipientId,
          status: "RESCHEDULED",
          pickupStart: d.pickupStart,
          pickupEnd: d.pickupEnd,
        };
        return out(Topics.reservationUpdated, createEvent("ReservationUpdated", updated, e));
      });
    });
  }
}




// Checks and small helpers used by the methods above


// Throws ClaimRefused unless every quantity is a whole number of 1 or more
// and no item is asked for twice. (The API has already checked the shape.)
function checkClaim(request: ClaimFoodRequest): void {
  if (request.items.length === 0) throw new ClaimRefused("invalid-argument", "pick at least one item");
  const seen = new Set<string>();
  for (const item of request.items) {
    if (!Number.isInteger(item.quantity) || item.quantity < 1) {
      throw new ClaimRefused("invalid-argument", "each quantity must be a whole number, 1 or more");
    }
    if (seen.has(item.itemId)) throw new ClaimRefused("invalid-argument", `item ${item.itemId} is listed twice`);
    seen.add(item.itemId);
  }
}

// Pairs a topic with an event, ready for handle() to send.
function out(topic: Topic, event: EventEnvelope): Outgoing {
  return {topic, event};
}
