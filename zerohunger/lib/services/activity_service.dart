// activity_service.dart
// Tracks what a user has given and done on Zero Hunger: their impact totals and history.
//
// Backed by the Activity processor once the cloud QueryService and database are ready
// (FoodAvailable, FoodClaimed, DonationStatusChanged -> ActivityProcessor).
//
// TODO: Review when database & Activity processor are complete. Replace the sample
//   data below with real cloud queries (screens only ask this class, so real backend
//   wiring changes this file only).

// What kind of milestone happened in the user's history.
enum ActivityKind {
  postedDonation, // donor posted a food listing
  foodGiven,      // claimed food was picked up / given out
  claim,          // user claimed a food listing
  eventHosted,    // user hosted a food distribution or donation event
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

  const ActivitySummary({
    required this.totals,
    required this.history,
  });
}

class ActivityService {
  ActivityService({
    this.initialSummary,
    this.simulatedDelay = const Duration(milliseconds: 250),
  });

  final ActivitySummary? initialSummary;
  final Duration simulatedDelay;

  // Loads the user's totals and history, newest history entry first.
  Future<ActivitySummary> myActivity() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final summary = initialSummary ?? _sampleActivity();
    final sortedHistory = List<ActivityEntry>.of(summary.history)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return ActivitySummary(
      totals: summary.totals,
      history: List<ActivityEntry>.unmodifiable(sortedHistory),
    );
  }
}

// Made-up activity data for building and testing My activity.
ActivitySummary _sampleActivity() {
  final now = DateTime.now();
  DateTime ago(Duration d) => now.subtract(d);

  return ActivitySummary(
    totals: const ActivityTotals(
      donationsPosted: 6,
      foodGiven: 34,
      claims: 4,
      eventsHosted: 2,
    ),
    history: [
      ActivityEntry(
        entryId: 'act-1',
        kind: ActivityKind.postedDonation,
        summary: 'Posted Rice and stew',
        detail: '10 portions · T2N, Calgary',
        occurredAt: ago(const Duration(hours: 2)),
      ),
      ActivityEntry(
        entryId: 'act-2',
        kind: ActivityKind.foodGiven,
        summary: 'Gave 6 portions of Homemade lentil soup',
        detail: 'Picked up by Alex Chen',
        occurredAt: ago(const Duration(days: 1, hours: 3)),
      ),
      ActivityEntry(
        entryId: 'act-3',
        kind: ActivityKind.claim,
        summary: 'Claimed Fresh bagels and bread',
        detail: '6 assorted bagels · T2G, Calgary',
        occurredAt: ago(const Duration(days: 2, hours: 5)),
      ),
      ActivityEntry(
        entryId: 'act-4',
        kind: ActivityKind.eventHosted,
        summary: 'Hosted Saturday Community Food Pantry',
        detail: 'Food distribution · NW Calgary',
        occurredAt: ago(const Duration(days: 5)),
      ),
      ActivityEntry(
        entryId: 'act-5',
        kind: ActivityKind.postedDonation,
        summary: 'Posted Vegetable biryani and raita',
        detail: '10 portions · T3A, Calgary',
        occurredAt: ago(const Duration(days: 8)),
      ),
      ActivityEntry(
        entryId: 'act-6',
        kind: ActivityKind.foodGiven,
        summary: 'Gave 8 items from Garden produce box',
        detail: 'Picked up by Priya Nair',
        occurredAt: ago(const Duration(days: 11)),
      ),
      ActivityEntry(
        entryId: 'act-7',
        kind: ActivityKind.claim,
        summary: 'Claimed Pasta and tomato sauce',
        detail: '3 portions · T2S, Calgary',
        occurredAt: ago(const Duration(days: 14)),
      ),
      ActivityEntry(
        entryId: 'act-8',
        kind: ActivityKind.eventHosted,
        summary: 'Hosted Campus Zero-Waste Share',
        detail: 'Donation event · University District',
        occurredAt: ago(const Duration(days: 21)),
      ),
    ],
  );
}
