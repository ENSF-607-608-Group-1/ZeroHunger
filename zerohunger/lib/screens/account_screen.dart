// account_screen.dart
// Shows the user's account details: name, email (read-only), phone, address, role,
// organizations they belong to / follow, and a Sign out button (or Sign in / Create account for guests).
//
// Reached from the "Account" section under the top-right Profile menu.
// Loads profile and role data from Cloud SQL via Firebase Data Connect when signed in,
// and reloads automatically whenever the authenticated user changes.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/account_settings_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_button.dart';
import '../widgets/form_parts.dart';
import '../widgets/notification_button.dart';
import 'sign_in_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    this.accountSettingsService,
    this.accountAction,
    this.userEmailOverride,
    this.isGuestOverride,
    this.onCreateAccount,
    this.onSignOut,
  });

  final AccountSettingsService? accountSettingsService;
  final Widget? accountAction;
  final String? userEmailOverride; // for widget tests without Firebase
  final bool? isGuestOverride;     // for widget tests without Firebase
  final VoidCallback? onCreateAccount;
  final Future<void> Function()? onSignOut;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AuthService? _auth =
      (widget.accountAction == null && widget.isGuestOverride == null) ? AuthService() : null;

  late final AccountSettingsService _service = widget.accountSettingsService ??
      (_auth != null
          ? AccountSettingsService(
              remoteLoader: _auth.getCurrentUserProfile,
              remoteRoleUpdater: _auth.updateCurrentUserRole,
            )
          : AccountSettingsService());

  late Future<UserPreferences> _prefsFuture = _service.load();
  StreamSubscription<User?>? _authSub;
  String? _lastAuthKey;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    final auth = _auth;
    if (auth != null) {
      _lastAuthKey = _authKey(auth.currentUser);
      _authSub = auth.userChanges.listen((user) {
        final nextKey = _authKey(user);
        if (nextKey != _lastAuthKey && mounted) {
          _lastAuthKey = nextKey;
          _reload();
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  String _authKey(User? user) => '${user?.uid ?? ''}:${user?.isAnonymous ?? true}:${user?.email ?? ''}';

  Future<void> _reload() async {
    final next = _service.load();
    if (!mounted) return;
    setState(() {
      _prefsFuture = next;
    });
    await next;
  }

  Future<void> _changeRole(UserRole role) async {
    try {
      final updated = await _service.updateRole(role);
      if (!mounted) return;
      setState(() {
        _prefsFuture = Future.value(updated);
      });
      showZhMessage(context, 'Role updated to ${role.label}');
    } catch (_) {
      if (!mounted) return;
      showZhMessage(context, 'Could not update role. Please try again.');
    }
  }

  Future<void> _unfollow(FollowedOrganization org) async {
    try {
      final updated = await _service.unfollowOrganization(org.organizationId);
      if (!mounted) return;
      setState(() {
        _prefsFuture = Future.value(updated);
      });
      showZhMessage(context, 'Unfollowed ${org.name}');
    } catch (_) {
      if (!mounted) return;
      showZhMessage(context, 'Could not update followed organizations.');
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _signingOut = true);
    try {
      if (widget.onSignOut != null) {
        await widget.onSignOut!();
      } else {
        await _auth?.signOut();
      }
      if (!mounted) return;
      showZhMessage(context, 'Signed out');
      await _reload();
    } catch (_) {
      if (!mounted) return;
      showZhMessage(context, 'Could not sign out. Please try again.');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _openAuthSheet(SignInSheetMode mode) async {
    final authenticated = await showSignInSheet(context, initialMode: mode);
    if (authenticated && mounted) {
      await _reload();
    }
  }

  Future<void> _handleSignIn() async {
    await _openAuthSheet(SignInSheetMode.signIn);
  }

  Future<void> _handleCreateAccount() async {
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
      return;
    }
    await _openAuthSheet(SignInSheetMode.createAccount);
  }

  @override
  Widget build(BuildContext context) {
    if (_auth == null) {
      final isGuest = widget.isGuestOverride ?? (widget.userEmailOverride == null);
      return _buildScaffold(
        context,
        user: null,
        email: isGuest ? null : widget.userEmailOverride,
        isGuest: isGuest,
      );
    }

    return StreamBuilder<User?>(
      stream: _auth.userChanges,
      initialData: _auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isGuest = user == null || user.isAnonymous;
        final email = isGuest ? null : (user.email ?? '');
        return _buildScaffold(context, user: user, email: email, isGuest: isGuest);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required User? user,
    required String? email,
    required bool isGuest,
  }) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ZhColors.background,
        foregroundColor: ZhColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: const Text(
          'Account',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
        ),
        actions: [
          NotificationButton(accountAction: widget.accountAction),
          if (widget.accountAction != null)
            widget.accountAction!
          else
            AccountButton(
              user: user,
              showAccount: false,
              onSignIn: _handleSignIn,
              onSignOut: _handleSignOut,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<UserPreferences>(
        future: _prefsFuture,
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
                    title: 'Could not load account',
                    subtitle: 'Check your connection, then pull down to try again.',
                  ),
                ],
              ),
            );
          }

          final prefs = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const SectionHeading('Account details'),
                _AccountDetailsCard(
                  email: email,
                  isGuest: isGuest,
                  prefs: prefs,
                  onRoleChanged: isGuest ? null : _changeRole,
                ),
                const SizedBox(height: 24),
                const SectionHeading('Organizations you follow'),
                if (prefs.followedOrganizations.isEmpty)
                  const _EmptyOrganizationsCard()
                else
                  for (final org in prefs.followedOrganizations) ...[
                    _OrganizationCard(
                      organization: org,
                      onUnfollow: () => _unfollow(org),
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 24),
                if (isGuest)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: zhPrimaryButton(),
                          onPressed: _handleSignIn,
                          child: const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ZhColors.primary,
                            side: const BorderSide(color: ZhColors.primary),
                            minimumSize: const Size.fromHeight(52),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _handleCreateAccount,
                          child: const Text('Create account'),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ZhColors.error,
                      side: const BorderSide(color: ZhColors.error),
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _signingOut ? null : _handleSignOut,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(_signingOut ? 'Signing out…' : 'Sign out'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// White card holding read-only profile fields (name, email, phone, address) and Role selector/badge.
class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({
    required this.email,
    required this.isGuest,
    required this.prefs,
    required this.onRoleChanged,
  });

  final String? email;
  final bool isGuest;
  final UserPreferences prefs;
  final ValueChanged<UserRole>? onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final displayEmail = isGuest ? 'Not signed in (Guest)' : (email ?? '');
    final role = prefs.role;

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
          if (!isGuest && prefs.fullName.isNotEmpty) ...[
            const GroupLabel('Name'),
            _ReadOnlyValueRow(
              icon: Icons.badge_outlined,
              value: prefs.fullName,
            ),
            const SizedBox(height: 16),
          ],
          const GroupLabel('Email'),
          _ReadOnlyValueRow(
            icon: Icons.mail_outline_rounded,
            value: displayEmail,
            muted: isGuest,
            locked: !isGuest,
          ),
          if (!isGuest && prefs.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 16),
            const GroupLabel('Phone'),
            _ReadOnlyValueRow(
              icon: Icons.phone_outlined,
              value: prefs.phoneNumber,
            ),
          ],
          if (!isGuest && (prefs.street.trim().isNotEmpty || prefs.city.trim().isNotEmpty)) ...[
            const SizedBox(height: 16),
            const GroupLabel('Address'),
            _ReadOnlyValueRow(
              icon: Icons.location_on_outlined,
              value: prefs.formattedAddress,
            ),
          ],
          const SizedBox(height: 16),
          const GroupLabel('Role'),
          if (isGuest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ZhColors.warningContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 18, color: ZhColors.warningIcon),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guest — sign in or create an account to choose Donor, Recipient, or Organization.',
                      style: TextStyle(fontSize: 13, color: ZhColors.onWarning),
                    ),
                  ),
                ],
              ),
            )
          else if (role == null)
            const Text(
              'Role information is not available yet.',
              style: TextStyle(fontSize: 14, color: ZhColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in UserRole.values)
                  TagChip(
                    label: option.label,
                    selected: role == option,
                    onTap: () => onRoleChanged?.call(option),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyValueRow extends StatelessWidget {
  const _ReadOnlyValueRow({
    required this.icon,
    required this.value,
    this.muted = false,
    this.locked = false,
  });

  final IconData icon;
  final String value;
  final bool muted;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ZhColors.background,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ZhColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: muted ? ZhColors.textSecondary : ZhColors.text,
              ),
            ),
          ),
          if (locked)
            const Icon(Icons.lock_outline_rounded, size: 16, color: ZhColors.textSecondary),
        ],
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({required this.organization, required this.onUnfollow});

  final FollowedOrganization organization;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (organization.city.isNotEmpty) organization.city,
      if (organization.memberRole != null && organization.memberRole!.isNotEmpty)
        organization.memberRole!,
    ].join(' • ');

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
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: ZhColors.primaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.groups_outlined, size: 20, color: ZhColors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organization.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ZhColors.text),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts,
                    style: const TextStyle(fontSize: 13, color: ZhColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onUnfollow,
            style: OutlinedButton.styleFrom(
              foregroundColor: ZhColors.primary,
              side: const BorderSide(color: ZhColors.primary),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Following'),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrganizationsCard extends StatelessWidget {
  const _EmptyOrganizationsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ZhColors.surface,
        border: Border.all(color: ZhColors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, size: 32, color: ZhColors.textSecondary),
          SizedBox(height: 8),
          Text(
            'No linked organizations yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ZhColors.text),
          ),
          SizedBox(height: 4),
          Text(
            'Register as an Organization or follow local groups to see them here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: ZhColors.textSecondary),
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
