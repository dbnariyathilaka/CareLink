import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/payment_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Payout History Screen
//  Figma node: 786-709
//  Reads real `payments` (empty until billing exists) and the real bank
//  details collected in onboarding step 6. The 4-stage payout lifecycle
//  (Pending → On hold → Processing → Released) is derived from real fields
//  — "On hold" is a genuine, working connection to the verification
//  feature: it's true only when the caregiver actually has a rejected
//  document in caregiverProfiles.documentReviews, not a fixed example.
//  "Processing" only shows if a real `payoutStage: 'processing'` field is
//  ever set (dormant — nothing writes it yet, since payouts are admin-
//  processed manually and there's no batching system built).
//  No fake purchase-order reference numbers or a fixed "every Friday"
//  cadence are shown — neither is backed by anything real.
// ─────────────────────────────────────────────────────────────
class CaregiverPayoutHistoryScreen extends StatefulWidget {
  const CaregiverPayoutHistoryScreen({super.key});

  @override
  State<CaregiverPayoutHistoryScreen> createState() => _CaregiverPayoutHistoryScreenState();
}

class _CaregiverPayoutHistoryScreenState extends State<CaregiverPayoutHistoryScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color bankCardBg = Color(0xFF33482E);
  static const Color bankAmber = Color(0xFFF5B301);
  static const Color sectionLabel = Color(0xFF544730);
  static const Color legendPendingBg = Color(0xFFDCD3C2);
  static const Color legendPendingText = Color(0xFF5A4B37);
  static const Color legendHoldBg = Color(0xFFF3E7C9);
  static const Color legendHoldText = Color(0xFF6B4A16);
  static const Color legendProcessingBg = Color(0xFFCBD5E1);
  static const Color legendProcessingText = Color(0xFF334155);
  static const Color legendReleasedBg = Color(0xFFB8E0C4);
  static const Color legendReleasedText = Color(0xFF1B5E2C);
  static const Color currentCardBg = Color(0xFFBAADA1);
  static const Color earlierCardBg = Color(0xFFBAADA1);
  static const Color trackDone = Color(0xFF4ADE80);
  static const Color trackActive = Color(0xFFF5B301);
  static const Color trackEmpty = Color(0xFFD8D3C5);
  static const Color emptyTitle = Color(0xFF462911);
  static const Color emptyBody = Color.fromRGBO(70, 41, 17, 0.67);
  static const Color taxCardBg = Color(0xFF1F3554);

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<Map<String, dynamic>> _payments = const [];
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _rejectedDoc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _sub = PaymentService.streamPaymentsForCaregiver(uid).listen((docs) {
      if (mounted) setState(() => _payments = docs);
    });
    final profile = await CaregiverService.getCaregiverProfile(uid);
    if (!mounted) return;
    final reviews = (profile?['documentReviews'] as Map?)?.cast<String, dynamic>() ?? const {};
    Map<String, dynamic>? rejected;
    for (final entry in reviews.entries) {
      final v = (entry.value as Map?)?.cast<String, dynamic>();
      if (v != null && v['status'] == 'rejected') {
        rejected = {'key': entry.key, ...v};
        break;
      }
    }
    setState(() {
      _profile = profile;
      _rejectedDoc = rejected;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  DateTime? _createdAt(Map<String, dynamic> p) {
    final ts = p['createdAt'];
    return ts is Timestamp ? ts.toDate() : null;
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

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  DateTime _weekStart(DateTime date) => date.subtract(Duration(days: date.weekday - 1));

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _docName(String key) {
    if (key == 'policeClearance') return 'police clearance certificate';
    if (key == 'nic') return 'NIC';
    if (key.startsWith('cert')) return 'certificate';
    return 'document';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: bg, body: Center(child: CircularProgressIndicator(color: darkGreen)));
    }

    final bankName = (_profile?['bankName'] as String?)?.trim();
    final accountNumber = (_profile?['accountNumber'] as String?)?.trim();
    final last4 = (accountNumber != null && accountNumber.length >= 4) ? accountNumber.substring(accountNumber.length - 4) : null;

    final now = DateTime.now();
    final currentWeekStart = _weekStart(now);

    final pendingPayments = _payments.where((p) => (p['type'] as String? ?? 'payment') == 'payment' && p['status'] == 'pending').toList();
    final currentWeekPending = pendingPayments.where((p) {
      final dt = _createdAt(p);
      return dt != null && !dt.isBefore(currentWeekStart);
    }).toList();
    final currentTotal = currentWeekPending.fold<double>(0, (t, p) => t + ((p['amount'] as num?)?.toDouble() ?? 0));
    final onHold = _rejectedDoc != null && currentWeekPending.isNotEmpty;
    final explicitStage = currentWeekPending.map((p) => p['payoutStage'] as String?).firstWhere((s) => s == 'processing', orElse: () => null);

    // Released payments + bonuses, grouped by week, most recent first.
    final releasedItems = _payments.where((p) {
      final type = p['type'] as String? ?? 'payment';
      return (type == 'payment' && p['status'] == 'completed') || type == 'bonus';
    }).toList();
    final weekGroups = <int, List<Map<String, dynamic>>>{};
    for (final p in releasedItems) {
      final dt = _createdAt(p);
      if (dt == null) continue;
      weekGroups.putIfAbsent(_isoWeekNumber(dt), () => []).add(p);
    }
    final sortedWeeks = weekGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    final yearStart = DateTime(now.year, 1, 1);
    final ytdPayments = _payments.where((p) {
      final type = p['type'] as String? ?? 'payment';
      final dt = _createdAt(p);
      return type == 'payment' && p['status'] == 'completed' && dt != null && !dt.isBefore(yearStart);
    }).toList();
    final grossYtd = ytdPayments.fold<double>(0, (t, p) => t + ((p['amount'] as num?)?.toDouble() ?? 0));
    final feesYtd = ytdPayments.fold<double>(0, (t, p) => t + ((p['platformFeeAmount'] as num?)?.toDouble() ?? 0));
    final netYtd = grossYtd - feesYtd;

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
                    child: Text('Payouts', style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: _showStatusHelp,
                    child: const Icon(Icons.help_outline_rounded, color: darkGreen, size: 22),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: bankCardBg, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (bankName != null && bankName.isNotEmpty)
                                      ? '$bankName${last4 != null ? ' •• $last4' : ''}'
                                      : 'No payout account set up',
                                  style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (bankName != null && bankName.isNotEmpty) ? 'Payout details' : 'Add your bank details to get paid',
                                  style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFFCBD5C0), fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Changing payout details isn\'t available yet — contact support.'), duration: Duration(seconds: 2)),
                            ),
                            child: const Text('Change', style: TextStyle(fontFamily: 'Open Sans', color: bankAmber, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('STATUS KEY', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _legendChip('Pending', legendPendingBg, legendPendingText),
                        _legendChip('On hold', legendHoldBg, legendHoldText),
                        _legendChip('Processing', legendProcessingBg, legendProcessingText),
                        _legendChip('Released', legendReleasedBg, legendReleasedText),
                      ],
                    ),
                    if (currentWeekPending.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'WEEK ${_isoWeekNumber(now)} · CURRENT',
                        style: const TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      _buildCurrentCard(currentTotal, onHold, explicitStage),
                    ],
                    const SizedBox(height: 20),
                    const Text('EARLIER PAYOUTS', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    if (sortedWeeks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: earlierCardBg, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 40, color: emptyTitle.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            const Text('No payouts yet', style: TextStyle(fontFamily: 'Open Sans', color: emptyTitle, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            const Text(
                              'Released payouts and bonuses will show up here once billing is set up.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Open Sans', color: emptyBody, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    else
                      ...sortedWeeks.expand((week) => weekGroups[week]!.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildEarlierRow(p, week, bankName, last4),
                          ))),
                    const SizedBox(height: 20),
                    const Text('TAX SUMMARY', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: taxCardBg, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          _taxRow('Gross ${now.year} (Jan–${_formatDate(now).split(' ').last})', _formatLkr(grossYtd), Colors.white),
                          _taxRow('Platform fees paid', '− ${_formatLkr(feesYtd)}', const Color(0xFFFCA5A5), isLast: false),
                          _taxRow('Net received', _formatLkr(netYtd), const Color(0xFF4ADE80), isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: taxCardBg,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PDF export isn\'t available yet.'), duration: Duration(seconds: 2)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.download_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 6),
                                      Text('Export PDF', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('CSV export isn\'t available yet.'), duration: Duration(seconds: 2)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: darkGreen, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Export CSV', style: TextStyle(fontFamily: 'Open Sans', color: darkGreen, fontSize: 12, fontWeight: FontWeight.w700)),
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

  Widget _legendChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontFamily: 'Open Sans', color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  void _showStatusHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payout statuses', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Pending: earned, not yet paid out.\nOn hold: paused because a submitted document needs attention.\nProcessing: being sent to your bank.\nReleased: paid out.',
          style: TextStyle(color: Color(0xFFD4CDC3), fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it', style: TextStyle(color: bankAmber))),
        ],
      ),
    );
  }

  Widget _buildCurrentCard(double total, bool onHold, String? explicitStage) {
    final stage = onHold ? 'onHold' : (explicitStage ?? 'pending');
    final label = switch (stage) {
      'onHold' => 'ON HOLD',
      'processing' => 'PROCESSING',
      _ => 'PENDING',
    };
    final (chipBg, chipText) = switch (stage) {
      'onHold' => (legendHoldBg, legendHoldText),
      'processing' => (legendProcessingBg, legendProcessingText),
      _ => (legendPendingBg, legendPendingText),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: currentCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
                child: Text(label, style: TextStyle(fontFamily: 'Open Sans', color: chipText, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              Text(_formatLkr(total), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStageTracker(stage),
          if (onHold && _rejectedDoc != null) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final note = _rejectedDoc!['note'] as String?;
              final decidedAt = _rejectedDoc!['decidedAt'];
              final dateLabel = decidedAt is Timestamp ? _formatDate(decidedAt.toDate()) : null;
              final docName = _docName(_rejectedDoc!['key'] as String);
              return Text(
                (note != null && note.isNotEmpty)
                    ? 'Held by CareLink${dateLabel != null ? ' on $dateLabel' : ''} — $note'
                    : 'Held by CareLink${dateLabel != null ? ' on $dateLabel' : ''} — your $docName was rejected. Re-upload it to release this payout.',
                style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 11, fontWeight: FontWeight.w500, height: 1.4),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStageTracker(String stage) {
    const stages = ['pending', 'onHold', 'processing', 'released'];
    const labels = ['Pending', 'On hold', 'Processing', 'Released'];
    const icons = [Icons.check_circle_rounded, Icons.pause_circle_filled_rounded, Icons.autorenew_rounded, Icons.savings_rounded];
    final currentIndex = stages.indexOf(stage).clamp(0, stages.length - 1);

    return Row(
      children: List.generate(stages.length, (i) {
        final isDone = i <= currentIndex;
        final color = isDone ? (i == currentIndex ? trackActive : trackDone) : trackEmpty;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0) Expanded(child: Container(height: 2, color: i <= currentIndex ? trackDone : trackEmpty)),
                  Icon(icons[i], color: color, size: 20),
                  if (i < stages.length - 1) Expanded(child: Container(height: 2, color: trackEmpty)),
                ],
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: TextStyle(fontFamily: 'Open Sans', fontSize: 9, fontWeight: FontWeight.w600, color: isDone ? const Color(0xFF3A332A) : const Color(0xFF9A8F80))),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEarlierRow(Map<String, dynamic> p, int week, String? bankName, String? last4) {
    final type = p['type'] as String? ?? 'payment';
    final dt = _createdAt(p);
    final amount = (p['amount'] as num?) ?? 0;

    if (type == 'bonus') {
      final reason = p['adjustmentReason'] as String? ?? 'Bonus issued';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: earlierCardBg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, color: Color(0xFF1B5E2C), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compensation${dt != null ? ' · ${_formatDate(dt)}' : ''}', style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(reason, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Text('+${_formatLkr(amount.abs())}', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: earlierCardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF1B5E2C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Week $week${dt != null ? ' · ${_formatDate(dt)}' : ''}', style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(
                  (bankName != null && bankName.isNotEmpty) ? '${bankName.split(' ').first}${last4 != null ? ' •• $last4' : ''}' : 'Payout released',
                  style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF3A332A), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatLkr(amount), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('RELEASED', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF1B5E2C), fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taxRow(String label, String value, Color valueColor, {bool isLast = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x22FFFFFF)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontFamily: 'Open Sans', color: valueColor, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
