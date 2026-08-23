import 'package:flutter/material.dart';

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
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: color,
                        size: 24,
                      ),
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
