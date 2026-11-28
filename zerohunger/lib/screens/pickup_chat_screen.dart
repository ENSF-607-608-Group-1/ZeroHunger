// pickup_chat_screen.dart
// Lets the donor and the person who claimed a donation arrange the pickup.
//
// Can be opened directly for a specific claim/recipient from:
//   - PickupChatsScreen (list of chats from Home)
//   - MyReservationsScreen ("Open pickup chat" -> PickupChatScreen.fromReservation)
//   - MyDonationsScreen ("Open pickup chat" for a specific recipient)
//   - ClaimedScreen ("Open pickup chat")

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/chat_service.dart';
import '../services/query_service.dart';
import '../services/zero_hunger_api.dart';
import '../theme/app_theme.dart';
import '../widgets/food_parts.dart';

class PickupChatScreen extends StatefulWidget {
  const PickupChatScreen({
    super.key,
    required this.conversationId,
    this.donationId,
    this.donationTitle,
    this.otherPartyName,
    this.myRole = ChatRole.recipient,
    this.status = ReservationStatus.active,
    this.pickupCode,
    this.pickupStart,
    this.pickupEnd,
    this.address,
    this.chatService,
  });

  // Opens the exact pickup chat for a claimed reservation.
  factory PickupChatScreen.fromReservation(
    Reservation reservation, {
    Key? key,
    ChatService? chatService,
  }) {
    return PickupChatScreen(
      key: key,
      conversationId: reservation.reservationId,
      donationId: reservation.donationId,
      donationTitle: reservation.donationTitle,
      myRole: ChatRole.recipient,
      status: reservation.status,
      pickupCode: reservation.pickupCode,
      pickupStart: reservation.pickupStart,
      pickupEnd: reservation.pickupEnd,
      address: reservation.address,
      chatService: chatService,
    );
  }

  // Opens a specific thread directly (from the chat list or from a donation's recipient list).
  factory PickupChatScreen.fromThread(
    PickupChatThread thread, {
    Key? key,
    ChatService? chatService,
  }) {
    return PickupChatScreen(
      key: key,
      conversationId: thread.conversationId,
      donationId: thread.donationId,
      donationTitle: thread.donationTitle,
      otherPartyName: thread.otherPartyName,
      myRole: thread.myRole,
      status: thread.status,
      pickupCode: thread.pickupCode,
      pickupStart: thread.pickupStart,
      pickupEnd: thread.pickupEnd,
      address: thread.address,
      chatService: chatService,
    );
  }

  final String conversationId;
  final String? donationId;
  final String? donationTitle;
  final String? otherPartyName;
  final ChatRole myRole;
  final ReservationStatus status;
  final String? pickupCode;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;
  final PickupAddress? address;
  final ChatService? chatService;

  @override
  State<PickupChatScreen> createState() => _PickupChatScreenState();
}

