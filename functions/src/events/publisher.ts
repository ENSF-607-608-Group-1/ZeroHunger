// publisher.ts
// Sends (publishes) an event to a Pub/Sub topic.
// Every processor and every callable function uses this one function to send events.

import {PubSub} from "@google-cloud/pubsub";        // Google's library for talking to Pub/Sub
import * as logger from "firebase-functions/logger"; // writes to the logs (Firebase console → Functions → Logs)
import {EventEnvelope} from "./envelope";
import {Topic} from "./topics";

// One connection to Pub/Sub, made once and reused for every event.
// In the cloud it signs in automatically as your project,
// so there are no passwords or keys in the code.
const pubsub = new PubSub();

// publishEvent() sends one event to one topic.
//
//   topic : where to send it, e.g. Topics.foodAvailable
//   event : the envelope to send (build it with createEvent)
//
// It waits until Pub/Sub confirms it has stored the event, then returns the
// message ID Pub/Sub gave it. If Pub/Sub can't store the event, it throws an
// error instead, so the caller knows the event didn't go through.
//
// The topic must already exist. Deploying a function creates the topic that function
// listens to. A topic nobody listens to yet (like food-available) has to be created
// once in the Google Cloud console. Otherwise Pub/Sub answers NOT_FOUND.
export async function publishEvent(topic: Topic, event: EventEnvelope): Promise<string> {
  // publishMessage({json}) turns the envelope into JSON and sends it.
  // "await" waits for Pub/Sub's answer before moving on.
  const messageId = await pubsub.topic(topic).publishMessage({json: event});

  // Write a line to the logs, so you can follow events as they flow.
  logger.info(`Published ${event.eventType} to ${topic}`, {
    eventId: event.eventId,
    correlationId: event.correlationId,
    hopCount: event.hopCount,
    messageId,
  });

  return messageId;
}

// TODO: Review when database is complete.
//   Processors will first save each event in an "outbox" table, in the same
//   database transaction as their other changes, and publish it from there.
//   Then an event can't be lost if the function crashes between saving
//   a change and publishing the event.