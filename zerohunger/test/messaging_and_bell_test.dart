import 'package:firebase_data_connect/firebase_data_connect.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/generated/zerohunger.dart';
import 'package:zerohunger/screens/claimed_screen.dart';
import 'package:zerohunger/screens/pickup_chat_screen.dart';
import 'package:zerohunger/services/chat_service.dart';
import 'package:zerohunger/services/notification_service.dart';
import 'package:zerohunger/services/push_notification_service.dart';
import 'package:zerohunger/services/query_service.dart';
import 'package:zerohunger/services/zero_hunger_api.dart';
import 'package:zerohunger/theme/app_theme.dart';
import 'package:zerohunger/widgets/notification_button.dart';

Widget _wrap(Widget child) => MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  testWidgets('NotificationButton colors bell icon when unread and resets when read', (tester) async {
    final service = NotificationService(
      initialNotifications: [
        AppNotification(
          notificationId: 'n1',
          title: 'New food near you',
          message: 'Fresh bread posted nearby.',
          createdAt: DateTime.now(),
          isRead: false,
          targetType: NotificationTargetType.food,
          targetId: 'don-1',
        ),
      ],
      simulatedDelay: Duration.zero,
    );

    await tester.pumpWidget(_wrap(Scaffold(
      appBar: AppBar(
        actions: [
          NotificationButton(
            notificationService: service,
            accountAction: const SizedBox.shrink(),
          ),
        ],
      ),
    )));

    final unreadIcon = tester.widget<Icon>(
      find.descendant(of: find.byType(NotificationButton), matching: find.byType(Icon)),
    );
    expect(unreadIcon.icon, Icons.notifications_active_rounded);
    expect(unreadIcon.color, ZhColors.error);

    await service.markAllAsRead();
    await tester.pump();

    final readIcon = tester.widget<Icon>(
      find.descendant(of: find.byType(NotificationButton), matching: find.byType(Icon)),
    );
    expect(readIcon.icon, Icons.notifications_none_rounded);
    expect(readIcon.color, ZhColors.textSecondary);
  });

  group('PickupChatMeta and Cloud SQL conversation mapping', () {
    test('encodes and parses pickup metadata with unique reservationId and pickupCode', () {
      final meta = PickupChatMeta(
        reservationId: '47e8682f-77cb-4a24-8871-8cb7f69eaf6b',
        donationId: '311379b8-8916-40de-8367-b5eec6b8fe84',
        donationTitle: 'Fresh Pasta',
        pickupCode: '615318',
        pickupStart: DateTime.utc(2026, 4, 10, 18, 0),
        pickupEnd: DateTime.utc(2026, 4, 10, 20, 0),
        donorAuthUid: 'uid-donor',
        recipientAuthUid: 'uid-recipient',
      );

      final encoded = encodePickupMetaMessage(meta);
      final parsed = parsePickupMetaMessage(encoded);

      expect(parsed, isNotNull);
      expect(parsed!.meta.reservationId, '47e8682f-77cb-4a24-8871-8cb7f69eaf6b');
      expect(parsed.meta.pickupCode, '615318');
      expect(parsed.meta.donationTitle, 'Fresh Pasta');
      expect(parsed.displayText, contains('615 318'));
      expect(parsed.displayText, isNot(contains('[PICKUP_META]')));
    });

    test('maps Cloud SQL conversations for both donor and recipient sides', () {
      final donorUser = ListMyConversationsUser(
        userId: BigInt.from(1),
        authUid: 'uid-donor',
        firstName: 'Alex',
        lastName: 'Taylor',
        userRole: 'donor',
      );
      final recipientUser = ListMyConversationsUser(
        userId: BigInt.from(2),
        authUid: 'uid-recipient',
        firstName: 'Jordan',
        lastName: 'Lee',
        userRole: 'recipient',
      );

      final openingContent = encodePickupMetaMessage(
        PickupChatMeta(
          reservationId: '47e8682f-77cb-4a24-8871-8cb7f69eaf6b',
          donationId: 'don-pasta',
          donationTitle: 'Fresh Pasta',
          pickupCode: '615318',
          donorAuthUid: 'uid-donor',
          recipientAuthUid: 'uid-recipient',
        ),
      );

      final record = ListMyConversationsUserConversation(
        conversation: ListMyConversationsConversation(
          conversationId: BigInt.from(99),
          conversationType: 'PICKUP',
          createdAt: Timestamp(0, 1775840000),
          members: [
            ListMyConversationsMember(user: donorUser),
            ListMyConversationsMember(user: recipientUser),
          ],
          messages: [
            ListMyConversationsMessage(
              messageId: BigInt.from(1),
              content: openingContent,
              sentAt: Timestamp(0, 1775840000),
              sender: recipientUser,
            ),
            ListMyConversationsMessage(
              messageId: BigInt.from(2),
              content: 'I will be there at 5pm!',
              sentAt: Timestamp(0, 1775840100),
              sender: recipientUser,
            ),
          ],
        ),
      );

      // Donor view
      final donorThreads = ChatService.fromDatabaseConversations(
        [record],
        currentAuthUid: 'uid-donor',
      );
      expect(donorThreads, hasLength(1));
      expect(donorThreads.first.myRole, ChatRole.donor);
      expect(donorThreads.first.otherPartyName, 'Jordan Lee');
      expect(donorThreads.first.otherPartyAuthUid, 'uid-recipient');
      expect(donorThreads.first.pickupCode, '615318');
      expect(donorThreads.first.conversationId, '47e8682f-77cb-4a24-8871-8cb7f69eaf6b');
      expect(donorThreads.first.messages[0].sender, ChatSender.system);
      expect(donorThreads.first.messages[1].sender, ChatSender.other);

      // Recipient view
      final recipientThreads = ChatService.fromDatabaseConversations(
        [record],
        currentAuthUid: 'uid-recipient',
      );
      expect(recipientThreads.first.myRole, ChatRole.recipient);
      expect(recipientThreads.first.otherPartyName, 'Alex Taylor');
      expect(recipientThreads.first.otherPartyAuthUid, 'uid-donor');
      expect(recipientThreads.first.messages[1].sender, ChatSender.me);
    });
  });

  testWidgets('ClaimedScreen opens PickupChatScreen with unique pickup code pinned at top', (tester) async {
    final now = DateTime.now();
    final donation = Donation(
      donationId: 'don-bread',
      title: 'Sourdough Loaves',
      items: const [
        DonationItem(
          itemId: 'item-bread',
          name: 'Sourdough',
          quantityLeft: 3,
          unit: 'loaves',
        ),
      ],
      address: const PickupAddress(
        line1: '55 University Ave',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T3A 1L1',
      ),
    );
    final claim = ClaimResult(
      reservationId: '47e8682f-77cb-4a24-8871-8cb7f69eaf6b',
      donationId: 'don-bread',
      quantityReserved: 3,
      pickupStart: now.add(const Duration(hours: 1)),
      pickupEnd: now.add(const Duration(hours: 3)),
      pickupCode: '842915',
      correlationId: 'corr-1',
    );
    final chat = ChatService(
      initialThreads: [
        PickupChatThread(
          conversationId: claim.reservationId,
          donationId: donation.donationId,
          donationTitle: donation.title,
          otherPartyName: 'Alex Taylor',
          myRole: ChatRole.recipient,
          status: ReservationStatus.active,
          pickupCode: claim.pickupCode,
          pickupStart: claim.pickupStart,
          pickupEnd: claim.pickupEnd,
          messages: [
            ChatMessage(
              messageId: 'sys-1',
              conversationId: claim.reservationId,
              sender: ChatSender.system,
              senderName: 'Zero Hunger',
              text: 'Pickup chat opened for Sourdough Loaves. Pickup code: 842 915.',
              sentAt: now,
            ),
          ],
        ),
      ],
      simulatedDelay: Duration.zero,
    );

    await tester.pumpWidget(_wrap(ClaimedScreen(
      donation: donation,
      items: donation.items,
      result: claim,
      chatService: chat,
    )));

    expect(find.text('Open pickup chat'), findsOneWidget);
    await tester.tap(find.text('Open pickup chat'));
    await tester.pumpAndSettle();

    expect(find.byType(PickupChatScreen), findsOneWidget);
    expect(find.text('PICKUP CODE'), findsOneWidget);
    expect(find.text('842 915'), findsOneWidget);
    expect(find.text('ID #47E8682F'), findsOneWidget);
    expect(find.text('Show this code to the donor to receive your food.'), findsOneWidget);

    // Pickup code banner appears ABOVE the first chat message.
    final codeY = tester.getTopLeft(find.text('842 915')).dy;
    final msgY = tester
        .getTopLeft(find.text('Pickup chat opened for Sourdough Loaves. Pickup code: 842 915.'))
        .dy;
    expect(codeY, lessThan(msgY));
  });

  testWidgets('Foreground push notification popup renders at the top of the screen', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    var viewed = false;

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      theme: zeroHungerTheme(),
      home: const Scaffold(body: Center(child: Text('Home content'))),
    ));

    PushNotificationService.instance.showTopNotificationBanner(
      overlay: navKey.currentState!.overlay!,
      notification: AppNotification(
        notificationId: 'top-1',
        title: 'Pickup chat',
        message: 'Pickup chat opened. Pickup code: 542 474.',
        createdAt: DateTime.now(),
        isRead: false,
        targetType: NotificationTargetType.chat,
        targetId: 'res-542474',
      ),
      onView: () => viewed = true,
      duration: const Duration(seconds: 5),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pickup chat'), findsOneWidget);
    expect(find.text('Pickup chat opened. Pickup code: 542 474.'), findsOneWidget);

    // Banner appears near the top of the screen, well above the centered body text.
    final bannerY = tester.getTopLeft(find.text('Pickup chat')).dy;
    final bodyY = tester.getTopLeft(find.text('Home content')).dy;
    expect(bannerY, lessThan(bodyY));

    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(viewed, isTrue);
    expect(find.text('Pickup chat'), findsNothing);
  });
}
