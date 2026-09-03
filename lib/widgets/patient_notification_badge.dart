import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_badge_service.dart';

/// Wraps a patient-side bottom nav's Notification icon with the real
/// unread-count badge (see NotificationBadgeService) — never a fixed/fake
/// number, and hidden entirely at 0. Each patient screen currently draws
/// its own bottom nav rather than sharing one widget, so this is dropped
/// into each of them individually rather than requiring a bigger refactor.
class PatientNotificationIconWithBadge extends StatefulWidget {
  final Widget icon;
  final Color badgeBorderColor;

  const PatientNotificationIconWithBadge({
    super.key,
    required this.icon,
    required this.badgeBorderColor,
  });

  @override
  State<PatientNotificationIconWithBadge> createState() => _PatientNotificationIconWithBadgeState();
}

class _PatientNotificationIconWithBadgeState extends State<PatientNotificationIconWithBadge> {
  // Created once per mount, not inline in build() — every patient screen
  // draws its own bottom nav (no shared widget on this side), so recreating
  // the stream on each rebuild meant a fresh pair of Firestore listeners
  // (users/{uid}, bookings) spun up repeatedly across many screens at once,
  // which is exactly the kind of still-live listener that throws a
  // permission-denied error if logout revokes the auth token before one of
  // them has been torn down.
  String? _uid;
  Stream<int>? _unreadCount;

  @override
  void initState() {
    super.initState();
    _uid = AuthService.currentUser?.uid;
    if (_uid != null) {
      _unreadCount = NotificationBadgeService.patientUnreadCount(_uid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final badgeBorderColor = widget.badgeBorderColor;
    if (_unreadCount == null) return icon;

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
