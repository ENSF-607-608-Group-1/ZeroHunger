import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/screens/home_screen.dart';
import 'package:zerohunger/screens/pickup_chat_screen.dart';
import 'package:zerohunger/screens/pickup_chats_screen.dart';
import 'package:zerohunger/services/chat_service.dart';
import 'package:zerohunger/services/query_service.dart';
import 'package:zerohunger/theme/app_theme.dart';

List<PickupChatThread> _sampleThreads() {
  final now = DateTime.now();
  return [
    PickupChatThread(
      conversationId: 'conv-rice',
      donationId: 'don-rice',
      donationTitle: 'Rice and stew',
      otherPartyName: 'Maya Patel',
      myRole: ChatRole.recipient,
      status: ReservationStatus.active,
      pickupCode: '615318',
      pickupStart: now.add(const Duration(hours: 1)),
      pickupEnd: now.add(const Duration(hours: 3)),
      unreadCount: 1,
      messages: [
        ChatMessage(
          messageId: 'm1',
          conversationId: 'conv-rice',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: now.subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          messageId: 'm2',
          conversationId: 'conv-rice',
          sender: ChatSender.other,
          senderName: 'Maya Patel',
          text: 'Ring bell #2 when you arrive.',
          sentAt: now.subtract(const Duration(minutes: 20)),
        ),
      ],
    ),
    PickupChatThread(
      conversationId: 'conv-soup-alex',
      donationId: 'don-soup',
      donationTitle: 'Homemade lentil soup',
      otherPartyName: 'Alex Chen',
      myRole: ChatRole.donor,
      status: ReservationStatus.active,
      pickupCode: '738204',
      pickupStart: now.add(const Duration(hours: 2)),
      pickupEnd: now.add(const Duration(hours: 4)),
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'm3',
          conversationId: 'conv-soup-alex',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: now.subtract(const Duration(hours: 1)),
        ),
        ChatMessage(
          messageId: 'm4',
          conversationId: 'conv-soup-alex',
          sender: ChatSender.other,
          senderName: 'Alex Chen',
          text: 'Is there visitor parking out front?',
          sentAt: now.subtract(const Duration(minutes: 10)),
        ),
      ],
    ),
    PickupChatThread(
      conversationId: 'conv-soup-priya',
      donationId: 'don-soup',
      donationTitle: 'Homemade lentil soup',
      otherPartyName: 'Priya Nair',
      myRole: ChatRole.donor,
      status: ReservationStatus.active,
      pickupCode: '849120',
      pickupStart: now.add(const Duration(hours: 2)),
      pickupEnd: now.add(const Duration(hours: 4)),
      unreadCount: 0,
      messages: [
        ChatMessage(
          messageId: 'm5',
          conversationId: 'conv-soup-priya',
          sender: ChatSender.system,
          senderName: 'Zero Hunger',
          text: 'Pickup chat opened',
          sentAt: now.subtract(const Duration(hours: 3)),
        ),
        ChatMessage(
          messageId: 'm6',
          conversationId: 'conv-soup-priya',
          sender: ChatSender.other,
          senderName: 'Priya Nair',
          text: 'See you at 6 pm!',
          sentAt: now.subtract(const Duration(minutes: 45)),
        ),
      ],
    ),
  ];
}

