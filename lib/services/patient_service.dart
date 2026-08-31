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

  /// Adds a real member to the care circle — no email invite is actually
  /// sent (no email backend exists), so this adds them directly rather
  /// than creating a fake "pending invite" that could never be delivered.
  static Future<void> addFamilyMember({
    required String patientUid,
    required String name,
    required String relation,
    required String role,
  }) async {
    await _collection.doc(patientUid).collection('familyMembers').add({
      'name': name,
      'relation': relation,
      'role': role,
      'addedAt': FieldValue.serverTimestamp(),
    });
    await logActivity(patientUid, '$name joined the care circle', icon: 'person_add');
  }

  static Future<void> removeFamilyMember(String patientUid, String memberId) {
    return _collection
        .doc(patientUid)
        .collection('familyMembers')
        .doc(memberId)
        .delete();
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
