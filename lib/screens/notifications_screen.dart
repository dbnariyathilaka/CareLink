import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../services/booking_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Notifications Screen  (Patient)
//  Figma node: 249-1064
//  No notification-producing backend exists yet (no caregiver-side
//  accept/decline, no shift tracking, no push/FCM), so the feed is
//  always empty today — the card/filter UI below is built to spec
//  so it lights up the moment that data exists.
// ─────────────────────────────────────────────────────────────

enum _NotificationCategory { booking, reminder, system }

enum _NotificationType {
  shiftCancelled,
  shiftStartingSoon,
  shiftEndingSoon,
  appointmentReminder,
  bookingAccepted,
  caregiverReachedOut,
  requestDeclined,
}

class _NotificationAction {
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;
  const _NotificationAction(this.label, {this.isPrimary = false, this.onTap});
}

class _AppNotification {
  final _NotificationType type;
  final String title;
  final String body;
  final String timeAgo;
  final List<_NotificationAction> actions;

  // Structured fields for the shiftEndingSoon "Extend time" sheet.
  final String? caregiverName;
  final String? visitLabel;
  final String? endTime;
  final String? bookingId;

  const _AppNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.actions = const [],
    this.caregiverName,
    this.visitLabel,
    this.endTime,
    this.bookingId,
  });
}

class _NotificationStyle {
  final IconData icon;
  final Color accent;
  final _NotificationCategory category;
  const _NotificationStyle(this.icon, this.accent, this.category);
}

