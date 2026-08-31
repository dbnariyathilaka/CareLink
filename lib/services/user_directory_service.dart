import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin read wrapper around the `users` collection — this is where a real
/// account's `name`, `email`, `phone` and `createdAt` actually live (patient
/// and caregiver profile docs don't carry these fields), so any screen that
/// needs to display those must join through here.
class UserDirectoryService {
  UserDirectoryService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _collection.doc(uid).get();
    if (!snap.exists) return null;
    return {'uid': snap.id, ...?snap.data()};
  }

  static Stream<Map<String, dynamic>?> streamUser(String uid) {
    return _collection.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return {'uid': snap.id, ...?snap.data()};
    });
  }

  /// Batch-fetches user records for many uids at once, chunked by
  /// Firestore's 30-item `whereIn` limit.
  static Future<Map<String, Map<String, dynamic>>> getUsers(
    List<String> uids,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    final ids = uids.toSet().toList();
    if (ids.isEmpty) return result;
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await _collection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        result[doc.id] = {'uid': doc.id, ...doc.data()};
      }
    }
    return result;
  }

  static Future<int> countByRole(String role) async {
    final snap = await _collection.where('role', isEqualTo: role).count().get();
    return snap.count ?? 0;
  }
}
