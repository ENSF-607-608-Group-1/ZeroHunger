// auth_service.dart

//   First launch    → signInAsGuest()  → a guest (anonymous user, no form)
//   Create account  → createAccount()  → the SAME user, now with an email and password
//   Sign in         → signIn()         → an existing account, e.g. on a new phone
//   Sign out        → signOut()        → back to being a new guest

// Every call to our Cloud Functions carries the signed-in user automatically:
// the cloud_functions package adds the user's token for us.

import 'package:firebase_auth/firebase_auth.dart';

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

  // A guest creates an account with an email and password.
  // linkWithCredential adds the email to the SAME user, so the user ID stays the same
  // and anything they did as a guest stays theirs.
  Future<void> createAccount(String email, String password) async {
    final credential = EmailAuthProvider.credential(email: email, password: password);
    final user = _auth.currentUser;
    late final UserCredential result;
    if (user != null && user.isAnonymous) {
      result = await user.linkWithCredential(credential);
    } else {
      result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    }
    await _ensureDataConnectUser(result.user);
  }

  // Signs in to an existing account, e.g. on a new phone.
  Future<void> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _ensureDataConnectUser(credential.user);
  }

  // Signs out, then carries on as a new guest.
  Future<void> signOut() async {
    await _auth.signOut();
    await signInAsGuest();
  }

  Future<void> _ensureDataConnectUser(User? user) async {
    if (user == null) {
      throw StateError('Firebase Authentication returned no user after sign-in.');
    }

    await user.getIdToken(true);
    final connector = ZerohungerConnector.instance;
    final currentUser = await connector.getCurrentUser().execute();
    if (currentUser.data.users.isEmpty) {
      await connector.createCurrentUser().execute();
    }
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