import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum _NotifCategory { booking, reminders, system }

class _NotificationData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String timeAgo;
  final String description;
  final _NotifCategory category;
  final String? primaryAction;
  final Color? primaryActionColor;
  final Color? primaryActionTextColor;
  final String? secondaryAction;

  const _NotificationData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.timeAgo,
    required this.description,
    required this.category,
    this.primaryAction,
    this.primaryActionColor,
    this.primaryActionTextColor,
    this.secondaryAction,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilter = 0;

  static const Color _amber = Color(0xFFF59E0B);
  static const Color _cerulean = Color(0xFF0EA5E9);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _red = Color(0xFFEF4444);
  static const Color _teal = Color(0xFF14B8A6);

  static const List<String> _filters = ['All 7', 'Booking', 'Reminders', 'System'];

  static final List<_NotificationData> _notifications = [
    _NotificationData(
      icon: Icons.alarm_rounded,
      accentColor: _amber,
      title: 'Appointment reminder',
      timeAgo: '1h',
      description: 'Alice starts tomorrow at 8:00 AM.',
      category: _NotifCategory.reminders,
    ),
    _NotificationData(
      icon: Icons.check_circle_rounded,
      accentColor: AppTheme.primaryGreen,
      title: 'Booking accepted',
      timeAgo: '2h',
      description: 'Alice Fernando accepted your request.',
      category: _NotifCategory.booking,
      primaryAction: 'View booking',
      primaryActionColor: AppTheme.primaryGreen,
      primaryActionTextColor: AppTheme.bottleGreen,
      secondaryAction: 'Message Alice',
    ),
    _NotificationData(
      icon: Icons.chat_bubble_rounded,
      accentColor: _indigo,
      title: 'Caregiver reached out',
      timeAgo: '3h',
      description: '"Brian Kumara: I\'m free now, can I help?"',
      category: _NotifCategory.booking,
      primaryAction: 'Accept Brian',
      primaryActionColor: _indigo,
      primaryActionTextColor: Colors.white,
      secondaryAction: 'Dismiss',
    ),
    _NotificationData(
      icon: Icons.cancel_rounded,
      accentColor: _red,
      title: 'Request declined',
      timeAgo: '5h',
      description: "Carol Silva can't take this booking.",
      category: _NotifCategory.booking,
      secondaryAction: 'Try next caregiver',
    ),
    _NotificationData(
      icon: Icons.groups_rounded,
      accentColor: _teal,
      title: 'New top 5 found',
      timeAgo: '1d',
      description: 'Your dashboard has been refreshed.',
      category: _NotifCategory.system,
    ),
  ];

  List<_NotificationData> get _filtered {
    if (_selectedFilter == 0) return _notifications;
    final map = {
      1: _NotifCategory.booking,
      2: _NotifCategory.reminders,
      3: _NotifCategory.system,
    };
    final type = map[_selectedFilter];
    return _notifications.where((n) => n.category == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                itemCount: _filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildNotificationCard(_filtered[i]),
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
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.signal_cellular_alt, color: AppTheme.textPrimary, size: 18),
                SizedBox(width: 5),
                Icon(Icons.wifi, color: AppTheme.textPrimary, size: 18),
                SizedBox(width: 5),
                Icon(Icons.battery_full, color: AppTheme.textPrimary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────
  Widget _buildFilterChips() {
    final chipColors = [AppTheme.primaryGreen, _amber, _cerulean, null];
    return SizedBox(
      height: 27,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final selected = i == _selectedFilter;
          final color = chipColors[i];
          final isPlainSelected = i == 0 && selected;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isPlainSelected ? 11 : 12, vertical: isPlainSelected ? 6 : 7),
              decoration: BoxDecoration(
                color: isPlainSelected
                    ? AppTheme.primaryGreen
                    : color != null
                        ? color.withValues(alpha: 0.15)
                        : AppTheme.cardColor,
                border: isPlainSelected
                    ? null
                    : Border.all(
                        color: color != null ? color.withValues(alpha: 0.4) : AppTheme.borderColor,
                      ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    color: isPlainSelected
                        ? AppTheme.bottleGreen
                        : color ?? AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Notification card ─────────────────────────────────────
  Widget _buildNotificationCard(_NotificationData data) {
    final hasActions = data.primaryAction != null || data.secondaryAction != null;
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
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.description,
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
              child: Row(
                children: [
                  if (data.primaryAction != null)
                    Material(
                      color: data.primaryActionColor,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          child: Text(
                            data.primaryAction!,
                            style: TextStyle(
                              color: data.primaryActionTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (data.primaryAction != null && data.secondaryAction != null)
                    const SizedBox(width: 8),
                  if (data.secondaryAction != null)
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {},
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Bottom nav (matches dashboard) ────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    const selectedIndex = 3; // Alerts tab always active on this screen

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
          final color = isSelected ? AppTheme.primaryGreen : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/patient-dashboard'));
              } else if (index == 1) {
                Navigator.pushNamed(context, '/search');
              } else if (index == 2) {
                Navigator.pushNamed(context, '/my-bookings');
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
