// notifications_screen.dart
// Keeps every alert in one place, so a missed push notification is never lost.
//
//   NotificationService.myNotifications() -> a card per alert -> tap to open the food, chat, or event
//
// Until the database exists, the list is the sample notifications in notification_service.dart.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/query_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/form_parts.dart';
import 'food_details_screen.dart';
import 'pickup_chat_screen.dart';

enum _NotificationFilter { all, unread, food, chat, event }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.notificationService,
    this.queryService,
    this.chatService,
    this.accountAction,
    this.onOpenNotification,
  });

  final NotificationService? notificationService;
  final QueryService? queryService;
  final ChatService? chatService;
  final Widget? accountAction;
  final ValueChanged<AppNotification>? onOpenNotification;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notifications = widget.notificationService ?? NotificationService();
  late final QueryService _query = widget.queryService ?? QueryService();
  late final ChatService _chat = widget.chatService ?? ChatService();
  late final AuthService? _auth = widget.accountAction == null ? AuthService() : null;

  late Future<List<AppNotification>> _listFuture = _notifications.myNotifications();
  _NotificationFilter _filter = _NotificationFilter.all;

  // Loads the list again (pull down to refresh).
  Future<void> _reload() async {
    final next = _notifications.myNotifications();
    setState(() {
      _listFuture = next;
    });
    await next;
  }

  List<AppNotification> _visible(List<AppNotification> all) {
    return switch (_filter) {
      _NotificationFilter.all => all,
      _NotificationFilter.unread => all.where((n) => !n.isRead).toList(),
      _NotificationFilter.food => all.where((n) => n.targetType == NotificationTargetType.food).toList(),
      _NotificationFilter.chat => all.where((n) => n.targetType == NotificationTargetType.chat).toList(),
      _NotificationFilter.event => all.where((n) => n.targetType == NotificationTargetType.event).toList(),
    };
  }

  Future<void> _markAllRead() async {
    await _notifications.markAllAsRead();
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    showZhMessage(context, 'All notifications marked as read');
  }

  Future<void> _openNotification(AppNotification notification) async {
    await _notifications.markAsRead(notification.notificationId);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;

    final customHandler = widget.onOpenNotification;
    if (customHandler != null) {
      customHandler(notification);
      return;
    }

    switch (notification.targetType) {
      case NotificationTargetType.chat:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PickupChatScreen(
              conversationId: notification.targetId,
              donationTitle: notification.targetTitle,
              chatService: _chat,
            ),
          ),
        );
      case NotificationTargetType.food:
        try {
          final donations = await _query.availableDonations();
          if (!mounted) return;
          Donation? match;
          for (final d in donations) {
            if (d.donationId == notification.targetId) {
              match = d;
              break;
            }
          }
          if (match == null) {
            showZhMessage(context, 'This food listing is no longer available.');
            return;
          }
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetailsScreen(
                donation: match!,
                accountAction: widget.accountAction,
              ),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          showZhMessage(context, 'Could not open this food listing. Please try again.');
        }
      case NotificationTargetType.event:
        final label = notification.targetTitle;
        showZhMessage(
          context,
          label != null && label.isNotEmpty
              ? 'Events screen is coming soon ($label).'
              : 'Events screen is coming soon.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _notifications.unreadCountListenable,
            builder: (context, unreadCount, _) {
              if (unreadCount <= 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: _markAllRead,
                style: TextButton.styleFrom(
                  foregroundColor: ZhColors.primary,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Mark all read'),
              );
            },
          ),
          if (widget.accountAction != null)
            widget.accountAction!
          else
            StreamBuilder<User?>(
              stream: _auth!.userChanges,
              initialData: _auth.currentUser,
              builder: (context, snapshot) => AccountButton(user: snapshot.data),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _filterRow(),
          Expanded(
            child: FutureBuilder<List<AppNotification>>(
              future: _listFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? const <AppNotification>[];
                final shown = _visible(all);

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (snapshot.hasError)
                        const _Notice(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load notifications',
                          subtitle: 'Check your connection, then pull down to try again.',
                        )
                      else if (all.isEmpty)
                        const _Notice(
                          icon: Icons.notifications_none_rounded,
                          title: 'No notifications yet',
                          subtitle: 'Alerts about nearby food, pickup chats, and events will show up here.',
                        )
                      else if (shown.isEmpty)
                        const _Notice(
                          icon: Icons.search_off_rounded,
                          title: 'No notifications match this filter',
                          subtitle: 'Try switching the filter above.',
                        )
                      else
                        for (final item in shown) ...[
                          _NotificationCard(
                            notification: item,
                            onTap: () => _openNotification(item),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Filter chips in a horizontally scrollable row, matching Find food, My reservations, and Pickup chats.
  Widget _filterRow() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          for (final filter in _NotificationFilter.values) ...[
            TagChip(
              label: _filterLabel(filter),
              selected: _filter == filter,
              onTap: () => setState(() => _filter = filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

String _filterLabel(_NotificationFilter filter) => switch (filter) {
      _NotificationFilter.all => 'All',
      _NotificationFilter.unread => 'Unread',
      _NotificationFilter.food => 'Food',
      _NotificationFilter.chat => 'Chats',
      _NotificationFilter.event => 'Events',
    };

// One notification row: icon, title, time, message, target badge, read/unread indicator.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Material(
      color: ZhColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: unread ? ZhColors.primary : ZhColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TargetAvatar(targetType: notification.targetType, unread: unread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                              color: ZhColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatNotificationTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                            color: unread ? ZhColors.primary : ZhColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: unread ? ZhColors.text : ZhColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _TargetPill(targetType: notification.targetType),
                        const SizedBox(width: 8),
                        _ReadStatusBadge(isRead: notification.isRead),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: ZhColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetAvatar extends StatelessWidget {
  const _TargetAvatar({required this.targetType, required this.unread});

  final NotificationTargetType targetType;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (targetType) {
      NotificationTargetType.food => (
          Icons.restaurant_outlined,
          ZhColors.primaryContainer,
          ZhColors.onPrimaryContainer,
        ),
      NotificationTargetType.chat => (
          Icons.chat_bubble_outline_rounded,
          ZhColors.primaryContainer,
          ZhColors.onPrimaryContainer,
        ),
      NotificationTargetType.event => (
          Icons.event_outlined,
          ZhColors.warningContainer,
          ZhColors.warningIcon,
        ),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: fg),
        ),
        if (unread)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: ZhColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: ZhColors.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _TargetPill extends StatelessWidget {
  const _TargetPill({required this.targetType});

  final NotificationTargetType targetType;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (targetType) {
      NotificationTargetType.food => ('Food', ZhColors.primaryContainer, ZhColors.onPrimaryContainer),
      NotificationTargetType.chat => ('Pickup chat', ZhColors.primaryContainer, ZhColors.onPrimaryContainer),
      NotificationTargetType.event => ('Event', ZhColors.warningContainer, ZhColors.onWarning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _ReadStatusBadge extends StatelessWidget {
  const _ReadStatusBadge({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isRead ? ZhColors.divider : ZhColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isRead ? 'Read' : 'Unread',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isRead ? ZhColors.textSecondary : ZhColors.primary,
        ),
      ),
    );
  }
}

// Formats a notification timestamp cleanly, e.g. "Just now", "18 min ago", "4 h ago", "Yesterday", or "Nov 24".
String _formatNotificationTime(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);

  if (!diff.isNegative) {
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && local.day == now.day) return '${diff.inHours} h ago';
  }

  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;
  if (days == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[local.month - 1]} ${local.day}';
}

// A message in place of the list, matching Find food, My reservations, and Pickup chats.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: ZhColors.primaryContainer, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: ZhColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
