// auth_service.dart

//   First launch    → signInAsGuest()  → a guest (anonymous user, no form)
//   Create account  → createAccount()  → the SAME user, now with an email and password
//   Sign in         → signIn()         → an existing account, e.g. on a new phone
//   Sign out        → signOut()        → back to being a new guest

// Every call to our Cloud Functions carries the signed-in user automatically:
// the cloud_functions package adds the user's token for us.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../generated/zerohunger.dart';

class AuthService {
  // FirebaseAuth.instance is the app's one connection to Firebase Authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    final credential = EmailAuthProvider.credential(email: email, password: password);
    final existing = _auth.currentUser;
    late final UserCredential result;
    if (existing != null && existing.isAnonymous) {
      await existing.linkWithCredential(credential);
      result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    } else {
      result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    }
    final user = result.user ?? _auth.currentUser;
    if (user == null) {
      throw StateError('Firebase Authentication returned no user after creating account.');
    }
    return user;
  }

  // Step 1 (Sign in): signs in to an existing Firebase Authentication account.
  Future<User> signInWithAuth(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = result.user ?? _auth.currentUser;
    if (user == null) {
      throw StateError('Firebase Authentication returned no user after sign-in.');
    }
    return user;
  }

  // Step 2: uploads the signed-in user's row to the Cloud SQL Users table via Data Connect
  // if they do not already exist there.
  Future<void> uploadCurrentUserToCloudSql({
    User? user,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    final activeUser = user ?? _auth.currentUser;
    if (activeUser == null) {
      throw StateError('No signed-in user to upload to Cloud SQL.');
    }

    await activeUser.getIdToken(true);
    final connector = ZerohungerConnector.instance;
    debugPrint('DataConnect: running GetCurrentUser for uid=${activeUser.uid}, email=${activeUser.email}');
    final currentUser = await connector.getCurrentUser().execute();
    if (currentUser.data.users.isEmpty) {
      debugPrint('DataConnect: user not in Cloud SQL yet, running CreateCurrentUser');
      final builder = connector.createCurrentUser();
      if (firstName != null) builder.firstName(firstName);
      if (lastName != null) builder.lastName(lastName);
      if (phoneNumber != null) builder.phoneNumber(phoneNumber);
      await builder.execute();
      debugPrint('DataConnect: CreateCurrentUser succeeded');
    } else {
      debugPrint('DataConnect: user already exists in Cloud SQL (userId=${currentUser.data.users.first.userId})');
    }
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