// schedulers.ts
// Scheduled functions: they start a workflow on a timer instead of from the app
//
//   ExpiryScheduler   → expiry-check       → ListingProcessor.onExpiryCheck
//   ReminderScheduler → donation-due-date  → NotificationProcessor.onDonationDueDate
//
// Cloud Scheduler runs them, and index.ts turns each one into its own function

import * as logger from "firebase-functions/logger";
import {createEvent} from "../events/envelope";
import {publishEvent} from "../events/publisher";
import {Topics} from "../events/topics";
import {DonationDueDate, ExpiryCheck} from "../events/types";
import {PublishFn} from "../processors/eventProcessor";

// ExpiryScheduler: asks Listing to expire every listing whose pickup time has passed
export class ExpiryScheduler {
  // publish: the function used to send events, normally publishEvent. A test can pass in a fake one
  constructor(private readonly publish: PublishFn = publishEvent) {}

  async run(): Promise<void> {
    const check: ExpiryCheck = {asOf: new Date().toISOString()};
    await this.publish(Topics.expiryCheck, createEvent("ExpiryCheck", check)); // a new workflow each run
  }
}

// ReminderScheduler: reminds donors when their next donation is due
export class ReminderScheduler {
  // publish: the function used to send events, normally publishEvent. A test can pass in a fake one
  constructor(private readonly publish: PublishFn = publishEvent) {}

  async run(): Promise<void> {
    // TODO: Review when database is complete. Load the donors whose donation reminder is due today
    //   instead of this empty list
    const due: DonationDueDate[] = [];

    for (const d of due) {
      await this.publish(Topics.donationDueDate, createEvent("DonationDueDate", d)); // one event per donor
    }
    logger.info(`Reminder scheduler: ${due.length} donors to remind`);
  }
}