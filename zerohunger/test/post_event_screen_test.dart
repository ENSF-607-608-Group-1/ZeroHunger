import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerohunger/screens/post_event_screen.dart';
import 'package:zerohunger/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  testWidgets('Guest sees sign-in notice', (tester) async {
    await tester.pumpWidget(_wrap(
      const PostEventScreen(signedInOverride: false),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to post an event'), findsOneWidget);
    expect(find.text('Sign in or create account'), findsOneWidget);
    expect(find.text('Post event'), findsNothing);
  });

  testWidgets('Shows validation errors when required fields are empty', (tester) async {
    bool called = false;
    await tester.pumpWidget(_wrap(
      PostEventScreen(
        signedInOverride: true,
        onPostEvent: (_) async {
          called = true;
          return const SubmittedEvent(eventId: 'evt-1', title: 'x', kind: EventKind.foodDistribution);
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post event'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.text('Please fix the fields marked in red.'), findsOneWidget);
    expect(find.text('Required'), findsWidgets);
    expect(find.text('Use the format A1A 1A1'), findsOneWidget);
  });

  testWidgets('Posts a donation event with organization, comments and tidied postal code', (tester) async {
    PostEventData? received;

    await tester.pumpWidget(_wrap(
      PostEventScreen(
        signedInOverride: true,
        onPostEvent: (data) async {
          received = data;
          return SubmittedEvent(eventId: 'evt-42', title: data.title, kind: data.kind);
        },
      ),
    ));
    await tester.pumpAndSettle();

    // Switch kind to Donation event.
    await tester.tap(find.text('Donation event'));
    await tester.pumpAndSettle();

    // Fill Title and Comments.
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Winter Food Drive');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Comments (optional)'),
      'Bring non-perishables to the main lobby.',
    );

    // Pick an optional Organization.
    await tester.tap(find.text('None (posting as yourself)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calgary Food Bank').last);
    await tester.pumpAndSettle();

    // Fill Address.
    await tester.enterText(find.widgetWithText(TextFormField, 'Street address'), '2500 University Dr NW');
    await tester.enterText(find.widgetWithText(TextFormField, 'Postal code'), 't2n1n4');

    // Submit.
    await tester.tap(find.text('Post event'));
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!.kind, EventKind.donationEvent);
    expect(received!.title, 'Winter Food Drive');
    expect(received!.comments, 'Bring non-perishables to the main lobby.');
    expect(received!.organization, 'Calgary Food Bank');
    expect(received!.address.line1, '2500 University Dr NW');
    expect(received!.address.city, 'Calgary');
    expect(received!.address.province, 'AB');
    expect(received!.address.postalCode, 'T2N 1N4');
    expect(received!.endTime.isAfter(received!.startTime), isTrue);

    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Event ID: evt-42'), findsOneWidget);
  });

  testWidgets('Posts a food distribution event with optional fields omitted', (tester) async {
    PostEventData? received;

    await tester.pumpWidget(_wrap(
      PostEventScreen(
        signedInOverride: true,
        onPostEvent: (data) async {
          received = data;
          return SubmittedEvent(eventId: 'evt-99', title: data.title, kind: data.kind);
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Sunday Community Meals');
    await tester.enterText(find.widgetWithText(TextFormField, 'Street address'), '615 Macleod Trail SE');
    await tester.enterText(find.widgetWithText(TextFormField, 'Postal code'), 'T2G 4T8');

    await tester.tap(find.text('Post event'));
    await tester.pumpAndSettle();

    expect(received, isNotNull);
    expect(received!.kind, EventKind.foodDistribution);
    expect(received!.comments, '');
    expect(received!.organization, isNull);
    expect(received!.address.postalCode, 'T2G 4T8');
  });
}
