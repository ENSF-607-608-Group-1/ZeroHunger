import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/screens/account_screen.dart';
import 'package:zerohunger/screens/sign_in_sheet.dart';
import 'package:zerohunger/services/account_settings_service.dart';
import 'package:zerohunger/services/auth_service.dart';
import 'package:zerohunger/theme/app_theme.dart';

Future<void> _tapScrollable(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(finder, 150, scrollable: scrollable);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterScrollable(WidgetTester tester, Finder finder, String text) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(finder, 150, scrollable: scrollable);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pump();
}

Widget _wrapSheet(Widget sheet) {
  return MaterialApp(
    theme: zeroHungerTheme(),
    home: Scaffold(body: sheet),
  );
}

void main() {
  group('Account validation helpers', () {
    test('normalizes and validates Canadian postal codes', () {
      expect(normalizeCanadianPostalCode('t2n1n4'), 'T2N 1N4');
      expect(normalizeCanadianPostalCode('  t3a  2b1 '), 'T3A 2B1');
      expect(isValidCanadianPostalCode('t2n1n4'), isTrue);
      expect(isValidCanadianPostalCode('T2N 1N4'), isTrue);
      expect(isValidCanadianPostalCode('12345'), isFalse);
      expect(isValidCanadianPostalCode('INVALID'), isFalse);
    });

    test('validates emails, phone numbers, and UserRole DB values', () {
      expect(isValidEmail('alex@example.com'), isTrue);
      expect(isValidEmail('not-an-email'), isFalse);

      expect(isValidPhoneNumber(''), isTrue);
      expect(isValidPhoneNumber('403-555-0142'), isTrue);
      expect(isValidPhoneNumber('+1 (403) 555-0142'), isTrue);
      expect(isValidPhoneNumber('123'), isFalse);

      expect(UserRole.donor.dbValue, 'donor');
      expect(UserRole.recipient.dbValue, 'recipient');
      expect(UserRole.organization.dbValue, 'organization');
      expect(UserRole.fromDbValue('donor'), UserRole.donor);
      expect(UserRole.fromDbValue('RECIPIENT'), UserRole.recipient);
      expect(UserRole.fromDbValue('organization'), UserRole.organization);
      expect(UserRole.fromDbValue('guest'), isNull);
    });
  });

  group('SignInSheet Create Account flow', () {
    testWidgets('opens on Sign in first and switches to Create account on tap', (tester) async {
      await tester.pumpWidget(_wrapSheet(const SignInSheet()));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Create account'), findsOneWidget);
    });

    testWidgets('validates required fields and password confirmation', (tester) async {
      AccountRegistrationData? submitted;

      await tester.pumpWidget(
        _wrapSheet(
          SignInSheet(
            initialMode: SignInSheetMode.createAccount,
            onCreateAccount: (data) async => submitted = data,
          ),
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Create account'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(submitted, isNull);
      expect(find.text('Please fix the highlighted fields above.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Email is required'),
        -200,
        scrollable: scrollable,
      );
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Last name is required'), findsOneWidget);
    });

    testWidgets('submits Donor registration with normalized postal code and preferences', (tester) async {
      AccountRegistrationData? submitted;

      await tester.pumpWidget(
        _wrapSheet(
          SignInSheet(
            initialMode: SignInSheetMode.createAccount,
            onCreateAccount: (data) async => submitted = data,
          ),
        ),
      );

      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Email'), 'donor@example.com');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Confirm password'), 'secret123');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'First name'), 'Alex');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Last name'), 'Taylor');
      await _enterScrollable(
        tester,
        find.widgetWithText(TextFormField, 'Phone number (optional)'),
        '403-555-0199',
      );
      await _enterScrollable(
        tester,
        find.widgetWithText(TextFormField, 'Street address (optional)'),
        '2500 University Dr NW',
      );
      await _enterScrollable(
        tester,
        find.widgetWithText(TextFormField, 'Postal code (optional)'),
        't2n1n4',
      );

      await _tapScrollable(tester, find.widgetWithText(FilledButton, 'Create account'));

      expect(submitted, isNotNull);
      expect(submitted!.email, 'donor@example.com');
      expect(submitted!.role, UserRole.donor);
      expect(submitted!.firstName, 'Alex');
      expect(submitted!.lastName, 'Taylor');
      expect(submitted!.phoneNumber, '403-555-0199');
      expect(submitted!.street, '2500 University Dr NW');
      expect(submitted!.postalCode, 'T2N 1N4');
      expect(submitted!.city, 'Calgary');
      expect(submitted!.province, 'AB');
      expect(submitted!.organizationName, isNull);
      expect(submitted!.notificationsEnabled, isTrue);
    });

    testWidgets('shows organization fields when Organization role is selected and submits them', (tester) async {
      AccountRegistrationData? submitted;

      await tester.pumpWidget(
        _wrapSheet(
          SignInSheet(
            initialMode: SignInSheetMode.createAccount,
            onCreateAccount: (data) async => submitted = data,
          ),
        ),
      );

      expect(find.widgetWithText(TextFormField, 'Organization name'), findsNothing);

      // Select Organization role.
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Organization name'), findsOneWidget);

      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Email'), 'rep@foodbank.org');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Confirm password'), 'secret123');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'First name'), 'Jordan');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Last name'), 'Lee');
      await _enterScrollable(
        tester,
        find.widgetWithText(TextFormField, 'Organization name'),
        'Calgary Food Bank',
      );
      await _enterScrollable(
        tester,
        find.widgetWithText(TextFormField, 'Organization email (optional)'),
        'info@calgaryfoodbank.com',
      );
      await _enterScrollable(
        tester,
        find.widgetWithText(TextFormField, 'Street address'),
        '5000 11 St SE',
      );
      await _enterScrollable(
        tester,
        find.widgetWithText(TextFormField, 'Postal code'),
        't2h2y5',
      );

      await _tapScrollable(tester, find.widgetWithText(FilledButton, 'Create account'));

      expect(submitted, isNotNull);
      expect(submitted!.role, UserRole.organization);
      expect(submitted!.organizationName, 'Calgary Food Bank');
      expect(submitted!.organizationEmail, 'info@calgaryfoodbank.com');
      expect(submitted!.street, '5000 11 St SE');
      expect(submitted!.postalCode, 'T2H 2Y5');
    });

    testWidgets('allows selecting Recipient role and offers Switch to Sign in when email exists', (tester) async {
      await tester.pumpWidget(
        _wrapSheet(
          SignInSheet(
            initialMode: SignInSheetMode.createAccount,
            onCreateAccount: (_) async {
              throw FirebaseAuthException(code: 'email-already-in-use');
            },
          ),
        ),
      );

      await tester.tap(find.text('Recipient'));
      await tester.pumpAndSettle();

      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Email'), 'existing@example.com');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Confirm password'), 'secret123');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'First name'), 'Sam');
      await _enterScrollable(tester, find.widgetWithText(TextFormField, 'Last name'), 'Patel');

      await _tapScrollable(tester, find.widgetWithText(FilledButton, 'Create account'));

      expect(
        find.text('That email already has an account. Sign in instead.'),
        findsOneWidget,
      );
      expect(find.text('Switch to Sign in'), findsOneWidget);

      await _tapScrollable(tester, find.text('Switch to Sign in'));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });
  });

  testWidgets('AccountScreen displays full Cloud SQL profile fields and Recipient role chip', (tester) async {
    final service = AccountSettingsService(
      simulatedDelay: Duration.zero,
      initialPreferences: const UserPreferences(
        role: UserRole.recipient,
        firstName: 'Alex',
        lastName: 'Taylor',
        phoneNumber: '403-555-0199',
        street: '2500 University Dr NW',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2N 1N4',
        foodPreferences: {},
        allergensToAvoid: {},
        notificationsEnabled: true,
        followedOrganizations: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: zeroHungerTheme(),
        home: AccountScreen(
          accountSettingsService: service,
          accountAction: const SizedBox.shrink(),
          userEmailOverride: 'alex@example.com',
          isGuestOverride: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alex Taylor'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('403-555-0199'), findsOneWidget);
    expect(find.text('2500 University Dr NW • Calgary, AB • T2N 1N4'), findsOneWidget);
    expect(find.text('Recipient'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
