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
import {subscribe} from "./events/subscribe";
import {Topics} from "./events/topics";
import {
  CancelOrRescheduleDonation,
  ClaimFoodRequest,
  DonationCancelled,
  DonationRescheduled,
  ExpiryCheck,
  FoodClaimed,
  PostFood,
  UpdateQuantity,
} from "./events/types";
import {ListingProcessor} from "./processors/listing";
import {ClaimProcessor} from "./processors/claim";
import {onCall} from "firebase-functions/https";
import {CancelOrRescheduleRequest, PostFoodRequest, UpdateQuantityRequest, ZeroHungerApi} from "./api/zeroHungerApi";



// All functions: region us-central1, at most 10 copies running at once (cost control).
setGlobalOptions({region: "us-central1", maxInstances: 10});



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




//API (ZeroHungerApi): the functions zero hunger flutter calls, named api-postFood, etc.
// Deploy: firebase.cmd deploy --only functions:api
const zeroHungerApi = new ZeroHungerApi();

export const api = {
  postFood: onCall<PostFoodRequest>((request) => zeroHungerApi.postFood(request)),
  updateQuantity: onCall<UpdateQuantityRequest>((request) => zeroHungerApi.updateQuantity(request)),
  cancelOrRescheduleDonation: onCall<CancelOrRescheduleRequest>(
    (request) => zeroHungerApi.cancelOrRescheduleDonation(request)),
  claimFood: onCall<ClaimFoodRequest>((request) => zeroHungerApi.claimFood(request)), // request-reply: the app waits
};