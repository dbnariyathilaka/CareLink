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

  /// Batch-fetches average rating + review count for many caregivers at
  /// once, chunked by Firestore's 30-item `whereIn` limit — so scoring a
  /// candidate list costs O(candidates / 30) queries instead of one query
  /// per caregiver. Caregivers with no reviews are included with count: 0.
  static Future<Map<String, ({double avg, int count})>> fetchRatingsFor(
    List<String> caregiverIds,
  ) async {
    final result = <String, ({double avg, int count})>{};
    if (caregiverIds.isEmpty) return result;

    final ids = caregiverIds.toSet().toList();
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap = await _collection.where('caregiverId', whereIn: chunk).get();

      final sums = <String, int>{};
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final id = data['caregiverId'] as String?;
        final rating = data['rating'] as int?;
        if (id == null || rating == null) continue;
        sums[id] = (sums[id] ?? 0) + rating;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      for (final id in chunk) {
        final count = counts[id] ?? 0;
        result[id] = (avg: count == 0 ? 0.0 : sums[id]! / count, count: count);
      }
    }
    return result;
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
