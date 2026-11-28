// notification_button.dart
// The round notification bell button shown next to AccountButton at the top right
// of screens. Shows a live unread badge and opens NotificationsScreen when tapped.

import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/query_service.dart';
import '../theme/app_theme.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({
    super.key,
    this.notificationService,
    this.queryService,
    this.chatService,
    this.accountAction,
    this.onPressed,
  });

  final NotificationService? notificationService;
  final QueryService? queryService;
  final ChatService? chatService;
  final Widget? accountAction;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final service = notificationService ??
        (accountAction == null ? NotificationService.connected() : NotificationService());

    return ValueListenableBuilder<int>(
      valueListenable: service.unreadCountListenable,
      builder: (context, unreadCount, _) {
        final hasUnread = unreadCount > 0;
        final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';

        return IconButton(
          tooltip: 'Notifications',
          onPressed: onPressed ??
              () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        notificationService: service,
                        queryService: queryService,
                        chatService: chatService,
                        accountAction: accountAction,
                      ),
                    ),
                  ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: hasUnread ? ZhColors.primaryContainer : ZhColors.divider,
                child: Icon(
                  hasUnread ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                  size: 18,
                  color: hasUnread ? ZhColors.onPrimaryContainer : ZhColors.textSecondary,
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: ZhColors.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ZhColors.background, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ZhColors.onPrimary,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
