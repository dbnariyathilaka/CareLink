import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around the `patientProfiles` Firestore collection and each
/// patient's `favorites` subcollection.
class PatientService {
  PatientService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('patientProfiles');

  static Future<void> savePatientProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return _collection.doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getPatientProfile(String uid) async {
    final snap = await _collection.doc(uid).get();
    if (!snap.exists) return null;
    return {'uid': snap.id, ...?snap.data()};
  }

  /// Returns the display name of a patient by checking their patient profile
  /// ('name' or 'patientName') with fallback to the user record in `users/{uid}`.
  static Future<String> getPatientName(
    String uid, {
    String fallback = 'Patient',
  }) async {
    try {
      final profile = await getPatientProfile(uid);
      final name = (profile?['name'] as String?)?.trim() ??
          (profile?['patientName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;

      final userSnap = await _firestore.collection('users').doc(uid).get();
      final userName = (userSnap.data()?['name'] as String?)?.trim();
      if (userName != null && userName.isNotEmpty) return userName;
    } catch (_) {}
    return fallback;
  }

  /// Every patient profile, live — used by the admin patients list.
  static Stream<List<Map<String, dynamic>>> streamAllPatients() {
    return _collection.snapshots().map(
          (snap) => snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList(),
        );
  }

  static Future<int> countAll() async {
    final snap = await _collection.count().get();
    return snap.count ?? 0;
  }

  static Future<void> toggleFavorite({
    required String patientUid,
    required String caregiverUid,
    required bool isFavorite,
  }) {
    final ref = _collection
        .doc(patientUid)
        .collection('favorites')
        .doc(caregiverUid);
    if (isFavorite) {
      return ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
    return ref.delete();
  }

  static Future<List<String>> getFavoriteCaregiverIds(String patientUid) async {
    final snap =
        await _collection.doc(patientUid).collection('favorites').get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// Relatives/helpers the patient has added to their profile (name,
  /// relation, phone/role, isPrimary).
  static Future<List<Map<String, dynamic>>> getFamilyMembers(
    String patientUid,
  ) async {
    final snap =
        await _collection.doc(patientUid).collection('familyMembers').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  static Stream<List<Map<String, dynamic>>> streamFamilyMembers(
    String patientUid,
  ) {
    return _collection
        .doc(patientUid)
        .collection('familyMembers')
        .snapshots()
        .map((snap) {
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) {
        final at = a['addedAt'];
        final bt = b['addedAt'];
        if (at is! Timestamp || bt is! Timestamp) return 0;
        return at.compareTo(bt);
      });
      return docs;
    });
  }

  /// Creates a real, pending invite — the invited person claims it
  /// themselves (see [fetchPendingInvitesForEmail] / [acceptFamilyInvite])
  /// once they sign in with this exact email under their own account; there
  /// is still no email/SMS backend to actually deliver a notification, so
  /// they only discover it by logging into (or registering) Sathkara.
  /// [name] is shown until acceptance, when it's replaced with the real
  /// name from the invitee's own account.
  static Future<String> addFamilyMember({
    required String patientUid,
    required String patientName,
    required String name,
    required String email,
    required String relation,
    required String role,
  }) async {
    final ref = await _collection.doc(patientUid).collection('familyMembers').add({
      'name': name,
      'email': email.trim().toLowerCase(),
      'patientName': patientName,
      'relation': relation,
      'role': role,
      'status': 'pending',
      'linkedUid': null,
      'addedAt': FieldValue.serverTimestamp(),
      'invitedAt': FieldValue.serverTimestamp(),
    });
    await logActivity(patientUid, 'Invited $name to the care circle', icon: 'person_add');
    return ref.id;
  }

  static Future<void> removeFamilyMember(String patientUid, String memberId) {
    return _collection
        .doc(patientUid)
        .collection('familyMembers')
        .doc(memberId)
        .delete();
  }

  /// Every pending invite addressed to [email] — checked at login/register
  /// time (see FamilyAccessService) so the invitee can be prompted to
  /// accept/decline the moment their account's email matches one, without
  /// needing to know a code or link. `patientUid` comes from the parent
  /// document's own id, not a stored field, since `familyMembers` is always
  /// a subcollection of exactly one `patientProfiles/{patientUid}`.
  static Future<List<Map<String, dynamic>>> fetchPendingInvitesForEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    final snap = await _firestore
        .collectionGroup('familyMembers')
        .where('email', isEqualTo: normalized)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.map((d) {
      final patientUid = d.reference.parent.parent!.id;
      return {'memberId': d.id, 'patientUid': patientUid, ...d.data()};
    }).toList();
  }

  /// Claims a pending invite for the signed-in [linkedUid] — the real
  /// counterpart to the old fake "adds them directly" behavior. Writes both
  /// the claim itself (documentReviews-style narrow update, see
  /// firestore.rules) and the family member's own `familyLinks` entry,
  /// which is what every other delegated-access rule (bookings, care
  /// journal) checks against. Also replaces the placeholder `name` (the
  /// email typed at invite time) with the invitee's real registered name,
  /// now that their account is known.
  static Future<void> acceptFamilyInvite({
    required String memberId,
    required String patientUid,
    required String linkedUid,
    required String role,
    required String patientName,
  }) async {
    String? realName;
    try {
      final userSnap = await _firestore.collection('users').doc(linkedUid).get();
      realName = (userSnap.data()?['name'] as String?)?.trim();
    } catch (_) {}

    final memberRef = _collection.doc(patientUid).collection('familyMembers').doc(memberId);
    await memberRef.set({
      'status': 'accepted',
      'linkedUid': linkedUid,
      'acceptedAt': FieldValue.serverTimestamp(),
      if (realName != null && realName.isNotEmpty) 'name': realName,
    }, SetOptions(merge: true));

    await _firestore
        .collection('familyLinks')
        .doc(linkedUid)
        .collection('patients')
        .doc(patientUid)
        .set({
      'role': role,
      'status': 'accepted',
      'memberId': memberId,
      'patientName': patientName,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    await logActivity(patientUid, '${realName ?? 'A family member'} joined the care circle', icon: 'person_add');
  }

  static Future<void> declineFamilyInvite({
    required String memberId,
    required String patientUid,
  }) {
    return _collection.doc(patientUid).collection('familyMembers').doc(memberId).set({
      'status': 'declined',
    }, SetOptions(merge: true));
  }

  /// Every patient this account has accepted delegated family access to —
  /// used by the "Your care circles" list and the post-login routing check
  /// (an account with no patient/caregiver role of its own but at least one
  /// accepted link goes straight here instead of role selection).
  static Stream<List<Map<String, dynamic>>> streamAcceptedFamilyLinks(String uid) {
    return _firestore
        .collection('familyLinks')
        .doc(uid)
        .collection('patients')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'patientUid': d.id, ...d.data()}).toList());
  }

  /// Real events only (member added, booking created) — no fabricated
  /// activity types like journal notes, since no such feature exists.
  static Future<void> logActivity(
    String patientUid,
    String message, {
    required String icon,
  }) {
    return _collection.doc(patientUid).collection('activity').add({
      'message': message,
      'icon': icon,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> streamActivity(String patientUid) {
    return _collection
        .doc(patientUid)
        .collection('activity')
        .snapshots()
        .map((snap) {
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) {
        final at = a['createdAt'];
        final bt = b['createdAt'];
        if (at is! Timestamp || bt is! Timestamp) return 0;
        return bt.compareTo(at);
      });
      return docs;
    });
  }
}
