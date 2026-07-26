import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../app_state.dart';
import '../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Text(
                'Notifications',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                message: 'No notifications yet.',
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav (matches dashboard) ────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: null, label: 'Match'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
    ];
    const selectedIndex = 4; // Alerts tab always active on this screen

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          if (index == 2) {
            return GestureDetector(
              onTap: () {
                if (AppState.hasActiveMatch.value) {
                  Navigator.pushNamed(context, '/advanced-match-results');
                } else {
                  Navigator.pushNamed(context, '/advanced-match-send-request');
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01D3A8), // Caribbean Green
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF01D3A8).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: Color(0xFF06240F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Match',
                    style: TextStyle(
                      color: Color(0xFF01D3A8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }

          final color = isSelected ? AppTheme.primaryGreen : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/patient-dashboard'));
              } else if (index == 1) {
                Navigator.pushNamed(context, '/search');
              } else if (index == 3) {
                Navigator.pushNamed(context, '/my-bookings');
              }
            },
            child: SizedBox(
              width: 60,
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
            ),
          );
        }),
      ),
    );
  }
}
