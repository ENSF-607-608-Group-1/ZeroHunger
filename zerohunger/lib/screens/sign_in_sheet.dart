// sign_in_sheet.dart
// The sheet a guest sees when they create an account or sign in.
//
//   final signedIn = await showSignInSheet(context); // true if they now have an account
//
// "Create account" links an email/password to the guest (preserving their Firebase Auth UID)
// and writes their full profile into Cloud SQL (Users, PostalCode, Organization,
// User_Organization, Locations, and UserPreferences).
// "Sign in" authenticates an existing account and syncs their Cloud SQL record.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/material.dart';

import '../services/account_settings_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_parts.dart';

const _provinces = ['AB', 'BC', 'MB', 'NB', 'NL', 'NS', 'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT'];

// Opens the sheet and waits for it to close.
// Returns true if the user signed in or created an account, false otherwise.
Future<bool> showSignInSheet(
  BuildContext context, {
  SignInSheetMode initialMode = SignInSheetMode.signIn,
}) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // lets the sheet move up above the keyboard
    backgroundColor: ZhColors.surface,
    barrierColor: const Color(0x66000000), // 40% black scrim
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SignInSheet(initialMode: initialMode),
  );
  return signedIn ?? false; // swiped down or tapped outside = not signed in
}

// The two tabs at the top of the sheet.
enum SignInSheetMode { signIn, createAccount }

typedef CreateAccountSubmitFn = Future<void> Function(AccountRegistrationData data);
typedef SignInSubmitFn = Future<void> Function(String email, String password);

class SignInSheet extends StatefulWidget {
  const SignInSheet({
    super.key,
    this.initialMode = SignInSheetMode.signIn,
    this.authService,
    this.onCreateAccount,
    this.onSignIn,
  });

  final SignInSheetMode initialMode;
  final AuthService? authService;
  final CreateAccountSubmitFn? onCreateAccount;
  final SignInSubmitFn? onSignIn;

  @override
  State<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<SignInSheet> {
  AuthService? _authInstance;
  AuthService get _auth => _authInstance ??= widget.authService ?? AuthService();

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _orgName = TextEditingController();
  final _orgEmail = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController(text: 'Calgary');
  final _postalCode = TextEditingController();

  late SignInSheetMode _mode = widget.initialMode;
  UserRole _role = UserRole.donor;
  String _province = 'AB';
  bool _notificationsEnabled = true;
  bool _hidePassword = true;
  bool _busy = false; // true while waiting for Firebase / Cloud SQL
  String? _error; // shown in red under the button
  bool _suggestSwitchToSignIn = false;

  @override
  void dispose() {
    for (final c in [
      _email,
      _password,
      _confirmPassword,
      _firstName,
      _lastName,
      _phoneNumber,
      _orgName,
      _orgEmail,
      _street,
      _city,
      _postalCode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _roleHint(UserRole role) => switch (role) {
        UserRole.donor =>
          'Share surplus food, post listings, and host community donation events.',
        UserRole.recipient =>
          'Browse and claim available food, track pickups, and follow local organizations.',
        UserRole.organization =>
          'Register your food bank or community group and post scheduled food distributions.',
      };

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!isValidEmail(text)) return 'Enter a valid email address';
    return null;
  }

  String? _validateOptionalEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!isValidEmail(text)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (_mode == SignInSheetMode.createAccount && text.length < 6) {
      return 'Use at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_mode != SignInSheetMode.createAccount) return null;
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != _password.text) return 'Passwords do not match';
    return null;
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!isValidPhoneNumber(text)) return 'Enter a valid phone number';
    return null;
  }

  String? _validatePostalCode(String? value) {
    final text = value?.trim() ?? '';
    final streetEntered = _street.text.trim().isNotEmpty;
    if (text.isEmpty) {
      if (_role == UserRole.organization) return 'Postal code is required for organizations';
      if (streetEntered) return 'Postal code is required when street is entered';
      return null;
    }
    return isValidCanadianPostalCode(text) ? null : 'Use the format A1A 1A1';
  }

