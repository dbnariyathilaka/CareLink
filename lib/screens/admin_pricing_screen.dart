import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import 'admin_bookings_screen.dart';
import 'admin_finance_screen.dart';

class AlgorithmWeight {
  final String label;
  double percent; // 0-100
  AlgorithmWeight({required this.label, required this.percent});
}

class ConfigRow {
  final String label;
  final String value;
  final Color valueColor;
  const ConfigRow({required this.label, required this.value, required this.valueColor});
}

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

  static const Color sliderLabelColor = Color(0xFF745A45);
  static const Color sliderValueColor = Color(0xFF666666);
  static const Color sliderTrackInactive = Color(0x80517146);
  static const Color sliderTrackActive = Color(0xFF376A3D);
  static const Color sliderThumb = Color(0xFFBEF2C3);

  static const Color rowDivider = Color(0x4D334155);
  static const Color rowLabelColor = Color(0xFF745A45);
  static const Color rowValueLight = Color(0xFFFFEFD7);
  static const Color rowValueOrange = Color(0xFFBC6522);

  static const Color saveBtnBg = Color(0xFF44331C);

  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  final List<AlgorithmWeight> _weights = [
    AlgorithmWeight(label: 'Care specialisation', percent: 40),
    AlgorithmWeight(label: 'Proximity', percent: 25),
    AlgorithmWeight(label: 'Rating & feedback', percent: 20),
    AlgorithmWeight(label: 'Availability', percent: 15),
  ];

  static const List<ConfigRow> _matchingSettings = [
    ConfigRow(label: 'Default search radius', value: '15 km', valueColor: rowValueLight),
    ConfigRow(label: 'Minimum caregiver rating', value: '4.0 ★', valueColor: rowValueLight),
    ConfigRow(label: 'Request expiry window', value: '6 hours', valueColor: rowValueLight),
  ];

  static const List<ConfigRow> _ratesAndFees = [
    ConfigRow(label: 'Platform fee', value: '12.5%', valueColor: rowValueLight),
    ConfigRow(label: 'Minimum hourly rate', value: 'LKR 650', valueColor: rowValueLight),
    ConfigRow(label: 'Emergency surcharge', value: '+25%', valueColor: rowValueOrange),
    ConfigRow(label: 'Night rate (10 PM–6 AM)', value: '+15%', valueColor: rowValueOrange),
    ConfigRow(label: 'Public holiday rate', value: '+30%', valueColor: rowValueOrange),
  ];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  void _saveConfiguration() {
    final total = _weights.fold<double>(0, (sum, w) => sum + w.percent);
    if ((total - 100).abs() > 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Algorithm weights add up to ${total.round()}% — adjust to total 100% before saving.'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Matching & pricing configuration saved.'), duration: Duration(seconds: 2)),
    );
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('ALGORITHM WEIGHTS'),
                    const SizedBox(height: 9),
                    _buildWeightsCard(),
                    const SizedBox(height: 16),
                    _buildConfigCard(_matchingSettings),
                    const SizedBox(height: 16),
                    _buildSectionLabel('RATES & FEES'),
                    const SizedBox(height: 9),
                    _buildConfigCard(_ratesAndFees),
                    const SizedBox(height: 16),
                    _buildSaveButton(),
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

  // ── Algorithm weights card ──────────────────────────────────────────────
  Widget _buildWeightsCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: List.generate(_weights.length, (i) {
          final w = _weights[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == _weights.length - 1 ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      w.label,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: sliderLabelColor),
                    ),
                    Text(
                      '${w.percent.round()}%',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: sliderValueColor),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    activeTrackColor: sliderTrackActive,
                    inactiveTrackColor: sliderTrackInactive,
                    thumbColor: sliderThumb,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: w.percent,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) => setState(() => w.percent = v),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Generic label/value config card ─────────────────────────────────────
  Widget _buildConfigCard(List<ConfigRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : const Border(bottom: BorderSide(color: rowDivider, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.value.label,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w600, color: rowLabelColor),
                ),
                Text(
                  e.value.value,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: e.value.valueColor),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Material(
      color: saveBtnBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _saveConfiguration,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Center(
            child: Text(
              'Save configuration',
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
          final isSelected = index == 4; // More tab is active (Pricing lives under More)
          final color = isSelected ? navGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (index == 0 || index == 1 || index == 4) {
                Navigator.pop(context);
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
                );
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
