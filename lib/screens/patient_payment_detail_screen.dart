import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/remote_or_local_image.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Payment Detail Screen ("view booking payment")
//  Figma node: 786-1327
//  Renders one real `payments` document — reached from "View booking" on a
//  completed payment card in the Payments screen. That collection doesn't
//  exist anywhere in this app yet (no billing feature has been built), so
//  every field here is read defensively and a breakdown line is only shown
//  when its underlying field is actually present on the document — nothing
//  is fabricated to fill in a line Figma shows (platform fee/night rate/
//  taxes/promo credit are genuinely optional per booking, not guaranteed).
// ─────────────────────────────────────────────────────────────
class PatientPaymentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payment;

  const PatientPaymentDetailScreen({super.key, required this.payment});

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color heroBg = Color(0xFF2C251D);
  static const Color heroAmount = Color(0xFFF5B301);
  static const Color heroSubtext = Color(0xFFB5ADA2);
  static const Color caregiverCardBg = Color(0xFFA8A48F);
  static const Color sectionLabel = Color(0xFF544730);
  static const Color darkCardBg = Color(0xFF2C251D);
  static const Color darkCardText = Colors.white;
  static const Color darkCardValue = Color(0xFFF5B301);
  static const Color promoGreen = Color(0xFF4ADE80);
  static const Color statusCompletedBg = Color(0xFFB8E0C4);
  static const Color statusCompletedText = Color(0xFF1B5E2C);
  static const Color methodCardBg = Color(0xFFA8A48F);
  static const Color chargedGreen = Color(0xFF1B5E2C);
  static const Color reportBorder = Color(0xFFB01E1E);

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _formatLkr(num amount) {
    final rounded = amount.round();
    final negative = rounded < 0;
    final str = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '${negative ? '− ' : ''}LKR $buffer';
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour12:$minute $period';
  }

  String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final transactionId = payment['transactionId'] as String?;
    final status = (payment['status'] as String?) ?? 'completed';
    final amount = (payment['amount'] as num?) ?? 0;
    final createdAt = payment['createdAt'];
    final paidAtLabel = createdAt is Timestamp ? _formatDateTime(createdAt.toDate()) : null;

    final caregiverName = payment['caregiverName'] as String? ?? 'Caregiver';
    final careType = payment['careType'] as String?;
    final bookingId = payment['bookingId'] as String?;

    final startDate = payment['startDate'] as String?;
    final endDate = payment['endDate'] as String?;
    final hoursBilled = payment['hoursBilled'] as num?;
    final hourlyRate = payment['hourlyRate'] as num?;

    final subtotal = (hoursBilled != null && hourlyRate != null) ? hoursBilled * hourlyRate : null;
    final platformFeePercent = payment['platformFeePercent'] as num?;
    final platformFeeAmount = payment['platformFeeAmount'] as num?;
    final nightRatePercent = payment['nightRatePercent'] as num?;
    final nightRateAmount = payment['nightRateAmount'] as num?;
    final taxAmount = payment['taxAmount'] as num?;
    final promoCreditAmount = payment['promoCreditAmount'] as num?;

    final cardBrand = payment['cardBrand'] as String?;
    final cardLast4 = payment['cardLast4'] as String?;
    final authorizedByName = payment['authorizedByName'] as String?;
    final authorizedAt = payment['authorizedAt'];
    final authorizedAtLabel = authorizedAt is Timestamp ? _formatTime(authorizedAt.toDate()) : null;
    final photoUrl = (payment['caregiverPhotoUrl'] as String?)?.trim() ?? (payment['photoUrl'] as String?)?.trim();

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
                  Expanded(
                    child: Text(
                      transactionId != null ? 'TXN-$transactionId' : 'Payment',
                      style: const TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _buildStatusPill(status),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Total paid hero ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(color: heroBg, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Text('Total paid', style: TextStyle(fontFamily: 'Open Sans', color: heroSubtext, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(_formatLkr(amount), style: const TextStyle(fontFamily: 'Open Sans', color: heroAmount, fontSize: 26, fontWeight: FontWeight.w800)),
                          if (paidAtLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(paidAtLabel, style: const TextStyle(fontFamily: 'Open Sans', color: heroSubtext, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: caregiverCardBg, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle),
                            child: (photoUrl != null && photoUrl.isNotEmpty)
                                ? ClipOval(
                                    child: RemoteOrLocalImage(
                                      source: photoUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _initialsFor(caregiverName),
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(caregiverName, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                                if (careType != null)
                                  Text(careType, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          if (bookingId != null)
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/my-bookings'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(bookingId, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFFC56322), fontSize: 11, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.open_in_new_rounded, color: Color(0xFFC56322), size: 12),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (startDate != null || hoursBilled != null || hourlyRate != null) ...[
                      const SizedBox(height: 18),
                      _buildSectionLabel('Booking'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        if (startDate != null) ('Dates', endDate != null ? '$startDate – $endDate' : startDate, null),
                        if (hoursBilled != null) ('Hours', '${hoursBilled.toStringAsFixed(1)} hrs', null),
                        if (hourlyRate != null) ('Hourly rate', _formatLkr(hourlyRate), null),
                      ]),
                    ],

                    if (subtotal != null || platformFeeAmount != null || taxAmount != null) ...[
                      const SizedBox(height: 18),
                      _buildSectionLabel('Breakdown'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        if (subtotal != null && hoursBilled != null && hourlyRate != null)
                          ('${hoursBilled.toStringAsFixed(1)} hrs × ${_formatLkr(hourlyRate)}', _formatLkr(subtotal), null),
                        if (platformFeeAmount != null)
                          (
                            'Platform fee${platformFeePercent != null ? ' (${platformFeePercent.toStringAsFixed(1)}%)' : ''}',
                            _formatLkr(platformFeeAmount),
                            null,
                          ),
                        if (nightRateAmount != null)
                          (
                            'Night rate${nightRatePercent != null ? ' (+${nightRatePercent.toStringAsFixed(0)}%)' : ''}',
                            _formatLkr(nightRateAmount),
                            null,
                          ),
                        if (taxAmount != null) ('Taxes', _formatLkr(taxAmount), null),
                        if (promoCreditAmount != null && promoCreditAmount > 0)
                          ('Promo credit', _formatLkr(-promoCreditAmount), promoGreen),
                      ], totalLabel: 'Total', totalValue: _formatLkr(amount)),
                    ],

                    if (cardBrand != null || cardLast4 != null) ...[
                      const SizedBox(height: 18),
                      _buildSectionLabel('Payment method'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: methodCardBg, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card_rounded, color: darkGreen, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${cardBrand ?? 'Card'}${cardLast4 != null ? ' •• $cardLast4' : ''}',
                                    style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  if (authorizedByName != null || authorizedAtLabel != null)
                                    Text(
                                      [
                                        if (authorizedByName != null) authorizedByName,
                                        if (authorizedAtLabel != null) 'authorised $authorizedAtLabel',
                                      ].join(' · '),
                                      style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: statusCompletedBg, borderRadius: BorderRadius.circular(999)),
                              child: const Text('CHARGED', style: TextStyle(fontFamily: 'Open Sans', color: chargedGreen, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Receipt downloads aren\'t available yet.'), duration: Duration(seconds: 2)),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(color: caregiverCardBg, borderRadius: BorderRadius.circular(10)),
                              child: const Center(
                                child: Text('Download receipt', style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reporting an issue isn\'t available yet.'), duration: Duration(seconds: 2)),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: reportBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('Report issue', style: TextStyle(fontFamily: 'Open Sans', color: reportBorder, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final styles = {
      'completed': (const Color(0xFFB8E0C4), const Color(0xFF1B5E2C), 'COMPLETED'),
      'pending': (const Color(0xFFDCD3C2), const Color(0xFF5A4B37), 'PENDING'),
      'refunded': (const Color(0xFFE3C79A), const Color(0xFF6B4A16), 'REFUNDED'),
      'failed': (const Color(0xFFF2C6C6), const Color(0xFFB01E1E), 'FAILED'),
    };
    final style = styles[status] ?? (const Color(0xFFDCD3C2), const Color(0xFF5A4B37), status.toUpperCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: style.$1, borderRadius: BorderRadius.circular(999)),
      child: Text(style.$3, style: TextStyle(fontFamily: 'Open Sans', color: style.$2, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }

  Widget _buildInfoCard(
    List<(String, String, Color?)> rows, {
    String? totalLabel,
    String? totalValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: darkCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: (i < rows.length - 1 || totalLabel != null)
                    ? const Border(bottom: BorderSide(color: Color(0x22FFFFFF)))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].$1, style: const TextStyle(fontFamily: 'Open Sans', color: darkCardText, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(
                    rows[i].$2,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: rows[i].$3 ?? darkCardValue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          if (totalLabel != null && totalValue != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(totalLabel, style: const TextStyle(fontFamily: 'Open Sans', color: darkCardValue, fontSize: 13, fontWeight: FontWeight.w800)),
                  Text(totalValue, style: const TextStyle(fontFamily: 'Open Sans', color: darkCardValue, fontSize: 13, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