  // Creates the account (or signs in), then persists the user record to Cloud SQL.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _suggestSwitchToSignIn = false;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _error = 'Please fix the highlighted fields above.';
      });
      return;
    }

    setState(() => _busy = true);

    String? error;
    var suggestSignIn = false;
    try {
      final email = _email.text.trim();
      final password = _password.text;

      if (_mode == SignInSheetMode.createAccount) {
        final normalizedPostal = normalizeCanadianPostalCode(_postalCode.text);
        final registration = AccountRegistrationData(
          email: email,
          password: password,
          role: _role,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phoneNumber: _phoneNumber.text.trim().isEmpty ? null : _phoneNumber.text.trim(),
          street: _street.text.trim().isEmpty ? null : _street.text.trim(),
          postalCode: normalizedPostal.isEmpty ? null : normalizedPostal,
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          province: _province,
          organizationName: _role == UserRole.organization ? _orgName.text.trim() : null,
          organizationEmail: _role == UserRole.organization && _orgEmail.text.trim().isNotEmpty
              ? _orgEmail.text.trim()
              : null,
          radiusSearch: 10,
          notificationsEnabled: _notificationsEnabled,
        );

        if (widget.onCreateAccount != null) {
          await widget.onCreateAccount!(registration);
        } else {
          await _auth.registerAccount(registration);
        }
      } else {
        if (widget.onSignIn != null) {
          await widget.onSignIn!(email, password);
        } else {
          await _auth.signIn(email, password);
        }
      }
    } on FirebaseAuthException catch (e) {
      error = authErrorText(e);
      if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
        suggestSignIn = true;
      }
    } on DataConnectOperationError catch (e) {
      final details = e.response.errors
          .map((err) => err.path.isEmpty ? err.message : '${err.path.join('.')}: ${err.message}')
          .join(' | ');
      debugPrint('Cloud SQL operation error (${e.code}): $details');
      error = 'Account authenticated, but failed to save to database: $details';
    } on DataConnectError catch (e) {
      debugPrint('Cloud SQL user upload failed (${e.code}): ${e.message}');
      error = 'Account authenticated, but failed to save to database: ${e.message}';
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
        _suggestSwitchToSignIn = suggestSignIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _mode == SignInSheetMode.createAccount;
    final isOrg = _role == UserRole.organization;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        // Keeps the sheet above the keyboard while typing.
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _formKey,
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
                    decoration: BoxDecoration(
                      color: ZhColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  creating ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: ZhColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  creating
                      ? 'Choose your role and add your details to join Zero Hunger.'
                      : 'Sign in with your Zero Hunger email and password.',
                  style: const TextStyle(fontSize: 14, color: ZhColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // The two tabs: Sign in | Create account.
                SegmentedButton<SignInSheetMode>(
                  segments: const [
                    ButtonSegment(
                      value: SignInSheetMode.signIn,
                      label: Text('Sign in'),
                    ),
                    ButtonSegment(
                      value: SignInSheetMode.createAccount,
                      label: Text('Create account'),
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (picked) => setState(() {
                    _mode = picked.first;
                    _error = null;
                    _suggestSwitchToSignIn = false;
                  }),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: ZhColors.primaryContainer,
                    selectedForegroundColor: ZhColors.onPrimaryContainer,
                    foregroundColor: ZhColors.textSecondary,
                    side: const BorderSide(color: ZhColors.outline),
                  ),
                ),
                const SizedBox(height: 20),

                if (creating) ...[
                  const GroupLabel('Account role'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in UserRole.values)
                        TagChip(
                          label: option.label,
                          selected: _role == option,
                          onTap: () => setState(() {
                            _role = option;
                            _error = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: ZhColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ZhColors.divider),
                    ),
                    child: Text(
                      _roleHint(_role),
                      style: const TextStyle(fontSize: 12, color: ZhColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Credentials
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  decoration: zhField(label: 'Email', hint: 'you@example.com'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  autofillHints: [
                    creating ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  validator: _validatePassword,
                  decoration: zhField(
                    label: 'Password',
                    helper: creating ? 'At least 6 characters' : null,
                    suffixIcon: TextButton(
                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      child: Text(_hidePassword ? 'Show' : 'Hide'),
                    ),
                  ),
                ),

                if (creating) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _hidePassword,
                    validator: _validateConfirmPassword,
                    decoration: zhField(label: 'Confirm password'),
                  ),
                  const SizedBox(height: 20),

                  // Personal details (Users table)
                  const GroupLabel('Your details'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstName,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.givenName],
                          validator: (v) => _validateRequired(v, 'First name'),
                          decoration: zhField(label: 'First name', hint: 'Alex'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastName,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.familyName],
                          validator: (v) => _validateRequired(v, 'Last name'),
                          decoration: zhField(label: 'Last name', hint: 'Taylor'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneNumber,
                    maxLength: 30,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: _validatePhone,
                    decoration: zhField(
                      label: 'Phone number (optional)',
                      hint: '403-555-0142',
                    ),
                  ),

                  // Organization details (Organization + User_Organization tables)
                  if (isOrg) ...[
                    const SizedBox(height: 20),
                    const GroupLabel('Organization details'),
                    TextFormField(
                      controller: _orgName,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => _validateRequired(v, 'Organization name'),
                      decoration: zhField(
                        label: 'Organization name',
                        hint: 'e.g. Calgary Food Bank',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orgEmail,
                      maxLength: 255,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateOptionalEmail,
                      decoration: zhField(
                        label: 'Organization email (optional)',
                        hint: 'contact@organization.org',
                        helper: 'Leave blank to use your account email',
                      ),
                    ),
                  ],

                  // Address / Area (PostalCode + Users.Street + Locations tables)
                  const SizedBox(height: 20),
                  GroupLabel(isOrg ? 'Organization address' : 'Location (optional)'),
                  TextFormField(
                    controller: _street,
                    maxLength: 150,
                    textCapitalization: TextCapitalization.words,
                    validator: isOrg ? (v) => _validateRequired(v, 'Street address') : null,
                    decoration: zhField(
                      label: isOrg ? 'Street address' : 'Street address (optional)',
                      hint: 'e.g. 2500 University Dr NW',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _city,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.words,
                          validator: isOrg ? (v) => _validateRequired(v, 'City') : null,
                          decoration: zhField(label: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 112,
                        child: DropdownButtonFormField<String>(
                          initialValue: _province,
                          items: [
                            for (final p in _provinces)
                              DropdownMenuItem(value: p, child: Text(p)),
                          ],
                          onChanged: (p) => setState(() => _province = p ?? _province),
                          decoration: zhField(
                            label: 'Province',
                            padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postalCode,
                    maxLength: 10,
                    textCapitalization: TextCapitalization.characters,
                    validator: _validatePostalCode,
                    decoration: zhField(
                      label: isOrg ? 'Postal code' : 'Postal code (optional)',
                      hint: 'T2N 1N4',
                      helper: 'Format: A1A 1A1 — used to match nearby food & events',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notification preference (UserPreferences table)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: ZhColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ZhColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nearby food & event alerts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ZhColors.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Get notified when food or distributions match your area.',
                                style: TextStyle(fontSize: 12, color: ZhColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Create account / Sign in button: 52 dp, green pill. Shows a spinner while busy.
                FilledButton(
                  style: zhPrimaryButton(),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ZhColors.onPrimary,
                          ),
                        )
                      : Text(creating ? 'Create account' : 'Sign in'),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: ZhColors.error),
                  ),
                  if (_suggestSwitchToSignIn) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _mode = SignInSheetMode.signIn;
                                  _error = null;
                                  _suggestSwitchToSignIn = false;
                                }),
                        child: const Text('Switch to Sign in'),
                      ),
                    ),
                  ],
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
        ),
      ),
    );
  }
}
