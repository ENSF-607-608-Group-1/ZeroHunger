// my_activity_screen.dart
// Shows what the user has given and done on Zero Hunger:
//   - Totals: donations posted, food given, claims, events hosted
//   - History: the date and what happened, e.g. "Posted Rice and stew"
//
// Reached from the "My activity" section under the top-right Profile button.
// Until the database exists, the summary comes from the sample data in activity_service.dart.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/form_parts.dart';
import '../widgets/notification_button.dart';

enum _ActivityFilter { all, postedDonation, foodGiven, claim, eventHosted }

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({
    super.key,
    this.activityService,
    this.accountAction,
  });

  final ActivityService? activityService;
  final Widget? accountAction;

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  late final ActivityService _activity = widget.activityService ?? ActivityService();
  late final AuthService? _auth = widget.accountAction == null ? AuthService() : null;

  late Future<ActivitySummary> _summaryFuture = _activity.myActivity();
  _ActivityFilter _filter = _ActivityFilter.all;

  // Loads the summary again (pull down to refresh).
  Future<void> _reload() async {
    final next = _activity.myActivity();
    setState(() {
      _summaryFuture = next;
    });
    await next;
  }

  List<ActivityEntry> _visibleHistory(List<ActivityEntry> all) {
    return switch (_filter) {
      _ActivityFilter.all => all,
      _ActivityFilter.postedDonation => all.where((e) => e.kind == ActivityKind.postedDonation).toList(),
      _ActivityFilter.foodGiven => all.where((e) => e.kind == ActivityKind.foodGiven).toList(),
      _ActivityFilter.claim => all.where((e) => e.kind == ActivityKind.claim).toList(),
      _ActivityFilter.eventHosted => all.where((e) => e.kind == ActivityKind.eventHosted).toList(),
    };
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
          'My activity',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          NotificationButton(accountAction: widget.accountAction),
          if (widget.accountAction != null)
            widget.accountAction!
          else
            StreamBuilder<User?>(
              stream: _auth!.userChanges,
              initialData: _auth.currentUser,
              builder: (context, snapshot) => AccountButton(user: snapshot.data, showMyActivity: false),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<ActivitySummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: const [
                  _Notice(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load activity',
                    subtitle: 'Check your connection, then pull down to try again.',
                  ),
                ],
              ),
            );
          }

          final summary = snapshot.data!;
          final shownHistory = _visibleHistory(summary.history);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Text(
                  'Your impact so far',
                  style: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600, color: ZhColors.text),
                ),
                const SizedBox(height: 4),
                const Text(
                  'See what you have shared, claimed, and hosted in your community.',
                  style: TextStyle(fontSize: 14, color: ZhColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const SectionHeading('Totals'),
                _TotalsGrid(totals: summary.totals),
                const SizedBox(height: 20),
                const SectionHeading('History'),
                _filterRow(),
                const SizedBox(height: 12),
                if (summary.history.isEmpty)
                  const _Notice(
                    icon: Icons.history_rounded,
                    title: 'No activity yet',
                    subtitle: 'Food you donate, claim, and events you host will show up here.',
                  )
                else if (shownHistory.isEmpty)
                  const _Notice(
                    icon: Icons.search_off_rounded,
                    title: 'No activity matches this filter',
                    subtitle: 'Try switching the filter above.',
                  )
                else
                  for (final entry in shownHistory) ...[
                    _HistoryCard(entry: entry),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final filter in _ActivityFilter.values) ...[
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

String _filterLabel(_ActivityFilter filter) => switch (filter) {
      _ActivityFilter.all => 'All',
      _ActivityFilter.postedDonation => 'Donations',
      _ActivityFilter.foodGiven => 'Food given',
      _ActivityFilter.claim => 'Claims',
      _ActivityFilter.eventHosted => 'Events',
    };

// 2x2 grid of totals cards: Donations posted, Food given, Claims, Events hosted.
class _TotalsGrid extends StatelessWidget {
  const _TotalsGrid({required this.totals});

  final ActivityTotals totals;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TotalCard(
                label: 'Donations posted',
                value: '${totals.donationsPosted}',
                icon: Icons.volunteer_activism_outlined,
                iconBg: ZhColors.primaryContainer,
                iconFg: ZhColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TotalCard(
                label: 'Food given',
                value: '${totals.foodGiven}',
                subtitle: 'portions & items',
                icon: Icons.restaurant_outlined,
                iconBg: ZhColors.primaryContainer,
                iconFg: ZhColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TotalCard(
                label: 'Claims',
                value: '${totals.claims}',
                icon: Icons.shopping_bag_outlined,
                iconBg: ZhColors.primaryContainer,
                iconFg: ZhColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TotalCard(
                label: 'Events hosted',
                value: '${totals.eventsHosted}',
                icon: Icons.event_outlined,
                iconBg: ZhColors.warningContainer,
                iconFg: ZhColors.warningIcon,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconFg),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ZhColors.text),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ZhColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// One row in the History list: icon, summary (e.g. "Posted Rice and stew"), optional detail, date, and badge.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg, badgeLabel) = switch (entry.kind) {
      ActivityKind.postedDonation => (
          Icons.volunteer_activism_outlined,
          ZhColors.primaryContainer,
          ZhColors.onPrimaryContainer,
          'Donation',
        ),
      ActivityKind.foodGiven => (
          Icons.task_alt_rounded,
          ZhColors.primaryContainer,
          ZhColors.onPrimaryContainer,
          'Food given',
        ),
      ActivityKind.claim => (
          Icons.shopping_bag_outlined,
          ZhColors.divider,
          ZhColors.textSecondary,
          'Claim',
        ),
      ActivityKind.eventHosted => (
          Icons.event_outlined,
          ZhColors.warningContainer,
          ZhColors.warningIcon,
          'Event',
        ),
    };

    final detail = entry.detail;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.summary,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ZhColors.text),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 13, color: ZhColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatHistoryDate(entry.occurredAt),
                      style: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Formats an activity date cleanly: "Today", "Yesterday", or "Nov 18, 2026" (or "Nov 18" for current year).
String _formatHistoryDate(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;

  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final dayLabel = '${months[local.month - 1]} ${local.day}';
  return local.year == now.year ? dayLabel : '$dayLabel, ${local.year}';
}

// A message in place of the list, matching Find food, My reservations, Pickup chats, and Notifications.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
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
