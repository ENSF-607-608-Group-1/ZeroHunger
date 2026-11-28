import 'package:firebase_data_connect/firebase_data_connect.dart'
    show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:zerohunger/generated/zerohunger.dart';
import 'package:zerohunger/services/activity_service.dart';

ListMyActivityUserActivities _activity({
  required int id,
  required String type,
  required String time,
  ListMyActivityUserActivitiesDonation? donation,
  ListMyActivityUserActivitiesEvent? event,
}) {
  return ListMyActivityUserActivities(
    activityId: BigInt.from(id),
    activityType: type,
    occurredAt: Timestamp.fromJson(time),
    donation: donation,
    event: event,
  );
}

ListMyActivityUserActivitiesDonation _donation({
  required String title,
  required int quantity,
  required String status,
}) {
  return ListMyActivityUserActivitiesDonation(
    donationTitle: title,
    itemQuantities: BigInt.from(quantity),
    status: ListMyActivityUserActivitiesDonationStatus(name: status),
  );
}

void main() {
  test('maps persisted activity rows into history and impact totals', () {
    final summary = ActivityService.fromDatabaseRecords([
      _activity(
        id: 5,
        type: 'EVENT_POSTED',
        time: '2026-11-27T15:00:00Z',
        event: ListMyActivityUserActivitiesEvent(eventType: 'DONATION_EVENT'),
      ),
      _activity(
        id: 4,
        type: 'STATUS_CHANGED',
        time: '2026-11-27T14:00:00Z',
        donation: _donation(
          title: 'Cancelled listing',
          quantity: 5,
          status: 'CANCELLED',
        ),
      ),
      _activity(
        id: 3,
        type: 'STATUS_CHANGED',
        time: '2026-11-27T13:00:00Z',
        donation: _donation(
          title: 'Lentil soup',
          quantity: 6,
          status: 'COMPLETED',
        ),
      ),
      _activity(
        id: 2,
        type: 'FOOD_CLAIMED',
        time: '2026-11-27T12:00:00Z',
        donation: _donation(
          title: 'Fresh bagels',
          quantity: 8,
          status: 'CLAIMED',
        ),
      ),
      _activity(
        id: 1,
        type: 'FOOD_POSTED',
        time: '2026-11-27T11:00:00Z',
        donation: _donation(
          title: 'Rice and stew',
          quantity: 10,
          status: 'AVAILABLE',
        ),
      ),
    ]);

    expect(summary.totals.donationsPosted, 1);
    expect(summary.totals.foodGiven, 6);
    expect(summary.totals.claims, 1);
    expect(summary.totals.eventsHosted, 1);
    expect(summary.history.map((entry) => entry.entryId), ['5', '3', '2', '1']);
    expect(summary.history.first.summary, 'Hosted a donation event');
    expect(summary.history.last.summary, 'Posted Rice and stew');
  });
}
