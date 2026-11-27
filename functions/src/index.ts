/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

//import {setGlobalOptions} from "firebase-functions";
// import {onRequest} from "firebase-functions/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
//setGlobalOptions({maxInstances: 10});

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });




//SAMPLE CODE ABOVE 


// index.ts
// Exports every Cloud Function. Firebase reads this file on deploy.

import {setGlobalOptions} from "firebase-functions";
import {onSchedule} from "firebase-functions/scheduler";
import {initializeApp} from "firebase-admin/app";
import {subscribe} from "./events/subscribe";
import {Topics} from "./events/topics";
import {
  CancelOrRescheduleDonation,
  ClaimFoodRequest,
  DistributionScheduled,
  DonationCancelled,
  DonationDueDate,
  DonationRescheduled,
  DonationStatusChanged,
  ExpiryCheck,
  FoodAvailable,
  FoodClaimed,
  MessageSent,
  PostDistribution,
  PostFood,
  ProcessingError,
  QuantityUpdated,
  SendMessage,
  UpdateQuantity,
} from "./events/types";
import {ListingProcessor} from "./processors/listing";
import {ClaimProcessor} from "./processors/claim";
import {MessagingProcessor} from "./processors/messaging";
import {DistributionProcessor} from "./processors/distribution";
import {NotificationProcessor} from "./processors/notification";
import {ActivityProcessor} from "./processors/activity";
import {WorkflowProcessor} from "./processors/workflow";
import {ExpiryScheduler, ReminderScheduler} from "./schedulers/schedulers";
import {onCall} from "firebase-functions/https";
import {CancelOrRescheduleRequest, PostDistributionRequest, PostFoodRequest, SendMessageRequest, UpdateQuantityRequest, ZeroHungerApi} from "./api/zeroHungerApi";



// All functions: region us-central1, at most 10 copies running at once (cost control).
setGlobalOptions({region: "us-central1", maxInstances: 10});

// Firebase Admin, set up once so Notification can send pushes through FCM
initializeApp();



// Listing processor: one function per topic (Table 2), named listing-onPostFood, etc.
// Deploy: firebase.cmd deploy --only functions:listing
const listingProcessor = new ListingProcessor();

export const listing = {
  onPostFood: subscribe<PostFood>(Topics.postFood, (e) => listingProcessor.onPostFood(e)),
  onUpdateQuantity: subscribe<UpdateQuantity>(Topics.updateQuantity, (e) => listingProcessor.onUpdateQuantity(e)),
  onCancelOrReschedule: subscribe<CancelOrRescheduleDonation>(
    Topics.cancelOrRescheduleDonation, (e) => listingProcessor.onCancelOrReschedule(e)),
  onFoodClaimed: subscribe<FoodClaimed>(Topics.foodClaimed, (e) => listingProcessor.onFoodClaimed(e)),
  onExpiryCheck: subscribe<ExpiryCheck>(Topics.expiryCheck, (e) => listingProcessor.onExpiryCheck(e)),
};



// Claim processor: one function per topic (Table 2), named claim-onDonationCancelled, etc.
// claimFood is reached through api-claimFood below.
// Deploy: firebase.cmd deploy --only functions:claim
const claimProcessor = new ClaimProcessor();

export const claim = {
  onDonationCancelled: subscribe<DonationCancelled>(
    Topics.donationCancelled, (e) => claimProcessor.onDonationCancelled(e)),
  onDonationRescheduled: subscribe<DonationRescheduled>(
    Topics.donationRescheduled, (e) => claimProcessor.onDonationRescheduled(e)),
};



// Messaging processor: one function per topic (Table 2), like messaging-onSendMessage
// food-claimed now has two listeners: Listing and Messaging, each with its own subscription
// Deploy: firebase.cmd deploy --only functions:messaging
const messagingProcessor = new MessagingProcessor();

export const messaging = {
  onSendMessage: subscribe<SendMessage>(Topics.sendMessage, (e) => messagingProcessor.onSendMessage(e)),
  onFoodClaimed: subscribe<FoodClaimed>(Topics.foodClaimed, (e) => messagingProcessor.onFoodClaimed(e)),
};



// Distribution processor: one function per topic (Table 2), like distribution-onPostDistribution
// Deploy: firebase.cmd deploy --only functions:distribution
const distributionProcessor = new DistributionProcessor();

export const distribution = {
  onPostDistribution: subscribe<PostDistribution>(
    Topics.postDistribution, (e) => distributionProcessor.onPostDistribution(e)),
};



// Notification processor: one function per topic (Table 2), like notification-onFoodAvailable
// food-claimed has three listeners now: Listing, Messaging and Notification
// Deploy: firebase.cmd deploy --only functions:notification
const notificationProcessor = new NotificationProcessor();

