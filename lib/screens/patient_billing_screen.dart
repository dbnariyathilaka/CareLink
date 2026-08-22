import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  PatientBillingScreen
//  Displays an invoice for a caregiver booking and triggers
//  PayHere payment via PaymentService.
//
//  Route: /billing
//  Expected arguments (all optional – falls back to demo data):
//    {
//      'bookingId':          String,
//      'amount':             double,
//      'caregiverName':      String,
//      'serviceDescription': String,
//      'serviceDate':        String,
//      'durationHours':      int,
//    }
// ─────────────────────────────────────────────────────────────

class PatientBillingScreen extends StatefulWidget {
  const PatientBillingScreen({super.key});

  @override
  State<PatientBillingScreen> createState() => _PatientBillingScreenState();
}

class _PatientBillingScreenState extends State<PatientBillingScreen> {
  // ── Design tokens ────────────────────────────────────────────
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color cardBg = Color(0xFFE9D3B3);
  static const Color accentGold = Color(0xFFFFC940);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFF9E0606);

  // ── State ────────────────────────────────────────────────────
  bool _paying = false;

  // ── Arguments from route (with defaults for demo) ────────────
  late String _bookingId;
  late double _amount;
  late String _caregiverName;
  late String _serviceDescription;
  late String _serviceDate;
  late int _durationHours;

  // Derived totals
  double get _subtotal => _amount;
  double get _tax => 0.0; // no taxes for now
  double get _total => _subtotal + _tax;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setStatusBarStyle(Brightness.light);
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = (args is Map<String, dynamic>) ? args : <String, dynamic>{};

    _bookingId = map['bookingId'] as String? ?? 'DEMO-BOOKING-001';
    _amount = (map['amount'] as num?)?.toDouble() ?? 4500.0;
    _caregiverName = map['caregiverName'] as String? ?? 'Demo Caregiver';
    _serviceDescription =
        map['serviceDescription'] as String? ?? 'Elder Care – Home Visit';
    _serviceDate = map['serviceDate'] as String? ?? 'Aug 25, 2026';
    _durationHours = (map['durationHours'] as int?) ?? 3;
  }

  // ────────────────────────────────────────────────────────────
  Future<void> _handlePayNow() async {
    final user = AuthService.currentUser;
    if (user == null) {
      _showSnack('Please log in to continue.', isError: true);
      return;
    }

    setState(() => _paying = true);

    // Split display-name into first/last for PayHere.
    final profile = await AuthService.getUserProfile(user.uid);
    final fullName = (profile?['name'] as String? ?? 'CareLink User').trim();
    final nameParts = fullName.split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '-';
    final email = user.email ?? 'noemail@carelink.lk';

    final result = await PaymentService.initiatePayment(
      bookingId: _bookingId,
      amount: _total,
      caregiverName: _caregiverName,
      patientUid: user.uid,
      patientFirstName: firstName,
      patientLastName: lastName,
      patientEmail: email,
    );

    if (!mounted) return;
    setState(() => _paying = false);

    switch (result) {
      case PaymentResult.success:
        _showSuccessDialog();
      case PaymentResult.failed:
        _showSnack('Payment failed. Please try again.', isError: true);
      case PaymentResult.dismissed:
        _showSnack('Payment cancelled.');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Quattrocento Sans'),
        ),
        backgroundColor: isError ? errorRed : darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: successGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 42),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Quattrocento Sans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your payment of LKR ${_total.toStringAsFixed(2)} '
              'for $_caregiverName has been confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Quattrocento Sans',
                fontSize: 14,
                color: Color(0xFF444444),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back from billing screen
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          _buildHeader(topInset),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvoiceCard(),
                  const SizedBox(height: 20),
                  _buildPaymentMethodsCard(),
                  const SizedBox(height: 20),
                  _buildSandboxNote(),
                  const SizedBox(height: 28),
                  _buildPayButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader(double topInset) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Billing',
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Invoice #${_bookingId.substring(0, _bookingId.length.clamp(0, 8)).toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentGold, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: accentGold, size: 14),
                SizedBox(width: 4),
                Text(
                  'Secure',
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: accentGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Invoice card ─────────────────────────────────────────────
  Widget _buildInvoiceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card top strip ───────────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: darkGreen,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _caregiverName,
                        style: const TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _serviceDescription,
                        style: TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Line items ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _invoiceRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Service date',
                  value: _serviceDate,
                ),
                const SizedBox(height: 14),
                _invoiceRow(
                  icon: Icons.schedule_rounded,
                  label: 'Duration',
                  value: '$_durationHours hour${_durationHours != 1 ? "s" : ""}',
                ),
                const SizedBox(height: 14),
                _invoiceRow(
                  icon: Icons.volunteer_activism_rounded,
                  label: 'Service type',
                  value: _serviceDescription,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFE0D5C8)),
                ),
                // Subtotal
                _amountRow('Subtotal', _subtotal),
                const SizedBox(height: 8),
                // Tax
                _amountRow('Tax', _tax, note: '(0%)'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                      color: darkGreen, thickness: 1.5),
                ),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        color: darkGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'LKR ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        color: darkGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: darkGreen, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Quattrocento Sans',
            color: Color(0xFF666666),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Quattrocento Sans',
            color: darkGreen,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _amountRow(String label, double amount, {String? note}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: Color(0xFF555555),
                fontSize: 14,
              ),
            ),
            if (note != null) ...[
              const SizedBox(width: 4),
              Text(
                note,
                style: const TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: Color(0xFF888888),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        Text(
          'LKR ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'Quattrocento Sans',
            color: Color(0xFF555555),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ── Accepted cards card ──────────────────────────────────────
  Widget _buildPaymentMethodsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.credit_card_rounded, color: darkGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Accepted payment methods',
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: darkGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _cardBadge('Visa', const Color(0xFF1A1F71), Colors.white),
              _cardBadge('Mastercard', const Color(0xFFEB001B), Colors.white),
              _cardBadge('Amex', const Color(0xFF007BC1), Colors.white),
              _cardBadge('eZ Cash', darkGreen, Colors.white),
              _cardBadge('mCash', const Color(0xFF4C2B8C), Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.security_rounded,
                  color: Color(0xFF555555), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Payments are secured and processed by PayHere. '
                  'CareLink does not store your card details.',
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: Colors.black.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Quattrocento Sans',
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Sandbox note ─────────────────────────────────────────────
  Widget _buildSandboxNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: accentGold.withValues(alpha: 0.5), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_rounded, color: Color(0xFFB07000), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'SANDBOX MODE — No real money is charged.\n'
              'Test card: 4916217501611292  •  Any expiry  •  Any CVV',
              style: TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: Color(0xFF7A5200),
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pay Now button ───────────────────────────────────────────
  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _paying ? null : _handlePayNow,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _paying
                ? darkGreen.withValues(alpha: 0.6)
                : darkGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _paying
                ? []
                : [
                    BoxShadow(
                      color: darkGreen.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_paying) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Processing…',
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else ...[
                const Icon(Icons.payment_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Pay LKR ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
