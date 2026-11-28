// account_settings_service.dart
// Models the user's profile details and alert settings for the Account and Settings screens.
//
// Used by AccountScreen and SettingsScreen (two separate pages under the Profile menu).
//
// No persistent settings operation is available yet. Tests can inject initialPreferences.

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
  final UserRole? role;
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
  AccountSettingsService({
    UserPreferences? initialPreferences,
    this.simulatedDelay = const Duration(milliseconds: 200),
  }) : _localPrefs = initialPreferences;

  UserPreferences? _localPrefs;
  final Duration simulatedDelay;

  bool get isAvailable => _localPrefs != null;

  static const UserPreferences _emptyPreferences = UserPreferences(
    role: null,
    postalCode: '',
    foodPreferences: {},
    allergensToAvoid: {},
    notificationsEnabled: false,
    followedOrganizations: [],
  );

  // Loads the user's current account & settings data.
  Future<UserPreferences> load() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final p = _localPrefs ?? _emptyPreferences;
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
    final current = _requireAvailable();
    _localPrefs = current.copyWith(role: role);
    return load();
  }

  // Stops following an organization.
  Future<UserPreferences> unfollowOrganization(String organizationId) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    final current = _requireAvailable();
    final updated = current.followedOrganizations
        .where((org) => org.organizationId != organizationId)
        .toList();
    _localPrefs = current.copyWith(followedOrganizations: updated);
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
    final current = _requireAvailable();
    _localPrefs = current.copyWith(
      postalCode: postalCode,
      foodPreferences: Set<String>.of(foodPreferences),
      allergensToAvoid: Set<String>.of(allergensToAvoid),
      notificationsEnabled: notificationsEnabled,
    );
    return load();
  }

  UserPreferences _requireAvailable() {
    final preferences = _localPrefs;
    if (preferences == null) {
      throw UnsupportedError('Account preferences are not connected to a persistent store.');
    }
    return preferences;
  }
}
