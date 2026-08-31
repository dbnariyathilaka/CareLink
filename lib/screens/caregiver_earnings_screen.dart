import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/payment_service.dart';
import '../widgets/status_bar.dart';
import 'caregiver_earnings_transactions_screen.dart';
import 'caregiver_payout_history_screen.dart';
import 'caregiver_verification_status_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Earnings Screen ("View details" from own profile)
//  Figma node: 777-765
//  Reads the real `payments` collection (see PaymentService) — empty until
//  billing exists, so every figure here is a real, honestly-zero sum today
//  rather than a fabricated number. The "Payout on hold" banner is a real,
//  working connection to the verification feature: it reflects an actual
//  rejected document from caregiverProfiles.documentReviews, not a
//  hardcoded example.
// ─────────────────────────────────────────────────────────────

enum _Period { week, month, allTime }

class CaregiverEarningsScreen extends StatefulWidget {
  const CaregiverEarningsScreen({super.key});

  @override
  State<CaregiverEarningsScreen> createState() => _CaregiverEarningsScreenState();
}

class _CaregiverEarningsScreenState extends State<CaregiverEarningsScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color headerBg = Color(0xFF1F3554);
  static const Color headerSub = Color(0xFFB5ADA2);
  static const Color tileBg = Color(0xFF1F3554);
  static const Color tileLabel = Color(0xFFB5ADA2);
  static const Color greenValue = Color(0xFF4ADE80);
  static const Color amberValue = Color(0xFFF5B301);
  static const Color holdBg = Color(0xFFF3E7C9);
  static const Color holdBorder = Color(0xFFD8C48F);
  static const Color holdTitle = Color(0xFF6B4A16);
  static const Color chartBg = Color(0xFF1F3554);
  static const Color barReleased = Color(0xFF2DD4BF);
  static const Color barOnHold = Color(0xFFF5B301);
  static const Color navRowBg = Color(0xFF4E4533);
  static const Color navRowText = Colors.white;
  static const Color navRowIcon = Color(0xFFF5B301);

  bool _loading = true;
  List<Map<String, dynamic>> _payments = const [];
  Map<String, dynamic>? _rejectedDoc; // first rejected verification doc, if any
  _Period _period = _Period.week;

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
    PaymentService.streamPaymentsForCaregiver(uid).listen((docs) {
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
      _rejectedDoc = rejected;
      _loading = false;
    });
  }

  DateTime? _createdAt(Map<String, dynamic> p) {
    final ts = p['createdAt'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  DateTime _periodStart() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.week:
        return now.subtract(Duration(days: now.weekday - 1)); // Monday this week
      case _Period.month:
        return DateTime(now.year, now.month, 1);
      case _Period.allTime:
        return DateTime(2000);
    }
  }

  List<Map<String, dynamic>> get _periodPayments {
    final start = _periodStart();
    return _payments.where((p) {
      final dt = _createdAt(p);
      return dt != null && !dt.isBefore(start);
    }).toList();
  }

  double _sum(Iterable<Map<String, dynamic>> docs, {String? status}) => docs
      .where((p) => status == null || p['status'] == status)
      .fold<double>(0, (total, p) => total + ((p['amount'] as num?)?.toDouble() ?? 0));

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

  @override
  Widget build(BuildContext context) {
    final periodPayments = _periodPayments;
    final completedInPeriod = periodPayments.where((p) => p['status'] == 'completed').toList();

    final totalEarned = _sum(_payments, status: 'completed');
    final pendingPayout = _sum(_payments, status: 'pending');

    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final thisMonthTotal = _sum(_payments.where((p) {
      final dt = _createdAt(p);
      return dt != null && !dt.isBefore(thisMonthStart);
    }), status: 'completed');
    final lastMonthTotal = _sum(_payments.where((p) {
      final dt = _createdAt(p);
      return dt != null && !dt.isBefore(lastMonthStart) && dt.isBefore(thisMonthStart);
    }), status: 'completed');
    final monthChangePercent = lastMonthTotal > 0 ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal * 100) : null;

    final pendingCount = _payments.where((p) => p['status'] == 'pending').length;

    final shiftsInPeriod = completedInPeriod.length;
    final hoursInPeriod = completedInPeriod.fold<double>(0, (t, p) => t + ((p['hoursBilled'] as num?)?.toDouble() ?? 0));
    final feePercent = completedInPeriod.map((p) => p['platformFeePercent'] as num?).whereType<num>().firstOrNull;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: headerBg))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(pendingPayout, shiftsInPeriod, hoursInPeriod, feePercent),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatTile('Total earned', _formatLkr(totalEarned), 'All time · LKR', greenValue)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatTile('Pending payout', _formatLkr(pendingPayout), 'On hold', amberValue)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatTile(
                                'This month',
                                _formatLkr(thisMonthTotal),
                                monthChangePercent != null
                                    ? '${monthChangePercent >= 0 ? '+' : ''}${monthChangePercent.toStringAsFixed(0)}% vs last month'
                                    : 'No prior month data',
                                greenValue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatTile(
                                'Expected next',
                                pendingCount > 0 ? _formatLkr(pendingPayout) : '—',
                                '$pendingCount booked shift${pendingCount == 1 ? '' : 's'}',
                                greenValue,
                              ),
                            ),
                          ],
                        ),
                        if (_rejectedDoc != null) ...[
                          const SizedBox(height: 18),
                          _buildHoldBanner(_rejectedDoc!),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          'LAST 6 WEEKS',
                          style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF6E6F72), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        _buildWeeklyChart(),
                        const SizedBox(height: 20),
                        _buildNavRow(
                          icon: Icons.receipt_long_rounded,
                          label: 'Earnings transactions',
                          trailing: '${_payments.length}',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverEarningsTransactionsScreen())),
                        ),
                        const SizedBox(height: 10),
                        _buildNavRow(
                          icon: Icons.account_balance_rounded,
                          label: 'Payout history',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverPayoutHistoryScreen())),
                        ),
                        const SizedBox(height: 10),
                        _buildNavRow(
                          icon: Icons.description_outlined,
                          label: 'Tax summary ${DateTime.now().year}',
                          trailing: 'Export',
                          trailingColor: amberValue,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tax summary export isn\'t available yet.'), duration: Duration(seconds: 2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(double pendingPayout, int shifts, double hours, num? feePercent) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 18),
      decoration: const BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Earnings', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Statement downloads aren\'t available yet.'), duration: Duration(seconds: 2)),
                ),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pendingPayout > 0 ? 'Pending payout' : 'No payout scheduled yet',
            style: const TextStyle(fontFamily: 'Open Sans', color: headerSub, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(_formatLkr(pendingPayout), style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            [
              '$shifts shift${shifts == 1 ? '' : 's'}',
              if (hours > 0) '${hours.toStringAsFixed(0)} hrs',
              if (feePercent != null) 'after ${feePercent.toStringAsFixed(1)}% platform fee',
            ].join(' · '),
            style: const TextStyle(fontFamily: 'Open Sans', color: headerSub, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPeriodChip('This week', _Period.week),
              const SizedBox(width: 8),
              _buildPeriodChip('Month', _Period.month),
              const SizedBox(width: 8),
              _buildPeriodChip('All time', _Period.allTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, _Period period) {
    final selected = _period == period;
    return GestureDetector(
      onTap: () => setState(() => _period = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, String sub, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Open Sans', color: tileLabel, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'Open Sans', color: valueColor, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontFamily: 'Open Sans', color: tileLabel, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHoldBanner(Map<String, dynamic> rejectedDoc) {
    final key = rejectedDoc['key'] as String;
    final note = rejectedDoc['note'] as String?;
    final docName = key == 'policeClearance'
        ? 'police clearance certificate'
        : key == 'nic'
            ? 'NIC'
            : key.startsWith('cert')
                ? 'a certificate'
                : 'a document';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: holdBg, border: Border.all(color: holdBorder), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pause_circle_filled_rounded, color: holdTitle, size: 18),
              const SizedBox(width: 8),
              const Text('Payout on hold', style: TextStyle(fontFamily: 'Open Sans', color: holdTitle, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            (note != null && note.isNotEmpty) ? note : 'Your $docName was rejected. Re-upload it to release your payout.',
            style: const TextStyle(fontFamily: 'Open Sans', color: holdTitle, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: holdTitle,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverVerificationStatusScreen())),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Center(child: Text('Re-upload document', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final now = DateTime.now();
    final weeks = List.generate(6, (i) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (5 - i) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final weekPayments = _payments.where((p) {
        final dt = _createdAt(p);
        return dt != null && !dt.isBefore(weekStart) && dt.isBefore(weekEnd);
      }).toList();
      final released = _sum(weekPayments, status: 'completed');
      final onHold = _sum(weekPayments, status: 'pending');
      return (weekNum: _isoWeekNumber(weekStart), released: released, onHold: onHold);
    });
    final maxVal = weeks.fold<double>(0, (m, w) => [m, w.released, w.onHold].reduce((a, b) => a > b ? a : b));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(color: chartBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weeks.map((w) {
              final isOnHold = w.onHold > 0 && w.released == 0;
              final value = isOnHold ? w.onHold : w.released;
              final height = maxVal == 0 ? 4.0 : (value / maxVal * 60.0).clamp(4.0, 60.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: height,
                    decoration: BoxDecoration(
                      color: value == 0 ? Colors.white.withValues(alpha: 0.15) : (isOnHold ? barOnHold : barReleased),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${w.weekNum}', style: const TextStyle(fontFamily: 'Open Sans', color: tileLabel, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: barReleased, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Released', style: TextStyle(fontFamily: 'Open Sans', color: tileLabel, fontSize: 10)),
              const SizedBox(width: 14),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: barOnHold, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('On hold', style: TextStyle(fontFamily: 'Open Sans', color: tileLabel, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(_dayOfYear(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  String _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays.toString();
  }

  Widget _buildNavRow({
    required IconData icon,
    required String label,
    String? trailing,
    Color trailingColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(color: navRowBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: navRowIcon, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontFamily: 'Open Sans', color: navRowText, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            if (trailing != null)
              Text(trailing, style: TextStyle(fontFamily: 'Open Sans', color: trailingColor, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: navRowText, size: 18),
          ],
        ),
      ),
    );
  }
}
