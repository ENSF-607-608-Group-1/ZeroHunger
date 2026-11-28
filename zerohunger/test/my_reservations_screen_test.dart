import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/screens/my_reservations_screen.dart';
import 'package:zerohunger/screens/pickup_chat_screen.dart';
import 'package:zerohunger/services/chat_service.dart';
import 'package:zerohunger/services/query_service.dart';
import 'package:zerohunger/services/zero_hunger_api.dart';
import 'package:zerohunger/theme/app_theme.dart';

class _FakeQueryService extends QueryService {
  _FakeQueryService(this.loader);

  Future<List<Reservation>> Function() loader;

  @override
  Future<List<Reservation>> myReservations() => loader();
}

List<Reservation> _buildSampleReservations() {
  final now = DateTime.now();
  return [
    Reservation(
      reservationId: 'res-expired',
      donationId: 'don-expired',
      donationTitle: 'Sourdough and pastries',
      pickupCode: '519034',
      pickupStart: now.subtract(const Duration(days: 2, hours: 2)),
      pickupEnd: now.subtract(const Duration(days: 2)),
      address: const PickupAddress(
        line1: '90 Sample Way NE',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T1Y 2C3',
      ),
      status: ReservationStatus.expired,
    ),
    Reservation(
      reservationId: 'res-active',
      donationId: 'don-active',
      donationTitle: 'Rice and stew',
      pickupCode: '615318',
      pickupStart: now.add(const Duration(hours: 1)),
      pickupEnd: now.add(const Duration(hours: 3)),
      address: const PickupAddress(
        line1: '12 Sample Crescent NW',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2N 1A1',
      ),
      status: ReservationStatus.active,
      items: const [
        DonationItem(
          itemId: 'item-1',
          name: 'Jasmine rice',
          quantityLeft: 6,
          unit: 'portions',
        ),
      ],
    ),
    Reservation(
      reservationId: 'res-cancelled',
      donationId: 'don-cancelled',
      donationTitle: 'Pasta and tomato sauce',
      pickupCode: '274815',
      pickupStart: now.subtract(const Duration(days: 1, hours: 2)),
      pickupEnd: now.subtract(const Duration(days: 1)),
      address: const PickupAddress(
        line1: '78 Sample Street SW',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2S 1B2',
      ),
      status: ReservationStatus.cancelled,
      cancelReason: 'Donor ran out of containers before pickup.',
    ),
    Reservation(
      reservationId: 'res-rescheduled',
      donationId: 'don-rescheduled',
      donationTitle: 'Vegetable biryani and raita',
      pickupCode: '482910',
      pickupStart: now.add(const Duration(days: 1)),
      pickupEnd: now.add(const Duration(days: 1, hours: 2)),
      address: const PickupAddress(
        line1: '56 Sample Road NW',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T3A 0A1',
      ),
      status: ReservationStatus.rescheduled,
    ),
    Reservation(
      reservationId: 'res-picked-up',
      donationId: 'don-picked-up',
      donationTitle: 'Fresh bagels and bread',
      pickupCode: '903421',
      pickupStart: now.subtract(const Duration(hours: 5)),
      pickupEnd: now.subtract(const Duration(hours: 3)),
      address: const PickupAddress(
        line1: '34 Sample Avenue SE',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2G 0A1',
      ),
      status: ReservationStatus.pickedUp,
    ),
  ];
}

