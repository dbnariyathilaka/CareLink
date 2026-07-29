import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around the `reviews` Firestore collection — one document per
/// patient review of a caregiver.
class ReviewService {
  ReviewService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('reviews');

  static Future<void> submitReview({
    required String caregiverId,
    required String patientUid,
    required int rating,
    required List<String> tags,
    required String text,
    List<String> mediaUrls = const [],
    String? bookingId,
  }) {
    return _collection.add({
      'caregiverId': caregiverId,
      'patientUid': patientUid,
      'rating': rating,
      'tags': tags,
      'text': text,
      'mediaUrls': mediaUrls,
      if (bookingId != null) 'bookingId': bookingId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> streamReviewsForCaregiver(
    String caregiverId,
  ) {
    return _collection
        .where('caregiverId', isEqualTo: caregiverId)
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