export const notification = {
  onFoodAvailable: subscribe<FoodAvailable>(Topics.foodAvailable, (e) => notificationProcessor.onFoodAvailable(e)),
  onFoodClaimed: subscribe<FoodClaimed>(Topics.foodClaimed, (e) => notificationProcessor.onFoodClaimed(e)),
  onQuantityUpdated: subscribe<QuantityUpdated>(
    Topics.quantityUpdated, (e) => notificationProcessor.onQuantityUpdated(e)),
  onDonationStatusChanged: subscribe<DonationStatusChanged>(
    Topics.donationStatusChanged, (e) => notificationProcessor.onDonationStatusChanged(e)),
  onDonationCancelled: subscribe<DonationCancelled>(
    Topics.donationCancelled, (e) => notificationProcessor.onDonationCancelled(e)),
  onDonationRescheduled: subscribe<DonationRescheduled>(
    Topics.donationRescheduled, (e) => notificationProcessor.onDonationRescheduled(e)),
  onDistributionScheduled: subscribe<DistributionScheduled>(
    Topics.distributionScheduled, (e) => notificationProcessor.onDistributionScheduled(e)),
  onMessageSent: subscribe<MessageSent>(Topics.messageSent, (e) => notificationProcessor.onMessageSent(e)),
  onDonationDueDate: subscribe<DonationDueDate>(
    Topics.donationDueDate, (e) => notificationProcessor.onDonationDueDate(e)),
};



// Activity processor: one function per topic (Table 2), like activity-onFoodAvailable
// food-claimed has four listeners now: Listing, Messaging, Notification and Activity
// Deploy: firebase.cmd deploy --only functions:activity
const activityProcessor = new ActivityProcessor();

export const activity = {
  onFoodAvailable: subscribe<FoodAvailable>(Topics.foodAvailable, (e) => activityProcessor.onFoodAvailable(e)),
  onFoodClaimed: subscribe<FoodClaimed>(Topics.foodClaimed, (e) => activityProcessor.onFoodClaimed(e)),
  onDonationStatusChanged: subscribe<DonationStatusChanged>(
    Topics.donationStatusChanged, (e) => activityProcessor.onDonationStatusChanged(e)),
  onDistributionScheduled: subscribe<DistributionScheduled>(
    Topics.distributionScheduled, (e) => activityProcessor.onDistributionScheduled(e)),
};



// Workflow processor: fixes events other processors couldn't use, like workflow-onProcessingError
// Deploy: firebase.cmd deploy --only functions:workflow
const workflowProcessor = new WorkflowProcessor();

export const workflow = {
  onProcessingError: subscribe<ProcessingError>(
    Topics.workflowErrors, (e) => workflowProcessor.onProcessingError(e)),
  // events Pub/Sub gave up on after 5 failed deliveries, which can be any kind of event
  onDeadLetter: subscribe(Topics.deadLetter, (e) => workflowProcessor.onDeadLetter(e)),
};



// Schedulers: Cloud Scheduler runs these on a timer in Calgary time, like schedulers-expiryCheck
// Deploy: firebase.cmd deploy --only functions:schedulers
const expiryScheduler = new ExpiryScheduler();
const reminderScheduler = new ReminderScheduler();

export const schedulers = {
  // every 15 minutes: expire listings whose pickup time has passed
  expiryCheck: onSchedule({schedule: "every 15 minutes", timeZone: "America/Edmonton"}, () => expiryScheduler.run()),
  // every morning at 9: remind donors whose next donation is due
  donationReminder: onSchedule({schedule: "every day 09:00", timeZone: "America/Edmonton"}, () => reminderScheduler.run()),
};




//API (ZeroHungerApi): the functions zero hunger flutter calls, named api-postFood, etc.
// Deploy: firebase.cmd deploy --only functions:api
const zeroHungerApi = new ZeroHungerApi();

export const api = {
  postFood: onCall<PostFoodRequest>((request) => zeroHungerApi.postFood(request)),
  updateQuantity: onCall<UpdateQuantityRequest>((request) => zeroHungerApi.updateQuantity(request)),
  cancelOrRescheduleDonation: onCall<CancelOrRescheduleRequest>(
    (request) => zeroHungerApi.cancelOrRescheduleDonation(request)),
  claimFood: onCall<ClaimFoodRequest>((request) => zeroHungerApi.claimFood(request)), // request-reply: the app waits
  sendMessage: onCall<SendMessageRequest>((request) => zeroHungerApi.sendMessage(request)),
  postDistribution: onCall<PostDistributionRequest>((request) => zeroHungerApi.postDistribution(request)),
};