Widget _wrap(Widget child) =>
    MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  test(
    'Unsupported reservation history does not return sample claims',
    () async {
      expect(await QueryService().myReservations(), isEmpty);
    },
  );

  testWidgets(
    'shows loading spinner then renders reservations sorted with all statuses',
    (tester) async {
      final completer = Completer<List<Reservation>>();
      final query = _FakeQueryService(() => completer.future);

      await tester.pumpWidget(
        _wrap(
          MyReservationsScreen(
            queryService: query,
            accountAction: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('My reservations'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_buildSampleReservations());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Upcoming claims appear first (Active, then Rescheduled).
      final activeY = tester.getTopLeft(find.text('Rice and stew')).dy;
      final rescheduledY = tester
          .getTopLeft(find.text('Vegetable biryani and raita'))
          .dy;
      expect(activeY, lessThan(rescheduledY));

      expect(find.text('615 318'), findsOneWidget);
      expect(
        find.text('12 Sample Crescent NW, Calgary, AB T2N 1A1'),
        findsOneWidget,
      );
      expect(find.text('Jasmine rice · 6 portions'), findsOneWidget);

      // Scroll down to verify past claims (Picked up, Cancelled with reason, Expired).
      final verticalList = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Fresh bagels and bread'),
        200,
        scrollable: verticalList,
      );
      expect(find.text('903 421'), findsOneWidget);
      expect(
        find.text('34 Sample Avenue SE, Calgary, AB T2G 0A1'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Pasta and tomato sauce'),
        200,
        scrollable: verticalList,
      );
      expect(find.text('274 815'), findsOneWidget);
      expect(
        find.text('Donor ran out of containers before pickup.'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Sourdough and pastries'),
        200,
        scrollable: verticalList,
      );
      expect(find.text('519 034'), findsOneWidget);
      expect(
        find.text('90 Sample Way NE, Calgary, AB T1Y 2C3'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'status filter chips filter reservations and handle empty matches',
    (tester) async {
      final items = _buildSampleReservations()
          .where((r) => r.status != ReservationStatus.expired)
          .toList();
      final query = _FakeQueryService(() async => items);

      await tester.pumpWidget(
        _wrap(
          MyReservationsScreen(
            queryService: query,
            accountAction: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Cancelled filter chip in the horizontal filter row.
      await tester.tap(find.text('Cancelled').first);
      await tester.pumpAndSettle();

      expect(find.text('Pasta and tomato sauce'), findsOneWidget);
      expect(find.text('Rice and stew'), findsNothing);

      // Tap Expired chip (after turning Cancelled off) when none are expired.
      await tester.tap(find.text('Cancelled').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Expired').first,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Expired').first);
      await tester.pumpAndSettle();

      expect(find.text('No reservations match these filters'), findsOneWidget);
    },
  );

  testWidgets(
    'Copy code copies raw code to clipboard and Open pickup chat invokes callback',
    (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            copiedText = args['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      Reservation? openedChatFor;
      final query = _FakeQueryService(
        () async => [_buildSampleReservations()[1]],
      ); // Active "Rice and stew"

      await tester.pumpWidget(
        _wrap(
          MyReservationsScreen(
            queryService: query,
            accountAction: const SizedBox.shrink(),
            onOpenChat: (reservation) => openedChatFor = reservation,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy code'));
      await tester.pump();
      expect(copiedText, '615318');
      expect(find.text('Pickup code copied'), findsOneWidget);

      await tester.tap(find.text('Open pickup chat'));
      await tester.pump();
      expect(openedChatFor?.reservationId, 'res-active');
    },
  );

  testWidgets(
    'Open pickup chat navigates directly to PickupChatScreen for that reservation',
    (tester) async {
      final query = _FakeQueryService(
        () async => [_buildSampleReservations()[1]],
      );
      final chat = ChatService(
        initialThreads: const [],
        simulatedDelay: Duration.zero,
      );

      await tester.pumpWidget(
        _wrap(
          MyReservationsScreen(
            queryService: query,
            chatService: chat,
            accountAction: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open pickup chat'));
      await tester.pumpAndSettle();

      expect(find.byType(PickupChatScreen), findsOneWidget);
      expect(find.text('Rice and stew'), findsOneWidget);
      expect(
        find.text(
          'Message history is not available yet. You can still send a message.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows empty notice and recovers from error on refresh', (
    tester,
  ) async {
    var shouldFail = true;
    final query = _FakeQueryService(() async {
      if (shouldFail) throw Exception('network');
      return const [];
    });

    await tester.pumpWidget(
      _wrap(
        MyReservationsScreen(
          queryService: query,
          accountAction: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load reservations'), findsOneWidget);

    // Pull down to refresh after recovery -> empty state.
    shouldFail = false;
    await tester.fling(
      find.text('Could not load reservations'),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Reservation history is not available yet'),
      findsOneWidget,
    );
  });
}
