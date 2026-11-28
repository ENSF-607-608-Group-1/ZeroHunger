// activity_service.dart
// Tracks what a user has given and done on Zero Hunger: their impact totals and history.
//
// Reads activity rows once the backend processor persists them.

import '../generated/zerohunger.dart';

// What kind of milestone happened in the user's history.
enum ActivityKind {
  postedDonation, // donor posted a food listing
  foodGiven, // claimed food was picked up / given out
  claim, // user claimed a food listing
  eventHosted, // user hosted a food distribution or donation event
}

// High-level impact totals shown at the top of My activity.
class ActivityTotals {
  final int donationsPosted;
  final int foodGiven; // total portions/items given away
  final int claims;
  final int eventsHosted;

  const ActivityTotals({
    required this.donationsPosted,
    required this.foodGiven,
    required this.claims,
    required this.eventsHosted,
  });
}

// One row in the user's activity history, e.g. "Posted Rice and stew".
class ActivityEntry {
  final String entryId;
  final ActivityKind kind;
  final String summary; // e.g. "Posted Rice and stew"
  final String? detail; // optional context, e.g. "10 portions · T2N, Calgary"
  final DateTime occurredAt;

  const ActivityEntry({
    required this.entryId,
    required this.kind,
    required this.summary,
    this.detail,
    required this.occurredAt,
  });
}

// Combined totals and chronological history for My activity.
class ActivitySummary {
  final ActivityTotals totals;
  final List<ActivityEntry> history;

  const ActivitySummary({required this.totals, required this.history});
}

class ActivityService {
  ActivityService({
    this.initialSummary,
    this.connector,
    this.simulatedDelay = const Duration(milliseconds: 250),
  });

  final ActivitySummary? initialSummary;
  final ZerohungerConnector? connector;
  final Duration simulatedDelay;

  // Loads the user's totals and history, newest history entry first.
  Future<ActivitySummary> myActivity() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final summary = initialSummary;
    if (summary != null) {
      return ActivitySummary(
        totals: summary.totals,
        history: List<ActivityEntry>.unmodifiable(
          List<ActivityEntry>.of(summary.history)
            ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
        ),
      );
    }

    final activeConnector = connector;
    if (activeConnector == null) throw const ActivityUnavailableException();

    final result = await activeConnector.listMyActivity().execute();
    return fromDatabaseRecords(result.data.userActivities);
  }

  static ActivitySummary fromDatabaseRecords(
    List<ListMyActivityUserActivities> records,
  ) {
    final history = <ActivityEntry>[];
    var donationsPosted = 0;
    var foodGiven = 0;
    var claims = 0;
    var eventsHosted = 0;

    for (final record in records) {
      final type = record.activityType.toUpperCase();
      final donation = record.donation;
      final title = donation?.donationTitle;
      final kind = switch (type) {
        'FOOD_POSTED' => ActivityKind.postedDonation,
        'FOOD_CLAIMED' => ActivityKind.claim,
        'STATUS_CHANGED'
            when donation?.status.name.toUpperCase() == 'COMPLETED' =>
          ActivityKind.foodGiven,
        'EVENT_POSTED' => ActivityKind.eventHosted,
        _ => null,
      };
      if (kind == null) continue;

      switch (kind) {
        case ActivityKind.postedDonation:
          donationsPosted++;
          break;
        case ActivityKind.foodGiven:
          foodGiven += donation?.itemQuantities.toInt() ?? 0;
          break;
        case ActivityKind.claim:
          claims++;
          break;
        case ActivityKind.eventHosted:
          eventsHosted++;
          break;
      }

      final eventType = record.event?.eventType;
      final summary = switch (kind) {
        ActivityKind.postedDonation => 'Posted ${title ?? 'a donation'}',
        ActivityKind.foodGiven => 'Gave ${title ?? 'food'}',
        ActivityKind.claim => 'Claimed ${title ?? 'food'}',
        ActivityKind.eventHosted => 'Hosted ${_eventLabel(eventType)}',
      };
      history.add(
        ActivityEntry(
          entryId: record.activityId.toString(),
          kind: kind,
          summary: summary,
          occurredAt: record.occurredAt.toDateTime(),
        ),
      );
    }

    return ActivitySummary(
      totals: ActivityTotals(
        donationsPosted: donationsPosted,
        foodGiven: foodGiven,
        claims: claims,
        eventsHosted: eventsHosted,
      ),
      history: List<ActivityEntry>.unmodifiable(history),
    );
  }

  static String _eventLabel(String? eventType) =>
      switch (eventType?.toUpperCase()) {
        'DONATION_EVENT' => 'a donation event',
        'FOOD_DISTRIBUTION' => 'a food distribution',
        _ => 'an event',
      };
}

class ActivityUnavailableException implements Exception {
  const ActivityUnavailableException();
}
