//
//One Pub/Sub topic per event type (please check the architecture section table 2 of the project description).
//Every topic name in the code comes from here, so a typo can't create astray topic

//KEY: the topic names are used in the processors to publish events, and in the event handlers to subscribe to events. 
//So if you change a topic name here, you must also change it in the processors and event handlers

//postFood     : "post-food",
//Name in code : the topic's real name in Pub/Sub


export const Topics = {
//initiating events: published by the callable API or a scheduler
  postFood: "post-food",
  updateQuantity: "update-quantity",
  cancelOrRescheduleDonation: "cancel-or-reschedule-donation",
  postDistribution: "post-distribution",
  sendMessage: "send-message",
  donationDueDate: "donation-due-date",
  expiryCheck: "expiry-check",

//derived events: these events are published by processors
  foodAvailable: "food-available",
  foodClaimed: "food-claimed",
  quantityUpdated: "quantity-updated",
  donationStatusChanged: "donation-status-changed",
  donationCancelled: "donation-cancelled",
  donationRescheduled: "donation-rescheduled",
  reservationUpdated: "reservation-updated",
  distributionScheduled: "distribution-scheduled",
  messageSent: "message-sent",
  usersNotified: "users-notified",
  activityRecorded: "activity-recorded",
} as const;

//Any one of the topic names above
export type Topic = (typeof Topics)[keyof typeof Topics];