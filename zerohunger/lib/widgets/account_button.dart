// account_button.dart
// The round profile/account button at the top right of every screen.
//   Guest:   a person icon. Tap it to open the Profile menu (Account, Settings, My activity, Sign in).
//   Account: the email's first letter. Tap it to open the Profile menu (email, Account, Settings, My activity, Sign out).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../screens/my_activity_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sign_in_sheet.dart';
import '../services/account_settings_service.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AccountButton extends StatelessWidget {
  const AccountButton({
    super.key,
    required this.user,
    this.showAccount = true,
    this.showSettings = true,
    this.showMyActivity = true,
    this.accountSettingsService,
    this.activityService,
    this.activityAccountAction,
    this.onSignIn,
    this.onSignOut,
  });

  final User? user; // the signed-in user (a guest too), or null
  final bool showAccount;
  final bool showSettings;
  final bool showMyActivity;
  final AccountSettingsService? accountSettingsService;
  final ActivityService? activityService;
  final Widget? activityAccountAction;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final email = (u == null || u.isAnonymous) ? null : (u.email ?? '');

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: email == null ? ZhColors.divider : ZhColors.primaryContainer,
      child: email == null
          ? const Icon(Icons.person_rounded, size: 18, color: ZhColors.textSecondary)
          : Text(
              email.isEmpty ? '?' : email[0].toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ZhColors.onPrimaryContainer),
            ),
    );

    final hasProfileSections = showAccount || showSettings || showMyActivity;

    return PopupMenuButton<String>(
      tooltip: 'Profile',
      onSelected: (value) {
        switch (value) {
          case 'account':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountScreen(
                  accountSettingsService: accountSettingsService,
                  accountAction: activityAccountAction,
                  userEmailOverride: activityAccountAction != null ? email : null,
                  isGuestOverride: activityAccountAction != null ? (email == null) : null,
                  onCreateAccount: onSignIn,
                ),
              ),
            );
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  accountSettingsService: accountSettingsService,
                  accountAction: activityAccountAction,
                ),
              ),
            );
          case 'my-activity':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyActivityScreen(
                  activityService: activityService,
                  accountAction: activityAccountAction,
                ),
              ),
            );
          case 'sign-in':
            (onSignIn ?? () => showSignInSheet(context))();
          case 'sign-out':
            (onSignOut ?? () => AuthService().signOut())();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ZhColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                email ?? 'Guest',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ZhColors.text),
              ),
            ],
          ),
        ),
        if (hasProfileSections) const PopupMenuDivider(),
        if (showAccount)
          const PopupMenuItem<String>(
            value: 'account',
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 20, color: ZhColors.primary),
                SizedBox(width: 12),
                Flexible(child: Text('Account')),
              ],
            ),
          ),
        if (showSettings)
          const PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 20, color: ZhColors.primary),
                SizedBox(width: 12),
                Flexible(child: Text('Settings')),
              ],
            ),
          ),
        if (showMyActivity)
          const PopupMenuItem<String>(
            value: 'my-activity',
            child: Row(
              children: [
                Icon(Icons.insights_rounded, size: 20, color: ZhColors.primary),
                SizedBox(width: 12),
                Flexible(child: Text('My activity')),
              ],
            ),
          ),
        const PopupMenuDivider(),
        if (email == null)
          const PopupMenuItem<String>(
            value: 'sign-in',
            child: Row(
              children: [
                Icon(Icons.login_rounded, size: 20),
                SizedBox(width: 12),
                Flexible(child: Text('Sign in')),
              ],
            ),
          )
        else
          const PopupMenuItem<String>(
            value: 'sign-out',
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 20),
                SizedBox(width: 12),
                Flexible(child: Text('Sign out')),
              ],
            ),
          ),
      ],
      child: Padding(padding: const EdgeInsets.all(8), child: avatar),
    );
  }
}


