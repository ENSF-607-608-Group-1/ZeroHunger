import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerohunger/screens/organizations_screen.dart';
import 'package:zerohunger/services/query_service.dart';
import 'package:zerohunger/theme/app_theme.dart';

class _FakeQueryService extends QueryService {
  _FakeQueryService(this.orgs);
  final List<OrganizationSummary> orgs;

  @override
  Future<List<OrganizationSummary>> organizations() async => orgs;
}

List<OrganizationSummary> _testOrganizations() => const [
      OrganizationSummary(
        organizationId: 'org-1',
        name: 'Calgary Food Bank',
        city: 'Calgary',
        following: false,
      ),
      OrganizationSummary(
        organizationId: 'org-2',
        name: 'UCalgary Food Pantry',
        city: 'Calgary',
        following: true,
      ),
      OrganizationSummary(
        organizationId: 'org-3',
        name: 'Airdrie Food Bank',
        city: 'Airdrie',
        following: false,
      ),
    ];

Widget _wrap(Widget child) => MaterialApp(theme: zeroHungerTheme(), home: child);

void main() {
  testWidgets('Displays organizations with name, city, and Follow/Following buttons', (tester) async {
    await tester.pumpWidget(_wrap(
      OrganizationsScreen(
        queryService: _FakeQueryService(_testOrganizations()),
        showAccountButton: false,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Calgary Food Bank'), findsOneWidget);
    expect(find.text('UCalgary Food Pantry'), findsOneWidget);
    expect(find.text('Airdrie Food Bank'), findsOneWidget);
    expect(find.text('Calgary'), findsNWidgets(2));
    expect(find.text('Airdrie'), findsOneWidget);
    expect(find.text('Follow'), findsNWidgets(2));
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('Toggles Follow and Following and notifies callback', (tester) async {
    String? toggledId;
    bool? toggledState;

    await tester.pumpWidget(_wrap(
      OrganizationsScreen(
        queryService: _FakeQueryService(_testOrganizations()),
        showAccountButton: false,
        onToggleFollow: (id, follow) async {
          toggledId = id;
          toggledState = follow;
        },
      ),
    ));
    await tester.pumpAndSettle();

    // Follow Calgary Food Bank.
    await tester.tap(find.text('Follow').first);
    await tester.pumpAndSettle();

    expect(toggledId, 'org-1');
    expect(toggledState, isTrue);
    expect(find.text('Following (2)'), findsOneWidget);

    // Unfollow Calgary Food Bank.
    await tester.tap(find.text('Following').first);
    await tester.pumpAndSettle();

    expect(toggledId, 'org-1');
    expect(toggledState, isFalse);
    expect(find.text('Following (1)'), findsOneWidget);
  });

  testWidgets('does not report a follow when no backend callback is available', (tester) async {
    await tester.pumpWidget(_wrap(
      OrganizationsScreen(
        queryService: _FakeQueryService(_testOrganizations()),
        showAccountButton: false,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Follow').first);
    await tester.pumpAndSettle();

    expect(find.text('Organization follows are not available yet.'), findsOneWidget);
    expect(find.text('Following (1)'), findsOneWidget);
  });

  testWidgets('Filters organizations by search query and Following chip', (tester) async {
    await tester.pumpWidget(_wrap(
      OrganizationsScreen(
        queryService: _FakeQueryService(_testOrganizations()),
        showAccountButton: false,
      ),
    ));
    await tester.pumpAndSettle();

    // Search by city.
    await tester.enterText(find.byType(TextField), 'Airdrie');
    await tester.pumpAndSettle();

    expect(find.text('Airdrie Food Bank'), findsOneWidget);
    expect(find.text('Calgary Food Bank'), findsNothing);

    // Clear search and filter by Following.
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Following (1)'));
    await tester.pumpAndSettle();

    expect(find.text('UCalgary Food Pantry'), findsOneWidget);
    expect(find.text('Calgary Food Bank'), findsNothing);
    expect(find.text('Airdrie Food Bank'), findsNothing);
  });
}