class _PickupChatScreenState extends State<PickupChatScreen> {
  late final ChatService _chat = widget.chatService ?? ChatService.connected();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  PickupChatThread? _thread;
  bool _loading = true;
  String? _loadError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
    ChatService.updatesListenable.addListener(_handleRemoteUpdate);
    _load();
  }

  @override
  void dispose() {
    ChatService.updatesListenable.removeListener(_handleRemoteUpdate);
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleRemoteUpdate() {
    if (mounted && _chat.isConnected && !_loading) {
      _refreshQuietly();
    }
  }

  Future<void> _refreshQuietly() async {
    try {
      final loaded = await _chat.openChat(
        conversationId: widget.conversationId,
        donationId: widget.donationId,
        donationTitle: widget.donationTitle,
        otherPartyName: widget.otherPartyName,
        myRole: widget.myRole,
        status: widget.status,
        pickupCode: widget.pickupCode,
        pickupStart: widget.pickupStart,
        pickupEnd: widget.pickupEnd,
        address: widget.address,
      );
      if (!mounted) return;
      final grew = loaded.messages.length > (_thread?.messages.length ?? 0);
      setState(() => _thread = loaded);
      if (grew) _scrollToBottom();
    } catch (_) {}
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final loaded = await _chat.openChat(
        conversationId: widget.conversationId,
        donationId: widget.donationId,
        donationTitle: widget.donationTitle,
        otherPartyName: widget.otherPartyName,
        myRole: widget.myRole,
        status: widget.status,
        pickupCode: widget.pickupCode,
        pickupStart: widget.pickupStart,
        pickupEnd: widget.pickupEnd,
        address: widget.address,
      );
      if (!mounted) return;
      setState(() {
        _thread = loaded;
        _loading = false;
      });
      _scrollToBottom(jump: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load pickup chat.';
      });
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _thread == null) return;

    setState(() => _sending = true);
    try {
      final sent = await _chat.sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );
      if (!mounted) return;
      _input.clear();
      setState(() {
        _thread = _thread!.copyWith(messages: [..._thread!.messages, sent]);
        _sending = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showZhMessage(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showZhMessage(context, 'Could not send message. Please try again.', onRetry: _send);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final title = thread?.donationTitle ?? widget.donationTitle ?? 'Pickup chat';
    final otherRole = thread?.otherPartyRoleLabel ?? (widget.myRole == ChatRole.recipient ? 'Donor' : 'Recipient');
    final otherName = thread?.otherPartyName ?? widget.otherPartyName;
    final subtitle = (otherName != null && otherName.isNotEmpty) ? '$otherRole · $otherName' : otherRole;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ZhColors.text),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (_chat.isConnected)
            IconButton(
              tooltip: 'Refresh messages',
              onPressed: _loading ? null : _refreshQuietly,
              icon: const Icon(Icons.refresh_rounded, size: 22),
            ),
        ],
      ),
      body: Column(
        children: [
          if (thread != null) _PickupSummaryBar(thread: thread),
          Expanded(child: _buildMessagesBody()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessagesBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: ZhColors.primaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.cloud_off_rounded, size: 32, color: ZhColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: ZhColors.text),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ZhColors.primary,
                  foregroundColor: ZhColors.onPrimary,
                  shape: const StadiumBorder(),
                ),
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final thread = _thread!;
    final messages = thread.messages;

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _chat.isConnected
                ? 'Pickup chat is ready. Send a message to coordinate pickup.'
                : 'Message history is not available yet. You can still send a message.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: message.sender == ChatSender.system
              ? _SystemMessageTile(message: message)
              : _MessageBubble(
                  message: message,
                  otherRoleLabel: thread.otherPartyRoleLabel,
                ),
        );
      },
    );
  }

  Widget _buildComposer() {
    final count = _input.text.length;
    final canSend = _input.text.trim().isNotEmpty && !_sending && !_loading && _thread != null;
    final nearLimit = count >= maxChatMessageLength - 100;

    return Container(
      decoration: const BoxDecoration(
        color: ZhColors.surface,
        border: Border(top: BorderSide(color: ZhColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_loading && _thread != null,
                    maxLength: maxChatMessageLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Write a message…',
                      hintStyle: const TextStyle(fontSize: 15, color: ZhColors.placeholder),
                      counterText: '',
                      filled: true,
                      fillColor: ZhColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: ZhColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: ZhColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: ZhColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton.filled(
                    tooltip: 'Send',
                    onPressed: canSend ? _send : null,
                    style: IconButton.styleFrom(
                      backgroundColor: ZhColors.primary,
                      foregroundColor: ZhColors.onPrimary,
                      disabledBackgroundColor: ZhColors.divider,
                      disabledForegroundColor: ZhColors.textSecondary,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.onPrimary),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 52),
              child: Text(
                '$count/$maxChatMessageLength',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: nearLimit ? FontWeight.w600 : FontWeight.w400,
                  color: count >= maxChatMessageLength ? ZhColors.error : ZhColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Prominent banner pinned at the top of the chat showing the unique pickup verification
// code, unique reservation ID, pickup time window, and reservation status.
class _PickupSummaryBar extends StatelessWidget {
  const _PickupSummaryBar({required this.thread});

  final PickupChatThread thread;

  @override
  Widget build(BuildContext context) {
    final start = thread.pickupStart?.toLocal();
    final end = thread.pickupEnd?.toLocal();
    final code = thread.pickupCode;

    if (start == null && (code == null || code.isEmpty)) return const SizedBox.shrink();

    final formattedCode = (code != null && code.isNotEmpty) ? formatPickupCode(code) : null;
    final instruction = thread.myRole == ChatRole.recipient
        ? 'Show this code to the donor to receive your food.'
        : 'Verify this code from the recipient at pickup.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: ZhColors.surface,
        border: Border(
          top: BorderSide(color: ZhColors.divider),
          bottom: BorderSide(color: ZhColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (formattedCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ZhColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ZhColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 22,
                    color: ZhColors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'PICKUP CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: ZhColors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ID #${thread.shortReservationId}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: ZhColors.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                            color: ZhColors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          instruction,
                          style: TextStyle(
                            fontSize: 11,
                            color: ZhColors.onPrimaryContainer.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code!));
                      if (context.mounted) showZhMessage(context, 'Pickup code copied');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: ZhColors.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text(
                      'Copy',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            if (start != null && end != null) const SizedBox(height: 8),
          ],
          if (start != null && end != null)
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 15, color: ZhColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pickupWindowText(start, end),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ZhColors.text),
                  ),
                ),
                _MiniStatusPill(status: thread.status),
              ],
            )
          else if (formattedCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_MiniStatusPill(status: thread.status)],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  const _MiniStatusPill({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// Centered system message from the app, e.g. "Pickup chat opened".
class _SystemMessageTile extends StatelessWidget {
  const _SystemMessageTile({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ZhColors.divider.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline_rounded, size: 15, color: ZhColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    message.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ZhColors.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _formatMessageTime(message.sentAt),
              style: const TextStyle(fontSize: 11, color: ZhColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// A message bubble from the current user or the other party, showing who sent it and when.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.otherRoleLabel});

  final ChatMessage message;
  final String otherRoleLabel;

  @override
  Widget build(BuildContext context) {
    final isMe = message.sender == ChatSender.me;
    final senderLabel = isMe ? 'You' : '${message.senderName} ($otherRoleLabel)';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '$senderLabel · ${_formatMessageTime(message.sentAt)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ZhColors.textSecondary),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? ZhColors.primary : ZhColors.surface,
                border: isMe ? null : Border.all(color: ZhColors.divider),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: isMe ? ZhColors.onPrimary : ZhColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Formats a message timestamp cleanly, e.g. "4:15 pm", "Yesterday, 5:30 pm", or "Nov 24, 2:10 pm".
String _formatMessageTime(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();
  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;

  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour < 12 ? 'am' : 'pm';
  final clock = '$hour:$minute $amPm';

  if (days == 0) return clock;
  if (days == 1) return 'Yesterday, $clock';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[local.month - 1]} ${local.day}, $clock';
}
