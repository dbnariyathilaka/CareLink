import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Patient My Profile Screen
//  Figma node: 160-1861
// ─────────────────────────────────────────────────────────────
class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  // ── Figma colour tokens ──────────────────────────────────
  static const Color _green45   = AppTheme.primaryGreen;   // #22C55E
  static const Color _green36   = AppTheme.primaryGreenDark;// #16A34A
  static const Color _green8    = AppTheme.bottleGreen;    // #06240F
  static const Color _azure11   = AppTheme.surfaceColor;   // #0F172A
  static const Color _azure17   = AppTheme.cardColor;      // #1E293B
  static const Color _azure27   = AppTheme.borderColor;    // #334155
  static const Color _azure47   = Color(0xFF64748B);
  static const Color _azure65   = AppTheme.textSecondary;  // #94A3B8
  static const Color _grey98    = AppTheme.textPrimary;    // #F8FAFC
  static const Color _red44     = Color(0xFFEF4444);       // heart icon

  static const Color _greenBadgeBg = Color(0x26227C55E);   // green 15%

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeaderSection(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 12),
                          _buildSectionLabel('Care requirements'),
                          const SizedBox(height: 8),
                          _buildCareRequirementsCard(),
                          const SizedBox(height: 12),
                          _buildSectionLabel('Favourite caregivers'),
                          const SizedBox(height: 8),
                          _buildFavouriteCard(context),
                          const SizedBox(height: 10),
                          _buildMenuList(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
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
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: _grey98,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.signal_cellular_alt, color: _grey98, size: 18),
                SizedBox(width: 5),
                Icon(Icons.wifi, color: _grey98, size: 18),
                SizedBox(width: 5),
                Icon(Icons.battery_full, color: _grey98, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: title + avatar + name + badge ────────────────
  Widget _buildHeaderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      child: Column(
        children: [
          // "My profile" title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My profile',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.settings_outlined,
                  color: _grey98,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_green45, _green36],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'NA',
                    style: TextStyle(
                      color: _green8,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Edit badge
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _azure17,
                    shape: BoxShape.circle,
                    border: Border.all(color: _azure11, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: _green45,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Name
          const Text(
            'Nipuni Ariyathilaka',
            style: TextStyle(
              color: _grey98,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // Email · Phone
          const Text(
            'nipuni@email.com · +94 77 123 4567',
            style: TextStyle(
              color: _azure65,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // "Patient / Family account" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _green45.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_rounded, color: _green45, size: 15),
                SizedBox(width: 5),
                Text(
                  'Patient / Family account',
                  style: TextStyle(
                    color: _green45,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row: Bookings · Reviews given · Favourite ──────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('3', 'Bookings')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('2', 'Reviews given')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('1', 'Favourite')),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _azure27),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _grey98,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _azure65,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _azure65,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Care requirements card ────────────────────────────────
  Widget _buildCareRequirementsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _azure27),
      ),
      child: Column(
        children: [
          _requirementRow('Care type', 'Elder care · Full-time', divider: true),
          _requirementRow('Location', 'Negombo, Western Province', divider: true),
          _requirementRow('Preferred gender', 'No preference', divider: false),
          const SizedBox(height: 10),
          // Edit link
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Edit requirements',
              style: TextStyle(
                color: _green45,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementRow(String label, String value, {required bool divider}) {
    return Container(
      height: 35,
      decoration: divider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _azure27, width: 1),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _azure65,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _grey98,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Favourite caregiver card ──────────────────────────────
  Widget _buildFavouriteCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _azure27),
      ),
      child: Row(
        children: [
          // Green avatar
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_green45, _green36],
              ),
            ),
            child: const Center(
              child: Text(
                'AF',
                style: TextStyle(
                  color: _green8,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Alice Fernando',
                  style: TextStyle(
                    color: _grey98,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Elder care · ★4.8',
                  style: TextStyle(
                    color: _azure65,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Heart icon (favourited = filled red)
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.favorite_rounded,
              color: _red44,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu list rows ────────────────────────────────────────
  Widget _buildMenuList(BuildContext context) {
    return Column(
      children: [
        _menuRow(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Messages',
          badge: '2',
          onTap: () => Navigator.pushNamed(context, '/messages'),
        ),
        const SizedBox(height: 9),
        _menuRow(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () {},
        ),
        const SizedBox(height: 9),
        _menuRow(
          icon: Icons.help_outline_rounded,
          label: 'Help & FAQ',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _azure27),
        ),
        child: Row(
          children: [
            Icon(icon, color: _green45, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _grey98,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: _green45,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: _green8,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, color: _azure65, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav (Profile tab active) ──────────────────────
  Widget _buildBottomNav(BuildContext context) {
    const items = [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.search_rounded, 'Search'),
      _NavItem(Icons.calendar_month_rounded, 'Bookings'),
      _NavItem(Icons.notifications_none_rounded, 'Alerts'),
      _NavItem(Icons.person_rounded, 'Profile'),
    ];
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: _azure11,
        border: Border(top: BorderSide(color: _azure27)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isActive = i == 4; // Profile is active
          final color = isActive ? _green45 : _azure47;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (i == 0) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/patient-dashboard', (r) => false);
              } else if (i == 1) {
                Navigator.pushNamed(context, '/search');
              } else if (i == 2) {
                Navigator.pushNamed(context, '/my-bookings');
              } else if (i == 3) {
                Navigator.pushNamed(context, '/notifications');
              }
              // i == 4 → already here
            },
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
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
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

// ── Nav item model ────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
