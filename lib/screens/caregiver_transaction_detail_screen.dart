import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/patient_service.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Transaction (Shift) Detail Screen
//  Figma node: 786-877 — note: labeled "tax summary" in the request, but
//  the actual design is a per-transaction shift receipt (booking id,
//  patient, shift times, earnings breakdown, payout batch), not a tax
//  document. Reached by tapping "Booking BK-xxxx" on a payment entry in
//  the Earnings transactions screen. Every field is read defensively from
//  the real payment document; a field with no real source (a fake payout
//  reference number, precise check-in/out timestamps that aren't actually
//  captured on payments) is either omitted or honestly relabeled rather
//  than fabricated — see the field-by-field notes below.
// ─────────────────────────────────────────────────────────────
class CaregiverTransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> payment;
  const CaregiverTransactionDetailScreen({super.key, required this.payment});

  @override
  State<CaregiverTransactionDetailScreen> createState() => _CaregiverTransactionDetailScreenState();
}

class _CaregiverTransactionDetailScreenState extends State<CaregiverTransactionDetailScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleDark = Color(0xFF06402B);
  static const Color patientCardBg = Color(0xFFA8A48F);
  static const Color statusReleasedBg = Color(0xFFB8E0C4);
  static const Color statusReleasedText = Color(0xFF1B5E2C);
  static const Color statusProcessingBg = Color(0xFFDCD3C2);
  static const Color statusProcessingText = Color(0xFF5A4B37);
  static const Color sectionLabel = Color(0xFF544730);
  static const Color infoCardBg = Color(0xFFD8D3C5);
  static const Color infoLabel = Color(0xFF544730);
  static const Color infoValue = Color(0xFF2E2A1F);
  static const Color darkCardBg = Color(0xFF1F3554);
  static const Color darkCardText = Colors.white;
  static const Color negativeColor = Color(0xFFFCA5A5);
  static const Color positiveColor = Color(0xFF4ADE80);
  static const Color payoutCardBg = Color(0xFFD8D3C5);
  static const Color reportBorder = Color(0xFFB01E1E);

  String? _patientName;

  @override
  void initState() {
    super.initState();
    final uid = widget.payment['patientUid'] as String?;
    if (uid != null && uid.isNotEmpty) {
      PatientService.getPatientName(uid).then((name) {
        if (mounted) setState(() => _patientName = name);
      });
    }
  }

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

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final bookingId = p['bookingId'] as String?;
    final status = (p['status'] as String?) ?? 'pending';
    final isReleased = status == 'completed';
    final careType = p['careType'] as String?;
    final city = p['city'] as String?;
    final createdAt = p['createdAt'];
    final createdAtDate = createdAt is Timestamp ? createdAt.toDate() : null;
    final startTime = p['startTime'] as String?;
    final endTime = p['endTime'] as String?;
    final hoursBilled = p['hoursBilled'] as num?;
    final hourlyRate = p['hourlyRate'] as num?;
    final platformFeePercent = p['platformFeePercent'] as num?;
    final platformFeeAmount = p['platformFeeAmount'] as num?;
    final transportAllowance = p['transportAllowance'] as num?;
    final amount = (p['amount'] as num?) ?? 0;
    final net = amount - (platformFeeAmount ?? 0) + (transportAllowance ?? 0);
    final cardBrand = p['cardBrand'] as String?;
    final cardLast4 = p['cardLast4'] as String?;

    final patientName = _patientName ?? (p['patientUid'] != null ? '…' : 'Patient');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleDark, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      bookingId ?? 'Transaction',
                      style: const TextStyle(fontFamily: 'Open Sans', color: titleDark, fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isReleased ? statusReleasedBg : statusProcessingBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      isReleased ? 'RELEASED' : 'PROCESSING',
                      style: TextStyle(fontFamily: 'Open Sans', color: isReleased ? statusReleasedText : statusProcessingText, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: patientCardBg, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: titleDark, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(_initialsFor(patientName), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patientName, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                                if (careType != null || city != null)
                                  Text(
                                    [if (careType != null) careType, if (city != null) city].join(' · '),
                                    style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/caregiver-bookings'),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Booking', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFFC56322), fontSize: 11, fontWeight: FontWeight.w700)),
                                SizedBox(width: 3),
                                Icon(Icons.open_in_new_rounded, color: Color(0xFFC56322), size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (createdAtDate != null || hoursBilled != null || hourlyRate != null) ...[
                      const SizedBox(height: 18),
                      const Text('SHIFT', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        if (createdAtDate != null) ('Date', _formatDate(createdAtDate)),
                        // Payments don't capture actual check-in/out timestamps
                        // today — only the scheduled shift window — so this is
                        // labeled honestly rather than implying real attendance
                        // tracking.
                        if (startTime != null && endTime != null) ('Scheduled', '$startTime – $endTime'),
                        if (hoursBilled != null) ('Hours billed', '${hoursBilled.toStringAsFixed(hoursBilled % 1 == 0 ? 0 : 1)} hrs'),
                        if (hourlyRate != null) ('Hourly rate', _formatLkr(hourlyRate)),
                      ]),
                    ],

                    if (hoursBilled != null || platformFeeAmount != null || transportAllowance != null) ...[
                      const SizedBox(height: 18),
                      const Text('BREAKDOWN', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      _buildBreakdownCard([
                        if (hoursBilled != null && hourlyRate != null)
                          ('${hoursBilled.toStringAsFixed(hoursBilled % 1 == 0 ? 0 : 1)} hrs × ${_formatLkr(hourlyRate)}', _formatLkr(hoursBilled * hourlyRate), null),
                        if (platformFeeAmount != null)
                          (
                            'Platform commission${platformFeePercent != null ? ' (${platformFeePercent.toStringAsFixed(1)}%)' : ''}',
                            '− ${_formatLkr(platformFeeAmount)}',
                            negativeColor,
                          ),
                        if (transportAllowance != null && transportAllowance > 0) ('Transport allowance', '+ ${_formatLkr(transportAllowance)}', positiveColor),
                      ], netLabel: 'Net earnings', netValue: _formatLkr(net)),
                    ],

                    const SizedBox(height: 18),
                    const Text('PAYOUT', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: payoutCardBg, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isReleased ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded, color: isReleased ? statusReleasedText : statusProcessingText, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isReleased && createdAtDate != null ? 'Included in Week ${_isoWeekNumber(createdAtDate)} payout' : 'Not yet included in a payout',
                                      style: const TextStyle(fontFamily: 'Open Sans', color: infoValue, fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                    if (createdAtDate != null)
                                      Text(_formatDate(createdAtDate), style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 11, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isReleased && (cardBrand != null || cardLast4 != null)) ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0x22000000)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.account_balance_rounded, color: infoValue, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Transferred to ${cardBrand ?? 'account'}${cardLast4 != null ? ' •• $cardLast4' : ''}',
                                    style: const TextStyle(fontFamily: 'Open Sans', color: infoValue, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: titleDark,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Receipt downloads aren\'t available yet.'), duration: Duration(seconds: 2)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Center(child: Text('Download receipt', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reporting an issue isn\'t available yet — contact support.'), duration: Duration(seconds: 2)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: reportBorder),
                              padding: const EdgeInsets.symmetric(vertical: 12.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Report an issue', style: TextStyle(fontFamily: 'Open Sans', color: reportBorder, fontSize: 12, fontWeight: FontWeight.w700)),
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

  Widget _buildInfoCard(List<(String, String)> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: infoCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: Color(0x22000000))) : null),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].$1, style: const TextStyle(fontFamily: 'Open Sans', color: infoLabel, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(rows[i].$2, style: const TextStyle(fontFamily: 'Open Sans', color: infoValue, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(List<(String, String, Color?)> rows, {required String netLabel, required String netValue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: darkCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x22FFFFFF)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].$1, style: const TextStyle(fontFamily: 'Open Sans', color: darkCardText, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(rows[i].$2, style: TextStyle(fontFamily: 'Open Sans', color: rows[i].$3 ?? darkCardText, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(netLabel, style: const TextStyle(fontFamily: 'Open Sans', color: positiveColor, fontSize: 13, fontWeight: FontWeight.w800)),
                Text(netValue, style: const TextStyle(fontFamily: 'Open Sans', color: positiveColor, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
