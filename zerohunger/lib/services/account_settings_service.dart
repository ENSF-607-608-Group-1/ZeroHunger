// account_settings_service.dart
// Models the user's profile details and alert settings for the Account and Settings screens.
//
// Used by AccountScreen and SettingsScreen (two separate pages under the Profile menu).
//
// Supports Cloud SQL-backed profile loading & role updates via optional remote callbacks,
// while keeping default construction safe for widget tests without Firebase.

// Role chosen for the account (matches project requirements & Users.UserRole in Cloud SQL).
enum UserRole {
  donor,
  recipient,
  organization;

  String get dbValue => switch (this) {
        UserRole.donor => 'donor',
        UserRole.recipient => 'recipient',
        UserRole.organization => 'organization',
      };

  String get label => switch (this) {
        UserRole.donor => 'Donor',
        UserRole.recipient => 'Recipient',
        UserRole.organization => 'Organization',
      };

  static UserRole? fromDbValue(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'donor':
        return UserRole.donor;
      case 'recipient':
        return UserRole.recipient;
      case 'organization':
        return UserRole.organization;
      default:
        return null;
    }
  }
}

// One food bank or community group linked to / followed by the user.
class FollowedOrganization {
  final String organizationId;
  final String name; // e.g. "Calgary Food Bank"
  final String city; // e.g. "Calgary"
  final String? memberRole; // e.g. "admin", "member", "follower"

  const FollowedOrganization({
    required this.organizationId,
    required this.name,
    required this.city,
    this.memberRole,
  });
}

// Combined account & settings state for the signed-in user (or guest).
class UserPreferences {
  final UserRole? role;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String street;
  final String city;
  final String province;
  final String postalCode;               // Canadian format, e.g. "T2N 1N4"
  final Set<String> foodPreferences;     // from foodCategoryOptions in zero_hunger_api.dart
  final Set<String> allergensToAvoid;    // from allergenOptions in zero_hunger_api.dart (11 priority allergens)
  final bool notificationsEnabled;
  final List<FollowedOrganization> followedOrganizations;

  const UserPreferences({
    required this.role,
    this.firstName = '',
    this.lastName = '',
    this.phoneNumber = '',
    this.street = '',
    this.city = '',
    this.province = '',
    required this.postalCode,
    required this.foodPreferences,
    required this.allergensToAvoid,
    required this.notificationsEnabled,
    required this.followedOrganizations,
  });

  String get fullName => [firstName.trim(), lastName.trim()].where((s) => s.isNotEmpty).join(' ');

  String get formattedAddress {
    final cityProv = [city.trim(), province.trim()].where((s) => s.isNotEmpty).join(', ');
    return [street.trim(), cityProv, postalCode.trim()].where((s) => s.isNotEmpty).join(' • ');
  }

  UserPreferences copyWith({
    UserRole? role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? street,
    String? city,
    String? province,
    String? postalCode,
    Set<String>? foodPreferences,
    Set<String>? allergensToAvoid,
    bool? notificationsEnabled,
    List<FollowedOrganization>? followedOrganizations,
  }) {
    return UserPreferences(
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      city: city ?? this.city,
      province: province ?? this.province,
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
    this.remoteLoader,
    this.remoteRoleUpdater,
  }) : _localPrefs = initialPreferences;

  UserPreferences? _localPrefs;
  final Duration simulatedDelay;
  final Future<UserPreferences> Function()? remoteLoader;
  final Future<UserPreferences> Function(UserRole role)? remoteRoleUpdater;

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
    if (remoteLoader != null) {
      final loaded = await remoteLoader!();
      return loaded.copyWith(
        foodPreferences: Set<String>.unmodifiable(loaded.foodPreferences),
        allergensToAvoid: Set<String>.unmodifiable(loaded.allergensToAvoid),
        followedOrganizations: List<FollowedOrganization>.unmodifiable(loaded.followedOrganizations),
      );
    }
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

  // Updates the account role (Donor, Recipient, or Organization).
  Future<UserPreferences> updateRole(UserRole role) async {
    if (remoteRoleUpdater != null) {
      return remoteRoleUpdater!(role);
    }
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
