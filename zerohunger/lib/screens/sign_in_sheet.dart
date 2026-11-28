// sign_in_sheet.dart
// The sheet a guest sees when they try to donate
// Only signed-in users can donate, so the Donate food screen opens this for guests.
//
//   final signedIn = await showSignInSheet(context); // true if they now have an account
//
// "Create account" adds an email to the guest (same user ID). "Sign in" uses an existing account.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

// Opens the sheet and waits for it to close.
// Returns true if the user signed in or created an account, false otherwise.
Future<bool> showSignInSheet(BuildContext context) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // lets the sheet move up above the keyboard
    backgroundColor: ZhColors.surface,
    barrierColor: const Color(0x66000000), // 40% black scrim
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => const _SignInSheet(),
  );
  return signedIn ?? false; // swiped down or tapped outside = not signed in
}

// The two tabs at the top of the sheet.
enum _Mode { createAccount, signIn }

class _SignInSheet extends StatefulWidget {
  const _SignInSheet();

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  _Mode _mode = _Mode.createAccount;
  bool _hidePassword = true;
  bool _busy = false;   // true while waiting for Firebase
  String? _error;       // shown in red under the button

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Creates the account (or signs in), then uploads the user record to Cloud SQL.
  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    String? error;
    try {
      final email = _email.text.trim();
      final user = _mode == _Mode.createAccount
          ? await _auth.createAuthUser(email, _password.text)
          : await _auth.signInWithAuth(email, _password.text);
      await _auth.uploadCurrentUserToCloudSql(user: user);
    } on FirebaseAuthException catch (e) {
      error = authErrorText(e); // e.g. "Wrong email or password."
    } on DataConnectOperationError catch (e) {
      final details = e.response.errors
          .map((err) => err.path.isEmpty ? err.message : '${err.path.join('.')}: ${err.message}')
          .join(' | ');
      debugPrint('Cloud SQL operation error (${e.code}): $details');
      error = 'Account signed in, but failed to save to database: $details';
    } on DataConnectError catch (e) {
      debugPrint('Cloud SQL user upload failed (${e.code}): ${e.message}');
      error = 'Account signed in, but failed to save to database: ${e.message}';
    } catch (e) {
      debugPrint('Sign-in or database upload failed: $e');
      error = 'Something went wrong. Please try again.';
    }

    if (!mounted) return; // the sheet was closed while we waited
    if (error == null) {
      Navigator.pop(context, true); // done: close the sheet and say "signed in"
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _mode == _Mode.createAccount;

    return Padding(
      // Keeps the sheet above the keyboard while typing.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle: 32 × 4 dp, 12 dp from the top.
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(color: ZhColors.outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to donate food',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: ZhColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              "Only signed-in users can donate. It's free.",
              style: TextStyle(fontSize: 14, color: ZhColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // The two tabs: Create account | Sign in.
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.createAccount, label: Text('Create account')),
                ButtonSegment(value: _Mode.signIn, label: Text('Sign in')),
              ],
              selected: {_mode},
              showSelectedIcon: false, // no tick on the chosen tab
              onSelectionChanged: (picked) => setState(() {
                _mode = picked.first;
                _error = null;
              }),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: ZhColors.primaryContainer,
                selectedForegroundColor: ZhColors.onPrimaryContainer,
                foregroundColor: ZhColors.textSecondary,
                side: const BorderSide(color: ZhColors.outline),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: zhField(label: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: zhField(
                label: 'Password',
                helper: 'At least 6 characters',
                suffixIcon: TextButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  child: Text(_hidePassword ? 'Show' : 'Hide'), // words instead of an eye icon
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Create account / Sign in button: 52 dp, green pill. Shows a spinner while busy.
            FilledButton(
              style: zhPrimaryButton(),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ZhColors.onPrimary),
                    )
                  : Text(creating ? 'Create account' : 'Sign in'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: ZhColors.error),
              ),
            ],

            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: ZhColors.textSecondary,
                  minimumSize: const Size(0, 48),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: const Text('Not now'),
              ),
            ),
            if (creating) ...[
              const SizedBox(height: 4),
              const Text(
                'Anything you did as a guest stays with your new account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: ZhColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


