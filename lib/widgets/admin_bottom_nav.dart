import 'dart:ui';
import 'package:flutter/material.dart';

import '../screens/admin_bookings_screen.dart';
import '../screens/admin_content_taxonomy_screen.dart';
import '../screens/admin_finance_screen.dart';
import '../screens/admin_patients_screen.dart';
import '../screens/admin_caregivers_screen.dart';
import '../screens/admin_pricing_screen.dart';
import '../screens/admin_review_moderation_screen.dart';
import '../screens/admin_support_hub_screen.dart';

/// Which admin section is currently on screen. Drives which footer icon
/// (and, if it lives under "More", which popup tile) is highlighted.
enum AdminNavTab { dashboard, users, bookings, finance, review, pricing, support, content }

/// Shared bottom navigation bar for every admin screen. Tapping Dashboard,
/// Bookings, or Finance takes the admin straight to that screen from
/// anywhere (not just back to Dashboard), tapping Users opens the same
/// Select-User picker the dashboard uses, and tapping More opens a popup
/// grid with every admin section, reachable from every screen.
class AdminBottomNav extends StatelessWidget {
  final AdminNavTab active;

  const AdminBottomNav({super.key, required this.active});

  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);
  static const Color moreMenuBg = Color(0xFF2C251D);
  static const Color moreMenuItemBg = Color(0xFF4A4032);

  static const List<AdminNavTab> _moreTabs = [
    AdminNavTab.review,
    AdminNavTab.pricing,
    AdminNavTab.support,
    AdminNavTab.content,
  ];

  bool get _isMoreActive => _moreTabs.contains(active);

  // When one of these sections is active, the footer's last slot shows that
  // section's own icon/label instead of the generic "More" — matching
  // Figma node 643:685 (the More icon is replaced, not just relabeled).
  static const Map<AdminNavTab, (String, IconData)> _moreTabMeta = {
    AdminNavTab.review: ('Review', Icons.rate_review_outlined),
    AdminNavTab.pricing: ('Pricing', Icons.sell_outlined),
    AdminNavTab.support: ('Support', Icons.support_agent_outlined),
    AdminNavTab.content: ('Content', Icons.auto_awesome_outlined),
  };

  // Every admin screen sits directly on top of AdminDashboardScreen (it's
  // pushed with pushNamedAndRemoveUntil on login), so popping to the first
  // route always lands back on Dashboard — from there we push the target
  // screen, keeping the back stack shallow instead of stacking endlessly.
  static void _goTo(BuildContext context, Widget screen) {
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  static void navigate(BuildContext context, AdminNavTab tab) {
    switch (tab) {
      case AdminNavTab.dashboard:
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case AdminNavTab.users:
        Navigator.popUntil(context, (route) => route.isFirst);
        showSelectUserSheet(context);
        break;
      case AdminNavTab.bookings:
        _goTo(context, const AdminBookingsScreen());
        break;
      case AdminNavTab.finance:
        _goTo(context, const AdminFinanceScreen());
        break;
      case AdminNavTab.review:
        _goTo(context, const AdminReviewModerationScreen());
        break;
      case AdminNavTab.pricing:
        _goTo(context, const AdminPricingScreen());
        break;
      case AdminNavTab.support:
        _goTo(context, const AdminSupportHubScreen());
        break;
      case AdminNavTab.content:
        _goTo(context, const AdminContentTaxonomyScreen());
        break;
    }
  }

  void _openMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => SafeArea(top: false, child: _MoreMenuPanel(active: active)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moreMeta = _isMoreActive ? _moreTabMeta[active] : null;
    final items = <Map<String, dynamic>>[
      {'label': 'Dashboard', 'icon': Icons.home_rounded, 'tab': AdminNavTab.dashboard},
      {'label': 'Users', 'icon': Icons.people_alt_outlined, 'tab': AdminNavTab.users},
      {'label': 'Bookings', 'icon': Icons.event_available_outlined, 'tab': AdminNavTab.bookings},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined, 'tab': AdminNavTab.finance},
      {
        'label': moreMeta?.$1 ?? 'More',
        'icon': moreMeta?.$2 ?? Icons.more_horiz_rounded,
        'tab': null,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: bottomNavBg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final tab = item['tab'] as AdminNavTab?;
          final isSelected = tab == null ? _isMoreActive : tab == active;
          final color = isSelected ? navGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (tab == null) {
                _openMoreMenu(context);
              } else if (tab != active) {
                navigate(context, tab);
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
        }).toList(),
      ),
    );
  }

  // ── Select User popup (Figma node 683:706) ─────────────────────────────
  // Shown when the admin taps "Users" — lets them pick Patient or Caregiver
  // before drilling into the relevant user list.
  static void showSelectUserSheet(BuildContext context) {
    String selected = 'patient';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5EEE8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                  bottomLeft: Radius.circular(42),
                  bottomRight: Radius.circular(42),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    blurRadius: 25,
                    offset: Offset(0, -20),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/who_needs_care_avatar.png',
                    width: 68,
                    height: 68,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select User',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color(0xFF564732),
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select the user type who you want to find out',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color.fromRGBO(85, 73, 57, 0.63),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildUserTypeOption(
                    label: 'patient',
                    description: 'Person who use app for find a caregiver',
                    icon: Icons.self_improvement_rounded,
                    iconBg: const Color(0xFFD9BDB5),
                    iconColor: const Color(0xFF41302B),
                    cardBg: const Color(0xFFAB9089),
                    borderColor: const Color(0xFF5A413A),
                    labelColor: const Color(0xFF352D2A),
                    descColor: const Color.fromRGBO(57, 42, 27, 0.43),
                    radioColor: const Color(0xFF352D2A),
                    isSelected: selected == 'patient',
                    onTap: () => setSheetState(() => selected = 'patient'),
                  ),
                  const SizedBox(height: 12),
                  _buildUserTypeOption(
                    label: 'Caregiver',
                    description: 'Person who give service for patients',
                    icon: Icons.family_restroom_rounded,
                    iconBg: const Color.fromRGBO(133, 107, 74, 0.54),
                    iconColor: const Color(0xFF4B381F),
                    cardBg: const Color(0xFFB1A28F),
                    borderColor: const Color(0xFF44392B),
                    labelColor: const Color(0xFF4B381F),
                    descColor: const Color.fromRGBO(58, 39, 14, 0.52),
                    radioColor: const Color(0xFF4B381F),
                    isSelected: selected == 'caregiver',
                    onTap: () => setSheetState(() => selected = 'caregiver'),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (selected == 'caregiver') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminCaregiversScreen()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminPatientsScreen()),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF746553),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildUserTypeOption({
    required String label,
    required String description,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
    required Color labelColor,
    required Color descColor,
    required Color radioColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: labelColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: descColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: radioColor, width: 1.5),
                color: isSelected ? radioColor : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.circle, color: Colors.white, size: 10) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── "More" popup (Figma node 698:1456) ──────────────────────────────────
