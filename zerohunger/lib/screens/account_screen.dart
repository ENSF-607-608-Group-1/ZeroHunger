// account_screen.dart
// Shows the user's account details: email (read-only), role, organizations they follow,
// and a Sign out button (or Create account for guests).
//
// Reached from the "Account" section under the top-right Profile menu.
// Role and followed-organization data are not represented by the current account integration.

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
  late final AccountSettingsService _service = widget.accountSettingsService ?? AccountSettingsService();
  late final AuthService? _auth =
      (widget.accountAction == null && widget.isGuestOverride == null) ? AuthService() : null;

  late Future<UserPreferences> _prefsFuture = _service.load();
  bool _signingOut = false;

  Future<void> _reload() async {
    final next = _service.load();
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
      showZhMessage(context, 'Role updated to ${_roleLabel(role)}');
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
    } catch (_) {
      if (!mounted) return;
      showZhMessage(context, 'Could not sign out. Please try again.');
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _handleCreateAccount() {
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
      return;
    }
    showSignInSheet(context);
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
            AccountButton(user: user, showAccount: false),
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
                  role: prefs.role,
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
                  FilledButton(
                    style: zhPrimaryButton(),
                    onPressed: _handleCreateAccount,
                    child: const Text('Create account'),
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

// White card holding read-only Email and Role selector/badge.
class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({
    required this.email,
    required this.isGuest,
    required this.role,
    required this.onRoleChanged,
  });

  final String? email;
  final bool isGuest;
  final UserRole? role;
  final ValueChanged<UserRole>? onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final displayEmail = isGuest ? 'Not signed in (Guest)' : (email ?? '');

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
          const GroupLabel('Email'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: ZhColors.background,
              border: Border.all(color: ZhColors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline_rounded, size: 20, color: ZhColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayEmail,
                    style: TextStyle(
                      fontSize: 15,
                      color: isGuest ? ZhColors.textSecondary : ZhColors.text,
                    ),
                  ),
                ),
                if (!isGuest)
                  const Icon(Icons.lock_outline_rounded, size: 16, color: ZhColors.textSecondary),
              ],
            ),
          ),
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
                      'Guest — create an account to choose Donor or Organization and post food.',
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
                    label: _roleLabel(option),
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

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({required this.organization, required this.onUnfollow});

  final FollowedOrganization organization;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 2),
                Text(
                  organization.city,
                  style: const TextStyle(fontSize: 13, color: ZhColors.textSecondary),
                ),
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
            'Organization follows are not available yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ZhColors.text),
          ),
          SizedBox(height: 4),
          Text(
            'The current account integration does not store organization follows.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: ZhColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
      UserRole.donor => 'Donor',
      UserRole.organization => 'Organization',
    };

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
