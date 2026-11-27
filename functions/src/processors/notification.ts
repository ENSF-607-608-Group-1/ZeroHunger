// notification.ts
// The Notification processor: decides who to tell about each event and what to say
//
// Tables it owns (Table 1): Notification, only this processor writes to it
//
// How it's reached, one handler per event (Table 2):
//   food-available           → onFoodAvailable
//   food-claimed             → onFoodClaimed
//   quantity-updated         → onQuantityUpdated
//   donation-status-changed  → onDonationStatusChanged
//   donation-cancelled       → onDonationCancelled
//   donation-rescheduled     → onDonationRescheduled
//   distribution-scheduled   → onDistributionScheduled
//   message-sent             → onMessageSent
//   donation-due-date        → onDonationDueDate
//
// Events it sends: UsersNotified
//
// Who gets a notification is a list of FCM topics. These are groups of phones, not Pub/Sub topics:
//   area-<gridCell>        everyone nearby, e.g. area-T2N
//   org-<organizationId>   an organization's followers
//   donation-<donationId>  everyone following a donation (a recipient follows it when they claim)
//   user-<userId>          one person
// The app subscribes each phone to its topics in Part 12b

import {randomUUID} from "crypto";
import {getMessaging} from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";
import {createEvent, EventEnvelope} from "../events/envelope";
import {Topics} from "../events/topics";
import {
  DistributionScheduled,
  DonationCancelled,
  DonationDueDate,
  DonationRescheduled,
  DonationState,
  DonationStatusChanged,
  FoodAvailable,
  FoodClaimed,
  MessageSent,
  QuantityUpdated,
  UsersNotified,
} from "../events/types";
import {EventProcessor, InvalidEvent, Outgoing, PublishFn} from "./eventProcessor";

export class NotificationProcessor extends EventProcessor {
  protected readonly name = "notification"; // shows up in the logs

  // pushFn: how a notification reaches phones, normally sendPush (FCM). A test can pass in a fake one
  constructor(publish?: PublishFn, private readonly pushFn: PushFn = sendPush) {
    super(publish);
  }

  // Every handler below runs through here: each push goes out through FCM first,
  // then EventProcessor.handle sends UsersNotified as usual
  protected async handle<T>(e: EventEnvelope<T>, work: () => Promise<Outgoing[]>): Promise<void> {
    await super.handle(e, async () => {
      const outgoing = await work();
      for (const o of outgoing) await this.push(o.event as EventEnvelope<UsersNotified>);
      return outgoing;
    });
  }

  // Sends one notification to phones. A push FCM will never take is reported instead of retried
  private async push(n: EventEnvelope<UsersNotified>): Promise<void> {
    try {
      const ids = await this.pushFn(n.data);
      logger.info(`Sent push ${n.data.kind} to ${n.data.fcmTopics.join(", ")}`, {
        notificationId: n.data.notificationId,
        correlationId: n.correlationId,
        fcmMessageIds: ids,
      });
    } catch (err) {
      const code = (err as {code?: string}).code ?? "";
      if (FCM_REFUSED.includes(code)) throw new InvalidEvent(`FCM refused the push (${code})`);
      throw err; // anything else, e.g. FCM is busy: let Pub/Sub retry
    }
  }

  // food-available: tell people nearby about new food
  async onFoodAvailable(e: EventEnvelope<FoodAvailable>): Promise<void> {
    await this.handle(e, async () => {
      const f = e.data;
      // TODO: Review when database is complete. Only tell people whose preferences match (FR12):
      //   food in their categories, and none of their allergens in f.allergens
      return [notify(e, {
        kind: "FOOD_AVAILABLE",
        fcmTopics: [fcmTopic("area", f.gridCell)],
        title: "New food near you",
        body: `${f.title}, pick up ${timeRange(f.pickupStart, f.pickupEnd)}`,
        data: {donationId: f.donationId},
      })];
    });
  }

