import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/status_bar.dart';

class AdminPricingScreen extends StatefulWidget {
  const AdminPricingScreen({super.key});

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  // ── Color Tokens matching Figma node 646:854 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);
  static const Color sectionLabelColor = Colors.black;

  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF493D2A);

  static const Color infoTextColor = Color(0xFF44331C);
  static const Color infoSubTextColor = Color(0xFF745A45);


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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('MATCHING ALGORITHM'),
                    const SizedBox(height: 9),
                    _buildInfoCard(
                      icon: Icons.balance_rounded,
                      title: 'Equal weighting — no per-criterion configuration',
                      body:
                          'Matching currently uses equal weighting across whichever criteria are active for a match — skill match, proximity, availability, and gender preference — with weights automatically redistributed when a caregiver has no data for a criterion. There is no "rating" criterion, and there are no adjustable per-criterion percentages today.',
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel('MATCHING & PRICING SETTINGS'),
                    const SizedBox(height: 9),
                    _buildInfoCard(
                      icon: Icons.tune_rounded,
                      title: 'Not yet connected to real behavior',
                      body:
                          'Search radius, minimum rating, request-expiry window, platform fee, minimum hourly rate, and surcharges are not backed by a configuration system in this app yet. There is nothing here to edit or save.',
                    ),
                  ],
                ),
              ),
            ),
            const AdminBottomNav(active: AdminNavTab.pricing),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 12, 22, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Matching & pricing',
              style: TextStyle(fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w800, color: titleColor),
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

  // ── Static info panel (replaces the fake weight sliders / config rows) ──
  Widget _buildInfoCard({required IconData icon, required String title, required String body}) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: infoTextColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: infoTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: infoSubTextColor, height: 1.45),
          ),
        ],
      ),
    );
  }

}
