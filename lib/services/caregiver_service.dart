import 'package:cloud_firestore/cloud_firestore.dart';

import 'nic_verification_service.dart';

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

  /// Assigns a real hourly rate to a caregiver's profile — the admin
  /// action that applies PaymentService.calculateHourlyRate's result,
  /// since there's no backend/cron to write it automatically. Shown on
  /// every caregiver card/profile, and used to price a booking's payment.
  static Future<void> setHourlyRate(String uid, double rate) {
    return _collection.doc(uid).set(
      {'hourlyRate': rate, 'hourlyRateAssignedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Plain, unscored lookup of caregivers — no matching/ranking logic.
  /// Optionally narrows by care type or city if provided.
  ///
  /// Every patient-facing surface (matching wizard, dashboard, emergency,
  /// direct search, saved caregivers) goes through this one method, so the
  /// `nicVerified` filter lives here rather than being repeated in each
  /// screen — a caregiver whose NIC hasn't passed automatic verification
  /// (NicVerificationService) is simply invisible to patients, matching,
  /// ranking, and booking requests alike. Admin screens read caregivers via
  /// streamAllCaregivers() instead, which deliberately does NOT filter,
  /// since admins need to see everyone regardless of verification status.
  static Future<List<Map<String, dynamic>>> searchCaregivers({
    String? careType,
    String? city,
  }) async {
    Query<Map<String, dynamic>> query = _collection.where('nicVerified', isEqualTo: true);
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
  /// verification-status screen.
  ///
  /// Nests `docKey` as a real Map key rather than a `'documentReviews.$docKey'`
  /// dot-path string — `set(..., merge: true)` already deep-merges nested
  /// maps (verified: sibling decisions survive), and unlike the dot-path
  /// form this is actually compatible with Firestore security rules —
  /// `affectedKeys()` throws a genuine evaluation error against a dotted
  /// field-name key, which was silently denying every admin
  /// approve/reject/verify-count write as a permission-denied crash.
  static Future<void> setDocumentReviewStatus({
    required String uid,
    required String docKey,
    required String status, // 'approved' | 'rejected'
    String? note,
  }) {
    return _collection.doc(uid).set({
      'documentReviews': {
        docKey: {
          'status': status,
          if (note != null && note.isNotEmpty) 'note': note,
          'decidedAt': FieldValue.serverTimestamp(),
          'decidedBy': 'CareLink verification team',
        },
      },
    }, SetOptions(merge: true));
  }

  /// Verifying the references document isn't a plain approve — the admin
  /// reads the attached letter and records how many references it actually
  /// lists. `referenceCount` (top-level) is what the onboarding-matching
  /// algorithm scores; the same number is echoed into the review record so
  /// the verification queue can display it without a second lookup. An
  /// unverified (or rejected) reference document has no count at all — the
  /// caller must NOT fall back to 0, since "unverified" and "verified with
  /// zero references" are different things.
  static Future<void> setReferenceCount(String uid, int count) {
    return _collection.doc(uid).set({
      'referenceCount': count,
      'documentReviews': {
        'reference': {
          'status': 'approved',
          'count': count,
          'decidedAt': FieldValue.serverTimestamp(),
          'decidedBy': 'CareLink verification team',
        },
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
      'documentReviews': {docKey: FieldValue.delete()},
    }, SetOptions(merge: true));
  }

  /// One-time backfill for caregivers who registered before automatic NIC
  /// verification existed. They have no `age` field on file, so unlike the
  /// real onboarding/edit-profile flow this can only honestly cross-check
  /// NIC format + gender (both already real, caregiver-provided fields) —
  /// see the `age` parameter on NicVerificationService.check. Only touches
  /// docs that have never been through a real check (no `nicVerified` field
  /// yet at all), so it's safe to run more than once and will never
  /// overwrite a decision the real per-caregiver path already made.
  static Future<({int checked, int verified})> backfillNicVerification() async {
    final snap = await _collection.get();
    var checked = 0;
    var verified = 0;
    var batch = _firestore.batch();
    var batchSize = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data.containsKey('nicVerified')) continue;
      final nic = (data['nic'] as String?)?.trim() ?? '';
      if (nic.isEmpty) continue;

      final gender = (data['gender'] as String?)?.trim() ?? '';
      final result = NicVerificationService.check(nic: nic, gender: gender);
      checked++;
      if (result.isValid) verified++;

      batch.set(doc.reference, {
        'nicVerified': result.isValid,
        'nicVerificationReason': result.reason,
        'nicVerifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batchSize++;

      // Firestore caps a single batch at 500 writes.
      if (batchSize == 400) {
        await batch.commit();
        batch = _firestore.batch();
        batchSize = 0;
      }
    }
    if (batchSize > 0) await batch.commit();

    return (checked: checked, verified: verified);
  }
}
