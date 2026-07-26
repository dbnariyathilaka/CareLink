import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around the `caregiverProfiles` Firestore collection.
class CaregiverService {
  CaregiverService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('caregiverProfiles');

  static Future<void> saveCaregiverProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return _collection.doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getCaregiverProfile(String uid) async {
    final snap = await _collection.doc(uid).get();
    if (!snap.exists) return null;
    return {'uid': snap.id, ...?snap.data()};
  }

  /// Plain, unscored lookup of caregivers — no matching/ranking logic.
  /// Optionally narrows by care type or city if provided.
  static Future<List<Map<String, dynamic>>> searchCaregivers({
    String? careType,
    String? city,
  }) async {
    Query<Map<String, dynamic>> query = _collection;
    if (careType != null && careType.isNotEmpty) {
      query = query.where('careTypes', arrayContains: careType);
    }
    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    final snap = await query.get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }
}
