import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerohunger/screens/events_screen.dart';
import 'package:zerohunger/services/query_service.dart';
import 'package:zerohunger/services/zero_hunger_api.dart';
import 'package:zerohunger/theme/app_theme.dart';

class _FakeQueryService extends QueryService {
  _FakeQueryService(this.events);
  final List<CommunityEvent> events;

  @override
  Future<List<CommunityEvent>> upcomingEvents() async => events;
}

List<CommunityEvent> _testEvents() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day, 14, 0);
  final end = DateTime(now.year, now.month, now.day, 17, 0);

  return [
    CommunityEvent(
      eventId: 'evt-1',
      title: 'Saturday Community Food Distribution',
      kind: EventKind.foodDistribution,
      startTime: start,
      endTime: end,
      address: const PickupAddress(
        line1: '5000 11 St SE',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2H 2Y5',
      ),
      organization: 'Calgary Food Bank',
      comments: 'Please bring reusable bags.',
      isHost: false,
      rsvpCount: 10,
    ),
    CommunityEvent(
      eventId: 'evt-2',
      title: 'Beltline Donation Drive',
      kind: EventKind.donationEvent,
      startTime: start,
      endTime: end,
      address: const PickupAddress(
        line1: '227 11 Ave SW',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2R 1B9',
      ),
      organization: 'Community Fridge YYC',
      comments: 'Drop off sealed dry goods.',
      isHost: true,
      rsvpCount: 5,
    ),
  ];
}

Widget _wrap(Widget child) => MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  testWidgets('Shows event cards and filters by event kind', (tester) async {
    await tester.pumpWidget(_wrap(
      EventsScreen(
        queryService: _FakeQueryService(_testEvents()),
        showAccountButton: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Saturday Community Food Distribution'), findsOneWidget);
    expect(find.text('Calgary Food Bank'), findsOneWidget);
    expect(find.text('5000 11 St SE\nCalgary, AB T2H 2Y5'), findsOneWidget);
    expect(find.text('Beltline Donation Drive'), findsOneWidget);

    // Filter to Donation event only.
    await tester.tap(find.text('Donation event').first);
    await tester.pumpAndSettle();

    expect(find.text('Beltline Donation Drive'), findsOneWidget);
    expect(find.text('Saturday Community Food Distribution'), findsNothing);
  });

  testWidgets('does not fake RSVP or follow state without backend callbacks', (tester) async {
    await tester.pumpWidget(_wrap(EventDetailsScreen(
      event: _testEvents().first,
      showAccountButton: false,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Follow organization'));
    await tester.pumpAndSettle();
    expect(find.text('Organization follows are not available yet.'), findsOneWidget);
    expect(find.text('Follow organization'), findsOneWidget);

    await tester.tap(find.text('RSVP'));
    await tester.pumpAndSettle();
    expect(find.text('Event RSVPs are not available yet.'), findsOneWidget);
    expect(find.text('RSVP'), findsOneWidget);
  });

  testWidgets('Opens event details, toggles RSVP and Follow organization', (tester) async {
    String? followedOrg;
    bool? followedState;
    String? rsvpEventId;
    bool? rsvpState;

    await tester.pumpWidget(_wrap(
      EventsScreen(
        queryService: _FakeQueryService(_testEvents()),
        showAccountButton: false,
        onToggleFollowOrg: (org, follow) async {
          followedOrg = org;
          followedState = follow;
        },
        onToggleRsvp: (id, rsvp) async {
          rsvpEventId = id;
          rsvpState = rsvp;
        },
      ),
    ));
    await tester.pumpAndSettle();

    // Open non-host event details.
    await tester.tap(find.text('Saturday Community Food Distribution'));
    await tester.pumpAndSettle();

    expect(find.text('Event details'), findsOneWidget);
    expect(find.text('Please bring reusable bags.'), findsOneWidget);
    expect(find.text('End early'), findsNothing); // non-host does not see End early

    // Follow organization.
    await tester.tap(find.text('Follow organization'));
    await tester.pumpAndSettle();

    expect(followedOrg, 'Calgary Food Bank');
    expect(followedState, isTrue);
    expect(find.text('Following organization'), findsOneWidget);

    // RSVP.
    await tester.tap(find.text('RSVP'));
    await tester.pumpAndSettle();

    expect(rsvpEventId, 'evt-1');
    expect(rsvpState, isTrue);
    expect(find.text('Going — Cancel RSVP'), findsOneWidget);
    expect(find.text('11 going'), findsOneWidget);

    // Navigate back and verify list reflects updated RSVP count & Going badge.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Going'), findsOneWidget);
    expect(find.text('11 going'), findsOneWidget);
  });

  testWidgets('Host can end an event early and disables RSVP', (tester) async {
    String? endedId;

    await tester.pumpWidget(_wrap(
      EventsScreen(
        queryService: _FakeQueryService(_testEvents()),
        showAccountButton: false,
        onEndEarly: (id) async {
          endedId = id;
        },
      ),
    ));
    await tester.pumpAndSettle();

    // Open hosted event.
    await tester.tap(find.text('Beltline Donation Drive'));
    await tester.pumpAndSettle();

    // Scroll down to Host controls and tap End early.
    await tester.scrollUntilVisible(find.text('End early'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Host controls'), findsOneWidget);
    expect(find.text('End early'), findsOneWidget);

    await tester.tap(find.text('End early'));
    await tester.pumpAndSettle();

    expect(find.text('End event early?'), findsOneWidget);

    // Confirm in bottom sheet.
    await tester.tap(find.widgetWithText(FilledButton, 'End early'));
    await tester.pumpAndSettle();

    expect(endedId, 'evt-2');
    expect(find.text('Event ended early'), findsOneWidget);
    expect(find.text('Event ended'), findsOneWidget);
  });
}
