import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'report_unavailability_dialog.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Schedule Screen
//  Figma node: 498-7369 · Schedule (Caregiver) — Upcoming tab
// ─────────────────────────────────────────────────────────────
enum _EventStatus { onDuty, confirmed, pending }

class _ScheduleEvent {
  final String name;
  final _EventStatus status;
  final String careType;
  final String time;
  final bool showDirections;
  final String dateLabel; // e.g. "Today · Mon 15 Dec"
  final int day; // day-of-month, for grouping

  const _ScheduleEvent({
    required this.name,
    required this.status,
    required this.careType,
    required this.time,
    required this.dateLabel,
    required this.day,
    this.showDirections = false,
  });
}

class _DayInfo {
  final String label;
  final int date;
  final bool available;
  const _DayInfo({required this.label, required this.date, required this.available});
}

class CaregiverScheduleScreen extends StatefulWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  State<CaregiverScheduleScreen> createState() => _CaregiverScheduleScreenState();
}

class _CaregiverScheduleScreenState extends State<CaregiverScheduleScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _indigoLighter = Color(0xFFC7D2FE);
  static const Color _green = AppTheme.primaryGreen;
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red71 = Color(0xFFF87171);
  static const Color _grey47 = Color(0xFF64748B);
  static const Color _grey35 = Color(0xFF475569);
  static const Color _geyser = Color(0xFFCBD5E1);

  int _selectedTab = 0; // 0=Upcoming, 1=Confirmed, 2=Pending, 3=Past
  int _selectedDay = 15;

  static const List<String> _tabs = ['Upcoming', 'Confirmed', 'Pending', 'Past'];

  static const List<String> _weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<int> _weekDates = [15, 16, 17, 18, 19, 20, 21];

  static const List<_DayInfo> _availability = [
    _DayInfo(label: 'Mon', date: 15, available: true),
    _DayInfo(label: 'Tue', date: 16, available: true),
    _DayInfo(label: 'Wed', date: 17, available: true),
    _DayInfo(label: 'Thu', date: 18, available: false),
    _DayInfo(label: 'Fri', date: 19, available: true),
    _DayInfo(label: 'Sat', date: 20, available: false),
    _DayInfo(label: 'Sun', date: 21, available: false),
  ];

  static const List<_ScheduleEvent> _events = [
    _ScheduleEvent(
      name: 'Nipuni Ariyathilaka',
      status: _EventStatus.onDuty,
      careType: 'Elder care · Full-time',
      time: '8:00 AM – 6:00 PM',
      dateLabel: 'Today · Mon 15 Dec',
      day: 15,
      showDirections: true,
    ),
    _ScheduleEvent(
      name: 'Kamal Perera',
      status: _EventStatus.confirmed,
      careType: 'Post-surgery care · Part-time',
      time: '7:00 PM – 9:00 PM',
      dateLabel: 'Today · Mon 15 Dec',
      day: 15,
      showDirections: true,
    ),
    _ScheduleEvent(
      name: 'Ishara Perera',
      status: _EventStatus.confirmed,
      careType: 'Dementia care · Live-in',
      time: 'All day',
      dateLabel: 'Wed 17 Dec',
      day: 17,
    ),
    _ScheduleEvent(
      name: 'Ranjan Jayasuriya',
      status: _EventStatus.pending,
      careType: 'Mobility assistance · One-time',
      time: '2:00 PM – 4:00 PM',
      dateLabel: 'Fri 19 Dec',
      day: 19,
    ),
  ];

  // Dot color shown under a week-strip day, based on that day's busiest event.
  Color? _dotColorForDay(int day) {
    final dayEvents = _events.where((e) => e.day == day);
    if (dayEvents.any((e) => e.status == _EventStatus.pending)) return _amber;
    if (dayEvents.any((e) => e.status == _EventStatus.confirmed || e.status == _EventStatus.onDuty)) {
      return _green;
    }
    return null;
  }

  List<_ScheduleEvent> get _filteredEvents {
    switch (_selectedTab) {
      case 1: // Confirmed
        return _events
            .where((e) => e.status == _EventStatus.confirmed || e.status == _EventStatus.onDuty)
            .toList();
      case 2: // Pending
        return _events.where((e) => e.status == _EventStatus.pending).toList();
      case 3: // Past
        return const [];
      default: // Upcoming
        return _events;
    }
  }

  String _bookingDetail(_ScheduleEvent e) {
    final datePart = e.dateLabel.contains('·') ? e.dateLabel.split('·').last.trim() : e.dateLabel;
    final careTypeShort = e.careType.split('·').first.trim();
    return '$careTypeShort · $datePart, ${e.time}';
  }

  void _showReportUnavailability(_ScheduleEvent e) {
    showReportUnavailabilityDialog(
      context,
      patientName: e.name,
      bookingDetail: _bookingDetail(e),
    );
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<_ScheduleEvent>>{};
    for (final e in _filteredEvents) {
      grouped.putIfAbsent(e.dateLabel, () => []).add(e);
    }

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
                        'Schedule',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showComingSoon('Calendar view'),
                        child: const Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Monday, 15 December 2026',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                  const SizedBox(height: 14),
                  _buildWeekStrip(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvailabilityCard(),
                    const SizedBox(height: 18),
                    if (grouped.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Nothing here yet.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(
                              color: _grey47,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        for (final e in entry.value) ...[
                          _buildEventCard(e),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 6),
                      ],
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Tab bar (pill style) ────────────────────────────────────
  Widget _buildTabBar() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? _indigo : AppTheme.cardColor,
                border: selected ? null : Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                _tabs[i],
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Week day-strip ──────────────────────────────────────────
  Widget _buildWeekStrip() {
    return SizedBox(
      height: 58,
      child: Row(
        children: List.generate(7, (i) {
          final date = _weekDates[i];
          final selected = date == _selectedDay;
          final dotColor = _dotColorForDay(date);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = date),
              child: Container(
                margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _indigo : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weekLabels[i],
                      style: TextStyle(
                        color: selected ? _indigoLighter : AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 6,
                      width: 6,
                      child: dotColor != null
                          ? DecoratedBox(
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Weekly availability card ────────────────────────────────
  Widget _buildAvailabilityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly availability',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () => _showComingSoon('Edit availability'),
                child: const Text(
                  'Edit',
                  style: TextStyle(color: _indigoLight, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            "Days you're open to work vs. unavailable",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          const Text(
            'DECEMBER 2026',
            style: TextStyle(
              color: _grey47,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_availability.length, (i) {
              final d = _availability[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                  child: Column(
                    children: [
                      Text(
                        d.label,
                        style: const TextStyle(color: _grey47, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.date}',
                        style: const TextStyle(color: _grey35, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: d.available ? _green : AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          d.available ? Icons.check_rounded : Icons.close_rounded,
                          color: d.available ? AppTheme.bottleGreen : _grey47,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Event card router ───────────────────────────────────────
  Widget _buildEventCard(_ScheduleEvent e) {
    switch (e.status) {
      case _EventStatus.onDuty:
        return _buildOnDutyCard(e);
      case _EventStatus.confirmed:
        return _buildConfirmedCard(e);
      case _EventStatus.pending:
        return _buildPendingCard(e);
    }
  }

  Widget _buildOnDutyCard(_ScheduleEvent e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, Color(0xFF15803D)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'On duty',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            e.careType,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(e.time, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showReportUnavailability(e),
                child: const Row(
                  children: [
                    Icon(Icons.event_busy_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 5),
                    Text(
                      "Can't attend",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              if (e.showDirections) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/caregiver-directions',
                    arguments: {'name': e.name},
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Get directions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedCard(_ScheduleEvent e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Confirmed',
                  style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            e.careType,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: _indigo, size: 16),
              const SizedBox(width: 6),
              Text(e.time, style: const TextStyle(color: _geyser, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showReportUnavailability(e),
                child: const Row(
                  children: [
                    Icon(Icons.event_busy_rounded, color: _red71, size: 14),
                    SizedBox(width: 5),
                    Text(
                      "Can't attend",
                      style: TextStyle(color: _red71, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (e.showDirections) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/caregiver-directions',
                    arguments: {'name': e.name},
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: _indigoLight, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Get directions',
                        style: TextStyle(color: _indigoLight, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(_ScheduleEvent e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: _amber),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  e.name,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(color: _amber, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            e.careType,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: _amber, size: 16),
              const SizedBox(width: 6),
              Text(e.time, style: const TextStyle(color: _geyser, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _indigo,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showComingSoon('Accept'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      child: Text(
                        'Accept',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showComingSoon('Decline'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Decline',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom nav (Schedule tab active) ──────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.calendar_month_rounded, label: 'Schedule'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    const selectedIndex = 1;

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
              } else if (index == 2) {
                Navigator.pushNamed(context, '/caregiver-notifications');
              } else if (index == 3) {
                Navigator.pushNamed(context, '/caregiver-own-profile');
              } else if (index != 1) {
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
