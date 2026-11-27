// events_screen.dart
// Upcoming food distributions and donation events near the user (guests included).
//
//   QueryService.upcomingEvents() -> a card per event -> tap one -> EventDetailsScreen
//
// EventDetailsScreen shows all event fields plus comments, RSVP (local state until backend
// exists), Follow organization, and for the host, End early.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/query_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/food_parts.dart';
import '../widgets/form_parts.dart';

typedef EndEventEarlyFn = Future<void> Function(String eventId);
typedef ToggleFollowOrgFn = Future<void> Function(String organization, bool follow);
typedef ToggleRsvpFn = Future<void> Function(String eventId, bool rsvp);

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    this.queryService,
    this.onEndEarly,
    this.onToggleFollowOrg,
    this.onToggleRsvp,
    this.showAccountButton = true,
  });

  final QueryService? queryService;
  final EndEventEarlyFn? onEndEarly;
  final ToggleFollowOrgFn? onToggleFollowOrg;
  final ToggleRsvpFn? onToggleRsvp;
  final bool showAccountButton;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  AuthService? _authInstance;
  AuthService get _auth => _authInstance ??= AuthService();
  late final QueryService _query = widget.queryService ?? QueryService();

  List<CommunityEvent>? _events;
  bool _loading = true;
  bool _loadFailed = false;
  EventKind? _kindFilter; // null shows both Food distribution and Donation event

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = _events == null;
      _loadFailed = false;
    });
    try {
      final list = await _query.upcomingEvents();
      if (!mounted) return;
      setState(() {
        _events = List<CommunityEvent>.from(list);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  List<CommunityEvent> get _visibleEvents {
    final all = _events ?? const [];
    if (_kindFilter == null) return all;
    return all.where((e) => e.kind == _kindFilter).toList();
  }

  Future<void> _openDetails(CommunityEvent event) async {
    final updated = await Navigator.push<CommunityEvent>(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          event: event,
          onEndEarly: widget.onEndEarly,
          onToggleFollowOrg: widget.onToggleFollowOrg,
          onToggleRsvp: widget.onToggleRsvp,
          showAccountButton: widget.showAccountButton,
        ),
      ),
    );
    if (updated == null || !mounted) return;

    setState(() {
      final list = _events;
      if (list == null) return;
      for (var i = 0; i < list.length; i++) {
        if (list[i].eventId == updated.eventId) {
          list[i] = updated;
        } else if (updated.organization != null && list[i].organization == updated.organization) {
          // Keep Follow state consistent across all events from the same organization.
          list[i] = list[i].copyWith(followingOrganization: updated.followingOrganization);
        }
      }
    });
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
          'Events',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          if (widget.showAccountButton)
            StreamBuilder<User?>(
              stream: _auth.userChanges,
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadEvents,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (_loadFailed)
                          const _Notice(
                            icon: Icons.cloud_off_rounded,
                            title: 'Could not load events',
                            subtitle: 'Check your connection, then pull down to try again.',
                          )
                        else if (_visibleEvents.isEmpty)
                          _Notice(
                            icon: Icons.event_busy_rounded,
                            title: _kindFilter == null
                                ? 'No upcoming events near you'
                                : 'No ${_kindFilter!.label.toLowerCase()}s right now',
                            subtitle: _kindFilter == null
                                ? 'Pull down to check again later.'
                                : 'Try switching the filter to All.',
                          )
                        else
                          for (final event in _visibleEvents) ...[
                            _EventCard(event: event, onTap: () => _openDetails(event)),
                            const SizedBox(height: 16),
                          ],
                      ],
                    ),
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
            selected: _kindFilter == null,
            onTap: () => setState(() => _kindFilter = null),
          ),
          const SizedBox(width: 8),
          for (final kind in EventKind.values) ...[
            TagChip(
              label: kind.label,
              selected: _kindFilter == kind,
              onTap: () => setState(() {
                _kindFilter = _kindFilter == kind ? null : kind;
              }),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// One event card: kind, title, date and time, address, organization.
class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final CommunityEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final a = e.address;

    return Material(
      color: ZhColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ZhColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _EventKindBadge(kind: e.kind),
                  if (e.endedEarly) const _SmallBadge(label: 'Ended early', bg: ZhColors.divider, fg: ZhColors.textSecondary),
                  if (e.isHost) const _SmallBadge(label: 'Host', bg: ZhColors.divider, fg: ZhColors.text),
                  if (e.rsvped && !e.endedEarly)
                    const _SmallBadge(label: 'Going', bg: ZhColors.primaryContainer, fg: ZhColors.onPrimaryContainer),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                e.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: ZhColors.text),
              ),
              const SizedBox(height: 12),
              IconLine(
                icon: Icons.schedule_rounded,
                text: pickupWindowText(e.startTime, e.endTime),
              ),
              const SizedBox(height: 8),
              IconLine(
                icon: Icons.place_outlined,
                text: '${a.line1}, ${a.city}, ${a.province} ${a.postalCode}',
              ),
              if (e.organization != null && e.organization!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                IconLine(
                  icon: Icons.groups_outlined,
                  text: e.organization!,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${e.rsvpCount} going',
                    style: const TextStyle(fontSize: 13, color: ZhColors.textSecondary),
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ZhColors.primary),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 20, color: ZhColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event details screen
// ---------------------------------------------------------------------------

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.event,
    this.onEndEarly,
    this.onToggleFollowOrg,
    this.onToggleRsvp,
    this.showAccountButton = true,
  });

  final CommunityEvent event;
  final EndEventEarlyFn? onEndEarly;
  final ToggleFollowOrgFn? onToggleFollowOrg;
  final ToggleRsvpFn? onToggleRsvp;
  final bool showAccountButton;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  AuthService? _authInstance;
  AuthService get _auth => _authInstance ??= AuthService();

  late CommunityEvent _event = widget.event;
  bool _togglingRsvp = false;
  bool _togglingFollow = false;
  bool _endingEarly = false;

  Future<void> _toggleRsvp() async {
    if (_event.endedEarly || _togglingRsvp) return;
    final nextRsvp = !_event.rsvped;

    setState(() => _togglingRsvp = true);
    try {
      if (widget.onToggleRsvp != null) {
        await widget.onToggleRsvp!(_event.eventId, nextRsvp);
      } else {
        // TODO: Wire RSVP to DistributionService once backend supports EventRSVP.
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      if (!mounted) return;
      final nextCount = (_event.rsvpCount + (nextRsvp ? 1 : -1)).clamp(0, 999999);
      setState(() {
        _event = _event.copyWith(rsvped: nextRsvp, rsvpCount: nextCount);
      });
      showZhMessage(context, nextRsvp ? 'RSVP confirmed!' : 'RSVP cancelled.');
    } catch (_) {
      if (mounted) showZhMessage(context, 'Could not update RSVP. Please try again.');
    } finally {
      if (mounted) setState(() => _togglingRsvp = false);
    }
  }

  Future<void> _toggleFollowOrganization() async {
    final org = _event.organization;
    if (org == null || _togglingFollow) return;
    final nextFollow = !_event.followingOrganization;

    setState(() => _togglingFollow = true);
    try {
      if (widget.onToggleFollowOrg != null) {
        await widget.onToggleFollowOrg!(org, nextFollow);
      } else {
        // TODO: Wire organization subscription to PushService / FCM topic once built.
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      if (!mounted) return;
      setState(() {
        _event = _event.copyWith(followingOrganization: nextFollow);
      });
      showZhMessage(
        context,
        nextFollow ? 'Following $org for future event alerts.' : 'Unfollowed $org.',
      );
    } catch (_) {
      if (mounted) showZhMessage(context, 'Could not update follow status. Please try again.');
    } finally {
      if (mounted) setState(() => _togglingFollow = false);
    }
  }

  Future<void> _confirmEndEarly() async {
    if (_event.endedEarly || _endingEarly) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ZhColors.surface,
      barrierColor: const Color(0x66000000),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _EndEarlySheet(title: _event.title),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _endingEarly = true);
    try {
      if (widget.onEndEarly != null) {
        await widget.onEndEarly!(_event.eventId);
      } else {
        // TODO: Wire End early to DistributionService once backend supports ending events early.
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!mounted) return;
      setState(() {
        _event = _event.copyWith(endedEarly: true);
      });
      showZhMessage(context, 'Event ended early.');
    } catch (_) {
      if (mounted) showZhMessage(context, 'Could not end event early. Please try again.');
    } finally {
      if (mounted) setState(() => _endingEarly = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _event;
    final a = e.address;
    final hasOrg = e.organization != null && e.organization!.trim().isNotEmpty;

    return PopScope<CommunityEvent>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _event);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ZhColors.background,
          foregroundColor: ZhColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _event),
          ),
          title: const Text(
            'Event details',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
          ),
          actions: [
            if (widget.showAccountButton)
              StreamBuilder<User?>(
                stream: _auth.userChanges,
                initialData: _auth.currentUser,
                builder: (context, snapshot) => AccountButton(user: snapshot.data),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _EventKindBadge(kind: e.kind),
                if (e.endedEarly)
                  const _SmallBadge(label: 'Ended early', bg: ZhColors.divider, fg: ZhColors.textSecondary),
                if (e.isHost) const _SmallBadge(label: 'Host', bg: ZhColors.divider, fg: ZhColors.text),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              e.title,
              style: const TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600, color: ZhColors.text),
            ),
            const SizedBox(height: 16),

            // Date, time, address and organization panel
            _Panel(
              children: [
                IconLine(
                  icon: Icons.schedule_rounded,
                  text: pickupWindowText(e.startTime, e.endTime),
                ),
                const SizedBox(height: 12),
                IconLine(
                  icon: Icons.place_outlined,
                  text: '${a.line1}\n${a.city}, ${a.province} ${a.postalCode}',
                ),
                if (hasOrg) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: ZhColors.divider),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: IconLine(
                          icon: Icons.groups_outlined,
                          text: e.organization!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  e.followingOrganization
                      ? FilledButton.tonalIcon(
                          onPressed: _togglingFollow ? null : _toggleFollowOrganization,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Following organization'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ZhColors.primaryContainer,
                            foregroundColor: ZhColors.onPrimaryContainer,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: _togglingFollow ? null : _toggleFollowOrganization,
                          icon: const Icon(Icons.notifications_active_outlined, size: 18),
                          label: const Text('Follow organization'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ZhColors.primary,
                            side: const BorderSide(color: ZhColors.primary),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                ],
              ],
            ),

            // Comments panel
            if (e.comments.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _Panel(
                children: [
                  const SectionHeading('Comments'),
                  Text(
                    e.comments,
                    style: const TextStyle(fontSize: 15, height: 1.5, color: ZhColors.text),
                  ),
                ],
              ),
            ],

            // Host controls: End early button
            if (e.isHost) ...[
              const SizedBox(height: 16),
              _Panel(
                children: [
                  const SectionHeading('Host controls'),
                  Text(
                    e.endedEarly
                        ? 'This event has been ended early. Attendees and nearby users can see that it is closed.'
                        : 'Food ran out or need to close early? End this event early so nearby users know.',
                    style: const TextStyle(fontSize: 14, height: 1.4, color: ZhColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: e.endedEarly || _endingEarly ? null : _confirmEndEarly,
                      icon: _endingEarly
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.error),
                            )
                          : const Icon(Icons.stop_circle_outlined, size: 20),
                      label: Text(e.endedEarly ? 'Event ended early' : 'End early'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ZhColors.error,
                        disabledForegroundColor: ZhColors.textSecondary,
                        side: BorderSide(color: e.endedEarly ? ZhColors.divider : ZhColors.error),
                        minimumSize: const Size.fromHeight(48),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

  Widget _bottomBar() {
    final e = _event;

    return Container(
      decoration: const BoxDecoration(
        color: ZhColors.surface,
        border: Border(top: BorderSide(color: ZhColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  e.endedEarly
                      ? 'Event status'
                      : (e.rsvped ? "You're going" : 'Attendance'),
                  style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  e.endedEarly ? 'Ended early' : '${e.rsvpCount} going',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ZhColors.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (e.rsvped && !e.endedEarly)
              OutlinedButton.icon(
                onPressed: _togglingRsvp ? null : _toggleRsvp,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Going — Cancel RSVP'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZhColors.primary,
                  side: const BorderSide(color: ZhColors.primary),
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              )
            else
              FilledButton.icon(
                style: zhPrimaryButton(),
                onPressed: e.endedEarly || _togglingRsvp ? null : _toggleRsvp,
                icon: const Icon(Icons.event_available_rounded, size: 20),
                label: Text(e.endedEarly ? 'Event ended' : 'RSVP'),
              ),
          ],
        ),
      ),
    );
  }
}

// Confirmation bottom sheet for the host's End early action.
class _EndEarlySheet extends StatelessWidget {
  const _EndEarlySheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(color: ZhColors.outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'End event early?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              '"$title" will be marked as ended early so people nearby know food is no longer being distributed.',
              style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ZhColors.error,
                foregroundColor: ZhColors.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End early'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: ZhColors.textSecondary,
                  minimumSize: const Size(0, 48),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: const Text('Keep running'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventKindBadge extends StatelessWidget {
  const _EventKindBadge({required this.kind});

  final EventKind kind;

  @override
  Widget build(BuildContext context) {
    final isDistribution = kind == EventKind.foodDistribution;
    return _SmallBadge(
      label: kind.label,
      bg: isDistribution ? ZhColors.primaryContainer : ZhColors.warningContainer,
      fg: isDistribution ? ZhColors.onPrimaryContainer : ZhColors.onWarning,
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
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
