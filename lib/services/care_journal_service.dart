import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around each patient's `careJournal` subcollection — real,
/// timestamped notes a caregiver leaves during/after a visit. Firestore's
/// own offline cache is the entire "draft" story: a write made offline (or
/// mid-flight) is queryable immediately with `hasPendingWrites: true` and
/// flips to false once the server acknowledges it, so entries can honestly
/// show "Draft — pending sync" without any bespoke sync-queue of our own.
class CareJournalService {
  CareJournalService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _collection(String patientUid) =>
      _firestore.collection('patientProfiles').doc(patientUid).collection('careJournal');

  static Future<void> addEntry({
    required String patientUid,
    required String authorUid,
    required String authorName,
    required String category,
    required String text,
    String? photoUrl,
    bool flagged = false,
    DateTime? occurredAt,
  }) {
    return _collection(patientUid).add({
      'category': category,
      'text': text,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'flagged': flagged,
      'authorUid': authorUid,
      'authorName': authorName,
      'createdAt': occurredAt != null ? Timestamp.fromDate(occurredAt) : FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateEntry(String patientUid, String entryId, String text) {
    return _collection(patientUid).doc(entryId).update({
      'text': text,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteEntry(String patientUid, String entryId) {
    return _collection(patientUid).doc(entryId).delete();
  }

  /// `includeMetadataChanges: true` so the "pending sync" state updates in
  /// real time as writes move from local-only to server-confirmed.
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamEntries(String patientUid) {
    return _collection(patientUid)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true);
  }
}
