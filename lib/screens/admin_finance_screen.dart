import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/status_bar.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  // ── Color Tokens matching Figma node 646:752 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color emptyStateIconColor = Color(0xFF8B7C64);
  static const Color emptyStateTitleColor = Color(0xFF44331C);
  static const Color emptyStateBodyColor = Color(0xFF655443);


  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildEmptyState()),
            const AdminBottomNav(active: AdminNavTab.finance),
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
                const SnackBar(
                  content: Text('Nothing to export — billing isn\'t implemented in this app yet.'),
                  duration: Duration(seconds: 2),
                ),
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

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 48, color: emptyStateIconColor),
            const SizedBox(height: 14),
            const Text(
              'No financial data yet',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: emptyStateTitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Billing isn\'t implemented in this app yet, so there are no payouts, transactions, or revenue figures to show.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w500, color: emptyStateBodyColor, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
