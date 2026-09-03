import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_badge_service.dart';

enum CaregiverNavTab { home, booking, notification, schedule }

class CaregiverBottomNav extends StatelessWidget {
  final CaregiverNavTab? activeTab;

  const CaregiverBottomNav({
    super.key,
    this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    const Color navBg = Color(0xFF1F3554);
    const Color activeColor = Color(0xFFFBBC05);
    const Color inactiveColor = Colors.white;

    final items = [
      (
        tab: CaregiverNavTab.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        route: '/caregiver-dashboard',
      ),
      (
        tab: CaregiverNavTab.booking,
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: 'Booking',
        route: '/caregiver-bookings',
      ),
      (
        tab: CaregiverNavTab.notification,
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        label: 'Notification',
        route: '/caregiver-notifications',
      ),
      (
        tab: CaregiverNavTab.schedule,
        icon: Icons.schedule_rounded,
        activeIcon: Icons.schedule_rounded,
        label: 'Schedule',
        route: '/caregiver-schedule',
      ),
    ];

    final uid = AuthService.currentUser?.uid;

    return Container(
      decoration: const BoxDecoration(
        color: navBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 67,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              final isSelected = activeTab == item.tab;
              final color = isSelected ? activeColor : inactiveColor;
              final icon = Icon(
                isSelected ? item.activeIcon : item.icon,
                color: color,
                size: 24,
              );
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isSelected) return;
                    if (item.tab == CaregiverNavTab.home) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/caregiver-dashboard',
                        (route) => false,
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, item.route);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      (item.tab == CaregiverNavTab.notification && uid != null)
                          ? _NotificationIconWithBadge(uid: uid, icon: icon)
                          : icon,
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Real unread count (see NotificationBadgeService) shown in red above the
/// bell — never a fixed/fake number, and hidden entirely at 0.
class _NotificationIconWithBadge extends StatefulWidget {
  final String uid;
  final Widget icon;
  const _NotificationIconWithBadge({required this.uid, required this.icon});

  @override
  State<_NotificationIconWithBadge> createState() => _NotificationIconWithBadgeState();
}

class _NotificationIconWithBadgeState extends State<_NotificationIconWithBadge> {
  // Created once per mount rather than inline in build() — this widget
  // lives inside CaregiverBottomNav, which every caregiver screen rebuilds
  // often (timers, stream updates elsewhere on the same screen); recreating
  // the stream on each of those rebuilds meant spinning up 3 fresh Firestore
  // listeners (users/{uid}, bookings, reviews) every time, all left for
  // StreamBuilder to reconcile away — multiplying exactly the kind of
  // still-live listener that errors loudly if logout revokes the auth
  // token while one of them hasn't been torn down yet.
  late final Stream<int> _unreadCount = NotificationBadgeService.caregiverUnreadCount(widget.uid);

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    return StreamBuilder<int>(
      stream: _unreadCount,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            icon,
            if (count > 0)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF1F3554), width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
