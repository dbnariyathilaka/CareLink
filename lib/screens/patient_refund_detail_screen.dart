import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/payment_service.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Refund & Dispute Detail Screen
//  Figma node: 786-1418
//  Renders one real `payments` document's refund-related fields — that
//  collection doesn't exist anywhere in this app yet (billing hasn't been
//  built), so every field is read defensively and the refund-progress
//  timeline only marks a step "done" when its real timestamp is actually
//  present. "Submit dispute" is a genuine write (PaymentService.submitDispute)
//  — there's no support-team resolution workflow behind it yet, but the
//  submission itself is real, not a fake success message.
// ─────────────────────────────────────────────────────────────
class PatientRefundDetailScreen extends StatefulWidget {
  final Map<String, dynamic> payment;

  const PatientRefundDetailScreen({super.key, required this.payment});

  @override
  State<PatientRefundDetailScreen> createState() => _PatientRefundDetailScreenState();
}

class _PatientRefundDetailScreenState extends State<PatientRefundDetailScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color cardBg = Color(0xFFBAADA1);
  static const Color sectionLabel = Color(0xFF544730);
  static const Color stepDoneIcon = Color(0xFF1B5E2C);
  static const Color stepProcessingIcon = Color(0xFFC56322);
  static const Color stepPendingIcon = Color(0xFF9A8F80);
  static const Color stepTitleColor = Color(0xFF2E2A1F);
  static const Color stepSubColor = Color(0xFF6E6F72);
  static const Color amberValue = Color(0xFFC56322);
  static const Color reasonSelectedBg = Color(0xFF6E4A2E);
  static const Color reasonBg = Color(0xFFA8A48F);
  static const Color noteFieldBg = Color(0xFFA8A48F);
  static const Color submitBg = Color(0xFF06402B);
  static const Color downloadBorder = Color(0xFF06402B);

  static const List<String> _disputeReasons = [
    'Charged more than quoted',
    'Care was not provided',
    'Duplicate charge',
    'Other',
  ];

  String? _selectedReason;
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;
  late bool _disputeSubmitted;

  @override
  void initState() {
    super.initState();
    _disputeSubmitted = widget.payment['disputeStatus'] != null;
    _selectedReason = widget.payment['disputeReason'] as String?;
    _noteController.text = (widget.payment['disputeNote'] as String?) ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
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

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $hour12:$minute $period';
  }

  Future<void> _submitDispute() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a reason before submitting.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    final paymentId = widget.payment['id'] as String?;
    if (paymentId == null) return;

    setState(() => _submitting = true);
    try {
      await PaymentService.submitDispute(
        paymentId: paymentId,
        reason: _selectedReason!,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _disputeSubmitted = true;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispute submitted — CareLink support will review it.'), duration: Duration(seconds: 3)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit dispute: $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final caregiverName = p['caregiverName'] as String? ?? 'Caregiver';
    final transactionId = p['transactionId'] as String?;
    final bookingId = p['bookingId'] as String?;
    final amount = (p['amount'] as num?) ?? 0;
    final cardLast4 = p['cardLast4'] as String?;
    final createdAt = p['createdAt'];
    final dateLabel = createdAt is Timestamp ? _formatDateTime(createdAt.toDate()).split(' · ').first : null;

    final refundRequestedAt = p['refundRequestedAt'];
    final refundReason = p['refundReason'] as String?;
    final refundApprovedAt = p['refundApprovedAt'];
    final refundApprovedNote = p['refundApprovedNote'] as String?;
    final refundCompletedAt = p['refundCompletedAt'];
    final refundExpectedByLabel = p['refundExpectedByLabel'] as String?;
    final refundCardBrand = (p['cardBrand'] as String?) ?? 'card';
    final refundAmount = (p['refundAmount'] as num?) ?? amount;
    final refundReference = p['refundReference'] as String?;

    final requestedAtDate = refundRequestedAt is Timestamp ? refundRequestedAt.toDate() : null;
    final approvedAtDate = refundApprovedAt is Timestamp ? refundApprovedAt.toDate() : null;
    final requestedDone = requestedAtDate != null;
    final approvedDone = approvedAtDate != null;
    final completedDone = refundCompletedAt is Timestamp;
    final processingActive = approvedDone && !completedDone;

    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Refund & dispute',
                    style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Payment summary row ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(_initialsFor(caregiverName), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(caregiverName, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                                Text(
                                  [
                                    if (transactionId != null) 'TXN-$transactionId',
                                    if (bookingId != null) bookingId,
                                    if (dateLabel != null) dateLabel,
                                  ].join(' · '),
                                  style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatLkr(amount), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                              if (cardLast4 != null)
                                Text('•• $cardLast4', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildSectionLabel('Refund progress'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          _buildProgressStep(
                            done: requestedDone,
                            active: false,
                            title: 'Requested',
                            subtitle: requestedAtDate != null
                                ? '${_formatDateTime(requestedAtDate)}${refundReason != null ? ' · $refundReason' : ''}'
                                : 'Not yet requested',
                          ),
                          _buildProgressStep(
                            done: approvedDone,
                            active: false,
                            title: 'Approved by CareLink support',
                            subtitle: approvedAtDate != null
                                ? '${_formatDateTime(approvedAtDate)}${refundApprovedNote != null ? ' · $refundApprovedNote' : ''}'
                                : 'Awaiting review',
                          ),
                          _buildProgressStep(
                            done: completedDone,
                            active: processingActive,
                            title: 'Processing to ${refundCardBrand[0].toUpperCase()}${refundCardBrand.substring(1)}${cardLast4 != null ? ' •• $cardLast4' : ''}',
                            subtitle: processingActive
                                ? (refundExpectedByLabel != null ? 'Expected by $refundExpectedByLabel' : 'In progress')
                                : (completedDone ? 'Sent to your card issuer' : 'Not started'),
                          ),
                          _buildProgressStep(
                            done: completedDone,
                            active: false,
                            title: 'Completed',
                            subtitle: 'Funds back in your account',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          _buildSummaryRow('Refund amount', _formatLkr(refundAmount), valueColor: amberValue),
                          _buildSummaryRow('Reference', refundReference ?? '—', isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_disputeSubmitted) ...[
                      _buildSectionLabel('Dispute status'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.flag_rounded, color: stepProcessingIcon, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dispute submitted: ${_selectedReason ?? ''}', style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  const Text('CareLink support will review this and follow up.', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _buildSectionLabel('Raise a dispute'),
                      const SizedBox(height: 8),
                      ..._disputeReasons.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildReasonOption(r),
                          )),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(color: noteFieldBg, borderRadius: BorderRadius.circular(12)),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 3,
                          style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: 'Tell us what happened — hours, dates and amounts help us resolve faster.',
                            hintStyle: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 12, fontWeight: FontWeight.w500),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: submitBg,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _submitting ? null : _submitDispute,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: _submitting
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Text('Submit dispute', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Receipt downloads aren\'t available yet.'), duration: Duration(seconds: 2)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: downloadBorder, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 13.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Download receipt', style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }

  Widget _buildProgressStep({
    required bool done,
    required bool active,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    final icon = done
        ? Icons.check_circle_rounded
        : active
            ? Icons.autorenew_rounded
            : Icons.radio_button_unchecked_rounded;
    final iconColor = done ? stepDoneIcon : (active ? stepProcessingIcon : stepPendingIcon);
    final titleColor = (done || active) ? stepTitleColor : stepPendingIcon;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Open Sans', color: titleColor, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontFamily: 'Open Sans', color: stepSubColor, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x22000000))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontFamily: 'Open Sans', color: valueColor ?? Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildReasonOption(String reason) {
    final selected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? reasonSelectedBg : reasonBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              reason,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: selected ? Colors.white : const Color(0xFF3A332A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? Colors.white : const Color(0xFF3A332A),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
