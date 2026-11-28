// activity_service.dart
// Tracks what a user has given and done on Zero Hunger: their impact totals and history.
//
// Activity records are unavailable until the activity processor persists them.

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
    final summary = initialSummary;
    if (summary == null) {
      throw const ActivityUnavailableException();
    }
    final sortedHistory = List<ActivityEntry>.of(summary.history)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return ActivitySummary(
      totals: summary.totals,
      history: List<ActivityEntry>.unmodifiable(sortedHistory),
    );
  }
}

class ActivityUnavailableException implements Exception {
  const ActivityUnavailableException();
}