// A 2x4 grid covering every admin section, reachable from any screen.
class _MoreMenuPanel extends StatelessWidget {
  final AdminNavTab active;

  const _MoreMenuPanel({required this.active});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[
      {'label': 'Dashboard', 'icon': Icons.home_rounded, 'tab': AdminNavTab.dashboard},
      {'label': 'Users', 'icon': Icons.people_alt_outlined, 'tab': AdminNavTab.users},
      {'label': 'Bookings', 'icon': Icons.event_available_outlined, 'tab': AdminNavTab.bookings},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined, 'tab': AdminNavTab.finance},
      {'label': 'Review', 'icon': Icons.rate_review_outlined, 'tab': AdminNavTab.review},
      {'label': 'Pricing', 'icon': Icons.sell_outlined, 'tab': AdminNavTab.pricing},
      {'label': 'Support', 'icon': Icons.support_agent_outlined, 'tab': AdminNavTab.support},
      {'label': 'Content', 'icon': Icons.auto_awesome_outlined, 'tab': AdminNavTab.content},
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: AdminBottomNav.moreMenuBg.withValues(alpha: 0.96),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFB5ADA2), size: 22),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: items.sublist(0, 4).map((item) => _buildItem(context, item)).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: items.sublist(4, 8).map((item) => _buildItem(context, item)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> item) {
    final tab = item['tab'] as AdminNavTab;
    final isSelected = tab == active;
    final color = isSelected ? AdminBottomNav.navGold : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (tab != active) AdminBottomNav.navigate(context, tab);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected ? AdminBottomNav.navGold.withValues(alpha: 0.18) : AdminBottomNav.moreMenuItemBg,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: AdminBottomNav.navGold, width: 1.5) : null,
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(height: 6),
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
  }
}
