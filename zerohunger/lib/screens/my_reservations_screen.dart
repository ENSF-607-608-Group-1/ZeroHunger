// my_reservations_screen.dart
// Keeps every claim and its pickup code in one place, so a code is never lost.
//
//   QueryService.myReservations() -> a card per claim -> copy code or open pickup chat
//
// The current schema has no reservation records; this screen shows an empty state.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/query_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/food_parts.dart';
import '../widgets/form_parts.dart';
import '../widgets/notification_button.dart';
import 'pickup_chat_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({
    super.key,
    this.queryService,
    this.chatService,
    this.accountAction,
    this.onOpenChat,
  });

  final QueryService? queryService;
  final ChatService? chatService;
  final Widget? accountAction;
  final ValueChanged<Reservation>? onOpenChat;

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  late final QueryService _query = widget.queryService ?? QueryService();
  late final AuthService? _auth = widget.accountAction == null ? AuthService() : null;

  late Future<List<Reservation>> _reservations = _query.myReservations();
  final _filters = <ReservationStatus>{}; // empty shows every status

  // Loads the list again (pull down to refresh).
  Future<void> _reload() async {
    final next = _query.myReservations();
    setState(() {
      _reservations = next;
    });
    await next;
  }

  // Upcoming reservations (active, rescheduled) first, then past ones; filtered if chips are selected.
  List<Reservation> _visible(List<Reservation> all) {
    final matching = _filters.isEmpty
        ? List<Reservation>.of(all)
        : all.where((r) => _filters.contains(r.status)).toList();

    matching.sort((a, b) {
      if (a.isUpcoming != b.isUpcoming) return a.isUpcoming ? -1 : 1;
      return a.isUpcoming
          ? a.pickupStart.compareTo(b.pickupStart) // soonest pickup first
          : b.pickupStart.compareTo(a.pickupStart); // most recent past claim first
    });
    return matching;
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    showZhMessage(context, 'Pickup code copied');
  }

  void _openChat(Reservation reservation) {
    final handler = widget.onOpenChat;
    if (handler != null) {
      handler(reservation);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PickupChatScreen.fromReservation(
          reservation,
          chatService: widget.chatService,
        ),
      ),
    );
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
          'My reservations',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          NotificationButton(
            queryService: widget.queryService,
            chatService: widget.chatService,
            accountAction: widget.accountAction,
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
            child: FutureBuilder<List<Reservation>>(
              future: _reservations,
              builder: (context, snapshot) {
                // A spinner on the first load. On a refresh the old list stays until the new one arrives.
                if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data ?? const <Reservation>[];
                final shown = _visible(all);

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(), // pull to refresh works on a short list too
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (snapshot.hasError)
                        const _Notice(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load reservations',
                          subtitle: 'Check your connection, then pull down to try again.',
                        )
                      else if (all.isEmpty)
                        const _Notice(
                          icon: Icons.receipt_long_rounded,
                          title: 'Reservation history is not available yet',
                          subtitle: 'The current database does not store claims and pickup codes for this screen.',
                        )
                      else if (shown.isEmpty)
                        const _Notice(
                          icon: Icons.search_off_rounded,
                          title: 'No reservations match these filters',
                          subtitle: 'Try turning a filter off.',
                        )
                      else
                        for (final reservation in shown) ...[
                          _ReservationCard(
                            reservation: reservation,
                            onCopyCode: () => _copyCode(reservation.pickupCode),
                            onOpenChat: () => _openChat(reservation),
                          ),
                          const SizedBox(height: 16),
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

  // The status filters, in a row you can scroll sideways. Tap one to turn it on or off.
  Widget _filterRow() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          for (final status in ReservationStatus.values) ...[
            TagChip(
              label: _statusLabel(status),
              selected: _filters.contains(status),
              onTap: () => setState(() {
                if (!_filters.remove(status)) _filters.add(status);
              }),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// One claim: donation name, status, pickup code + copy button, pickup time, address, and open chat.
class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.onCopyCode,
    required this.onOpenChat,
  });

  final Reservation reservation;
  final VoidCallback onCopyCode;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final start = r.pickupStart.toLocal();
    final end = r.pickupEnd.toLocal();
    final addr = r.address;
    final cancelReason = r.cancelReason;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  r.donationTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text),
                ),
              ),
              const SizedBox(width: 12),
              _StatusChip(status: r.status),
            ],
          ),
          if (r.items.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              itemsSummary(r.items),
              style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          _CodeBox(
            code: r.pickupCode,
            highlight: r.isUpcoming,
            onCopy: onCopyCode,
          ),
          const SizedBox(height: 12),
          IconLine(icon: Icons.schedule_rounded, text: pickupWindowText(start, end)),
          if (r.isUpcoming) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                r.status == ReservationStatus.rescheduled
                    ? 'New time · ${_startsIn(start, end)}'
                    : _startsIn(start, end),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: r.status == ReservationStatus.rescheduled ? ZhColors.warningIcon : ZhColors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          IconLine(
            icon: Icons.place_outlined,
            text: '${addr.line1}, ${addr.city}, ${addr.province} ${addr.postalCode}',
          ),
          if (r.status == ReservationStatus.cancelled && cancelReason != null && cancelReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: ZhColors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cancelReason,
                    style: const TextStyle(fontSize: 13, color: ZhColors.error),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: r.isUpcoming
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ZhColors.primary,
                      foregroundColor: ZhColors.onPrimary,
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Open pickup chat'),
                  )
                : OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ZhColors.textSecondary,
                      side: const BorderSide(color: ZhColors.outline),
                      minimumSize: const Size.fromHeight(44),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    onPressed: onOpenChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Open pickup chat'),
                  ),
          ),
        ],
      ),
    );
  }
}

