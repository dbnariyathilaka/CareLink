import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/payment_service.dart';
import '../widgets/status_bar.dart';
import 'caregiver_transaction_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Earnings Transactions Screen
//  Figma node: 777-1093
//  Reads the real `payments` collection — empty until billing exists.
//  Adjustments (penalties/bonuses) use a `type` field ('payment' |
//  'penalty' | 'bonus', default 'payment' when absent) on the same
//  collection rather than a separate one, consistent with the rest of the
//  schema built up this session.
//
//  This screen deliberately differs from Figma in a few places, based on
//  feedback given earlier when this exact mock was reviewed:
//  - The summary bar shows real NET earnings alongside gross, not gross
//    alone (a caregiver take-home figure matters more than the top-line
//    charge).
//  - Every payment entry uses the same expand/collapse breakdown, not just
//    the first one arbitrarily shown expanded.
//  - Totals are tab-aware (recompute for whichever tab — Paid/Pending/
//    Adjustments — is active), not a single static figure.
//  - Penalty cards get a real "Question this?" action instead of no
//    dispute path at all.
// ─────────────────────────────────────────────────────────────

enum _Tab { paid, pending, adjustments }

class CaregiverEarningsTransactionsScreen extends StatefulWidget {
  const CaregiverEarningsTransactionsScreen({super.key});

  @override
  State<CaregiverEarningsTransactionsScreen> createState() => _CaregiverEarningsTransactionsScreenState();
}

