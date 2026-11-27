// account_settings_service.dart
// Stores the user's account profile details (role, followed organizations) and
// alert settings (postal code area, food preferences, allergens to avoid, notifications on/off).
//
// Used by AccountScreen and SettingsScreen (two separate pages under the Profile menu).
//
// TODO: Review when database & user profile API are complete. Replace the in-memory
//   store below with real cloud queries / Cloud Functions calls (screens only ask this
//   class, so real backend wiring changes this file only).

// Role chosen for the account (matches Sign in / create account roles).
enum UserRole {
  donor,
  organization,
}

// One food bank or community group the user follows for alerts.
class FollowedOrganization {
  final String organizationId;
  final String name; // e.g. "Calgary Food Bank"
  final String city; // e.g. "Calgary"

  const FollowedOrganization({
    required this.organizationId,
    required this.name,
    required this.city,
  });
}

// Combined account & settings state for the signed-in user (or guest).
class UserPreferences {
  final UserRole role;
  final String postalCode;               // Canadian format, e.g. "T2N 1N4"
  final Set<String> foodPreferences;     // from foodCategoryOptions in zero_hunger_api.dart
  final Set<String> allergensToAvoid;    // from allergenOptions in zero_hunger_api.dart (11 priority allergens)
  final bool notificationsEnabled;
  final List<FollowedOrganization> followedOrganizations;

  const UserPreferences({
    required this.role,
    required this.postalCode,
    required this.foodPreferences,
    required this.allergensToAvoid,
    required this.notificationsEnabled,
    required this.followedOrganizations,
  });

  UserPreferences copyWith({
    UserRole? role,
    String? postalCode,
    Set<String>? foodPreferences,
    Set<String>? allergensToAvoid,
    bool? notificationsEnabled,
    List<FollowedOrganization>? followedOrganizations,
  }) {
    return UserPreferences(
      role: role ?? this.role,
      postalCode: postalCode ?? this.postalCode,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      allergensToAvoid: allergensToAvoid ?? this.allergensToAvoid,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      followedOrganizations: followedOrganizations ?? this.followedOrganizations,
    );
  }
}

class AccountSettingsService {
  // Shared in-memory store for the running app so changes saved in Settings or
  // Account stay in place when navigating between screens.
  static UserPreferences _sharedPrefs = _seedPreferences();

  AccountSettingsService({
    UserPreferences? initialPreferences,
    this.simulatedDelay = const Duration(milliseconds: 200),
  }) : _localPrefs = initialPreferences;

  UserPreferences? _localPrefs;
  final Duration simulatedDelay;

  UserPreferences get _current => _localPrefs ?? _sharedPrefs;

  set _current(UserPreferences next) {
    if (_localPrefs != null) {
      _localPrefs = next;
    } else {
      _sharedPrefs = next;
    }
  }

  // Loads the user's current account & settings data.
  Future<UserPreferences> load() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final p = _current;
    return p.copyWith(
      foodPreferences: Set<String>.unmodifiable(p.foodPreferences),
      allergensToAvoid: Set<String>.unmodifiable(p.allergensToAvoid),
      followedOrganizations: List<FollowedOrganization>.unmodifiable(p.followedOrganizations),
    );
  }

  // Updates the account role (Donor or Organization).
  Future<UserPreferences> updateRole(UserRole role) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    _current = _current.copyWith(role: role);
    return load();
  }

  // Stops following an organization.
  Future<UserPreferences> unfollowOrganization(String organizationId) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final updated = _current.followedOrganizations
        .where((org) => org.organizationId != organizationId)
        .toList();
    _current = _current.copyWith(followedOrganizations: updated);
    return load();
  }

  // Saves the alert & dietary settings edited on SettingsScreen.
  Future<UserPreferences> saveSettings({
    required String postalCode,
    required Set<String> foodPreferences,
    required Set<String> allergensToAvoid,
    required bool notificationsEnabled,
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    _current = _current.copyWith(
      postalCode: postalCode,
      foodPreferences: Set<String>.of(foodPreferences),
      allergensToAvoid: Set<String>.of(allergensToAvoid),
      notificationsEnabled: notificationsEnabled,
    );
    return load();
  }
}

UserPreferences _seedPreferences() {
  return const UserPreferences(
    role: UserRole.donor,
    postalCode: 'T2N 1N4',
    foodPreferences: {'HALAL', 'VEGETARIAN'},
    allergensToAvoid: {'PEANUTS'},
    notificationsEnabled: true,
    followedOrganizations: [
      FollowedOrganization(
        organizationId: 'org-calgary-food-bank',
        name: 'Calgary Food Bank',
        city: 'Calgary',
      ),
      FollowedOrganization(
        organizationId: 'org-campus-kitchen',
        name: 'Campus Community Kitchen',
        city: 'Calgary',
      ),
      FollowedOrganization(
        organizationId: 'org-sunside-pantry',
        name: 'Sunside Neighbourhood Pantry',
        city: 'Calgary',
      ),
    ],
  );
}
