// activity.ts
// The Activity processor: keeps each person's history and the donors' totals (FR13)
//
// Tables it owns (Table 1): Distribution, only this processor writes to it
//
// How it's reached, one handler per event (Table 2):
//   food-available           → onFoodAvailable          adds the listing to the donor's history
//   food-claimed             → onFoodClaimed            records the claim for the donor and the recipient
//   donation-status-changed  → onDonationStatusChanged  updates the donor's totals
//   distribution-scheduled   → onDistributionScheduled  records the event for whoever posted it
//
// Events it sends: ActivityRecorded, which nothing listens to yet

import {randomUUID} from "crypto";
import {createEvent, EventEnvelope} from "../events/envelope";
import {Topics} from "../events/topics";
import {ActivityRecorded, DistributionScheduled, DonationStatusChanged, FoodAvailable, FoodClaimed} from "../events/types";
import {EventProcessor, InvalidEvent, Outgoing} from "./eventProcessor";

export class ActivityProcessor extends EventProcessor {
  protected readonly name = "activity"; // shows up in the logs

  // food-available: a donor posted food, so it goes in their history
  async onFoodAvailable(e: EventEnvelope<FoodAvailable>): Promise<void> {
    await this.handle(e, async () => {
      const f = e.data;
      return [record(e, {kind: "FOOD_POSTED", userIds: [f.donorId], donationId: f.donationId, quantity: f.quantity})];
    });
  }

  // food-claimed: someone claimed food, so it goes in the donor's and the recipient's history
  async onFoodClaimed(e: EventEnvelope<FoodClaimed>): Promise<void> {
    await this.handle(e, async () => {
      const c = e.data;
      return [record(e, {
        kind: "FOOD_CLAIMED",
        userIds: [c.donorId, c.recipientId],
        donationId: c.donationId,
        quantity: c.quantityClaimed,
      })];
    });
  }

  // donation-status-changed: update the donor's totals, e.g. one more completed donation
  async onDonationStatusChanged(e: EventEnvelope<DonationStatusChanged>): Promise<void> {
    await this.handle(e, async () => {
      const s = e.data;
      // TODO: Review when database is complete. When s.to is COMPLETED, add one to the donor's
      //   completed donations and add the donation's quantity to the food they've given
      return [record(e, {kind: "STATUS_CHANGED", userIds: [s.donorId], donationId: s.donationId, status: s.to})];
    });
  }

  // distribution-scheduled: someone posted a distribution or a donation event, so it goes in their history
  async onDistributionScheduled(e: EventEnvelope<DistributionScheduled>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;
      return [record(e, {
        kind: "EVENT_POSTED",
        userIds: [d.hostId],
        distributionId: d.distributionId,
        organizationId: d.organizationId,
      })];
    });
  }
}

// What a handler decides: what happened and whose history it goes in
type Entry = Omit<ActivityRecorded, "activityId" | "recordedAt">;

// Turns an entry into an ActivityRecorded event, ready for handle() to send
function record(cause: EventEnvelope, entry: Entry): Outgoing {
  if (entry.userIds.some((id) => typeof id !== "string" || id.trim() === "")) {
    throw new InvalidEvent("a user ID is missing, so this can't go in anyone's history");
  }
  // TODO: Review when database is complete. Save the entry in each person's history
  //   (Activity's table, Distribution in Table 1)
  const recorded: ActivityRecorded = {activityId: randomUUID(), ...entry, recordedAt: new Date().toISOString()};
  // Passing `cause` keeps the same correlationId and adds one hop
  return {topic: Topics.activityRecorded, event: createEvent("ActivityRecorded", recorded, cause)};
}