class _CaregiverEarningsTransactionsScreenState extends State<CaregiverEarningsTransactionsScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF1F3554);
  static const Color tabActiveBg = Color(0xFF1F3554);
  static const Color tabInactiveBorder = Color(0xFF1F3554);
  static const Color summaryBg = Color(0xFF1F3554);
  static const Color summaryAmber = Color(0xFFF5B301);
  static const Color cardBg = Color(0xFFBAADA1);
  static const Color penaltyCardBg = Color(0xFFF3D9D9);
  static const Color bonusCardBg = Color(0xFFD9EAD9);
  static const Color breakdownBg = Color(0xFF8B7563);
  static const Color emptyTitle = Color(0xFF462911);
  static const Color emptyBody = Color.fromRGBO(70, 41, 17, 0.67);
  static const Color statusReleasedBg = Color(0xFFB8E0C4);
  static const Color statusReleasedText = Color(0xFF1B5E2C);
  static const Color statusProcessingBg = Color(0xFFDCD3C2);
  static const Color statusProcessingText = Color(0xFF5A4B37);
  static const Color statusDeductedBg = Color(0xFFE8A0A0);
  static const Color statusDeductedText = Color(0xFF8B1E1E);

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<Map<String, dynamic>> _payments = const [];
  final Map<String, String> _patientNames = {};
  final Set<String> _expandedIds = {};
  _Tab _tab = _Tab.paid;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _sub = PaymentService.streamPaymentsForCaregiver(uid).listen((docs) {
        if (mounted) setState(() => _payments = docs);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _resolvePatientName(String? uid) {
    if (uid == null || uid.isEmpty || _patientNames.containsKey(uid)) return;
    PatientService.getPatientName(uid).then((name) {
      if (mounted) setState(() => _patientNames[uid] = name);
    });
  }

  String _type(Map<String, dynamic> p) => (p['type'] as String?) ?? 'payment';

  List<Map<String, dynamic>> get _tabItems {
    switch (_tab) {
      case _Tab.paid:
        return _payments.where((p) => _type(p) == 'payment' && p['status'] == 'completed').toList();
      case _Tab.pending:
        return _payments.where((p) => _type(p) == 'payment' && p['status'] == 'pending').toList();
      case _Tab.adjustments:
        return _payments.where((p) => _type(p) == 'penalty' || _type(p) == 'bonus').toList();
    }
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

  String _dayLabel(DateTime dt) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final items = _tabItems;
    final grossTotal = items.fold<double>(0, (t, p) => t + ((p['amount'] as num?)?.toDouble() ?? 0));
    final netTotal = items.fold<double>(0, (t, p) {
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      final fee = (p['platformFeeAmount'] as num?)?.toDouble() ?? 0;
      return t + (amount - fee);
    });

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final p in items) {
      final ts = p['createdAt'];
      final key = ts is Timestamp ? _dayLabel(ts.toDate()) : 'Unknown date';
      grouped.putIfAbsent(key, () => []).add(p);
    }

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
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text('Transactions', style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export isn\'t available yet.'), duration: Duration(seconds: 2)),
                    ),
                    child: const Icon(Icons.ios_share_rounded, color: darkGreen, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _buildTab('Paid', _Tab.paid),
                  const SizedBox(width: 8),
                  _buildTab('Pending', _Tab.pending),
                  const SizedBox(width: 8),
                  _buildTab('Adjustments', _Tab.adjustments),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: summaryBg, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${items.length} entr${items.length == 1 ? 'y' : 'ies'} · gross ${_formatLkr(grossTotal)}',
                      style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    if (_tab != _Tab.adjustments)
                      Text('net ${_formatLkr(netTotal)}', style: const TextStyle(fontFamily: 'Open Sans', color: summaryAmber, fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: emptyTitle.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              switch (_tab) {
                                _Tab.paid => 'No paid transactions yet',
                                _Tab.pending => 'Nothing pending',
                                _Tab.adjustments => 'No adjustments',
                              },
                              style: const TextStyle(fontFamily: 'Open Sans', color: emptyTitle, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'This will fill in once billing is set up and real bookings are paid for.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Open Sans', color: emptyBody, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: grouped.entries.expand((entry) => [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8, top: 8),
                                child: Text(entry.key, style: const TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              ...entry.value.map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildCard(p),
                                  )),
                            ]).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, _Tab tab) {
    final selected = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tabActiveBg : Colors.transparent,
          border: Border.all(color: tabInactiveBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Open Sans', color: selected ? Colors.white : darkGreen, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final type = _type(p);
    if (type == 'penalty') return _buildPenaltyCard(p);
    if (type == 'bonus') return _buildBonusCard(p);
    return _buildPaymentCard(p);
  }

  Widget _buildPaymentCard(Map<String, dynamic> p) {
    final id = p['id'] as String;
    final patientUid = p['patientUid'] as String?;
    _resolvePatientName(patientUid);
    final patientName = _patientNames[patientUid] ?? '…';
    final careType = p['careType'] as String? ?? '';
    final startTime = p['startTime'] as String?;
    final endTime = p['endTime'] as String?;
    final hoursBilled = p['hoursBilled'] as num?;
    final hourlyRate = p['hourlyRate'] as num?;
    final platformFeePercent = p['platformFeePercent'] as num?;
    final platformFeeAmount = p['platformFeeAmount'] as num?;
    final nightRatePercent = p['nightRatePercent'] as num?;
    final amount = (p['amount'] as num?) ?? 0;
    final bookingId = p['bookingId'] as String?;
    final status = (p['status'] as String?) ?? 'pending';
    final isReleased = status == 'completed';
    final net = amount - (platformFeeAmount ?? 0);
    final expanded = _expandedIds.contains(id);

    final timeLabel = (startTime != null && endTime != null)
        ? '$startTime – $endTime'
        : (hoursBilled != null ? '${hoursBilled.toStringAsFixed(hoursBilled % 1 == 0 ? 0 : 1)} hrs' : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (expanded) {
                _expandedIds.remove(id);
              } else {
                _expandedIds.add(id);
              }
            }),
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: darkGreen, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(_initialsFor(patientName), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                      if (careType.isNotEmpty || timeLabel != null)
                        Text(
                          [careType, if (timeLabel != null) timeLabel].join(' · '),
                          style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatLkr(amount), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                    if (platformFeeAmount != null)
                      Text('− ${_formatLkr(platformFeeAmount)} fee', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF8B1E1E), fontSize: 10, fontWeight: FontWeight.w600))
                    else if (nightRatePercent != null)
                      Text('+${nightRatePercent.toStringAsFixed(0)}% night', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (expanded && hoursBilled != null && hourlyRate != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: breakdownBg, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  _breakdownRow('${hoursBilled.toStringAsFixed(hoursBilled % 1 == 0 ? 0 : 1)} hrs × ${_formatLkr(hourlyRate)}', _formatLkr(hoursBilled * hourlyRate)),
                  if (platformFeeAmount != null)
                    _breakdownRow(
                      'Platform commission${platformFeePercent != null ? ' ${platformFeePercent.toStringAsFixed(1)}%' : ''}',
                      '− ${_formatLkr(platformFeeAmount)}',
                      valueColor: const Color(0xFFFCA5A5),
                    ),
                  const Divider(height: 14, color: Color(0x33FFFFFF)),
                  _breakdownRow('Net earnings', _formatLkr(net), bold: true, valueColor: const Color(0xFF4ADE80)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: isReleased ? statusReleasedBg : statusProcessingBg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  isReleased ? 'RELEASED' : 'PROCESSING',
                  style: TextStyle(fontFamily: 'Open Sans', color: isReleased ? statusReleasedText : statusProcessingText, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
              if (bookingId != null)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaregiverTransactionDetailScreen(payment: p))),
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Booking $bookingId', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 3),
                    const Icon(Icons.open_in_new_rounded, color: Color(0xFF1B5E2C), size: 12),
                  ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 11, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(value, style: TextStyle(fontFamily: 'Open Sans', color: valueColor ?? Colors.white, fontSize: 11, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPenaltyCard(Map<String, dynamic> p) {
    final reason = p['adjustmentReason'] as String? ?? 'Penalty applied';
    final amount = (p['amount'] as num?) ?? 0;
    final bookingId = p['bookingId'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: penaltyCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.remove_circle_rounded, color: Color(0xFF8B1E1E), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Late-cancellation penalty', style: TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(reason, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(_formatLkr(-amount.abs()), style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF8B1E1E), fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusDeductedBg, borderRadius: BorderRadius.circular(999)),
                child: const Text('DEDUCTED', style: TextStyle(fontFamily: 'Open Sans', color: statusDeductedText, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bookingId != null) ...[
                    Text('Booking $bookingId', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                  ],
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Disputing a penalty isn\'t available yet — contact support.'), duration: Duration(seconds: 2)),
                    ),
                    child: const Text('Question this?', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF8B1E1E), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBonusCard(Map<String, dynamic> p) {
    final reason = p['adjustmentReason'] as String? ?? 'Bonus issued';
    final amount = (p['amount'] as num?) ?? 0;
    final bookingId = p['bookingId'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bonusCardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Color(0xFF1B5E2C), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Compensation bonus', style: TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                Text(reason, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500)),
                if (bookingId != null) ...[
                  const SizedBox(height: 6),
                  Text('Booking $bookingId', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          Text('+ ${_formatLkr(amount.abs())}', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty || parts.first == '…') return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
