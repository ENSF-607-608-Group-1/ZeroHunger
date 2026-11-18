// account_button.dart
// The round account button at the top right of every screen.
//   Guest:   a person icon. Tap it to sign in.
//   Account: the email's first letter. Tap it to see the email and sign out.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/sign_in_sheet.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AccountButton extends StatelessWidget {
  const AccountButton({super.key, required this.user});

  final User? user; // the signed-in user (a guest too), or null

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

    if (email == null) {
      return IconButton(tooltip: 'Sign in', onPressed: () => showSignInSheet(context), icon: avatar);
    }

    return PopupMenuButton<String>(
      tooltip: 'Account',
      onSelected: (_) => AuthService().signOut(),
      itemBuilder: (context) => [
        PopupMenuItem<String>(enabled: false, child: Text(email)),
        const PopupMenuItem<String>(
          value: 'sign-out',
          child: Row(
            children: [Icon(Icons.logout_rounded, size: 20), SizedBox(width: 12), Text('Sign out')],
          ),
        ),
      ],
      child: Padding(padding: const EdgeInsets.all(8), child: avatar),
    );
  }
}