const Map<_NotificationType, _NotificationStyle> _notificationStyles = {
  _NotificationType.shiftCancelled: _NotificationStyle(
    Icons.event_busy_rounded, Color(0xFFEF4444), _NotificationCategory.booking,
  ),
  _NotificationType.shiftStartingSoon: _NotificationStyle(
    Icons.play_circle_rounded, Color(0xFF521D5F), _NotificationCategory.reminder,
  ),
  _NotificationType.shiftEndingSoon: _NotificationStyle(
    Icons.alarm_rounded, Color(0xFF267B6A), _NotificationCategory.reminder,
  ),
  _NotificationType.appointmentReminder: _NotificationStyle(
    Icons.alarm_rounded, Color(0xFF3E189F), _NotificationCategory.reminder,
  ),
  _NotificationType.bookingAccepted: _NotificationStyle(
    Icons.check_circle_rounded, Color(0xFF22C55E), _NotificationCategory.booking,
  ),
  _NotificationType.caregiverReachedOut: _NotificationStyle(
    Icons.waving_hand_rounded, Color(0xFF6366F1), _NotificationCategory.booking,
  ),
  _NotificationType.requestDeclined: _NotificationStyle(
    Icons.cancel_rounded, Color(0xFF975151), _NotificationCategory.booking,
  ),
};

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color cardBg = Color(0xFFEEDEC9);
  static const Color tabGreen = Color(0xFF2A9C5B);
  static const Color timeText = Color(0xFF765F43);
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);

  _NotificationCategory? _selectedCategory; // null = All

  late final AnimationController _matchIconController;
  late final Animation<double> _matchIconRotation;

  // No notification-producing backend exists yet — kept empty until a
  // real event source (caregiver actions, shift tracking, FCM) exists.
  final List<_AppNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _matchIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _matchIconRotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 2),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
    ]).animate(_matchIconController);
  }

  @override
  void dispose() {
    _matchIconController.dispose();
    super.dispose();
  }

  List<_AppNotification> get _filtered {
    if (_selectedCategory == null) return _notifications;
    return _notifications
        .where((n) => _notificationStyles[n.type]!.category == _selectedCategory)
        .toList();
  }

  // ── Time helpers ("9:00 PM" ⇄ TimeOfDay) ───────────────────
  TimeOfDay? _parseTimeString(String s) {
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
            .firstMatch(s.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final total = (t.hour * 60 + t.minute + minutes) % (24 * 60);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  // ── "Extend time" bottom sheet (Figma node 275-2140) ───────
  void _showExtendTimeSheet(
    BuildContext context, {
    required String caregiverName,
    required String visitLabel,
    required String currentEndTime,
    String? bookingId,
  }) {
    final baseTime =
        _parseTimeString(currentEndTime) ?? const TimeOfDay(hour: 21, minute: 0);
    int? selectedMinutes = 60;
    TimeOfDay? customTime;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setSheetState) {
            final newTime = customTime ?? _addMinutes(baseTime, selectedMinutes ?? 0);
            final newTimeLabel = _formatTimeOfDay(newTime);

            Widget durationChip(String label, int? minutes, {bool isCustom = false}) {
              final isSelected = isCustom
                  ? customTime != null
                  : (selectedMinutes == minutes && customTime == null);
              return GestureDetector(
                onTap: () async {
                  if (isCustom) {
                    final picked = await showTimePicker(
                      context: builderCtx,
                      initialTime: newTime,
                    );
                    if (picked != null) {
                      setSheetState(() {
                        customTime = picked;
                        selectedMinutes = null;
                      });
                    }
                  } else {
                    setSheetState(() {
                      selectedMinutes = minutes;
                      customTime = null;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE7D9C7)
                        : const Color(0xFFB1A28F),
                    border: Border.all(color: const Color(0xFFB1A28F)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: isSelected
                          ? const Color(0xFFB19878)
                          : const Color(0xFF5A462D),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5EEE8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 14,
                bottom: MediaQuery.of(builderCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9E9284),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.more_time_rounded, color: Color(0xFF967065), size: 24),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Extend time',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: Color(0xFFA94813),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$caregiverName · $visitLabel',
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: Color.fromRGBO(0, 0, 0, 0.62),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAB9089),
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
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: Color.fromRGBO(0, 0, 0, 0.69),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentEndTime,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: Color(0xFFF8FAFC),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFF4D4431), size: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'New end time',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: Color.fromRGBO(0, 0, 0, 0.69),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              newTimeLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF62366B),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ADD TIME',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color.fromRGBO(49, 49, 49, 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: durationChip('+30 min', 30)),
                      const SizedBox(width: 10),
                      Expanded(child: durationChip('+1 hour', 60)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: durationChip('+2 hours', 120)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: durationChip(
                          customTime != null ? _formatTimeOfDay(customTime!) : 'Custom…',
                          null,
                          isCustom: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(245, 158, 11, 0.1),
                      border: Border.all(color: const Color.fromRGBO(245, 158, 11, 0.35)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_rounded, color: Color(0xFFF59E0B), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Extra time is billed at the caregiver's hourly rate "
                            "and needs their confirmation.",
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Color.fromRGBO(85, 70, 48, 0.89),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () async {
                      final extraMinutes = customTime != null
                          ? ((customTime!.hour * 60 + customTime!.minute) -
                                  (baseTime.hour * 60 + baseTime.minute) +
                                  24 * 60) %
                              (24 * 60)
                          : (selectedMinutes ?? 0);
                      if (bookingId != null) {
                        await BookingService.requestExtension(
                          bookingId: bookingId,
                          newEndTime: newTimeLabel,
                          extraMinutes: extraMinutes,
                        );
                      }
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Extension request sent — waiting on $caregiverName to confirm.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9E9284),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9E9284).withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Request extension',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color.fromRGBO(0, 0, 0, 0.76),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.notifications_none_rounded,
                      iconColor: darkGreen,
                      textColor: darkGreen.withValues(alpha: 0.7),
                      message: 'No notifications yet.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(17, 0, 12, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _buildCard(filtered[i]),
                    ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: darkGreen,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          GestureDetector(
            onTap: _notifications.isEmpty ? null : () {},
            child: Text(
              'Mark all read',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.black.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter tabs ────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final tabs = [
      (category: null, label: 'All ${_notifications.length}'),
      (category: _NotificationCategory.booking, label: 'Booking'),
      (category: _NotificationCategory.reminder, label: 'Reminders'),
      (category: _NotificationCategory.system, label: 'System'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length * 2 - 1, (i) {
            if (i.isOdd) return const SizedBox(width: 7);
            final tab = tabs[i ~/ 2];
            final isActive = tab.category == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = tab.category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? tabGreen : Colors.transparent,
                  border: Border.all(color: tabGreen),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: isActive ? Colors.white : tabGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Notification card ──────────────────────────────────────
  Widget _buildCard(_AppNotification n) {
    final style = _notificationStyles[n.type]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 13, 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          top: BorderSide(color: style.accent, width: 0.5),
          right: BorderSide(color: style.accent, width: 0.5),
          bottom: BorderSide(color: style.accent, width: 0.5),
          left: BorderSide(color: style.accent, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, color: style.accent, size: 22),
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
                            n.title,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          n.timeAgo,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: timeText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (n.actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 33),
              child: Row(
                children: List.generate(n.actions.length * 2 - 1, (i) {
                  if (i.isOdd) return const SizedBox(width: 8);
                  final action = n.actions[i ~/ 2];
                  final isExtendTime = n.type == _NotificationType.shiftEndingSoon &&
                      action.label == 'Extend time';
                  return GestureDetector(
                    onTap: isExtendTime
                        ? () => _showExtendTimeSheet(
                              context,
                              caregiverName: n.caregiverName ?? 'Your caregiver',
                              visitLabel: n.visitLabel ?? "today's visit",
                              currentEndTime: n.endTime ?? '9:00 PM',
                              bookingId: n.bookingId,
                            )
                        : action.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: action.isPrimary
                            ? style.accent.withValues(alpha: 0.3)
                            : Colors.transparent,
                        border: action.isPrimary
                            ? null
                            : Border.all(color: style.accent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        action.label,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: style.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Bottom nav (matches dashboard/search/bookings) ────────
  Widget _buildBottomBar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        _buildBottomNav(),
        Positioned(top: -22, child: _buildMatchFab()),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', route: '/patient-dashboard'),
      (icon: Icons.search_rounded, label: 'Search', route: '/search'),
      (icon: null, label: 'Match', route: null),
      (icon: Icons.calendar_month_outlined, label: 'Booking', route: '/my-bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Notification', route: null),
    ];
    return Container(
      width: double.infinity,
      height: 67,
      color: darkGreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];

          if (index == 2) {
            return const SizedBox(
              width: 60,
              child: Padding(
                padding: EdgeInsets.only(top: 41),
                child: Text(
                  'Match',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: navMatchLabel,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          // "Notification" tab is the current screen.
          final color = index == 4 ? navHomeLabel : Colors.white;
          return GestureDetector(
            onTap: item.route != null
                ? () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      item.route!,
                      (route) => route.settings.name == '/patient-dashboard',
                    )
                : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: color, size: 25),
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
        }),
      ),
    );
  }

  Widget _buildMatchFab() {
    return GestureDetector(
      onTap: () {
        if (AppState.hasActiveMatch.value) {
          Navigator.pushNamed(context, '/advanced-match-results');
        } else {
          Navigator.pushNamed(context, '/advanced-match-send-request');
        }
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: RotationTransition(
          turns: _matchIconRotation,
          child: SvgPicture.asset(
            'assets/images/match_target_icon.svg',
            width: 65,
            height: 65,
          ),
        ),
      ),
    );
  }
}
