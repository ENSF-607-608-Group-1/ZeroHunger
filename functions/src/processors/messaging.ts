// messaging.ts
// The Messaging processor: saves chat messages and opens a pickup chat after each claim
//
// Tables it owns (Table 1): Conversation and Message, only this processor writes to them
//
// How it's reached:
//   send-message → onSendMessage
//   food-claimed → onFoodClaimed (opens the pickup chat)
//
// Events it sends: MessageSent
//
// Who can write where (decided): people with an account in any chat they're part of,
// guests only in the pickup chat for their own claim

import {randomUUID} from "crypto";
import {createEvent, EventEnvelope} from "../events/envelope";
import {Topic, Topics} from "../events/topics";
import {FoodClaimed, MessageSent, SendMessage} from "../events/types";
import {EventProcessor, Outgoing} from "./eventProcessor";

export class MessagingProcessor extends EventProcessor {
  protected readonly name = "messaging"; // shows up in the logs

  // send-message: someone sent a message, so save it and let Notification tell the others
  async onSendMessage(e: EventEnvelope<SendMessage>): Promise<void> {
    await this.handle(e, async () => {
      const m = e.data;

      // TODO: Review when database is complete. Load the Conversation and throw InvalidEvent if it
      //   doesn't exist, the sender isn't in it, or a guest writes anywhere but their own pickup chat.
      //   Then save the Message (if m.messageId is already saved it's a repeat, so send nothing)
      // Stand-in values until then
      const donationId = "unknown-donation";     // Conversation.donationId
      const receiverIds = ["unknown-receiver"];  // everyone else in the chat

      const sent: MessageSent = {
        messageId: m.messageId,
        conversationId: m.conversationId,
        donationId,
        senderId: m.senderId,
        receiverIds,
        kind: "USER",
        text: m.text,
        sentAt: e.occurredAt, // when they pressed Send
      };
      return [out(Topics.messageSent, createEvent("MessageSent", sent, e))];
    });
  }

  // food-claimed: open a pickup chat for the donor and the recipient, with a first message from the app
  async onFoodClaimed(e: EventEnvelope<FoodClaimed>): Promise<void> {
    await this.handle(e, async () => {
      const c = e.data;

      // TODO: Review when database is complete. Save the Conversation (ID c.reservationId, type PICKUP,
      //   members c.donorId and c.recipientId) and this first message

      const opened: MessageSent = {
        messageId: randomUUID(),
        conversationId: c.reservationId, // a pickup chat uses the reservation's ID
        donationId: c.donationId,
        senderId: "system",
        receiverIds: [c.donorId, c.recipientId],
        kind: "SYSTEM",
        text: "Pickup chat opened. Use it to arrange the pickup.",
        sentAt: new Date().toISOString(),
      };
      return [out(Topics.messageSent, createEvent("MessageSent", opened, e))];
    });
  }
}

// Pairs a topic with an event, ready for handle() to send
function out(topic: Topic, event: EventEnvelope): Outgoing {
  return {topic, event};
}