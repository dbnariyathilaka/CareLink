import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() =>
      _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedNavIndex = 0;

  // Colors used only on this screen (from Figma)
  static const Color emergencyRedStart = Color(0xFFEF4444); // red/60
  static const Color emergencyRedEnd = Color(0xFFDC2626); // red/51
  static const Color blueAvatarStart = Color(0xFF0EA5E9); // azure/48
  static const Color blueAvatarEnd = Color(0xFF0284C7); // azure/39
  static const Color starAmber = Color(0xFFF59E0B); // Buttercup

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmergencyBanner(),
                    const SizedBox(height: 12),
                    _buildStatsRow(),
                    const SizedBox(height: 6),
                    _buildSectionHeader(),
                    const SizedBox(height: 12),
                    _buildMatchCard(
                      initials: 'AF',
                      avatarGradient: const [
                        AppTheme.primaryGreen,
                        AppTheme.primaryGreenDark,
                      ],
                      name: 'Alice Fernando',
                      matchScore: '92%',
                      subtitle: 'Elder care · 7 yrs exp',
                      tags: const ['Mobility', 'Medication', 'Dementia'],
                      distance: '2.3 km',
                      rating: '4.8',
                      available: true,
                      expanded: true,
                    ),
                    const SizedBox(height: 12),
                    _buildMatchCard(
                      initials: 'BK',
                      avatarGradient: const [blueAvatarStart, blueAvatarEnd],
                      name: 'Brian Kumara',
                      matchScore: '88%',
                      subtitle: 'Post-surgery · 5 yrs exp',
                      tags: const [],
                      distance: '',
                      rating: '',
                      available: false,
                      expanded: false,
                    ),
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

  // ── Header: greeting + avatar + search bar ──────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.3, -1),
          end: Alignment(0.3, 1),
          colors: [
            AppTheme.primaryGreenDark, // #16A34A
            Color(0xFF15803D), // spring-green/29
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Nipuni 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'NA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Search caregivers…',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Emergency banner ─────────────────────────────────────
  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [emergencyRedStart, emergencyRedEnd],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.white,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency — find a caregiver now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Top 3 nearest available caregivers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ── Stats row: match score + available now ───────────────
  Widget _buildStatsRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statCard('Your match score', '85%', greenValue: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard('Available now', '12', caption: 'near you'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value, {
    String? caption,
    bool greenValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: greenValue ? AppTheme.primaryGreen : AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── "Top matches for you" section header ─────────────────
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Top matches for you',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'See all',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Caregiver match card ──────────────────────────────────
  Widget _buildMatchCard({
    required String initials,
    required List<Color> avatarGradient,
    required String name,
    required String matchScore,
    required String subtitle,
    required List<String> tags,
    required String distance,
    required String rating,
    required bool available,
    required bool expanded,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: avatarGradient,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: expanded ? AppTheme.bottleGreen : Colors.white,
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
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            matchScore,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
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
          if (expanded) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) => _buildTagChip(tag)).toList(),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: AppTheme.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  distance,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.star_rounded, color: starAmber, size: 14),
                const SizedBox(width: 3),
                Text(
                  rating,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  available ? 'Available' : 'Unavailable',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
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
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {},
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
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Bottom navigation bar ─────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == _selectedNavIndex;
          final color = isSelected
              ? AppTheme.primaryGreen
              : const Color(0xFF64748B);
          return GestureDetector(
            onTap: () => setState(() => _selectedNavIndex = index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
