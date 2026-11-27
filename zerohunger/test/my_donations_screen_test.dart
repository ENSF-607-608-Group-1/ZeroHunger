import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerohunger/screens/my_donations_screen.dart';
import 'package:zerohunger/services/query_service.dart';
import 'package:zerohunger/services/zero_hunger_api.dart';
import 'package:zerohunger/theme/app_theme.dart';

class _FakeQueryService extends QueryService {
  _FakeQueryService(this.items);
  final List<DonorDonation> items;

  @override
  Future<List<DonorDonation>> myDonations() async => items;
}

List<DonorDonation> _testDonations() {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day, 17, 0);
  final todayEnd = DateTime(now.year, now.month, now.day, 19, 0);

  return [
    DonorDonation(
      donationId: 'don-1',
      title: 'Rice and stew',
      status: DonationStatus.available,
      amountLeft: 10,
      unit: 'portions',
      pickupStart: todayStart,
      pickupEnd: todayEnd,
      pickupChats: [
        PickupChatSummary(
          chatId: 'chat-1',
          recipientLabel: 'Recipient #1043',
          lastMessage: 'Pickup chat opened.',
          updatedAt: now.subtract(const Duration(minutes: 10)),
        ),
      ],
    ),
    DonorDonation(
      donationId: 'don-2',
      title: 'Fresh bagels',
      status: DonationStatus.claimed,
      amountLeft: 0,
      unit: 'items',
      pickupStart: todayStart,
      pickupEnd: todayEnd,
    ),
  ];
}

Widget _wrap(Widget child) => MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  testWidgets('Guest sees sign-in notice', (tester) async {
    await tester.pumpWidget(_wrap(
      MyDonationsScreen(
        queryService: _FakeQueryService(const []),
        signedInOverride: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to manage your donations'), findsOneWidget);
    expect(find.text('Sign in or create account'), findsOneWidget);
  });

  testWidgets('Displays donor donations and updates amount left', (tester) async {
    String? updatedId;
    int? updatedQty;

    await tester.pumpWidget(_wrap(
      MyDonationsScreen(
        queryService: _FakeQueryService(_testDonations()),
        signedInOverride: true,
        updateQuantity: ({required donationId, required newQuantity}) async {
          updatedId = donationId;
          updatedQty = newQuantity;
          return Submitted(donationId, 'corr-1');
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Rice and stew'), findsOneWidget);
    expect(find.text('10 portions left'), findsOneWidget);
    expect(find.text('Fresh bagels'), findsOneWidget);

    // Open Update amount sheet on the available donation.
    await tester.tap(find.text('Update amount'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(updatedId, 'don-1');
    expect(updatedQty, 4);
    expect(find.text('4 portions left'), findsOneWidget);
  });

  testWidgets('Reschedules a donation', (tester) async {
    String? rescheduledId;

    await tester.pumpWidget(_wrap(
      MyDonationsScreen(
        queryService: _FakeQueryService(_testDonations()),
        signedInOverride: true,
        rescheduleDonation: ({required donationId, required newPickupStart, required newPickupEnd}) async {
          rescheduledId = donationId;
          return Submitted(donationId, 'corr-2');
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reschedule').first);
    await tester.pumpAndSettle();

    expect(find.text('Reschedule pickup'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(rescheduledId, 'don-1');
  });

  testWidgets('Cancels a donation with an optional reason', (tester) async {
    String? cancelledId;
    String? cancelledReason;

    await tester.pumpWidget(_wrap(
      MyDonationsScreen(
        queryService: _FakeQueryService(_testDonations()),
        signedInOverride: true,
        cancelDonation: ({required donationId, String? reason}) async {
          cancelledId = donationId;
          cancelledReason = reason;
          return Submitted(donationId, 'corr-3');
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Already picked up locally');
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel donation'));
    await tester.pumpAndSettle();

    expect(cancelledId, 'don-1');
    expect(cancelledReason, 'Already picked up locally');
    expect(find.text('Reason: Already picked up locally'), findsOneWidget);
  });

  testWidgets('Opens pickup chats for a donation', (tester) async {
    await tester.pumpWidget(_wrap(
      MyDonationsScreen(
        queryService: _FakeQueryService(_testDonations()),
        signedInOverride: true,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pickup chats (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Recipient #1043'), findsOneWidget);
    expect(find.text('Pickup chat opened.'), findsOneWidget);
  });
}
