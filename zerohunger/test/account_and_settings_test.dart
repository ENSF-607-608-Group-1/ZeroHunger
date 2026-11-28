import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zerohunger/screens/account_screen.dart';
import 'package:zerohunger/screens/home_screen.dart';
import 'package:zerohunger/screens/settings_screen.dart';
import 'package:zerohunger/services/account_settings_service.dart';
import 'package:zerohunger/services/zero_hunger_api.dart';
import 'package:zerohunger/theme/app_theme.dart';
import 'package:zerohunger/widgets/account_button.dart';
import 'package:zerohunger/widgets/food_parts.dart';

UserPreferences _samplePrefs() {
  return const UserPreferences(
    role: UserRole.donor,
    postalCode: 'T2N 1N4',
    foodPreferences: {'HALAL'},
    allergensToAvoid: {'PEANUTS'},
    notificationsEnabled: true,
    followedOrganizations: [
      FollowedOrganization(
        organizationId: 'org-1',
        name: 'Calgary Food Bank',
        city: 'Calgary',
      ),
      FollowedOrganization(
        organizationId: 'org-2',
        name: 'Campus Community Kitchen',
        city: 'Calgary',
      ),
    ],
  );
}

Widget _wrap(Widget child) =>
    MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  test('default account settings expose no seeded profile and reject non-persistent writes', () async {
    final service = AccountSettingsService(simulatedDelay: Duration.zero);
    final preferences = await service.load();

    expect(service.isAvailable, isFalse);
    expect(preferences.role, isNull);
    expect(preferences.postalCode, isEmpty);
    expect(preferences.foodPreferences, isEmpty);
    expect(preferences.allergensToAvoid, isEmpty);
    expect(preferences.followedOrganizations, isEmpty);
    await expectLater(
      service.saveSettings(
        postalCode: '',
        foodPreferences: const {},
        allergensToAvoid: const {},
        notificationsEnabled: false,
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  testWidgets(
    'Profile menu shows Account, Settings, and My activity and opens AccountScreen and SettingsScreen',
    (tester) async {
      final service = AccountSettingsService(
        initialPreferences: _samplePrefs(),
        simulatedDelay: Duration.zero,
      );

      await tester.pumpWidget(
        _wrap(
          HomeScreen(
            accountAction: AccountButton(
              user: null,
              accountSettingsService: service,
              activityAccountAction: const SizedBox.shrink(),
              onSignIn: () {},
            ),
          ),
        ),
      );

      // Open Profile menu -> shows all 3 sections.
      await tester.tap(find.byType(AccountButton));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('My activity'), findsOneWidget);

      // Tap Account -> opens AccountScreen.
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('Calgary Food Bank'), findsOneWidget);

      // Go back, reopen Profile menu, tap Settings -> opens SettingsScreen.
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AccountButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Food preferences'), findsOneWidget);
    },
  );

  testWidgets(
    'AccountScreen shows non-editable email, role switching, followed orgs unfollow, and Sign out',
    (tester) async {
      final service = AccountSettingsService(
        initialPreferences: _samplePrefs(),
        simulatedDelay: Duration.zero,
      );
      var signedOut = false;

      await tester.pumpWidget(
        _wrap(
          AccountScreen(
            accountSettingsService: service,
            accountAction: const SizedBox.shrink(),
            userEmailOverride: 'donor@example.com',
            isGuestOverride: false,
            onSignOut: () async => signedOut = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Email is displayed (not a TextField).
      expect(find.text('donor@example.com'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // Switch role to Organization.
      await tester.tap(find.text('Organization'));
      await tester.pumpAndSettle();
      expect((await service.load()).role, UserRole.organization);

      // Unfollow Calgary Food Bank.
      expect(find.text('Calgary Food Bank'), findsOneWidget);
      await tester.tap(find.text('Following').first);
      await tester.pumpAndSettle();
      expect(find.text('Calgary Food Bank'), findsNothing);
      expect(find.text('Campus Community Kitchen'), findsOneWidget);

      // Scroll to Sign out button and tap it.
      await tester.scrollUntilVisible(
        find.text('Sign out'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
    },
  );

  testWidgets(
    'AccountScreen shows Create account button for guests instead of Sign out',
    (tester) async {
      final service = AccountSettingsService(
        initialPreferences: _samplePrefs(),
        simulatedDelay: Duration.zero,
      );
      var createTapped = false;

      await tester.pumpWidget(
        _wrap(
          AccountScreen(
            accountSettingsService: service,
            accountAction: const SizedBox.shrink(),
            isGuestOverride: true,
            onCreateAccount: () => createTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not signed in (Guest)'), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);

      await tester.ensureVisible(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create account'));
      await tester.pump();
      expect(createTapped, isTrue);
    },
  );

  testWidgets(
    'SettingsScreen validates postal code, shows all food & 11 allergen options, toggles alerts and saves',
    (tester) async {
      final service = AccountSettingsService(
        initialPreferences: _samplePrefs(),
        simulatedDelay: Duration.zero,
      );

      await tester.pumpWidget(
        _wrap(
          SettingsScreen(
            accountSettingsService: service,
            accountAction: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 5 food categories and all 11 Health Canada priority allergens are present.
      for (final cat in foodCategoryOptions) {
        expect(find.text(tagLabel(cat)), findsOneWidget);
      }

      final verticalList = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Sulphites'),
        150,
        scrollable: verticalList,
      );
      for (final allergen in allergenOptions) {
        expect(find.text(tagLabel(allergen)), findsOneWidget);
      }

      // Scroll back up to postal code and test invalid postal code validation.
      await tester.scrollUntilVisible(
        find.byType(TextFormField),
        -200,
        scrollable: verticalList,
      );
      await tester.enterText(find.byType(TextFormField), 'INVALID');
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();
      expect(find.text('Use the format A1A 1A1'), findsOneWidget);

      // Enter lowercase valid postal code -> tidied to "T3A 2B1" on save.
      await tester.enterText(find.byType(TextFormField), 't3a2b1');

      // Toggle Vegan on.
      await tester.tap(find.text('Vegan'));
      await tester.pump();

      // Scroll down, toggle Soy allergen on and turn Notifications off.
      await tester.scrollUntilVisible(
        find.text('Alerts on'),
        200,
        scrollable: verticalList,
      );
      await tester.tap(find.text('Soy'));
      await tester.pump();
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Save settings.
      await tester.tap(find.text('Save settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings saved'), findsOneWidget);

      final saved = await service.load();
      expect(saved.postalCode, 'T3A 2B1');
      expect(saved.foodPreferences, containsAll(['HALAL', 'VEGAN']));
      expect(saved.allergensToAvoid, containsAll(['PEANUTS', 'SOY']));
      expect(saved.notificationsEnabled, isFalse);
    },
  );
}