  // food-claimed: tell the donor someone claimed their food
  async onFoodClaimed(e: EventEnvelope<FoodClaimed>): Promise<void> {
    await this.handle(e, async () => {
      const c = e.data;
      return [notify(e, {
        kind: "FOOD_CLAIMED",
        fcmTopics: [fcmTopic("user", c.donorId)],
        title: "Your food was claimed",
        body: c.remainingQuantity > 0 ?
          `Someone claimed ${c.quantityClaimed} from your donation, ${c.remainingQuantity} left` :
          "Someone claimed the last of your donation",
        data: {donationId: c.donationId, reservationId: c.reservationId},
      })];
    });
  }

  // quantity-updated: tell the donation's followers how much is left
  async onQuantityUpdated(e: EventEnvelope<QuantityUpdated>): Promise<void> {
    await this.handle(e, async () => {
      const q = e.data;
      return [notify(e, {
        kind: "QUANTITY_UPDATED",
        fcmTopics: [fcmTopic("donation", q.donationId)],
        title: "Food update",
        body: `A donation you follow now has ${q.remainingQuantity} left`,
        data: {donationId: q.donationId},
      })];
    });
  }

  // donation-status-changed: tell the donation's followers its new status
  async onDonationStatusChanged(e: EventEnvelope<DonationStatusChanged>): Promise<void> {
    await this.handle(e, async () => {
      const s = e.data;
      const words = STATUS_WORDS[s.to];
      if (!words) throw new InvalidEvent(`"${s.to}" is not a donation state`);
      return [notify(e, {
        kind: "STATUS_CHANGED",
        fcmTopics: [fcmTopic("donation", s.donationId)],
        title: "Donation update",
        body: `A donation you follow is now ${words}`,
        data: {donationId: s.donationId, status: s.to},
      })];
    });
  }

  // donation-cancelled: tell the donation's followers, which includes everyone who claimed it
  async onDonationCancelled(e: EventEnvelope<DonationCancelled>): Promise<void> {
    await this.handle(e, async () => {
      const c = e.data;
      return [notify(e, {
        kind: "DONATION_CANCELLED",
        fcmTopics: [fcmTopic("donation", c.donationId)],
        title: "Donation cancelled",
        body: c.reason ? `A donation you follow was cancelled: ${c.reason}` : "A donation you follow was cancelled",
        data: {donationId: c.donationId},
      })];
    });
  }

  // donation-rescheduled: tell the donation's followers the new pickup time
  async onDonationRescheduled(e: EventEnvelope<DonationRescheduled>): Promise<void> {
    await this.handle(e, async () => {
      const r = e.data;
      return [notify(e, {
        kind: "DONATION_RESCHEDULED",
        fcmTopics: [fcmTopic("donation", r.donationId)],
        title: "Pickup time changed",
        body: `New pickup time: ${timeRange(r.pickupStart, r.pickupEnd)}`,
        data: {donationId: r.donationId},
      })];
    });
  }

  // distribution-scheduled: tell people nearby, and the organization's followers if there is one
  async onDistributionScheduled(e: EventEnvelope<DistributionScheduled>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;
      const fcmTopics = [fcmTopic("area", d.gridCell)];
      if (d.organizationId) fcmTopics.push(fcmTopic("org", d.organizationId));
      return [notify(e, {
        kind: "DISTRIBUTION_SCHEDULED",
        fcmTopics,
        title: d.kind === "DISTRIBUTION" ? "Food distribution near you" : "Donation event near you",
        body: `${d.title}, ${timeRange(d.startTime, d.endTime)} at ${d.address.line1}`,
        data: {distributionId: d.distributionId},
      })];
    });
  }

  // message-sent: push the message to the people it's for
  async onMessageSent(e: EventEnvelope<MessageSent>): Promise<void> {
    await this.handle(e, async () => {
      const m = e.data;
      if (!Array.isArray(m.receiverIds) || m.receiverIds.length === 0) return []; // nobody to tell
      return [notify(e, {
        kind: "NEW_MESSAGE",
        fcmTopics: m.receiverIds.map((id) => fcmTopic("user", id)),
        title: m.kind === "SYSTEM" ? "Pickup chat" : "New message",
        body: preview(m.text),
        data: {conversationId: m.conversationId, messageId: m.messageId, donationId: m.donationId},
      })];
    });
  }

  // donation-due-date: remind a donor it's time to donate again
  async onDonationDueDate(e: EventEnvelope<DonationDueDate>): Promise<void> {
    await this.handle(e, async () => {
      const d = e.data;
      return [notify(e, {
        kind: "DONATION_DUE",
        fcmTopics: [fcmTopic("user", d.donorId)],
        title: "Time to donate again",
        body: "Got food to spare? Post it on Zero Hunger",
        data: {},
      })];
    });
  }
}

