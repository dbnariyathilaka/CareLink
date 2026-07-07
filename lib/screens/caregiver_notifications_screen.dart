import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _CaregiverNotifData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String timeAgo;
  final Color timeColor;
  final String? description;
  final InlineSpan? richDescription;
  final String? primaryAction;
  final String? secondaryAction;
  final String? soloAction;

  const _CaregiverNotifData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.timeAgo,
    required this.timeColor,
    this.description,
    this.richDescription,
    this.primaryAction,
    this.secondaryAction,
    this.soloAction,
  });
}

// ─────────────────────────────────────────────────────────────
//  Caregiver Notifications Screen
//  Figma node: 46-4739
// ─────────────────────────────────────────────────────────────
class CaregiverNotificationsScreen extends StatelessWidget {
  const CaregiverNotificationsScreen({super.key});

  static const Color _indigo = Color(0xFF6366F1);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _cyan = Color(0xFF0EA5E9);
  static const Color _red = Color(0xFFEF4444);

  static const List<_CaregiverNotifData> _notifications = [
    _CaregiverNotifData(
      icon: Icons.event_note_rounded,
      accentColor: _indigo,
      title: 'New booking request',
      timeAgo: '5h 42m',
      timeColor: _amber,
      description: 'Nipuni Ariyathilaka · Full-time elder care',
      primaryAction: 'Accept',
      secondaryAction: 'Decline',
    ),
    _CaregiverNotifData(
      icon: Icons.check_circle_rounded,
      accentColor: AppTheme.primaryGreen,
      title: 'Booking confirmed',
      timeAgo: '2h',
      timeColor: Color(0xFF64748B),
      description: 'Kamal Perera accepted your reach-back.',
      primaryAction: 'View booking',
      secondaryAction: 'Message patient',
    ),
    _CaregiverNotifData(
      icon: Icons.alarm_rounded,
      accentColor: _cyan,
      title: 'Appointment reminder',
      timeAgo: '4h',
      timeColor: Color(0xFF64748B),
      description: 'Your job starts tomorrow.',
    ),
    _CaregiverNotifData(
      icon: Icons.warning_amber_rounded,
      accentColor: _amber,
      title: 'Missed request',
      timeAgo: '1h 42m',
      timeColor: _amber,
      description: 'Reach-back window closes soon.',
      soloAction: 'Send reach-back message',
    ),
    _CaregiverNotifData(
      icon: Icons.cancel_rounded,
      accentColor: _red,
      title: 'Booking cancelled',
      timeAgo: '1d',
      timeColor: Color(0xFF64748B),
      description: 'Sunil Mendis cancelled the booking.',
    ),
    _CaregiverNotifData(
      icon: Icons.star_rounded,
      accentColor: _amber,
      title: 'New review',
      timeAgo: '2d',
      timeColor: Color(0xFF64748B),
      richDescription: TextSpan(
        children: [
          TextSpan(
            text: 'Kamal Perera gave you 5 stars. ',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: 'View review',
            style: TextStyle(
              color: _indigo,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
    _CaregiverNotifData(
      icon: Icons.account_balance_wallet_rounded,
      accentColor: AppTheme.primaryGreen,
      title: 'Payment received',
      timeAgo: '3d',
      timeColor: Color(0xFF64748B),
      description: 'LKR 12,000 has been paid out.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: _indigo,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildNotificationCard(context, _notifications[i]),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Notification card ─────────────────────────────────────
  Widget _buildNotificationCard(BuildContext context, _CaregiverNotifData data) {
    final hasActions = data.primaryAction != null || data.soloAction != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 13, 13, 13),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          top: BorderSide(color: data.accentColor),
          right: BorderSide(color: data.accentColor),
          bottom: BorderSide(color: data.accentColor),
          left: BorderSide(color: data.accentColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, color: data.accentColor, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          data.timeAgo,
                          style: TextStyle(
                            color: data.timeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (data.richDescription != null)
                      RichText(text: data.richDescription!)
                    else
                      Text(
                        data.description ?? '',
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
          if (hasActions) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 33),
              child: data.soloAction != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _indigo),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () => _showComingSoon(context, data.soloAction!),
                        child: Text(
                          data.soloAction!,
                          style: const TextStyle(
                            color: _indigo,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Material(
                          color: _indigo,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showComingSoon(context, data.primaryAction!),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              child: Text(
                                data.primaryAction!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (data.secondaryAction != null) ...[
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showComingSoon(context, data.secondaryAction!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data.secondaryAction!,
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action coming soon!')),
    );
  }

  // ── Bottom nav (Alerts tab active) ────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.calendar_month_rounded, label: 'Schedule'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    const selectedIndex = 2;

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
          final isSelected = index == selectedIndex;
          final color = isSelected ? _indigo : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/caregiver-dashboard'));
              } else if (index == 1) {
                Navigator.pushNamed(context, '/caregiver-schedule');
              } else if (index != 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.label} coming soon!')),
                );
              }
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
