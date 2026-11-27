// workflow.ts
// The Workflow processor: fixes events that other processors couldn't use (the workflow event pattern)
//
// Tables it owns: none yet. The repair dashboard will need one (a TODO below)
//
// How it's reached:
//   workflow-errors → onProcessingError
//   dead-letter     → onDeadLetter, for events Pub/Sub gave up on after 5 failed deliveries
//
// What it does with a bad event, like Figure 4 in the project description:
//   1. tries to fix the data itself, e.g. a postal code typed as t2n1n4 becomes T2N 1N4
//   2. if that works, sends the fixed event back to its original topic
//   3. if not, keeps it for the repair dashboard, where an administrator fixes it

import * as logger from "firebase-functions/logger";
import {createEvent, EventEnvelope} from "../events/envelope";
import {Topic, Topics} from "../events/topics";
import {Address, PostDistribution, PostFood, ProcessingError} from "../events/types";
import {EventProcessor, InvalidEvent} from "./eventProcessor";

export class WorkflowProcessor extends EventProcessor {
  protected readonly name = "workflow"; // shows up in the logs

  // workflow-errors: a processor couldn't use an event, so try to fix it
  async onProcessingError(e: EventEnvelope<ProcessingError>): Promise<void> {
    await this.handle(e, async () => {
      const report: Partial<ProcessingError> = e.data ?? {}; // any field might be missing
      const {failedEvent, processor, reason} = report;
      if (!failedEvent || typeof failedEvent.eventType !== "string") {
        throw new InvalidEvent("the report has no failed event in it");
      }
      const fix = tryToFix(failedEvent);

      if (fix) {
        logger.info(`Fixed ${failedEvent.eventType} from ${processor}: ${fix.change}`, {
          failedEventId: failedEvent.eventId,
          correlationId: e.correlationId,
        });
        // A new eventId, but the same correlationId with one more hop, so the whole story stays together
        return [{topic: fix.topic, event: createEvent(failedEvent.eventType, fix.data, e)}];
      }

      // TODO: Review when database is complete. Save it in a repair table, so the repair dashboard
      //   can show it and an administrator can fix it and send it back
      logger.warn(`Needs repair: ${failedEvent.eventType} from ${processor}: ${reason}`, {
        failedEventId: failedEvent.eventId,
        correlationId: e.correlationId,
      });
      return [];
    });
  }

  // dead-letter: an event failed 5 deliveries in a row, e.g. a bug or the database was down,
  // so Pub/Sub moved it here instead of retrying it forever
  async onDeadLetter(e: EventEnvelope): Promise<void> {
    await this.handle(e, async () => {
      // TODO: Review when database is complete. Save it in the repair table too, so an administrator
      //   can send it again once the problem is fixed
      // Pub/Sub also says which subscription gave up (CloudPubSubDeadLetterSourceSubscription),
      //   subscribe() would need to pass the message's attributes on for us to read it
      logger.warn(`Needs repair: ${e.eventType} failed 5 deliveries, so Pub/Sub dead-lettered it`, {
        failedEventId: e.eventId,
        correlationId: e.correlationId, // search this to see which processor kept failing
      });
      return [];
    });
  }

  // Workflow never reports to workflow-errors itself, or a bad report would go round in circles
  protected async reportError(e: EventEnvelope, reason: string): Promise<void> {
    logger.error(`workflow could not process ${e.eventType}: ${reason}`, {
      eventId: e.eventId,
      correlationId: e.correlationId,
    });
  }
}

// A fix that worked: the fixed data, the topic it goes back to, and what changed
interface Fix {
  topic: Topic;
  data: unknown;
  change: string;
}

// The fixes Workflow knows so far. Undefined means it can't fix this one
function tryToFix(failed: EventEnvelope): Fix | undefined {
  switch (failed.eventType) {
  case "PostFood":
    return fixPostalCode(failed.data as PostFood, Topics.postFood);
  case "PostDistribution":
    return fixPostalCode(failed.data as PostDistribution, Topics.postDistribution);
  default:
    return undefined;
  }
}

// A postal code typed the wrong way, e.g. "t2n1n4" or "T2N-1N4", becomes "T2N 1N4"
function fixPostalCode<T extends {address: Address}>(data: T, topic: Topic): Fix | undefined {
  const typed = data?.address?.postalCode;
  if (typeof typed !== "string") return undefined;

  const letters = typed.toUpperCase().replace(/[^A-Z0-9]/g, ""); // just the letters and digits
  if (!/^[A-Z]\d[A-Z]\d[A-Z]\d$/.test(letters)) return undefined; // not a postal code we can rescue

  const fixed = `${letters.slice(0, 3)} ${letters.slice(3)}`;
  if (fixed === typed) return undefined; // it was already right, so something else was wrong

  return {
    topic,
    data: {...data, address: {...data.address, postalCode: fixed}},
    change: `postal code "${typed}" became "${fixed}"`,
  };
}