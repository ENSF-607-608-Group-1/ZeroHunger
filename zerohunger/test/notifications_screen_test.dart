import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/screens/food_details_screen.dart';
import 'package:zerohunger/screens/home_screen.dart';
import 'package:zerohunger/screens/notifications_screen.dart';
import 'package:zerohunger/screens/pickup_chat_screen.dart';
import 'package:zerohunger/services/chat_service.dart';
import 'package:zerohunger/services/notification_service.dart';
import 'package:zerohunger/services/query_service.dart';
import 'package:zerohunger/services/zero_hunger_api.dart';
import 'package:zerohunger/theme/app_theme.dart';
import 'package:zerohunger/widgets/notification_button.dart';

class _FakeQueryService extends QueryService {
  _FakeQueryService(this.donations);

  final List<Donation> donations;

  @override
  Future<List<Donation>> availableDonations() async => donations;
}

class _FailingNotificationService extends NotificationService {
  _FailingNotificationService() : super(initialNotifications: const [], simulatedDelay: Duration.zero);

  bool shouldFail = true;

  @override
  Future<List<AppNotification>> myNotifications() async {
    if (shouldFail) throw Exception('network');
    return super.myNotifications();
  }
}

List<AppNotification> _sampleNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      notificationId: 'n-chat',
      title: 'New pickup message',
      message: 'Maya Patel sent a message about Rice and stew.',
      createdAt: now.subtract(const Duration(minutes: 10)),
      isRead: false,
      targetType: NotificationTargetType.chat,
      targetId: 'conv-rice',
      targetTitle: 'Rice and stew',
    ),
    AppNotification(
      notificationId: 'n-food',
      title: 'New food near you',
      message: 'Fresh bagels and bread posted in T2G, Calgary.',
      createdAt: now.subtract(const Duration(hours: 2)),
      isRead: false,
      targetType: NotificationTargetType.food,
      targetId: 'don-bagels',
      targetTitle: 'Fresh bagels and bread',
    ),
    AppNotification(
      notificationId: 'n-event',
      title: 'Upcoming food distribution',
      message: 'Saturday Community Food Pantry starts tomorrow at 10 am.',
      createdAt: now.subtract(const Duration(days: 1)),
      isRead: true,
      targetType: NotificationTargetType.event,
      targetId: 'event-1',
      targetTitle: 'Saturday Community Food Pantry',
    ),
  ];
}

Donation _sampleBagelsDonation() {
  final now = DateTime.now();
  return Donation(
    donationId: 'don-bagels',
    title: 'Fresh bagels and bread',
    description: 'Unsold bagels and sourdough.',
    items: const [
      DonationItem(
        itemId: 'item-bagels',
        name: 'Assorted bagels',
        categories: ['VEGETARIAN'],
        allergens: ['WHEAT'],
        quantityLeft: 12,
        unit: 'items',
      ),
    ],
    area: 'T2G',
    address: const PickupAddress(
      line1: '34 Sample Avenue SE',
      city: 'Calgary',
      province: 'AB',
      postalCode: 'T2G 0A1',
    ),
    pickupStart: now.add(const Duration(hours: 2)),
    pickupEnd: now.add(const Duration(hours: 4)),
  );
}

Widget _wrap(Widget child) => MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  testWidgets('Home AppBar shows NotificationButton next to user icon and opens NotificationsScreen', (tester) async {
    final notifications = NotificationService(
      initialNotifications: _sampleNotifications(),
      simulatedDelay: Duration.zero,
    );
    const userActionKey = Key('user-action');

    await tester.pumpWidget(_wrap(HomeScreen(
      notificationService: notifications,
      accountAction: const SizedBox(key: userActionKey, width: 32, height: 32),
    )));

    final notifButton = find.byType(NotificationButton);
    final userAction = find.byKey(userActionKey);
    expect(notifButton, findsOneWidget);
    expect(userAction, findsOneWidget);

    // Notification icon sits to the left of the user icon in the AppBar.
    expect(tester.getTopLeft(notifButton).dx, lessThan(tester.getTopLeft(userAction).dx));
    // Shows unread badge "2".
    expect(find.text('2'), findsOneWidget);

    await tester.tap(notifButton);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('New pickup message'), findsOneWidget);
    expect(find.text('New food near you'), findsOneWidget);
    expect(find.text('Upcoming food distribution'), findsOneWidget);
  });

  testWidgets('Filters work and Mark all read clears unread notifications and updates badge', (tester) async {
    final notifications = NotificationService(
      initialNotifications: _sampleNotifications(),
      simulatedDelay: Duration.zero,
    );

    await tester.pumpWidget(_wrap(HomeScreen(
      notificationService: notifications,
      accountAction: const SizedBox.shrink(),
    )));

    await tester.tap(find.byType(NotificationButton));
    await tester.pumpAndSettle();

    // Filter to Unread only.
    await tester.tap(find.text('Unread').first);
    await tester.pumpAndSettle();
    expect(find.text('New pickup message'), findsOneWidget);
    expect(find.text('New food near you'), findsOneWidget);
    expect(find.text('Upcoming food distribution'), findsNothing);

    // Filter to Events.
    await tester.scrollUntilVisible(find.text('Events').first, 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Events').first);
    await tester.pumpAndSettle();
    expect(find.text('Upcoming food distribution'), findsOneWidget);
    expect(find.text('New pickup message'), findsNothing);

    // Mark all read -> clears unread count and removes button.
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsNothing);
    expect(notifications.unreadCount, 0);

    // Back on HomeScreen, unread badge "2" is gone.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);
  });

  testWidgets('Tapping chat, food, and event notifications marks read and opens the right target', (tester) async {
    final notifications = NotificationService(
      initialNotifications: _sampleNotifications(),
      simulatedDelay: Duration.zero,
    );
    final chat = ChatService(initialThreads: const [], simulatedDelay: Duration.zero);
    final query = _FakeQueryService([_sampleBagelsDonation()]);

    await tester.pumpWidget(_wrap(NotificationsScreen(
      notificationService: notifications,
      chatService: chat,
      queryService: query,
      accountAction: const SizedBox.shrink(),
    )));
    await tester.pumpAndSettle();

    // 1. Tap chat notification -> opens PickupChatScreen and marks read.
    await tester.tap(find.text('New pickup message'));
    await tester.pumpAndSettle();
    expect(find.byType(PickupChatScreen), findsOneWidget);
    expect(find.text('Rice and stew'), findsOneWidget);
    expect(notifications.unreadCount, 1);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 2. Tap food notification -> opens FoodDetailsScreen and marks read.
    await tester.tap(find.text('New food near you'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodDetailsScreen), findsOneWidget);
    expect(find.text('Fresh bagels and bread'), findsOneWidget);
    expect(notifications.unreadCount, 0);

    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Tap event notification -> shows coming-soon message.
    await tester.tap(find.text('Upcoming food distribution'));
    await tester.pump();
    expect(find.text('Events screen is coming soon (Saturday Community Food Pantry).'), findsOneWidget);
  });

  testWidgets('Shows error notice and recovers to empty notice on pull to refresh', (tester) async {
    final notifications = _FailingNotificationService();

    await tester.pumpWidget(_wrap(NotificationsScreen(
      notificationService: notifications,
      accountAction: const SizedBox.shrink(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Could not load notifications'), findsOneWidget);

    notifications.shouldFail = false;
    await tester.fling(find.text('Could not load notifications'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
  });
}
