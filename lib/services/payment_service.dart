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

  /// Records a completed payment for a booking. Written by the sandbox
  /// PayHere-style checkout (`PayhereCheckoutScreen`) — there's no real
  /// payment gateway wired up, so this simulates a successful charge and
  /// persists it using the same schema documented above, so the existing
  /// read-only Payments/Earnings screens display it exactly like a real one.
  static Future<String> recordCompletedPayment({
    required String bookingId,
    required String patientUid,
    required String caregiverId,
    required String caregiverName,
    required String careType,
    required double amount,
    String gateway = 'PayHere (sandbox)',
    String cardLast4 = '4242',
  }) async {
    final ref = await _collection.add({
      'bookingId': bookingId,
      'patientUid': patientUid,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'careType': careType,
      'amount': amount,
      'status': 'completed',
      'gateway': gateway,
      'cardLast4': cardLast4,
      'transactionId': 'SANDBOX-${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// The payment recorded for one booking (there's at most one — a booking
  /// is only ever paid once through the sandbox checkout) — used by the
  /// "Receipt" action on the patient notifications screen to jump straight
  /// to that payment's detail view instead of the full payments list.
  ///
  /// Filtering by [patientUid] here isn't just extra safety — it's
  /// required. The `payments` read rule checks `resource.data.patientUid`,
  /// and Firestore can only validate a list query against that rule if the
  /// query itself is constrained on that same field; a bookingId-only
  /// query gave Firestore no way to prove every possible match would pass,
  /// so it rejected the whole request with permission-denied even though
  /// the one real result would have been the caller's own payment.
  static Future<Map<String, dynamic>?> getPaymentForBooking(
    String bookingId,
    String patientUid,
  ) async {
    final snap = await _collection
        .where('bookingId', isEqualTo: bookingId)
        .where('patientUid', isEqualTo: patientUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

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

  /// Real (currently near-always-zero, since billing isn't live yet) total
  /// of completed payments for one caregiver — same computation the
  /// caregiver's own Earnings screen uses, just summed here for one admin
  /// list row instead of streamed for a detail screen.
  static Future<double> sumCompletedEarningsForCaregiver(String caregiverId) async {
    final snap = await _collection
        .where('caregiverId', isEqualTo: caregiverId)
        .where('status', isEqualTo: 'completed')
        .get();
    double total = 0;
    for (final doc in snap.docs) {
      final amount = doc.data()['amount'];
      if (amount is num) total += amount.toDouble();
    }
    return total;
  }

  /// Real count of a patient's disputed payments — payments carry
  /// `disputeStatus` once [submitDispute] is called. Almost always 0 today
  /// since billing isn't live, but a real Firestore count, never a
  /// fabricated number.
  static Future<int> countDisputesForPatient(String patientUid) async {
    final snap = await _collection
        .where('patientUid', isEqualTo: patientUid)
        .where('disputeStatus', isNotEqualTo: null)
        .count()
        .get();
    return snap.count ?? 0;
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
