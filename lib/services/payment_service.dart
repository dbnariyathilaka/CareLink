import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around a `payments` Firestore collection — this collection
/// does not exist yet anywhere in this app (billing hasn't been built), so
/// every read here returns an empty list today. Built against the schema
/// proposed for the future billing feature (patientUid, caregiverId,
/// caregiverName, careType, bookingId, amount, refundAmount, status
/// [completed/pending/refunded/failed], cardLast4, transactionId, gateway,
/// createdAt, refundEtaLabel, failureReason, hoursBilled, hourlyRate,
/// platformFeePercent, platformFeeAmount, nightRatePercent, nightRateAmount)
/// so the patient Payments screen and caregiver Earnings screens activate
/// automatically — no code changes needed here — the moment a real billing
/// feature starts writing documents.
///
/// A document also carries `type` ('payment' | 'penalty' | 'bonus', default
/// 'payment' when absent) plus `adjustmentReason` for the latter two, used
/// by the caregiver's Earnings transactions screen to show real deductions/
/// credits (e.g. a late-cancellation penalty) alongside regular payments,
/// rather than a separate collection.
class PaymentService {
  PaymentService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('payments');

  static Stream<List<Map<String, dynamic>>> streamPaymentsForPatient(
    String patientUid,
  ) {
    return _collection
        .where('patientUid', isEqualTo: patientUid)
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

  /// Same as [streamPaymentsForPatient] but from the caregiver's side —
  /// used for real earnings figures instead of a guessed flat rate.
  static Stream<List<Map<String, dynamic>>> streamPaymentsForCaregiver(
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

  /// Real write — records a patient-raised dispute onto its payment
  /// document. There's no support-team resolution workflow behind this yet
  /// (no admin screen reads `disputeStatus` today), but the submission
  /// itself is genuinely persisted, not a fake success message.
  static Future<void> submitDispute({
    required String paymentId,
    required String reason,
    String? note,
  }) {
    return _collection.doc(paymentId).update({
      'disputeReason': reason,
      if (note != null && note.isNotEmpty) 'disputeNote': note,
      'disputeStatus': 'submitted',
      'disputeSubmittedAt': FieldValue.serverTimestamp(),
    });
  }
}
