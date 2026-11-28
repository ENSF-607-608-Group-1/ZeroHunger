// auth_service.dart
//
//   First launch    → signInAsGuest()    → a guest (anonymous user, no form)
//   Create account  → registerAccount()  → links guest or creates Firebase Auth user,
//                                          then writes Users, PostalCode, Organization,
//                                          User_Organization, Locations, and UserPreferences
//                                          into Cloud SQL via Firebase Data Connect
//   Sign in         → signIn()           → an existing account, e.g. on a new phone
//   Sign out        → signOut()          → back to being a new guest
//
// Every call to our Cloud Functions carries the signed-in user automatically:
// the cloud_functions package adds the user's token for us.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../generated/zerohunger.dart';
import 'account_settings_service.dart';

final RegExp _canadianPostalCodePattern = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _phonePattern = RegExp(r'^[0-9+\-\s().]{7,30}$');

// Tidies a Canadian postal code: "t2n1n4" → "T2N 1N4".
String normalizeCanadianPostalCode(String raw) {
  final stripped = raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  if (stripped.isEmpty) return '';
  if (stripped.length == 6) {
    return '${stripped.substring(0, 3)} ${stripped.substring(3)}';
  }
  return stripped;
}

bool isValidCanadianPostalCode(String raw) {
  final normalized = normalizeCanadianPostalCode(raw);
  return _canadianPostalCodePattern.hasMatch(normalized);
}

bool isValidEmail(String raw) => _emailPattern.hasMatch(raw.trim());

bool isValidPhoneNumber(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return true;
  final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
  return _phonePattern.hasMatch(trimmed) && digitsOnly.length >= 7 && digitsOnly.length <= 15;
}

// All fields collected during Create Account, mapped directly onto the deployed Cloud SQL schema:
//   Users, PostalCode, Organization, User_Organization, Locations, UserPreferences.
class AccountRegistrationData {
  final String email;
  final String password;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? street;
  final String? postalCode;
  final String? city;
  final String? province;
  final String? organizationName;
  final String? organizationEmail;
  final int radiusSearch;
  final bool notificationsEnabled;

  const AccountRegistrationData({
    required this.email,
    required this.password,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.street,
    this.postalCode,
    this.city,
    this.province,
    this.organizationName,
    this.organizationEmail,
    this.radiusSearch = 10,
    this.notificationsEnabled = true,
  });

  String? get normalizedPostalCode {
    final raw = postalCode?.trim() ?? '';
    if (raw.isEmpty) return null;
    final normalized = normalizeCanadianPostalCode(raw);
    return normalized.isEmpty ? null : normalized;
  }

  String? get trimmedPhone => _nonEmptyOrNull(phoneNumber);
  String? get trimmedStreet => _nonEmptyOrNull(street);
  String? get trimmedCity => _nonEmptyOrNull(city);
  String? get trimmedProvince => _nonEmptyOrNull(province);
  String? get trimmedOrganizationName => _nonEmptyOrNull(organizationName);
  String? get trimmedOrganizationEmail => _nonEmptyOrNull(organizationEmail);
}

