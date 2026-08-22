import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  PaymentService
//  Wraps PayHere mobile SDK — sandbox mode for testing.
//
//  IMPORTANT: Replace the placeholder MERCHANT_ID below with
//  your PayHere sandbox merchant ID.
//  Get it at: https://www.payhere.lk → Settings → Domains &
//  Credentials → Add Domain/App → App.
// ─────────────────────────────────────────────────────────────

/// Result of a payment attempt.
enum PaymentResult { success, failed, dismissed }

class PaymentService {
  // ── Sandbox credentials ──────────────────────────────────────
  // TODO: Replace with your actual PayHere sandbox Merchant ID.
  static const String _merchantId = 'YOUR_MERCHANT_ID';

  // ────────────────────────────────────────────────────────────
  /// Initiates a PayHere payment for a given booking.
  ///
  /// Returns a [PaymentResult] enum value after the SDK closes.
  static Future<PaymentResult> initiatePayment({
    required String bookingId,
    required double amount,
    required String caregiverName,
    required String patientUid,
    required String patientFirstName,
    required String patientLastName,
    required String patientEmail,
    String patientPhone = '0771234567',
  }) async {
    final orderId =
        'CL-${bookingId.substring(0, bookingId.length.clamp(0, 8))}-'
        '${DateTime.now().millisecondsSinceEpoch}';

    final paymentObject = {
      // Set to false in production.
      'sandbox': true,
      'merchant_id': _merchantId,
      // notify_url is used for server-side verification.
      // Sandbox testing relies on the SDK success callback.
      'notify_url': 'https://sandbox.payhere.lk/pay/notify',
      'order_id': orderId,
      'items': 'CareLink – Caregiver booking ($caregiverName)',
      'amount': amount.toStringAsFixed(2),
      'currency': 'LKR',
      'first_name': patientFirstName,
      'last_name': patientLastName,
      'email': patientEmail,
      'phone': patientPhone,
      'address': 'N/A',
      'city': 'Colombo',
      'country': 'Sri Lanka',
    };

    PaymentResult? result;

    PayHere.startPayment(
      paymentObject,
      (paymentId) async {
        await _recordPayment(
          paymentId: paymentId.toString(),
          orderId: orderId,
          bookingId: bookingId,
          patientUid: patientUid,
          amount: amount,
        );
        result = PaymentResult.success;
      },
      (error) {
        result = PaymentResult.failed;
      },
      () {
        result = PaymentResult.dismissed;
      },
    );

    // Poll until the PayHere SDK completes (callback-based → Future bridge).
    while (result == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return result!;
  }

  // ────────────────────────────────────────────────────────────
  /// Writes a confirmed payment record to Firestore.
  static Future<void> _recordPayment({
    required String paymentId,
    required String orderId,
    required String bookingId,
    required String patientUid,
    required double amount,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .set({
        'paymentId': paymentId,
        'orderId': orderId,
        'bookingId': bookingId,
        'patientUid': patientUid,
        'amount': amount,
        'currency': 'LKR',
        'status': 'SUCCESS',
        'gateway': 'payhere',
        'sandbox': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal: payment succeeded; Firestore write failure
      // should not block the user flow.
    }
  }
}
