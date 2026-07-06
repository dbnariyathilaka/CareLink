import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopMatchesScreen extends StatefulWidget {
  const TopMatchesScreen({super.key});

  @override
  State<TopMatchesScreen> createState() => _TopMatchesScreenState();
}

class _TopMatchesScreenState extends State<TopMatchesScreen> {
  bool _previousExpanded = false;

  // Colours
  static const Color bkBlue = Color(0xFF058CD0);
  static const Color acceptBlue = Color(0xFF6366F1); // indigo/accent for Accept button
  static const Color starAmber = Color(0xFFF59E0B);
  static const Color declinedRed = Color(0xFFEF4444);
  static const Color reachedOutGreen = Color(0xFF22C55E);

  // Previous-5 data
  static const List<Map<String, dynamic>> _previous5 = [
    {'name': 'Alice Fernando', 'status': 'Request expired', 'statusType': 'expired'},
    {'name': 'Brian Kumara', 'status': 'Reached out to you', 'statusType': 'reached'},
    {'name': 'Carol Silva', 'status': 'Declined', 'statusType': 'declined'},
    {'name': 'David Ranasinghe', 'status': 'Request expired', 'statusType': 'expired'},
    {'name': 'Emma Nonis', 'status': 'Request expired', 'statusType': 'expired'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(),
            _buildBackRow(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildUpdatedMatchesBanner(),
                    const SizedBox(height: 14),
                    _buildFathimaCard(),
                    const SizedBox(height: 14),
                    _buildBrianReachedBackCard(),
                    const SizedBox(height: 14),
                    _buildPreviousSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status bar ────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.signal_cellular_alt, color: AppTheme.textPrimary, size: 18),
                SizedBox(width: 5),
                Icon(Icons.wifi, color: AppTheme.textPrimary, size: 18),
                SizedBox(width: 5),
                Icon(Icons.battery_full, color: AppTheme.textPrimary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Back arrow row ────────────────────────────────────────
  Widget _buildBackRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 22, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 22),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 10),
          Text(
            'Search caregivers...',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Updated matches banner ────────────────────────────────
  Widget _buildUpdatedMatchesBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Updated matches',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Your previous 5 didn't respond — here are 5 new caregivers.",
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Fathima Perera card ───────────────────────────────────
  Widget _buildFathimaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name/badge + subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green gradient avatar
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF22C55E), AppTheme.primaryGreenDark],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'FP',
                    style: TextStyle(
                      color: AppTheme.bottleGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fathima Perera',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // "New" badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'New',
                            style: TextStyle(
                              color: AppTheme.bottleGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Elder care · 6 yrs · 91% match',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          // Distance · Rating · Available
          Row(
            children: [
              const Icon(Icons.place_outlined, color: AppTheme.textSecondary, size: 14),
              const SizedBox(width: 3),
              const Text(
                '1.8 km',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.star_rounded, color: starAmber, size: 14),
              const SizedBox(width: 3),
              const Text(
                '4.9',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 14),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(3.5),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Available',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 11),
          // Request + Profile buttons
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      child: Text(
                        'Request',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.bottleGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/caregiver-profile'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Brian Kumara reached-back card ────────────────────────
  Widget _buildBrianReachedBackCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744), // dark blue-tinted background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B4F7A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name/subtitle row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: bkBlue,
                ),
                child: const Center(
                  child: Text(
                    'BK',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Brian Kumara reached back',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'One of your previous 5',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quote bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '"Hi, I just saw your care request — I\'m free now and happy to help."',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Accept + Dismiss buttons
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 11),
                        child: Text(
                          'Accept Brian',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/caregiver-profile'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF3B4F7A)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Dismiss',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Previous 5 caregivers collapsible section ─────────────
  Widget _buildPreviousSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // Header row — tap to expand/collapse
          GestureDetector(
            onTap: () => setState(() => _previousExpanded = !_previousExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Previous 5 caregivers (no response)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _previousExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible rows
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: AppTheme.borderColor),
                ..._previous5.map((entry) => _buildPreviousRow(entry)).toList(),
              ],
            ),
            crossFadeState: _previousExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousRow(Map<String, dynamic> entry) {
    Color statusColor;
    switch (entry['statusType']) {
      case 'reached':
        statusColor = reachedOutGreen;
        break;
      case 'declined':
        statusColor = declinedRed;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry['name'],
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                entry['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (entry != _previous5.last)
          const Divider(height: 1, color: AppTheme.borderColor, indent: 16, endIndent: 16),
      ],
    );
  }
}
