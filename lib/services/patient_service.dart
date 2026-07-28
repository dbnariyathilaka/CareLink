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
  /// relation, phone, isPrimary). No add flow exists yet, so this is
  /// always empty today — reading it is wired up ahead of that screen.
  static Future<List<Map<String, dynamic>>> getFamilyMembers(
    String patientUid,
  ) async {
    final snap =
        await _collection.doc(patientUid).collection('familyMembers').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