Widget _wrap(Widget child) =>
    MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  test('default pickup chat history is empty', () async {
    final chat = ChatService(simulatedDelay: Duration.zero);

    expect(await chat.myChats(), isEmpty);
    expect(await chat.totalUnreadCount(), 0);
  });

  testWidgets(
    'Home message FAB opens PickupChatsScreen and lets user open a specific chat',
    (tester) async {
      final chat = ChatService(
        initialThreads: _sampleThreads(),
        simulatedDelay: Duration.zero,
      );

      await tester.pumpWidget(
        _wrap(
          HomeScreen(chatService: chat, accountAction: const SizedBox.shrink()),
        ),
      );

      // Message icon button sits in the FloatingActionButton slot at bottom right.
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      expect(find.byIcon(Icons.message_rounded), findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.byType(PickupChatsScreen), findsOneWidget);
      expect(find.text('Pickup chats'), findsOneWidget);
      expect(find.text('Rice and stew'), findsOneWidget);
      expect(find.text('Homemade lentil soup'), findsNWidgets(2));
      expect(find.text('Recipient · Alex Chen'), findsOneWidget);
      expect(find.text('Recipient · Priya Nair'), findsOneWidget);

      // Filter to My donations only.
      await tester.tap(find.text('My donations'));
      await tester.pumpAndSettle();
      expect(find.text('Rice and stew'), findsNothing);
      expect(find.text('Recipient · Alex Chen'), findsOneWidget);

      // Tap Alex Chen's chat -> opens PickupChatScreen directly for Alex Chen.
      await tester.tap(find.text('Recipient · Alex Chen'));
      await tester.pumpAndSettle();

      expect(find.byType(PickupChatScreen), findsOneWidget);
      expect(find.text('Homemade lentil soup'), findsOneWidget);
      expect(find.text('Recipient · Alex Chen'), findsOneWidget);
      expect(find.text('Pickup chat opened'), findsOneWidget);
      expect(find.text('Is there visitor parking out front?'), findsOneWidget);
    },
  );

  testWidgets(
    'PickupChatScreen displays sender, timestamps, sends messages and enforces 1,000-char limit',
    (tester) async {
      final chat = ChatService(
        initialThreads: _sampleThreads(),
        simulatedDelay: Duration.zero,
      );

      await tester.pumpWidget(
        _wrap(PickupChatScreen(conversationId: 'conv-rice', chatService: chat)),
      );
      await tester.pumpAndSettle();

      // Donation name at top + system message + incoming donor message.
      expect(find.text('Rice and stew'), findsOneWidget);
      expect(find.text('Donor · Maya Patel'), findsOneWidget);
      expect(find.text('Pickup chat opened'), findsOneWidget);
      expect(find.text('Ring bell #2 when you arrive.'), findsOneWidget);
      expect(find.textContaining('Maya Patel (Donor)'), findsOneWidget);
      expect(find.text('0/1000'), findsOneWidget);

      // Send button starts disabled when input is empty.
      final sendButtonFinder = find.widgetWithIcon(
        IconButton,
        Icons.send_rounded,
      );
      expect(tester.widget<IconButton>(sendButtonFinder).onPressed, isNull);

      // Typing whitespace keeps Send disabled.
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(tester.widget<IconButton>(sendButtonFinder).onPressed, isNull);

      // Entering more than 1,000 characters is capped at 1,000.
      final overLimit = 'a' * 1050;
      await tester.enterText(find.byType(TextField), overLimit);
      await tester.pump();
      expect(find.text('1000/1000'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .controller
            ?.text
            .length,
        1000,
      );

      // Type a normal message and send it.
      await tester.enterText(find.byType(TextField), 'On my way now!');
      await tester.pump();
      expect(find.text('14/1000'), findsOneWidget);
      expect(tester.widget<IconButton>(sendButtonFinder).onPressed, isNotNull);

      await tester.tap(sendButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('On my way now!'), findsOneWidget);
      expect(find.textContaining('You ·'), findsOneWidget);
      expect(find.text('0/1000'), findsOneWidget);
    },
  );

  testWidgets(
    'Sending a message updates the preview and clears unread badge in PickupChatsScreen',
    (tester) async {
      final chat = ChatService(
        initialThreads: _sampleThreads(),
        simulatedDelay: Duration.zero,
      );

      await tester.pumpWidget(
        _wrap(
          PickupChatsScreen(
            chatService: chat,
            accountAction: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unread badge "1" initially visible on Rice and stew.
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Rice and stew'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Thanks Maya, bringing a tote bag!',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      // Navigate back to the chat list.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        find.text('You: Thanks Maya, bringing a tote bag!'),
        findsOneWidget,
      );
      expect(find.text('1'), findsNothing);
    },
  );

  testWidgets(
    'Opening a specific donation recipient chat directly goes straight to that chat',
    (tester) async {
      final chat = ChatService(
        initialThreads: _sampleThreads(),
        simulatedDelay: Duration.zero,
      );

      await tester.pumpWidget(
        _wrap(
          PickupChatScreen(
            conversationId: 'conv-soup-priya',
            donationId: 'don-soup',
            donationTitle: 'Homemade lentil soup',
            otherPartyName: 'Priya Nair',
            myRole: ChatRole.donor,
            chatService: chat,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Homemade lentil soup'), findsOneWidget);
      expect(find.text('Recipient · Priya Nair'), findsOneWidget);
      expect(find.text('See you at 6 pm!'), findsOneWidget);
      expect(find.text('Is there visitor parking out front?'), findsNothing);
    },
  );
}
