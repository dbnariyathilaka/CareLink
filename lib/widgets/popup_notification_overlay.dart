import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/popup_notification_service.dart';

/// Global "new notification" toast — sits above whatever screen is
/// current (mounted once via MaterialApp.builder, not per-screen), shows a
/// card at the top for 5 seconds and auto-dismisses. Tapping it opens the
/// role-appropriate notifications screen; letting it time out leaves the
/// current screen untouched. Re-subscribes on every auth change, so a
/// caregiver/patient logging back in after being signed out when an event
/// happened sees it pop up immediately — PopupNotificationService's cursor
/// is server-side, not tied to this widget's lifetime.
class PopupNotificationOverlay extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const PopupNotificationOverlay({super.key, required this.navigatorKey});

  @override
  State<PopupNotificationOverlay> createState() => _PopupNotificationOverlayState();
}

class _PopupNotificationOverlayState extends State<PopupNotificationOverlay> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<PopupNotification>? _popupSub;
  String? _uid;
  String? _role;
  PopupNotification? _current;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  Future<void> _onAuthChanged(User? user) async {
    _popupSub?.cancel();
    _popupSub = null;
    _dismissTimer?.cancel();
    _uid = null;
    _role = null;
    if (mounted) setState(() => _current = null);
    if (user == null) return;

    final profile = await AuthService.getUserProfile(user.uid);
    // Bail if auth changed again while that lookup was in flight.
    if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) return;

    final role = profile?['role'] as String?;
    _uid = user.uid;
    _role = role;
    if (role == 'caregiver') {
      _popupSub = PopupNotificationService.caregiverPopups(user.uid).listen(_show);
    } else if (role == 'patient') {
      _popupSub = PopupNotificationService.patientPopups(user.uid).listen(_show);
    }
  }

  void _show(PopupNotification notif) {
    if (!mounted || _uid == null) return;
    PopupNotificationService.markShown(_uid!, notif.timestamp);
    _dismissTimer?.cancel();
    setState(() => _current = notif);
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _current = null);
    });
  }

  void _onTap() {
    final role = _role;
    _dismissTimer?.cancel();
    setState(() => _current = null);
    widget.navigatorKey.currentState?.pushNamed(
      role == 'caregiver' ? '/caregiver-notifications' : '/notifications',
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _popupSub?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notif = _current;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: IgnorePointer(
          ignoring: notif == null,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            offset: notif == null ? const Offset(0, -1.3) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: notif == null ? 0 : 1,
              child: notif == null ? const SizedBox(height: 1) : _card(notif),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(PopupNotification notif) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1F3554),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: Color(0xFFFBBC05), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_rounded, color: Color(0xFF1F3554), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notif.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: Color(0xFFCBD5E1),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
