import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../app_state.dart';

enum _NotifCategory { booking, reminders, system }

class _NotificationData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String timeAgo;
  final String? description;
  final _NotifCategory category;
  final String? primaryAction;
  final Color? primaryActionColor;
  final Color? primaryActionTextColor;
  final String? secondaryAction;
  final Color? secondaryActionTextColor;

  const _NotificationData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.timeAgo,
    this.description,
    required this.category,
    this.primaryAction,
    this.primaryActionColor,
    this.primaryActionTextColor,
    this.secondaryAction,
    this.secondaryActionTextColor,
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
  static const Color _teal = Color(0xFF01D3A8); // Caribbean Green — Match brand accent
  static const Color _tealActionText = Color(0xFF06231D);
  static const Color _dismissText = Color(0xFF94A3B8);

  List<String> get _filters => [
        'All ${_notifications.length}',
        'Booking',
        'Reminders',
        'System',
      ];

  static final List<_NotificationData> _notifications = [
    _NotificationData(
      icon: Icons.event_busy_rounded,
      accentColor: _red,
      title: 'Shift cancelled by caregiver',
      timeAgo: 'Now',
      description: "Nipuni Ariyathilaka cancelled today's 7:00 PM – 9:00 PM "
          "visit. We can help you find a replacement.",
      category: _NotifCategory.booking,
      primaryAction: 'Find replacement',
      primaryActionColor: _teal,
      primaryActionTextColor: _tealActionText,
      secondaryAction: 'View booking',
    ),
    _NotificationData(
      icon: Icons.play_circle_rounded,
      accentColor: _teal,
      title: 'Shift starting soon',
      timeAgo: 'Now',
      description: "Alice Fernando's visit starts at 8:00 AM. She's on her way.",
      category: _NotifCategory.booking,
      primaryAction: 'Track caregiver',
      primaryActionColor: _teal,
      primaryActionTextColor: _tealActionText,
      secondaryAction: 'Message',
    ),
    _NotificationData(
      icon: Icons.alarm_rounded,
      accentColor: _amber,
      title: 'Shift ending soon',
      timeAgo: '15m',
      description: "Nipuni Ariyathilaka's today 7:00 PM – 9:00 PM visit is "
          "ending soon. Extend the time or let it wrap up.",
      category: _NotifCategory.reminders,
      primaryAction: 'Extend time',
      primaryActionColor: _teal,
      primaryActionTextColor: _tealActionText,
      secondaryAction: 'View details',
    ),
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
      icon: Icons.waving_hand_rounded,
      accentColor: _indigo,
      title: 'Caregiver reached out',
      timeAgo: '3h',
      description: 'Brian Kumara: "I\'m free now, can I help?"',
      category: _NotifCategory.booking,
      primaryAction: 'Accept Brian',
      primaryActionColor: _indigo,
      primaryActionTextColor: Colors.white,
      secondaryAction: 'Dismiss',
      secondaryActionTextColor: _dismissText,
    ),
    _NotificationData(
      icon: Icons.cancel_rounded,
      accentColor: _red,
      title: 'Request declined',
      timeAgo: '5h',
      category: _NotifCategory.booking,
    ),
    _NotificationData(
      icon: Icons.task_alt_rounded,
      accentColor: AppTheme.primaryGreen,
      title: 'Caregiver checked in',
      timeAgo: '1d',
      description: 'Alice Fernando checked in for her scheduled visit.',
      category: _NotifCategory.booking,
    ),
    _NotificationData(
      icon: Icons.groups_rounded,
      accentColor: _teal,
      title: 'New top 5 matches found',
      timeAgo: '1d',
      description: 'Your dashboard has been refreshed with new caregiver matches.',
      category: _NotifCategory.system,
    ),
    _NotificationData(
      icon: Icons.summarize_rounded,
      accentColor: _cerulean,
      title: 'Weekly care summary ready',
      timeAgo: '2d',
      description: "Review last week's visits, notes, and ratings.",
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
                itemBuilder: (ctx, i) => _buildNotificationCard(ctx, _filtered[i]),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }



  // ── Filter chips ──────────────────────────────────────────
  Widget _buildFilterChips() {
    final chipColors = [AppTheme.primaryGreen, _amber, _cerulean, null];
    return SizedBox(
      height: 32,
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
  Widget _buildNotificationCard(BuildContext context, _NotificationData data) {
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
                    if (data.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.description!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                        onTap: () {
                          if (data.primaryAction == 'Extend time') {
                            _showExtendTimeSheet(context);
                          }
                        },
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
                            style: TextStyle(
                              color: data.secondaryActionTextColor ?? const Color(0xFFCBD5E1),
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

  // ── Extend time popup (P-22b) ─────────────────────────────
  void _showExtendTimeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _ExtendTimeSheet(
        patientName: 'Nipuni Ariyathilaka',
        visitLabel: "today's visit",
        currentEndTime: TimeOfDay(hour: 21, minute: 0),
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

// ── Extend time bottom sheet (P-22b · Extend time (popup)) ────────────────
enum _ExtendOption { min30, hour1, hour2, custom }

class _ExtendTimeSheet extends StatefulWidget {
  final String patientName;
  final String visitLabel;
  final TimeOfDay currentEndTime;

  const _ExtendTimeSheet({
    required this.patientName,
    required this.visitLabel,
    required this.currentEndTime,
  });

  @override
  State<_ExtendTimeSheet> createState() => _ExtendTimeSheetState();
}

class _ExtendTimeSheetState extends State<_ExtendTimeSheet> {
  static const Color _teal = Color(0xFF01D3A8);
  static const Color _tealText = Color(0xFF06231D);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _geyser = Color(0xFFCBD5E1);
  static const Color _azure47 = Color(0xFF64748B);

  _ExtendOption _selected = _ExtendOption.hour1;
  TimeOfDay? _customEndTime;

  TimeOfDay get _newEndTime {
    if (_selected == _ExtendOption.custom) {
      return _customEndTime ?? _addMinutes(widget.currentEndTime, 60);
    }
    final minutes = switch (_selected) {
      _ExtendOption.min30 => 30,
      _ExtendOption.hour1 => 60,
      _ExtendOption.hour2 => 120,
      _ExtendOption.custom => 60,
    };
    return _addMinutes(widget.currentEndTime, minutes);
  }

  TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final dt = DateTime(2000, 1, 1, t.hour, t.minute).add(Duration(minutes: minutes));
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _addMinutes(widget.currentEndTime, 60),
    );
    if (picked != null) {
      setState(() {
        _customEndTime = picked;
        _selected = _ExtendOption.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.more_time_rounded, color: _teal, size: 24),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extend time',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.patientName} · ${widget.visitLabel}',
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
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current end time',
                          style: TextStyle(color: _azure47, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(widget.currentEndTime),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: _teal, size: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'New end time',
                          style: TextStyle(color: _azure47, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(_newEndTime),
                          style: const TextStyle(color: _teal, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ADD TIME',
                style: TextStyle(
                  color: _azure47,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _optionTile('+30 min', _ExtendOption.min30)),
                  const SizedBox(width: 10),
                  Expanded(child: _optionTile('+1 hour', _ExtendOption.hour1)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _optionTile('+2 hours', _ExtendOption.hour2)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _optionTile(
                      _selected == _ExtendOption.custom ? _formatTime(_newEndTime) : 'Custom…',
                      _ExtendOption.custom,
                      onTap: _pickCustomTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.1),
                  border: Border.all(color: _amber.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: _amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Extra time is billed at the caregiver's hourly rate and needs their confirmation.",
                        style: TextStyle(
                          color: _geyser,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: _teal,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () {
                      final newEndTime = _formatTime(_newEndTime);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Extension request sent — new end time $newEndTime.',
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'Request extension',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _tealText, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(String label, _ExtendOption option, {VoidCallback? onTap}) {
    final isSelected = _selected == option;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _selected = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _teal.withValues(alpha: 0.15) : AppTheme.cardColor,
          border: Border.all(color: isSelected ? _teal : AppTheme.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? _teal : _geyser,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
