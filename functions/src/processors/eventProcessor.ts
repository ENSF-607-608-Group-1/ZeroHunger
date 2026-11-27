// eventProcessor.ts
// The parent class every processor extends (ListingProcessor, ClaimProcessor, ...).
// It holds the steps that are the same for every event, so each processor
// only has to write its own logic.

import * as logger from "firebase-functions/logger";
import {createEvent, EventEnvelope} from "../events/envelope";
import {publishEvent} from "../events/publisher";
import {Topic, Topics} from "../events/topics";
import {ProcessingError} from "../events/types";

// An event to send once the current event has been handled.
export interface Outgoing {
  topic: Topic;          // where to send it
  event: EventEnvelope;  // what to send
}

// Throw this when an event's data is wrong, e.g. a badly typed postal code.
// Sending the same event again would fail the same way, so it is NOT retried.
export class InvalidEvent extends Error {}

// The shape of a function that sends an event, like publishEvent.
export type PublishFn = (topic: Topic, event: EventEnvelope) => Promise<string>;

// "abstract" means you never create an EventProcessor on its own,
// only the processors that extend it, e.g. new ListingProcessor().
export abstract class EventProcessor {
  // Each processor gives itself a name, e.g. "listing". It shows up in the logs.
  // "protected" means only this class and the processors that extend it can use it.
  protected abstract readonly name: string;

  // publish: the function used to send events. Normally publishEvent.
  // A test can pass in a fake one, so nothing is really sent.
  constructor(protected readonly publish: PublishFn = publishEvent) {}

  // handle() runs one event the same way for every processor:
  //   1. run the processor's own work, which returns the events to send next
  //   2. send those events
  //
  // If the work throws InvalidEvent (bad data), the event is reported and skipped.
  // If it throws anything else (e.g. the database is down), the error is passed on,
  // so Pub/Sub delivers the event again later.
  protected async handle<T>(e: EventEnvelope<T>, work: () => Promise<Outgoing[]>): Promise<void> {
    // TODO: Review when database is complete. Skip the event if (e.eventId, this.name)
    //   is already in the ProcessedEvent table: Pub/Sub can deliver an event twice.

    let outgoing: Outgoing[];
    try {
      // TODO: Review when database is complete. Run `work` in one database transaction that
      //   also records e.eventId in ProcessedEvent and saves `outgoing` to the outbox table.
      outgoing = await work();
    } catch (err) {
      if (err instanceof InvalidEvent) {
        await this.reportError(e, err.message); // bad data: report it and stop
        return;
      }
      throw err; // anything else: let Pub/Sub retry
    }

    // TODO: Review when database is complete. Send from the outbox after the transaction instead.
    for (const o of outgoing) {
      await this.publish(o.topic, o.event);
    }
  }

  // Workflow event pattern (from the project description): pass a bad event to the
  // workflow processor so it can be fixed, and carry on with the next event.
  protected async reportError(e: EventEnvelope, reason: string): Promise<void> {
    logger.warn(`${this.name} could not process ${e.eventType}: ${reason}`, {
      eventId: e.eventId,
      correlationId: e.correlationId,
    });
    // TODO: Publish a ProcessingError to the workflow-errors topic once the workflow processor exists.
    const report: ProcessingError = {failedEvent: e, processor: this.name, reason};
    await this.publish(Topics.workflowErrors, createEvent("ProcessingError", report, e)); // same correlationId, one more hop
  }
}