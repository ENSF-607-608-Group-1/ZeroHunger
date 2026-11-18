//envelope.ts defines the wrapper every event travels in


import {randomUUID} from "crypto";

// If an event has been passed along more than 10 times, it's probably stuck
// in a loop between processors, so we throw it away. ("export" means other files can use it.)
export const MAX_HOPS = 10;


// The shape of every envelope.
// <T> means "the type of what's inside". For example, EventEnvelope<PostFood>
// is an envelope with a PostFood inside.
export interface EventEnvelope<T = unknown> {
  eventId: string;        // a unique ID for this one event, so we can spot it if it arrives twice

  eventType: string;      // the name of what happened, e.g. "FoodAvailable"

  version: number;        // which layout "data" uses (everything starts at 1)


  occurredAt: string;     // the date and time it happened

  correlationId: string;  // the same ID on e very event in one chain, e.g PostFood -> FoodAvailable

  hopCount: number;       // how many times the chain has been passed along (starts at 0)

  data: T;                // the event's own details, e.gthe food's title and pickup times
}


// createEvent() builds a new envelope, so we never fill in these fields by hand
//KEY;     //   eventType: the name of the event e.g "FoodAvailable"
           //   data     : the events details
           //   cause    : (optional, hence the "?") the event we're reacting to

export function createEvent<T>(eventType: string, data: T, cause?: EventEnvelope): EventEnvelope<T> {
  return {
    eventId: randomUUID(), // a new unique ID every time
    eventType,   // short veersion  for eventType: eventType
    version: 1,
    occurredAt: new Date().toISOString(),

    // "cause ? A : B" 
    // means: if there is a cause, use A; otherwise use B.
    correlationId: cause ? cause.correlationId : randomUUID(),
    hopCount: cause ? cause.hopCount + 1 : 0,

    data, // passed on
  };
}