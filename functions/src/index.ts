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
// Every Cloud Function in the project is listed (exported) here.
// When you deploy, Firebase reads this file to find out which functions exist.

import {setGlobalOptions} from "firebase-functions";
import {subscribe} from "./events/subscribe";
import {Topics} from "./events/topics";
import {CancelOrRescheduleDonation, ExpiryCheck, FoodClaimed, PostFood, UpdateQuantity} from "./events/types";
import {ListingProcessor} from "./processors/listing";



// Settings for every function:
//   region: run everything in the same place (us-central1, Iowa). Without this, the
//           Firebase CLI puts Pub/Sub-triggered functions in us-east1 and the rest in us-central1.
//   maxInstances: at most 10 copies of one function running at once (cost control).
setGlobalOptions({region: "us-central1", maxInstances: 10});



// ---------------------------------------------------------------------------
// Listing processor: one Cloud Function per topic it listens to (Table 2).
// Grouping them under `listing` names them listing-onPostFood, listing-onUpdateQuantity, …
// and lets you deploy just these with:  firebase deploy --only functions:listing
// ---------------------------------------------------------------------------
const listingProcessor = new ListingProcessor();

export const listing = {
  // name in the cloud       topic it listens to                 method that handles it
  onPostFood: subscribe<PostFood>(Topics.postFood, (e) => listingProcessor.onPostFood(e)),
  onUpdateQuantity: subscribe<UpdateQuantity>(Topics.updateQuantity, (e) => listingProcessor.onUpdateQuantity(e)),
  onCancelOrReschedule: subscribe<CancelOrRescheduleDonation>(
    Topics.cancelOrRescheduleDonation, (e) => listingProcessor.onCancelOrReschedule(e)),
  onFoodClaimed: subscribe<FoodClaimed>(Topics.foodClaimed, (e) => listingProcessor.onFoodClaimed(e)),
  onExpiryCheck: subscribe<ExpiryCheck>(Topics.expiryCheck, (e) => listingProcessor.onExpiryCheck(e)),
};