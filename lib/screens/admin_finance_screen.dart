import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

enum FinanceFilter { payouts, ledger, refunds }

enum PayoutStatus { pending, onHold, released }

class PayoutRunEntry {
  final String id;
  final String initials;
  final Color avatarBg;
  final Color avatarText;
  final String name;
  final String shiftsInfo;
  final int amount;
  final int feeAmount;
  PayoutStatus status;
  String? holdReason;

  PayoutRunEntry({
    required this.id,
    required this.initials,
    required this.avatarBg,
    required this.avatarText,
    required this.name,
    required this.shiftsInfo,
    required this.amount,
    required this.feeAmount,
    this.status = PayoutStatus.pending,
    this.holdReason,
  });
}

enum TransactionType { payment, fee, refund }

class FinanceTransaction {
  final TransactionType type;
  final String title;
  final String subtitle;
  final int amount; // signed
  const FinanceTransaction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
  });
}

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  // ── Color Tokens matching Figma node 646:752 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color filterActiveBg = Color(0xFF5D5445);
  static const Color filterActiveFg = Color(0xFFF8FAFC);
  static const Color filterInactiveBorder = Color(0xFF5D5445);

  static const Color pendingCardBorder = Color(0x4D0EA5E9);
  static const Color pendingLabelColor = Color(0xFF95703F);
  static const Color pendingValueColor = Color(0xFFFFE5CE);
  static const Color pendingSubColor = Color(0xFF8B7C64);

  static const Color revenueCardBg = Color(0xFF493D2A);
  static const Color revenueCardBorder = Color(0xFF334155);
  static const Color revenueValueColor = Color(0xFFFBBC05);

  static const Color sectionLabelColor = Colors.black;

  static const Color payoutCardBg = Color(0xFFC4BBAC);
  static const Color payoutCardBorder = Color(0xFF493D2A);
  static const Color payoutNameColor = Color(0xFF493D2A);
  static const Color payoutSubColor = Color(0xFFA47241);

  static const Color releaseBtnBg = Color(0x6E8C7C62);
  static const Color releaseBtnFg = Color(0xFF70573C);
  static const Color holdBtnBorder = Color(0xFF493D2A);

  static const Color transactionCardBg = Color(0xFFC4BBAC);
  static const Color transactionCardBorder = Color(0xFF334155);
  static const Color transactionTitleColor = Color(0xFF313131);
  static const Color transactionSubColor = Color(0xFF64748B);
  static const Color paymentAmountColor = Color(0xFF666666);
  static const Color feeAmountColor = Color(0xFFC79049);
  static const Color refundAmountColor = Color(0xFFEF4444);

  static const Color ctaBtnBg = Color(0xFF44331C);

  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  FinanceFilter _activeFilter = FinanceFilter.payouts;

  final List<PayoutRunEntry> _payoutRun = [
    PayoutRunEntry(
      id: 'po_1',
      initials: 'AF',
      avatarBg: const Color(0xFFB88F48),
      avatarText: const Color(0xFF04212E),
      name: 'Alice Fernando',
      shiftsInfo: '6 shifts · 48 hrs',
      amount: 42000,
      feeAmount: 5250,
    ),
    PayoutRunEntry(
      id: 'po_2',
      initials: 'BK',
      avatarBg: const Color(0xFF735726),
      avatarText: Colors.white,
      name: 'Brian Kumara',
      shiftsInfo: '5 shifts · 40 hrs',
      amount: 36000,
      feeAmount: 4500,
      status: PayoutStatus.onHold,
      holdReason: 'On hold · verification expired',
    ),
    PayoutRunEntry(
      id: 'po_3',
      initials: 'SP',
      avatarBg: const Color(0xFFA28C66),
      avatarText: const Color(0xFF3B2404),
      name: 'Sanduni Perera',
      shiftsInfo: '9 shifts · 72 hrs',
      amount: 61000,
      feeAmount: 7625,
    ),
  ];

  final List<FinanceTransaction> _transactions = const [
    FinanceTransaction(
      type: TransactionType.payment,
      title: 'Payment · Nipuni A.',
      subtitle: 'Booking BK-8841 · 22 Aug',
      amount: 48000,
    ),
    FinanceTransaction(
      type: TransactionType.fee,
      title: 'Platform fee',
      subtitle: '12.5% commission',
      amount: 6000,
    ),
    FinanceTransaction(
      type: TransactionType.refund,
      title: 'Refund · Mala Perera',
      subtitle: 'Caregiver no-show · full',
      amount: -18000,
    ),
    FinanceTransaction(
      type: TransactionType.payment,
      title: 'Payment · Kamal P.',
      subtitle: 'Booking BK-8839 · 21 Aug',
      amount: 36000,
    ),
    FinanceTransaction(
      type: TransactionType.refund,
      title: 'Refund · David R.',
      subtitle: 'Late cancellation · partial',
      amount: -1500,
    ),
    FinanceTransaction(
      type: TransactionType.fee,
      title: 'Platform fee',
      subtitle: '12.5% commission',
      amount: 4500,
    ),
  ];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  List<PayoutRunEntry> get _visiblePayoutRun =>
      _payoutRun.where((p) => p.status != PayoutStatus.released).toList();

  List<FinanceTransaction> get _visibleTransactions {
    if (_activeFilter == FinanceFilter.refunds) {
      return _transactions.where((t) => t.type == TransactionType.refund).toList();
    }
    return _transactions;
  }

  void _releasePayout(PayoutRunEntry p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Release Payout?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Release LKR ${_formatAmount(p.amount)} to ${p.name}?',
          style: const TextStyle(color: Color(0xFFC4BBAC), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ctaBtnBg),
            onPressed: () {
              setState(() => p.status = PayoutStatus.released);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payout released to ${p.name}.'), duration: const Duration(seconds: 2)),
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _holdPayout(PayoutRunEntry p) {
    setState(() {
      p.status = PayoutStatus.onHold;
      p.holdReason = 'On hold · pending review';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payout held for ${p.name}.'), duration: const Duration(seconds: 2)),
    );
  }

  void _releaseAllApproved() {
    final approved = _payoutRun.where((p) => p.status == PayoutStatus.pending).toList();
    if (approved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No approved payouts to release.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Release All Approved Payouts?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This releases ${approved.length} approved payout${approved.length == 1 ? '' : 's'} totalling LKR ${_formatAmount(approved.fold(0, (sum, p) => sum + p.amount))}.',
          style: const TextStyle(color: Color(0xFFC4BBAC), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ctaBtnBg),
            onPressed: () {
              setState(() {
                for (final p in approved) {
                  p.status = PayoutStatus.released;
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${approved.length} payout${approved.length == 1 ? '' : 's'} released.'), duration: const Duration(seconds: 2)),
              );
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    final s = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCardsRow(),
                    if (_activeFilter == FinanceFilter.payouts) ...[
                      const SizedBox(height: 16),
                      _buildSectionLabel('PAYOUT RUN · WEEK 34'),
                      const SizedBox(height: 9),
                      ..._visiblePayoutRun.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _buildPayoutCard(p),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildSectionLabel(
                      _activeFilter == FinanceFilter.refunds ? 'REFUNDS' : 'RECENT TRANSACTIONS',
                    ),
                    const SizedBox(height: 9),
                    _buildTransactionsCard(),
                    if (_activeFilter == FinanceFilter.payouts) ...[
                      const SizedBox(height: 16),
                      _buildReleaseAllButton(),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'Finance',
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: titleColor, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting finance report (CSV)...'), duration: Duration(seconds: 2)),
              );
            },
            tooltip: 'Export',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = [
      (FinanceFilter.payouts, 'Payouts'),
      (FinanceFilter.ledger, 'Ledger'),
      (FinanceFilter.refunds, 'Refunds'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: filters.map((f) {
          final isActive = _activeFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? filterActiveBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: filterInactiveBorder, width: isActive ? 0 : 1),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? filterActiveFg : filterInactiveBorder,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Stat cards ──────────────────────────────────────────────────────────
  Widget _buildStatCardsRow() {
    final pendingTotal = _visiblePayoutRun.fold<int>(0, (sum, p) => sum + p.amount);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 76),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pendingCardBorder, width: 1),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF45371F), Color(0xFF6C6354)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending payouts',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: pendingLabelColor),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'LKR ${_formatAmount(pendingTotal ~/ 1000)}k',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w800, color: pendingValueColor),
                  ),
                  Text(
                    '${_visiblePayoutRun.length} caregivers',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: pendingSubColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 76),
              decoration: BoxDecoration(
                color: revenueCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: revenueCardBorder, width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform revenue',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: pendingLabelColor),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'LKR 528k',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w800, color: revenueValueColor),
                  ),
                  Text(
                    '12.5% avg fee',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: pendingSubColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: sectionLabelColor,
        letterSpacing: 0.6,
      ),
    );
  }

  // ── Payout run card ─────────────────────────────────────────────────────
  Widget _buildPayoutCard(PayoutRunEntry p) {
    final isOnHold = p.status == PayoutStatus.onHold;
    return Container(
      decoration: BoxDecoration(
        color: payoutCardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: payoutCardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: p.avatarBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  p.initials,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: p.avatarText),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: payoutNameColor),
                    ),
                    Text(
                      isOnHold ? (p.holdReason ?? 'On hold') : p.shiftsInfo,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: payoutSubColor),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${_formatAmount(p.amount)}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: payoutNameColor),
                  ),
                  if (!isOnHold)
                    Text(
                      '– ${_formatAmount(p.feeAmount)} fee',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: payoutSubColor),
                    ),
                ],
              ),
            ],
          ),
          if (!isOnHold) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: releaseBtnBg,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => _releasePayout(p),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 9),
                        child: Center(
                          child: Text(
                            'Release',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: releaseBtnFg),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => _holdPayout(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: holdBtnBorder, width: 1),
                        ),
                        child: const Center(
                          child: Text(
                            'Hold',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: payoutNameColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Transactions card ────────────────────────────────────────────────────
  Widget _buildTransactionsCard() {
    final txns = _visibleTransactions;
    if (txns.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: transactionCardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: transactionCardBorder, width: 1),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Text(
          'No transactions in this view',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: transactionSubColor),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: transactionCardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: transactionCardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        children: txns.asMap().entries.map((e) {
          final isLast = e.key == txns.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: isLast ? null : const Border(bottom: BorderSide(color: transactionCardBorder, width: 1)),
            ),
            child: _buildTransactionRow(e.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionRow(FinanceTransaction t) {
    IconData icon;
    Color amountColor;
    String sign;
    switch (t.type) {
      case TransactionType.payment:
        icon = Icons.call_received_rounded;
        amountColor = paymentAmountColor;
        sign = '+';
        break;
      case TransactionType.fee:
        icon = Icons.percent_rounded;
        amountColor = feeAmountColor;
        sign = '+';
        break;
      case TransactionType.refund:
        icon = Icons.call_made_rounded;
        amountColor = refundAmountColor;
        sign = '–';
        break;
    }
    return Row(
      children: [
        Icon(icon, size: 17, color: transactionTitleColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.title,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: transactionTitleColor),
              ),
              Text(
                t.subtitle,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: transactionSubColor),
              ),
            ],
          ),
        ),
        Text(
          '$sign${_formatAmount(t.amount)}',
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: amountColor),
        ),
      ],
    );
  }

  Widget _buildReleaseAllButton() {
    return Material(
      color: ctaBtnBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _releaseAllApproved,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Center(
            child: Text(
              'Release all approved payouts',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Navigation Bar (matching Admin Dashboard) ────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.insights_rounded},
      {'label': 'Users', 'icon': Icons.people_alt_outlined},
      {'label': 'Bookings', 'icon': Icons.calendar_month_outlined},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined},
      {'label': 'More', 'icon': Icons.more_horiz_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: bottomNavBg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == 3; // Finance tab is active
          final color = isSelected ? navGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (index == 0 || index == 1 || index == 2 || index == 4) {
                Navigator.pop(context);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 22, color: color),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