// What a handler decides: what it's about, who to tell and what to say
type Draft = Omit<UsersNotified, "notificationId" | "sentAt">;

// Turns a draft into a UsersNotified event, ready for handle() to send
function notify(cause: EventEnvelope, draft: Draft): Outgoing {
  // TODO: Review when database is complete. Save it in the Notification table first, so the app
  //   can still list it if the push is missed (Figure 5, point 4)
  // TODO: Part 12b sends the push through FCM here, before UsersNotified goes out
  const notified: UsersNotified = {notificationId: randomUUID(), ...draft, sentAt: new Date().toISOString()};
  // Passing `cause` keeps the same correlationId and adds one hop
  return {topic: Topics.usersNotified, event: createEvent("UsersNotified", notified, cause)};
}

// How a notification reaches phones, giving back FCM's message IDs
type PushFn = (n: UsersNotified) => Promise<string[]>;

// FCM errors that mean the push itself is wrong, so sending it again won't help
const FCM_REFUSED = [
  "messaging/invalid-argument", "messaging/invalid-recipient",
  "messaging/invalid-payload", "messaging/payload-size-limit-exceeded",
];

// Sends a notification through FCM to every phone in its FCM topics
// Up to 5 topics go in one condition, e.g. "'area-T2N' in topics || 'org-7' in topics",
// so a phone in two of the topics still gets it once (FCM allows 5 topics per condition)
async function sendPush(n: UsersNotified): Promise<string[]> {
  const ids: string[] = [];
  for (let i = 0; i < n.fcmTopics.length; i += 5) {
    const group = n.fcmTopics.slice(i, i + 5);
    const to = group.length === 1 ? {topic: group[0]} : {condition: group.map((t) => `'${t}' in topics`).join(" || ")};
    ids.push(await getMessaging().send({
      ...to,
      notification: {title: n.title, body: n.body},
      data: {...n.data, kind: n.kind, notificationId: n.notificationId}, // what the app reads when it's tapped
    }));
  }
  return ids;
}

// An FCM topic name, e.g. fcmTopic("area", "T2N") gives "area-T2N"
// FCM only allows letters, numbers and - _ . ~ % in a name, so anything else becomes _
function fcmTopic(group: "area" | "org" | "donation" | "user", id: string): string {
  return `${group}-${id.replace(/[^A-Za-z0-9\-_.~%]/g, "_")}`;
}

// Times in notifications are shown in Calgary time, e.g. "Fri, Nov 27" and "10:00 a.m."
const DAY = new Intl.DateTimeFormat("en-CA", {timeZone: "America/Edmonton", weekday: "short", month: "short", day: "numeric"});
const TIME = new Intl.DateTimeFormat("en-CA", {timeZone: "America/Edmonton", hour: "numeric", minute: "2-digit"});

// A time window people can read, e.g. "Fri, Nov 27, 10:00 a.m. to 2:00 p.m."
function timeRange(start: string, end: string): string {
  const from = new Date(start);
  const to = new Date(end);
  if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
    throw new InvalidEvent(`"${start}" to "${end}" is not a time window`);
  }
  const fromDay = DAY.format(from);
  const toDay = DAY.format(to);
  if (fromDay === toDay) return `${fromDay}, ${TIME.format(from)} to ${TIME.format(to)}`;
  return `${fromDay}, ${TIME.format(from)} to ${toDay}, ${TIME.format(to)}`; // runs past midnight
}

// The words for each donation state, e.g. CLAIMED becomes "fully claimed"
const STATUS_WORDS: Record<DonationState, string> = {
  AVAILABLE: "available again",
  CLAIMED: "fully claimed",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
  EXPIRED: "expired",
};

// The start of a long message, so the push stays short on the phone
function preview(text: string): string {
  return text.length > 120 ? `${text.slice(0, 117)}...` : text;
}