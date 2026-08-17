import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth + the `users` Firestore collection.
///
/// `users/{uid}` is the single source of truth for "which role does this
/// account have" — used at login time to route to the correct dashboard.
class AuthService {
  AuthService._();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> signInWithGoogleCredential(
    AuthCredential credential,
  ) {
    return _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() => _auth.signOut();

  /// Sends a real Firebase-hosted password-reset email. Firebase only
  /// delivers it to addresses with an existing account; depending on the
  /// project's email-enumeration-protection setting it either throws
  /// `user-not-found` for unknown addresses or (the more secure default)
  /// silently no-ops so callers can't probe which emails are registered —
  /// either way, this is the real check, not a client-side guess. Tapping
  /// the link in that email takes the user to Firebase's own hosted page
  /// to set a new password; no in-app screen is involved.
  static Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Maps a [FirebaseAuthException] thrown while requesting a password
  /// reset to a user-facing message.
  static String messageForPasswordResetError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'Could not send the reset email. Please try again.';
    }
  }

  /// Creates/overwrites the `users/{uid}` profile document. `role` is only
  /// written when provided — omitting it (e.g. when just editing name/email)
  /// must not clobber the role set at registration time.
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    String? role,
    String? phone,
  }) {
    return Future.wait([
      _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        if (role != null) 'role': role,
        if (phone != null) 'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      _indexEmailForLookup(email),
    ]);
  }

  static String _emailKey(String email) => email.trim().toLowerCase();

  /// Registers this email into a minimal, PII-free existence index so
  /// isEmailRegistered (below) can answer "does an account exist for this
  /// email" from an unauthenticated screen — Firebase's own
  /// sendPasswordResetEmail can't reliably answer that itself; see its doc
  /// comment. No Cloud Functions exist in this project to do this lookup
  /// server-side, so this is the lowest-exposure client-only alternative:
  /// the Firestore rule for this collection allows a single-document `get`
  /// (check one already-known email) but not `list` (bulk-enumerate every
  /// registered email).
  static Future<void> _indexEmailForLookup(String email) {
    return _firestore.collection('registeredEmails').doc(_emailKey(email)).set({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Whether [email] belongs to a registered account. Used by the
  /// forgot-password screen before attempting a reset email.
  static Future<bool> isEmailRegistered(String email) async {
    final snap = await _firestore
        .collection('registeredEmails')
        .doc(_emailKey(email))
        .get();
    return snap.exists;
  }

  /// Deletes an Auth account that never completed onboarding, along with
  /// every Firestore document created for it. Used to clean up half-baked
  /// caregiver accounts on login so they cannot access the app in a broken
  /// state.  Each delete is best-effort — one failure does not block others.
  static Future<void> deleteIncompleteAccount(String uid, String email) async {
    // 1. Delete the Firebase Auth user (requires the session to still be live).
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {}

    // 2. Wipe Firestore documents.
    for (final collectionPath in [
      'users',
      'caregiverProfiles',
    ]) {
      try {
        await _firestore.collection(collectionPath).doc(uid).delete();
      } catch (_) {}
    }

    // 3. Remove the email from the lookup index.
    try {
      await _firestore
          .collection('registeredEmails')
          .doc(_emailKey(email))
          .delete();
    } catch (_) {}
  }

  /// Returns true only when the caregiver has reached the success screen
  /// and tapped "Go to dashboard" (i.e., `onboardingComplete == true` in
  /// caregiverProfiles/{uid}).
  static Future<bool> isCaregiverOnboardingComplete(String uid) async {
    try {
      final snap = await _firestore
          .collection('caregiverProfiles')
          .doc(uid)
          .get();
      return snap.data()?['onboardingComplete'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Best-effort cleanup of whatever saveUserProfile managed to write
  /// before failing partway through — used to roll back a half-created
  /// registration so the email isn't left stuck as "already registered"
  /// with no real profile behind it. Each delete is independent so one
  /// failing doesn't stop the other from being attempted.
  static Future<void> deleteUserProfile(String uid, String email) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (_) {}
    try {
      await _firestore
          .collection('registeredEmails')
          .doc(_emailKey(email))
          .delete();
    } catch (_) {}
  }

  static Future<void> setUserRole(String uid, String role) {
    return _firestore.collection('users').doc(uid).set({
      'role': role,
    }, SetOptions(merge: true));
  }

  /// Returns the `users/{uid}` document, or null if it doesn't exist
  /// (e.g. an Auth account exists but registration never finished).
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.data();
  }

  /// Maps a [FirebaseAuthException] thrown during registration to a
  /// user-facing message.
  static String messageForRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled yet. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'Could not create your account. Please try again.';
    }
  }

  /// Maps a [FirebaseAuthException] thrown during sign-in to a
  /// user-facing message.
  static String messageForSignInError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }
}
