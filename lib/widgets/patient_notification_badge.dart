import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_badge_service.dart';

/// Wraps a patient-side bottom nav's Notification icon with the real
/// unread-count badge (see NotificationBadgeService) — never a fixed/fake
/// number, and hidden entirely at 0. Each patient screen currently draws
/// its own bottom nav rather than sharing one widget, so this is dropped
/// into each of them individually rather than requiring a bigger refactor.
class PatientNotificationIconWithBadge extends StatelessWidget {
  final Widget icon;
  final Color badgeBorderColor;

  const PatientNotificationIconWithBadge({
    super.key,
    required this.icon,
    required this.badgeBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return icon;

    return StreamBuilder<int>(
      stream: NotificationBadgeService.patientUnreadCount(uid),
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
                    border: Border.all(color: badgeBorderColor, width: 1.5),
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
