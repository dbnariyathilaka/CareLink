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

  /// Number of reviews a patient has submitted — used by the patient's own
  /// profile stats row.
  static Future<int> countReviewsByPatient(String patientUid) async {
    final snap = await _collection
        .where('patientUid', isEqualTo: patientUid)
        .count()
        .get();
    return snap.count ?? 0;
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

  /// Every review across every caregiver — used by the admin review screen.
  /// There is no moderation-status field on these documents (nothing has
  /// ever flagged/hidden a review), so this is the raw, unfiltered list.
  static Stream<List<Map<String, dynamic>>> streamAllReviews() {
    return _collection.snapshots().map((snap) {
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

  /// Platform-wide average rating across every review — used by the admin
  /// dashboard's "Avg rating" tile, and as the Bayesian prior (C) below.
  static Future<({double avg, int count})> fetchPlatformAverage() async {
    final snap = await _collection.get();
    if (snap.docs.isEmpty) return (avg: 0.0, count: 0);
    var sum = 0;
    for (final doc in snap.docs) {
      sum += (doc.data()['rating'] as int?) ?? 0;
    }
    return (avg: sum / snap.docs.length, count: snap.docs.length);
  }

  /// Smoothing value (m) for the Bayesian-adjusted rating — the point at
  /// which a caregiver's own ratings begin to outweigh the platform
  /// average. Also the threshold for the introductory hourly-rate phase.
  static const int ratingSmoothing = 5;

  /// Bayesian-adjusted rating: weighs a caregiver's own average against how
  /// many reviews back it, so a single 5-star review doesn't outrank a 4.7
  /// average over 40 reviews. [platformAverage] is the real, live platform
  /// average (fetchPlatformAverage) — not a frozen constant, so this moves
  /// with actual review data. A brand-new caregiver (count 0) resolves
  /// exactly to the platform average — the formula cold-starts on its own,
  /// no special case needed.
  static double adjustedRating({
    required double average,
    required int count,
    required double platformAverage,
  }) {
    final v = count.toDouble();
    const m = ratingSmoothing;
    return (v / (v + m)) * average + (m / (v + m)) * platformAverage;
  }

  /// [fetchPlatformAverage] returns 0.0 when literally no review exists on
  /// the platform yet — unusable as a Bayesian prior (it would drag every
  /// new caregiver's adjusted rating to 0). This is the only place that
  /// bootstrap case is handled: the neutral midpoint of the 1–5 scale.
  static double platformAverageOrNeutral(({double avg, int count}) platform) {
    return platform.count == 0 ? 3.0 : platform.avg;
  }

  /// Stamps a real `adjustedRating` **and** `reviewCount` onto each
  /// caregiver map in place — MatchingService/OnboardingMatchingService are
  /// pure Dart with no Firestore access, so callers building a candidate
  /// list for either must do this first. `reviewCount` (added alongside the
  /// pre-existing `adjustedRating` stamp) is what lets those services tell
  /// "0 reviews" — the thesis's cold-start case, where rating is
  /// structurally absent and its weight redistributes — from "some reviews
  /// that happen to average close to the smoothed value."
  static Future<void> stampAdjustedRatings(
    List<Map<String, dynamic>> caregivers,
  ) async {
    final ids = caregivers
        .map((c) => c['uid'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return;
    final platform = platformAverageOrNeutral(await fetchPlatformAverage());
    final ratings = await fetchRatingsFor(ids);
    for (final c in caregivers) {
      final uid = c['uid'] as String?;
      if (uid == null) continue;
      final r = ratings[uid];
      c['adjustedRating'] = adjustedRating(
        average: r?.avg ?? platform,
        count: r?.count ?? 0,
        platformAverage: platform,
      );
      c['reviewCount'] = r?.count ?? 0;
    }
  }
}
