// distribution.ts
// The Distribution processor: saves distributions and donation events, then tells everyone they're on
//
// Tables it owns (Table 1): DistributionEvent and EventRSVP, only this processor writes to them
//
// How it's reached:
//   post-distribution → onPostDistribution
//
// Events it sends: DistributionScheduled
//
// Who can post (Table 2): organizations and donors, guests can't (the API stops them)

import {randomUUID} from "crypto";
import {createEvent, EventEnvelope} from "../events/envelope";
import {Topic, Topics} from "../events/topics";
import {DistributionScheduled, PostDistribution} from "../events/types";
import {EventProcessor, InvalidEvent, Outgoing} from "./eventProcessor";

export class DistributionProcessor extends EventProcessor {
  protected readonly name = "distribution"; // shows up in the logs

  // post-distribution: someone posted a distribution or a donation event
  // Check it, save it, then send DistributionScheduled so Notification can tell people nearby
  async onPostDistribution(e: EventEnvelope<PostDistribution>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;
      checkPostDistribution(d); // throws InvalidEvent if something is wrong

      // TODO: Review when database is complete. Find or create the Location for d.address and use its ID
      //   instead of this one (Location is Listing's table in Table 1, so the team needs to agree who saves it)
      const locationId = randomUUID();

      // TODO: Review when database is complete. Save the DistributionEvent (EventID d.distributionId,
      //   EventType d.kind, TimeStart, TimeEnd, LocationID). If it's already saved, the event came twice: return []

      const scheduled: DistributionScheduled = {
        distributionId: d.distributionId,
        hostId: d.hostId,
        organizationId: d.organizationId,
        kind: d.kind,
        title: d.title,
        address: d.address,
        startTime: d.startTime,
        endTime: d.endTime,
        locationId,
        gridCell: areaOf(d.address.postalCode),
      };
      // Passing `e` keeps the same correlationId and adds one hop
      return [out(Topics.distributionScheduled, createEvent("DistributionScheduled", scheduled, e))];
    });
  }
}

// A Canadian postal code, e.g. "T2N 1N4" (the same check Listing does)
const POSTAL_CODE = /^[A-Z]\d[A-Z] \d[A-Z]\d$/;

// Throws InvalidEvent if a PostDistribution is missing something or has a wrong value
function checkPostDistribution(d: PostDistribution): void {
  if (!d.title?.trim()) throw new InvalidEvent("title is missing");
  if (d.kind !== "DISTRIBUTION" && d.kind !== "DONATION_EVENT") {
    throw new InvalidEvent(`kind must be DISTRIBUTION or DONATION_EVENT, not "${d.kind}"`);
  }
  const postalCode = d.address?.postalCode ?? "";
  if (!POSTAL_CODE.test(postalCode)) {
    throw new InvalidEvent(`postal code "${postalCode}" is not in the form A1A 1A1`);
  }
  const start = Date.parse(d.startTime ?? ""); // NaN if it isn't a date
  const end = Date.parse(d.endTime ?? "");
  if (Number.isNaN(start) || Number.isNaN(end)) {
    throw new InvalidEvent("startTime and endTime must be ISO 8601 dates");
  }
  if (end <= start) throw new InvalidEvent("an event must end after it starts");
}

// The area used to tell users nearby, for now the first part of the postal code, e.g. "T2N"
// TODO: Swap it for a map grid cell once locations have coordinates, same as Listing
function areaOf(postalCode: string): string {
  return postalCode.slice(0, 3).toUpperCase();
}

// Pairs a topic with an event, ready for handle() to send
function out(topic: Topic, event: EventEnvelope): Outgoing {
  return {topic, event};
}