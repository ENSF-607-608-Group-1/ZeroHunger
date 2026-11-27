// pickup_chats_screen.dart
// Shows the user's pickup chats across different donations.
//
// Reached from the message button at the bottom right of HomeScreen,
// or scoped to a single donation (by passing donationId) from My donations.
// Tapping any chat opens PickupChatScreen directly for that specific recipient/donor.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/query_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/form_parts.dart';
import 'pickup_chat_screen.dart';

enum _ChatFilter { all, claims, donations }

class PickupChatsScreen extends StatefulWidget {
  const PickupChatsScreen({
    super.key,
    this.donationId,
    this.donationTitle,
    this.chatService,
    this.accountAction,
  });

  final String? donationId;    // optional: show only chats for one donation
  final String? donationTitle; // optional header when scoped to one donation
  final ChatService? chatService;
  final Widget? accountAction;

  @override
  State<PickupChatsScreen> createState() => _PickupChatsScreenState();
}

class _PickupChatsScreenState extends State<PickupChatsScreen> {
  late final ChatService _chat = widget.chatService ?? ChatService();
  late final AuthService? _auth = widget.accountAction == null ? AuthService() : null;

  late Future<List<PickupChatThread>> _threads = _chat.myChats(donationId: widget.donationId);
  _ChatFilter _filter = _ChatFilter.all;

  Future<void> _reload() async {
    final next = _chat.myChats(donationId: widget.donationId);
    setState(() {
      _threads = next;
    });
    await next;
  }

  List<PickupChatThread> _visible(List<PickupChatThread> all) {
    return switch (_filter) {
      _ChatFilter.all => all,
      _ChatFilter.claims => all.where((t) => t.myRole == ChatRole.recipient).toList(),
      _ChatFilter.donations => all.where((t) => t.myRole == ChatRole.donor).toList(),
    };
  }

  Future<void> _openThread(PickupChatThread thread) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickupChatScreen.fromThread(thread, chatService: _chat),
      ),
    );
    if (mounted) {
      // Refresh list on return so newly sent messages and cleared unread badges appear.
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoped = widget.donationId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scoped ? (widget.donationTitle ?? 'Donation chats') : 'Pickup chats',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
            ),
            if (scoped)
              const Text(
                'Pickup chats for this donation',
                style: TextStyle(fontSize: 12, color: ZhColors.textSecondary),
              ),
          ],
        ),
        actions: [
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
          if (!scoped) _filterRow(),
          Expanded(
            child: FutureBuilder<List<PickupChatThread>>(
              future: _threads,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? const <PickupChatThread>[];
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
                          title: 'Could not load pickup chats',
                          subtitle: 'Check your connection, then pull down to try again.',
                        )
                      else if (all.isEmpty)
                        const _Notice(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No pickup chats yet',
                          subtitle: 'When you claim food or someone claims your donation, your chat will appear here.',
                        )
                      else if (shown.isEmpty)
                        const _Notice(
                          icon: Icons.search_off_rounded,
                          title: 'No chats in this view',
                          subtitle: 'Try switching the filter above.',
                        )
                      else
                        for (final thread in shown) ...[
                          _ChatThreadCard(
                            thread: thread,
                            onTap: () => _openThread(thread),
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

  Widget _filterRow() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          TagChip(
            label: 'All',
            selected: _filter == _ChatFilter.all,
            onTap: () => setState(() => _filter = _ChatFilter.all),
          ),
          const SizedBox(width: 8),
          TagChip(
            label: 'My claims',
            selected: _filter == _ChatFilter.claims,
            onTap: () => setState(() => _filter = _ChatFilter.claims),
          ),
          const SizedBox(width: 8),
          TagChip(
            label: 'My donations',
            selected: _filter == _ChatFilter.donations,
            onTap: () => setState(() => _filter = _ChatFilter.donations),
          ),
        ],
      ),
    );
  }
}

// One row/card in the pickup chat list: donation name, recipient/donor, status, last message & time.
class _ChatThreadCard extends StatelessWidget {
  const _ChatThreadCard({required this.thread, required this.onTap});

  final PickupChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = thread.lastMessage;
    final hasUnread = thread.unreadCount > 0;
    final preview = switch (last) {
      null => 'Pickup chat opened',
      ChatMessage(sender: ChatSender.me, text: final t) => 'You: $t',
      ChatMessage(text: final t) => t,
    };

    return Material(
      color: ZhColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: hasUnread ? ZhColors.primary : ZhColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(thread: thread),
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
                            thread.donationTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: ZhColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatListTime(thread.lastActivityAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            color: hasUnread ? ZhColors.primary : ZhColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${thread.otherPartyRoleLabel} · ${thread.otherPartyName}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: ZhColors.textSecondary,
                          ),
                        ),
                        _StatusBadge(status: thread.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: last?.sender == ChatSender.system ? FontStyle.italic : FontStyle.normal,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                              color: hasUnread ? ZhColors.text : ZhColors.textSecondary,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: ZhColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${thread.unreadCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ZhColors.onPrimary,
                              ),
                            ),
                          ),
                        ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.thread});

  final PickupChatThread thread;

  @override
  Widget build(BuildContext context) {
    final isDonorSide = thread.myRole == ChatRole.donor;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDonorSide ? ZhColors.warningContainer : ZhColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isDonorSide ? Icons.volunteer_activism_outlined : Icons.chat_bubble_outline_rounded,
        size: 22,
        color: isDonorSide ? ZhColors.warningIcon : ZhColors.onPrimaryContainer,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ReservationStatus.active => ('Active', ZhColors.primaryContainer, ZhColors.onPrimaryContainer),
      ReservationStatus.rescheduled => ('Rescheduled', ZhColors.warningContainer, ZhColors.onWarning),
      ReservationStatus.pickedUp => ('Picked up', ZhColors.divider, ZhColors.textSecondary),
      ReservationStatus.cancelled => ('Cancelled', ZhColors.error.withValues(alpha: 0.12), ZhColors.error),
      ReservationStatus.expired => ('Expired', ZhColors.divider, ZhColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// Short timestamp for the chat list: "4:15 pm", "Yesterday", or "Nov 24".
String _formatListTime(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;

  if (days == 0) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute $amPm';
  }
  if (days == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[local.month - 1]} ${local.day}';
}

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
