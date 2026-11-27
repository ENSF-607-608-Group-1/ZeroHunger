// organizations_screen.dart
// Lets anyone (guests included) find local food banks and community groups,
// and follow them for alerts about upcoming donations and distribution events.
//
//   QueryService.organizations() -> one row per organization (name, city, Follow/Following)
//
// Organization rows come from Data Connect. Follow toggles remain local until a
// dedicated follow relation and notification subscription flow are available.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/query_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/form_parts.dart';

typedef ToggleOrganizationFollowFn = Future<void> Function(String organizationId, bool follow);

class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({
    super.key,
    this.queryService,
    this.onToggleFollow,
    this.showAccountButton = true,
  });

  final QueryService? queryService;
  final ToggleOrganizationFollowFn? onToggleFollow;
  final bool showAccountButton;

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  AuthService? _authInstance;
  AuthService get _auth => _authInstance ??= AuthService();
  late final QueryService _query = widget.queryService ?? QueryService();

  final _search = TextEditingController();
  List<OrganizationSummary>? _organizations;
  final _busyIds = <String>{}; // org IDs currently saving a follow toggle
  bool _loading = true;
  bool _loadFailed = false;
  bool _onlyFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _loading = _organizations == null;
      _loadFailed = false;
    });
    try {
      final list = await _query.organizations();
      if (!mounted) return;
      setState(() {
        _organizations = List<OrganizationSummary>.from(list);
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

  Future<void> _toggleFollow(OrganizationSummary org) async {
    if (_busyIds.contains(org.organizationId)) return;
    final nextFollow = !org.following;

    setState(() => _busyIds.add(org.organizationId));
    try {
      if (widget.onToggleFollow != null) {
        await widget.onToggleFollow!(org.organizationId, nextFollow);
      } else {
        showZhMessage(context, 'Organization follows are not available yet.');
        return;
      }
      if (!mounted) return;
      setState(() {
        final list = _organizations;
        if (list != null) {
          final index = list.indexWhere((o) => o.organizationId == org.organizationId);
          if (index != -1) list[index] = org.copyWith(following: nextFollow);
        }
      });
      showZhMessage(
        context,
        nextFollow
            ? 'Following ${org.name} for alerts.'
            : 'Unfollowed ${org.name}.',
      );
    } catch (_) {
      if (mounted) showZhMessage(context, 'Could not update follow status. Please try again.');
    } finally {
      if (mounted) setState(() => _busyIds.remove(org.organizationId));
    }
  }

  List<OrganizationSummary> get _visibleOrganizations {
    final all = _organizations ?? const [];
    final q = _search.text.trim().toLowerCase();

    return all.where((org) {
      if (_onlyFollowing && !org.following) return false;
      if (q.isEmpty) return true;
      return org.name.toLowerCase().contains(q) || org.city.toLowerCase().contains(q);
    }).toList();
  }

  int get _followingCount => (_organizations ?? const []).where((o) => o.following).length;

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
          'Organizations',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: zhField(
                label: 'Search organizations',
                hint: 'Name or city',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: _search.text.isEmpty
                    ? const Icon(Icons.search_rounded, color: ZhColors.textSecondary)
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => setState(() => _search.clear()),
                        icon: const Icon(Icons.close_rounded, color: ZhColors.textSecondary),
                      ),
              ),
            ),
          ),
          _filterRow(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadOrganizations,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (_loadFailed)
                          const _Notice(
                            icon: Icons.cloud_off_rounded,
                            title: 'Could not load organizations',
                            subtitle: 'Check your connection, then pull down to try again.',
                          )
                        else if (_visibleOrganizations.isEmpty)
                          _Notice(
                            icon: _onlyFollowing ? Icons.notifications_none_rounded : Icons.search_off_rounded,
                            title: _onlyFollowing && _search.text.trim().isEmpty
                                ? 'Not following any organizations yet'
                                : 'No organizations found',
                            subtitle: _onlyFollowing && _search.text.trim().isEmpty
                                ? 'Follow local food banks and groups to get alerts about upcoming events.'
                                : 'Try a different name, city, or filter.',
                          )
                        else
                          for (final org in _visibleOrganizations) ...[
                            _OrganizationRow(
                              organization: org,
                              busy: _busyIds.contains(org.organizationId),
                              onToggleFollow: () => _toggleFollow(org),
                            ),
                            const SizedBox(height: 12),
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
    final count = _followingCount;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          TagChip(
            label: 'All',
            selected: !_onlyFollowing,
            onTap: () => setState(() => _onlyFollowing = false),
          ),
          const SizedBox(width: 8),
          TagChip(
            label: count > 0 ? 'Following ($count)' : 'Following',
            selected: _onlyFollowing,
            onTap: () => setState(() => _onlyFollowing = !_onlyFollowing),
          ),
        ],
      ),
    );
  }
}

// One row per organization: name, city, and a Follow / Following button.
class _OrganizationRow extends StatelessWidget {
  const _OrganizationRow({
    required this.organization,
    required this.busy,
    required this.onToggleFollow,
  });

  final OrganizationSummary organization;
  final bool busy;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final org = organization;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: ZhColors.primaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.groups_outlined, size: 22, color: ZhColors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ZhColors.text),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 15, color: ZhColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        org.city,
                        style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          org.following
              ? FilledButton.tonalIcon(
                  onPressed: busy ? null : onToggleFollow,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Following'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ZhColors.primaryContainer,
                    foregroundColor: ZhColors.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                )
              : OutlinedButton(
                  onPressed: busy ? null : onToggleFollow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ZhColors.primary,
                    side: const BorderSide(color: ZhColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Follow'),
                ),
        ],
      ),
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
