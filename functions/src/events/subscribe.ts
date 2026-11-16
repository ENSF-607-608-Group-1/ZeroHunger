// Connects one Pub/Sub topic to one processor method.
// Every arrow in Table 2 (e.g. post-food → ListingProcessor.onPostFood) becomes
// one call to subscribe(), and each call becomes its own Cloud Function
import * as logger from "firebase-functions/logger";
import {onMessagePublished} from "firebase-functions/pubsub"; // runs a function whenever a message arrives on a topic
import {EventEnvelope, MAX_HOPS} from "./envelope";
import {Topic} from "./topics";

// subscribe() returns a Cloud Function that runs every time an event arrives on `topic`.
//   topic   : the topic to listen to, e.g. Topics.postFood
//   handler : the processor method to call with the event, e.g. listing.onPostFood
//
// <T> is the type of the event's data, e.g. subscribe<PostFood>(...).
//
// retry: true means: if the handler throws an error, Pub/Sub delivers the
// same event again until it works. (Later we'll stop after 5 tries and send
// it to a dead-letter topic instead.)
export function subscribe<T>(topic: Topic, handler: (e: EventEnvelope<T>) => Promise<void>) {
  return onMessagePublished<EventEnvelope<T>>({topic, retry: true}, async (cloudEvent) => {

    // 1. Read the envelope out of the Pub/Sub message. If the message isn't valid JSON, reading it throws, so we catch
    let event: EventEnvelope<T> | undefined;
    try {
      event = cloudEvent.data.message.json;
    } catch {
      event = undefined;
    }

    // 2. Ignore anything that isn't one of our envelopes.Log it and stop WITHOUT an error
    if (!event || typeof event.eventId !== "string" || typeof event.hopCount !== "number") {
      logger.error(`Dropped a message on ${topic} that is not an event envelope`, {
        messageId: cloudEvent.data.message.messageId,
      });
      return;
    }

    // 3. Drop events that have been passed along too many times (probably a loop).
    if (event.hopCount > MAX_HOPS) {
      logger.error(`Dropped ${event.eventType} on ${topic}: hopCount ${event.hopCount} is above ${MAX_HOPS}`, {
        eventId: event.eventId,
        correlationId: event.correlationId,
      });
      return;
    }

    // 4. Hand the event to the processor method.
    await handler(event);
  });
}