// The pickup code box with the formatted 6-digit code and a Copy code button.
class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.code,
    required this.highlight,
    required this.onCopy,
  });

  final String code;
  final bool highlight;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    // "615318" -> "615 318", easier to read out at pickup.
    final shown = code.length == 6 ? '${code.substring(0, 3)} ${code.substring(3)}' : code;
    final ink = highlight ? ZhColors.onPrimaryContainer : ZhColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? ZhColors.primaryContainer : ZhColors.background,
        border: highlight ? null : Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKUP CODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    shown,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onCopy,
            style: TextButton.styleFrom(
              foregroundColor: ink,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy code'),
          ),
        ],
      ),
    );
  }
}

// Status badge matching the app's chip style (8 dp corners, 12 sp medium/semibold text).
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, iconColor, icon) = switch (status) {
      ReservationStatus.active => (
          ZhColors.primaryContainer,
          ZhColors.onPrimaryContainer,
          ZhColors.onPrimaryContainer,
          Icons.check_circle_outline_rounded,
        ),
      ReservationStatus.rescheduled => (
          ZhColors.warningContainer,
          ZhColors.onWarning,
          ZhColors.warningIcon,
          Icons.update_rounded,
        ),
      ReservationStatus.pickedUp => (
          ZhColors.divider,
          ZhColors.textSecondary,
          ZhColors.textSecondary,
          Icons.task_alt_rounded,
        ),
      ReservationStatus.cancelled => (
          ZhColors.error.withValues(alpha: 0.12),
          ZhColors.error,
          ZhColors.error,
          Icons.cancel_outlined,
        ),
      ReservationStatus.expired => (
          ZhColors.divider,
          ZhColors.textSecondary,
          ZhColors.textSecondary,
          Icons.event_busy_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 4),
          Text(
            _statusLabel(status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(ReservationStatus status) => switch (status) {
      ReservationStatus.active => 'Active',
      ReservationStatus.rescheduled => 'Rescheduled',
      ReservationStatus.pickedUp => 'Picked up',
      ReservationStatus.cancelled => 'Cancelled',
      ReservationStatus.expired => 'Expired',
    };

// When pickup starts, in words: "Starts in 1 h 45 min", "Pickup is open now" or "The pickup time has passed".
String _startsIn(DateTime start, DateTime end) {
  final now = DateTime.now();
  if (now.isAfter(end)) return 'The pickup time has passed';
  if (!now.isBefore(start)) return 'Pickup is open now';
  final wait = start.difference(now);
  final hours = wait.inHours;
  final minutes = wait.inMinutes % 60;
  if (hours == 0) return 'Starts in $minutes min';
  return minutes == 0 ? 'Starts in $hours h' : 'Starts in $hours h $minutes min';
}

// A message in place of the list, e.g. "No reservations yet".
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
