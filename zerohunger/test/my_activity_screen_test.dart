import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/screens/home_screen.dart';
import 'package:zerohunger/screens/my_activity_screen.dart';
import 'package:zerohunger/services/activity_service.dart';
import 'package:zerohunger/theme/app_theme.dart';
import 'package:zerohunger/widgets/account_button.dart';

class _FakeActivityService extends ActivityService {
  _FakeActivityService(this.loader) : super(simulatedDelay: Duration.zero);

  Future<ActivitySummary> Function() loader;

  @override
  Future<ActivitySummary> myActivity() => loader();
}

ActivitySummary _sampleSummary() {
  final now = DateTime.now();
  return ActivitySummary(
    totals: const ActivityTotals(
      donationsPosted: 6,
      foodGiven: 34,
      claims: 4,
      eventsHosted: 2,
    ),
    history: [
      ActivityEntry(
        entryId: 'e-1',
        kind: ActivityKind.postedDonation,
        summary: 'Posted Rice and stew',
        detail: '10 portions · T2N, Calgary',
        occurredAt: now.subtract(const Duration(hours: 2)),
      ),
      ActivityEntry(
        entryId: 'e-2',
        kind: ActivityKind.foodGiven,
        summary: 'Gave 6 portions of Homemade lentil soup',
        detail: 'Picked up by Alex Chen',
        occurredAt: now.subtract(const Duration(days: 1)),
      ),
      ActivityEntry(
        entryId: 'e-3',
        kind: ActivityKind.claim,
        summary: 'Claimed Fresh bagels and bread',
        detail: '6 assorted bagels · T2G, Calgary',
        occurredAt: now.subtract(const Duration(days: 3)),
      ),
      ActivityEntry(
        entryId: 'e-4',
        kind: ActivityKind.eventHosted,
        summary: 'Hosted Saturday Community Food Pantry',
        detail: 'Food distribution · NW Calgary',
        occurredAt: now.subtract(const Duration(days: 5)),
      ),
    ],
  );
}

Widget _wrap(Widget child) => MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  testWidgets('reports activity as unavailable instead of displaying sample totals', (tester) async {
    await tester.pumpWidget(_wrap(MyActivityScreen(
      activityService: ActivityService(simulatedDelay: Duration.zero),
      accountAction: const SizedBox.shrink(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Activity is not available yet'), findsOneWidget);
    expect(find.text('34'), findsNothing);
  });

  testWidgets('Profile menu includes My activity section and opens MyActivityScreen', (tester) async {
    final activity = ActivityService(initialSummary: _sampleSummary(), simulatedDelay: Duration.zero);

    await tester.pumpWidget(_wrap(HomeScreen(
      accountAction: AccountButton(
        user: null,
        activityService: activity,
        activityAccountAction: const SizedBox.shrink(),
        onSignIn: () {},
      ),
    )));

    // Tap the top-right profile button to open the Profile menu.
    await tester.tap(find.byType(AccountButton));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('My activity'), findsOneWidget);

    // Tap My activity -> navigates directly to MyActivityScreen.
    await tester.tap(find.text('My activity'));
    await tester.pumpAndSettle();

    expect(find.byType(MyActivityScreen), findsOneWidget);
    expect(find.text('Totals'), findsOneWidget);
    expect(find.text('Donations posted'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Food given'), findsWidgets);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('Claims'), findsWidgets);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Events hosted'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Posted Rice and stew'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Posted Rice and stew'), findsOneWidget);
  });

  testWidgets('shows loading spinner then renders totals, history, and filters cleanly', (tester) async {
    final completer = Completer<ActivitySummary>();
    final service = _FakeActivityService(() => completer.future);

    await tester.pumpWidget(_wrap(MyActivityScreen(
      activityService: service,
      accountAction: const SizedBox.shrink(),
    )));

    expect(find.text('My activity'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_sampleSummary());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    final verticalList = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Posted Rice and stew'), 150, scrollable: verticalList);
    expect(find.text('Posted Rice and stew'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    // Filter history to Donations only.
    await tester.tap(find.text('Donations'));
    await tester.pumpAndSettle();
    expect(find.text('Posted Rice and stew'), findsOneWidget);
    expect(find.text('Gave 6 portions of Homemade lentil soup'), findsNothing);

    // Filter history to Events only.
    final horizontalFilters = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(find.text('Events'), 100, scrollable: horizontalFilters);
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Hosted Saturday Community Food Pantry'),
      150,
      scrollable: verticalList,
    );
    expect(find.text('Hosted Saturday Community Food Pantry'), findsOneWidget);
    expect(find.text('Posted Rice and stew'), findsNothing);
  });

  testWidgets('shows error notice and recovers to empty history on pull to refresh', (tester) async {
    var shouldFail = true;
    final service = _FakeActivityService(() async {
      if (shouldFail) throw Exception('network');
      return const ActivitySummary(
        totals: ActivityTotals(donationsPosted: 0, foodGiven: 0, claims: 0, eventsHosted: 0),
        history: [],
      );
    });

    await tester.pumpWidget(_wrap(MyActivityScreen(
      activityService: service,
      accountAction: const SizedBox.shrink(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Could not load activity'), findsOneWidget);

    shouldFail = false;
    await tester.fling(find.text('Could not load activity'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('No activity yet'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No activity yet'), findsOneWidget);
  });
}
