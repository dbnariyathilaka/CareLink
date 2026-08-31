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

  /// Every caregiver profile, live — used by the admin caregivers list.
  static Stream<List<Map<String, dynamic>>> streamAllCaregivers() {
    return _collection.snapshots().map(
          (snap) => snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList(),
        );
  }

  static Future<int> countAll() async {
    final snap = await _collection.count().get();
    return snap.count ?? 0;
  }

  /// Whether a caregiver profile map has at least one uploaded document —
  /// there's no per-document or overall "verified" status field anywhere in
  /// the schema, so this is the closest real, honest signal of "has
  /// submitted something for review".
  static bool hasSubmittedDocuments(Map<String, dynamic> profile) {
    final certs = profile['certificateUrls'] as List<dynamic>?;
    final police = profile['policeClearanceUrl'] as String?;
    final other = profile['otherDocumentUrls'] as List<dynamic>?;
    return (certs != null && certs.isNotEmpty) ||
        (police != null && police.isNotEmpty) ||
        (other != null && other.isNotEmpty);
  }

  /// Real count of caregivers who have submitted at least one document —
  /// used for the admin dashboard tile that used to show a fabricated
  /// "documents to verify" number.
  static Future<int> countWithSubmittedDocuments() async {
    final snap = await _collection.get();
    return snap.docs.where((d) => hasSubmittedDocuments(d.data())).length;
  }

  /// Real per-document verification decision, keyed by a stable doc key
  /// ('nic', 'policeClearance', 'cert0'/'cert1'/…, 'other0'/'other1'/…,
  /// matching index position in the corresponding URL array — a document
  /// removed and re-added could shift these, a known limitation of keying
  /// by array index rather than a persisted per-file id). Written by the
  /// admin verification-queue screen, read by the caregiver's own
  /// verification-status screen. Uses dot-path addressing so this only
  /// touches the one key inside `documentReviews`, never clobbering
  /// sibling decisions.
  static Future<void> setDocumentReviewStatus({
    required String uid,
    required String docKey,
    required String status, // 'approved' | 'rejected'
    String? note,
  }) {
    return _collection.doc(uid).set({
      'documentReviews.$docKey': {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
        'decidedAt': FieldValue.serverTimestamp(),
        'decidedBy': 'CareLink verification team',
      },
    }, SetOptions(merge: true));
  }

  /// Real replacement of one submitted document's file, used when a
  /// caregiver re-uploads after a rejection. Clears that document's review
  /// decision (a replaced file is unreviewed again) rather than leaving a
  /// stale approved/rejected verdict attached to a file that no longer
  /// exists at that URL.
  static Future<void> replaceDocumentUrl({
    required String uid,
    required String docKey,
    required String newUrl,
  }) async {
    if (docKey == 'policeClearance') {
      await _collection.doc(uid).update({'policeClearanceUrl': newUrl});
    } else if (docKey.startsWith('cert')) {
      final index = int.tryParse(docKey.substring(4));
      final snap = await _collection.doc(uid).get();
      final urls = (snap.data()?['certificateUrls'] as List?)?.cast<String>().toList() ?? [];
      if (index != null && index >= 0 && index < urls.length) {
        urls[index] = newUrl;
        await _collection.doc(uid).update({'certificateUrls': urls});
      }
    } else if (docKey.startsWith('other')) {
      final index = int.tryParse(docKey.substring(5));
      final snap = await _collection.doc(uid).get();
      final urls = (snap.data()?['otherDocumentUrls'] as List?)?.cast<String>().toList() ?? [];
      if (index != null && index >= 0 && index < urls.length) {
        urls[index] = newUrl;
        await _collection.doc(uid).update({'otherDocumentUrls': urls});
      }
    }
    await _collection.doc(uid).set({
      'documentReviews.$docKey': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}
