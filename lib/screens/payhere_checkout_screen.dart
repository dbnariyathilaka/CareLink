import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  PayHere Checkout Screen (Sandbox)
//  There's no real PayHere merchant integration in this app — this is a
//  clearly-labelled sandbox checkout so the booking → pay → confirmed flow
//  can be exercised end to end without moving real money. "Paying" here
//  writes a real `payments` document (PaymentService.recordCompletedPayment)
//  and stamps the real booking with paymentStatus: 'paid'
//  (BookingService.markBookingPaid), so everything downstream — the patient
//  Payments screen, caregiver Earnings, the "Payment completed" notification
//  card — lights up exactly as it would for a real gateway.
// ─────────────────────────────────────────────────────────────
class PayhereCheckoutScreen extends StatefulWidget {
  const PayhereCheckoutScreen({super.key});

  @override
  State<PayhereCheckoutScreen> createState() => _PayhereCheckoutScreenState();
}

class _PayhereCheckoutScreenState extends State<PayhereCheckoutScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color panelBg = Color(0xFF2C251D);
  static const Color amber = Color(0xFFF5B301);
  static const Color mutedText = Color(0xFFB5ADA2);
  static const Color fieldBg = Color(0xFFEFE7D8);
  static const Color fieldBorder = Color.fromRGBO(0, 0, 0, 0.18);

  bool _loadedArgs = false;
  String? _bookingId;
  String? _caregiverId;
  String _caregiverName = 'Your caregiver';
  String? _careType;
  double _amount = 5000;

  bool _processing = false;
  bool _success = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _bookingId = args['bookingId'] as String?;
      _caregiverId = args['caregiverId'] as String?;
      _caregiverName = (args['caregiverName'] as String?)?.trim().isNotEmpty == true
          ? args['caregiverName'] as String
          : 'Your caregiver';
      _careType = args['careType'] as String?;
      final amount = args['amount'];
      if (amount is num && amount > 0) _amount = amount.toDouble();
    }
  }

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
  }

  String _formatLkr(num amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return 'LKR $buffer';
  }

  Future<void> _pay() async {
    if (_bookingId == null || _processing) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _processing = true);
    try {
      // Simulated gateway round-trip — long enough to feel real, short
      // enough not to annoy anyone testing the flow.
      await Future.delayed(const Duration(milliseconds: 1400));
      await PaymentService.recordCompletedPayment(
        bookingId: _bookingId!,
        patientUid: uid,
        caregiverId: _caregiverId ?? '',
        caregiverName: _caregiverName,
        careType: _careType ?? 'Care visit',
        amount: _amount,
      );
      await BookingService.markBookingPaid(_bookingId!);
      if (!mounted) return;
      setState(() {
        _processing = false;
        _success = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: _success ? _buildSuccess(context) : _buildCheckout(context),
      ),
    );
  }

  // ── Checkout form ──────────────────────────────────────────
  Widget _buildCheckout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 22, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Checkout',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sandbox banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(245, 179, 1, 0.15),
                    border: Border.all(color: amber),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_outlined, color: Color(0xFF8A6A00), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sandbox mode — this simulates PayHere checkout. No real money moves.',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: Color(0xFF6B5300),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── PayHere-style dark amount panel ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PayHere',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'SANDBOX',
                              style: TextStyle(
                                color: amber,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Amount payable',
                        style: TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatLkr(_amount),
                        style: const TextStyle(
                          color: amber,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _summaryRow('Caregiver', _caregiverName),
                      if (_careType != null && _careType!.isNotEmpty)
                        _summaryRow('Care type', _careType!),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Card details',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _fakeField('Card number', '4242 4242 4242 4242', Icons.credit_card_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _fakeField('Expiry', '12/29', Icons.event_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _fakeField('CVV', '123', Icons.lock_outline_rounded)),
                  ],
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'Pre-filled with PayHere\'s standard sandbox test card — this screen never asks for or stores a real card.',
                    style: TextStyle(color: Color(0xFF6B6355), fontSize: 10.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: _processing ? darkGreen.withValues(alpha: 0.6) : darkGreen,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _bookingId == null || _processing ? null : _pay,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _processing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                )
                              : Text(
                                  'Pay ${_formatLkr(_amount)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_bookingId == null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'This booking could not be identified — go back and try again.',
                    style: TextStyle(color: Colors.red, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: mutedText, fontSize: 12, fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fakeField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: fieldBg,
        border: Border.all(color: fieldBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: darkGreen, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF6B6355), fontSize: 9.5, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Success state ───────────────────────────────────────────
  Widget _buildSuccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: Color(0xFFDCF5E4), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Color(0xFF1B5E2C), size: 46),
          ),
          const SizedBox(height: 22),
          const Text(
            'Payment successful',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment of ${_formatLkr(_amount)} to $_caregiverName is confirmed. Your booking is now fully set.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromRGBO(0, 0, 0, 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: darkGreen,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst || r.settings.name == '/my-bookings'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Done',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/my-bookings'),
            child: const Text(
              'View my bookings',
              style: TextStyle(color: darkGreen, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