String? _nonEmptyOrNull(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    ZerohungerConnector? connector,
  })  : _authOverride = auth,
        _connectorOverride = connector;

  final FirebaseAuth? _authOverride;
  final ZerohungerConnector? _connectorOverride;

  // FirebaseAuth.instance is the app's one connection to Firebase Authentication.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  ZerohungerConnector get _connector => _connectorOverride ?? ZerohungerConnector.instance;

  // The signed-in user, or null if no one is signed in yet.
  User? get currentUser => _auth.currentUser;

  // True for a guest: signed in anonymously, with no email yet.
  bool get isGuest => _auth.currentUser?.isAnonymous ?? true;

  // Tells listeners (e.g. a screen) whenever the user changes:
  // signed in, signed out, or a guest who just created an account.
  Stream<User?> get userChanges => _auth.userChanges();

  // On launch: if no one is signed in, sign in as a guest.
  // Firebase remembers the user on this phone, so a new guest is only made the first time.
  Future<void> signInAsGuest() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Step 1 (Create account): creates or links the user in Firebase Authentication.
  // When linking an anonymous guest, re-signs in with email/password so the issued ID token
  // has sign_in_provider == "password" (required by CreateCurrentUser's @auth rule).
  Future<User> createAuthUser(String email, String password) async {
    final trimmedEmail = email.trim();
    final existing = _auth.currentUser;

    // If a previous attempt already created this Firebase Auth account and only the
    // Cloud SQL step failed, reuse the signed-in user so retrying succeeds cleanly.
    if (existing != null &&
        !existing.isAnonymous &&
        existing.email?.toLowerCase() == trimmedEmail.toLowerCase()) {
      return existing;
    }

    final credential = EmailAuthProvider.credential(email: trimmedEmail, password: password);
    late final UserCredential result;
    if (existing != null && existing.isAnonymous) {
      await existing.linkWithCredential(credential);
      result = await _auth.signInWithEmailAndPassword(email: trimmedEmail, password: password);
    } else {
      result = await _auth.createUserWithEmailAndPassword(email: trimmedEmail, password: password);
    }
    final user = result.user ?? _auth.currentUser;
    if (user == null) {
      throw StateError('Firebase Authentication returned no user after creating account.');
    }
    return user;
  }

  // Step 1 (Sign in): signs in to an existing Firebase Authentication account.
  Future<User> signInWithAuth(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user ?? _auth.currentUser;
    if (user == null) {
      throw StateError('Firebase Authentication returned no user after sign-in.');
    }
    return user;
  }

  // Step 2: uploads the signed-in user's account records into Cloud SQL via Data Connect
  // matching the deployed schema: PostalCode -> Users -> Organization & User_Organization
  // -> Locations -> UserPreferences. Safe to retry if partially completed.
  Future<void> uploadCurrentUserToCloudSql({
    User? user,
    AccountRegistrationData? registration,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserRole? role,
    String? street,
    String? postalCode,
    String? city,
    String? province,
    String? organizationName,
    String? organizationEmail,
    int? radiusSearch,
    bool? notificationsEnabled,
  }) async {
    final activeUser = user ?? _auth.currentUser;
    if (activeUser == null) {
      throw StateError('No signed-in user to upload to Cloud SQL.');
    }

    await activeUser.getIdToken(true);
    final connector = _connector;

    final resolvedFirstName = _nonEmptyOrNull(registration?.firstName ?? firstName);
    final resolvedLastName = _nonEmptyOrNull(registration?.lastName ?? lastName);
    final resolvedPhone = _nonEmptyOrNull(registration?.trimmedPhone ?? phoneNumber);
    final resolvedRole = registration?.role ?? role ?? UserRole.donor;
    final resolvedStreet = _nonEmptyOrNull(registration?.trimmedStreet ?? street);
    final resolvedPostalCode = registration?.normalizedPostalCode ??
        (_nonEmptyOrNull(postalCode) != null ? normalizeCanadianPostalCode(postalCode!) : null);
    final resolvedCity = _nonEmptyOrNull(registration?.trimmedCity ?? city);
    final resolvedProvince = _nonEmptyOrNull(registration?.trimmedProvince ?? province);
    final resolvedOrgName = _nonEmptyOrNull(registration?.trimmedOrganizationName ?? organizationName);
    final resolvedOrgEmail = _nonEmptyOrNull(registration?.trimmedOrganizationEmail ?? organizationEmail);
    final resolvedRadius = (registration?.radiusSearch ?? radiusSearch ?? 10);
    final resolvedNotifications = registration?.notificationsEnabled ?? notificationsEnabled ?? true;

    final hasProfilePayload = registration != null ||
        resolvedFirstName != null ||
        resolvedLastName != null ||
        resolvedPhone != null ||
        role != null ||
        resolvedStreet != null ||
        resolvedPostalCode != null;

    // 1. Resolve or create PostalCode (Code is UNIQUE in PostgreSQL).
    BigInt? postalCodeId;
    if (resolvedPostalCode != null) {
      postalCodeId = await _resolveOrCreatePostalCode(
        connector,
        code: resolvedPostalCode,
        city: resolvedCity,
        province: resolvedProvince,
      );
    }

    // 2. Check whether the user already exists in Cloud SQL Users.
    debugPrint('DataConnect: running GetCurrentUser for uid=${activeUser.uid}, email=${activeUser.email}');
    final currentUserResult = await connector.getCurrentUser().execute();
    GetCurrentUserUsers? existingUser =
        currentUserResult.data.users.isEmpty ? null : currentUserResult.data.users.first;

    late final BigInt userId;
    if (existingUser == null) {
      debugPrint('DataConnect: user not in Cloud SQL yet, running CreateCurrentUser (role=${resolvedRole.dbValue})');
      final builder = connector.createCurrentUser(userRole: resolvedRole.dbValue);
      if (resolvedFirstName != null) builder.firstName(resolvedFirstName);
      if (resolvedLastName != null) builder.lastName(resolvedLastName);
      if (resolvedPhone != null) builder.phoneNumber(resolvedPhone);
      if (resolvedStreet != null) builder.street(resolvedStreet);
      if (postalCodeId != null) builder.postalCodeId(postalCodeId);
      final inserted = await builder.execute();
      userId = inserted.data.user_insert.userId;
      debugPrint('DataConnect: CreateCurrentUser succeeded (userId=$userId)');
    } else {
      userId = existingUser.userId;
      debugPrint('DataConnect: user already exists in Cloud SQL (userId=$userId)');
      if (hasProfilePayload) {
        final updateBuilder = connector.updateCurrentUser();
        if (resolvedFirstName != null) updateBuilder.firstName(resolvedFirstName);
        if (resolvedLastName != null) updateBuilder.lastName(resolvedLastName);
        if (resolvedPhone != null) updateBuilder.phoneNumber(resolvedPhone);
        if (registration != null || role != null) updateBuilder.userRole(resolvedRole.dbValue);
        if (resolvedStreet != null) updateBuilder.street(resolvedStreet);
        if (postalCodeId != null) updateBuilder.postalCodeId(postalCodeId);
        await updateBuilder.execute();
        debugPrint('DataConnect: UpdateCurrentUser synced profile for userId=$userId');
      }
    }

    // 3. If registering as an Organization, create/resolve Organization and link User_Organization.
    BigInt? orgId;
    if (resolvedRole == UserRole.organization && resolvedOrgName != null) {
      final primaryEmail = resolvedOrgEmail ?? activeUser.email?.trim() ?? '';
      if (primaryEmail.isNotEmpty) {
        orgId = await _resolveOrCreateOrganization(
          connector,
          orgName: resolvedOrgName,
          orgPrimaryEmail: primaryEmail,
          street: resolvedStreet,
          postalCodeId: postalCodeId,
        );
        await connector
            .linkUserToOrganization(
              userId: userId,
              orgId: orgId,
              memberRole: 'admin',
            )
            .execute();
        debugPrint('DataConnect: Linked userId=$userId to orgId=$orgId as admin');
      }
    }

    // 4. Create Locations row when both required columns (Street, PostalCodeID) are present.
    BigInt? locationId = existingUser?.userPreferences_on_user?.locationId;
    if (locationId == null && resolvedStreet != null && postalCodeId != null) {
      final locBuilder = connector.createLocation(
        street: resolvedStreet,
        postalCodeId: postalCodeId,
      )..userId(userId);
      if (orgId != null) locBuilder.orgId(orgId);
      final locResult = await locBuilder.execute();
      locationId = locResult.data.locations_insert.locationId;
      debugPrint('DataConnect: CreateLocation succeeded (locationId=$locationId)');
    }

    // 5. Create UserPreferences row once per user (UserID is UNIQUE, RadiusSearch > 0).
    if (existingUser?.userPreferences_on_user == null) {
      final safeRadius = resolvedRadius > 0 ? resolvedRadius : 10;
      final prefBuilder = connector.createUserPreferences(userId: userId)
        ..radiusSearch(safeRadius)
        ..notificationPreference(resolvedNotifications ? 'enabled' : 'disabled')
        ..alertSetting(resolvedNotifications ? 'all' : 'paused');
      if (locationId != null) prefBuilder.locationId(locationId);
      await prefBuilder.execute();
      debugPrint('DataConnect: CreateUserPreferences succeeded for userId=$userId');
    }
  }

  Future<BigInt> _resolveOrCreatePostalCode(
    ZerohungerConnector connector, {
    required String code,
    String? city,
    String? province,
  }) async {
    final existing = await connector.getPostalCodeByCode(code: code).execute();
    if (existing.data.postalCodes.isNotEmpty) {
      return existing.data.postalCodes.first.postalCodeId;
    }

    // Also check without space in case seeded rows were stored as e.g. "T2N1N4".
    final compact = code.replaceAll(' ', '');
    if (compact != code) {
      final compactExisting = await connector.getPostalCodeByCode(code: compact).execute();
      if (compactExisting.data.postalCodes.isNotEmpty) {
        return compactExisting.data.postalCodes.first.postalCodeId;
      }
    }

    try {
      final builder = connector.createPostalCode(code: code);
      if (city != null) builder.city(city);
      if (province != null) builder.province(province);
      final inserted = await builder.execute();
      return inserted.data.postalCode_insert.postalCodeId;
    } catch (_) {
      // Handle race condition if another user inserted the same postal code concurrently.
      final retry = await connector.getPostalCodeByCode(code: code).execute();
      if (retry.data.postalCodes.isNotEmpty) {
        return retry.data.postalCodes.first.postalCodeId;
      }
      rethrow;
    }
  }

  Future<BigInt> _resolveOrCreateOrganization(
    ZerohungerConnector connector, {
    required String orgName,
    required String orgPrimaryEmail,
    String? street,
    BigInt? postalCodeId,
  }) async {
    final existing =
        await connector.getOrganizationByPrimaryEmail(orgPrimaryEmail: orgPrimaryEmail).execute();
    if (existing.data.organizations.isNotEmpty) {
      return existing.data.organizations.first.orgId;
    }

    try {
      final builder = connector.createOrganization(
        orgName: orgName,
        orgPrimaryEmail: orgPrimaryEmail,
      );
      if (street != null) builder.street(street);
      if (postalCodeId != null) builder.postalCodeId(postalCodeId);
      final inserted = await builder.execute();
      return inserted.data.organization_insert.orgId;
    } catch (_) {
      final retry =
          await connector.getOrganizationByPrimaryEmail(orgPrimaryEmail: orgPrimaryEmail).execute();
      if (retry.data.organizations.isNotEmpty) {
        return retry.data.organizations.first.orgId;
      }
      rethrow;
    }
  }

  // Full registration flow: creates/links Firebase Auth user and provisions Cloud SQL records.
  Future<void> registerAccount(AccountRegistrationData data) async {
    final user = await createAuthUser(data.email, data.password);
    await uploadCurrentUserToCloudSql(user: user, registration: data);
  }

  // Convenience wrapper: creates the Firebase Auth user and uploads them to Cloud SQL.
  Future<void> createAccount(String email, String password) async {
    final user = await createAuthUser(email, password);
    await uploadCurrentUserToCloudSql(user: user);
  }

  // Convenience wrapper: signs in via Firebase Auth and ensures the user exists in Cloud SQL.
  Future<void> signIn(String email, String password) async {
    final user = await signInWithAuth(email, password);
    await uploadCurrentUserToCloudSql(user: user);
  }

  // Loads the signed-in user's full account profile from Cloud SQL.
  Future<UserPreferences> getCurrentUserProfile() async {
    final activeUser = _auth.currentUser;
    if (activeUser == null || activeUser.isAnonymous) {
      return const UserPreferences(
        role: null,
        postalCode: '',
        foodPreferences: {},
        allergensToAvoid: {},
        notificationsEnabled: false,
        followedOrganizations: [],
      );
    }

    final result = await _connector.getCurrentUser().execute();
    if (result.data.users.isEmpty) {
      return const UserPreferences(
        role: null,
        postalCode: '',
        foodPreferences: {},
        allergensToAvoid: {},
        notificationsEnabled: false,
        followedOrganizations: [],
      );
    }

    final row = result.data.users.first;
    final prefs = row.userPreferences_on_user;
    final notifPref = (prefs?.notificationPreference ?? '').toLowerCase();
    final notificationsEnabled = prefs != null && notifPref != 'disabled' && notifPref != 'none';

    return UserPreferences(
      role: UserRole.fromDbValue(row.userRole),
      firstName: row.firstName ?? '',
      lastName: row.lastName ?? '',
      phoneNumber: row.phoneNumber ?? '',
      street: row.street ?? '',
      city: row.postalCode?.city ?? '',
      province: row.postalCode?.province ?? '',
      postalCode: row.postalCode?.code ?? '',
      foodPreferences: const {},
      allergensToAvoid: const {},
      notificationsEnabled: notificationsEnabled,
      followedOrganizations: row.userOrganizations_on_user
          .map(
            (link) => FollowedOrganization(
              organizationId: link.organization.orgId.toString(),
              name: link.organization.orgName,
              city: link.organization.postalCode?.city ?? '',
              memberRole: link.memberRole,
            ),
          )
          .toList(),
    );
  }

  // Persists a role change in Cloud SQL Users.UserRole and returns the refreshed profile.
  Future<UserPreferences> updateCurrentUserRole(UserRole role) async {
    await _connector.updateCurrentUserRole(userRole: role.dbValue).execute();
    return getCurrentUserProfile();
  }

  // Signs out, then carries on as a new guest.
  Future<void> signOut() async {
    await _auth.signOut();
    await signInAsGuest();
  }
}

// Turns a sign-in error into words we can show the user.
String authErrorText(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
    case 'credential-already-in-use':
      return 'That email already has an account. Sign in instead.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'weak-password':
      return 'Use a password with at least 6 characters.';
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Wrong email or password.';
    case 'network-request-failed':
      return 'No connection. Check your internet and try again.';
    default:
      return e.message ?? 'Sign-in failed. Please try again.';
  }
}
