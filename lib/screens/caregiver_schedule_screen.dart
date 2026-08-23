import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../widgets/caregiver_bottom_nav.dart';
import '../widgets/status_bar.dart';
import 'report_unavailability_dialog.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Schedule Screen ("Schedule" / "Upcoming shifts")
//  Figma nodes: 478-824, 596-389, 596-710
// ─────────────────────────────────────────────────────────────
class CaregiverScheduleScreen extends StatefulWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  State<CaregiverScheduleScreen> createState() => _CaregiverScheduleScreenState();
}

enum _ScheduleFilter { upcoming, confirmed, pending, past }

const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _monthAbbrevs = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class _CaregiverScheduleScreenState extends State<CaregiverScheduleScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleDark = Color(0xFF1F3554);
  static const Color chipActiveBg = Color(0xFF1F3554);
  static const Color chipInactiveText = Color(0xFF1F3554);

  static const Color confirmedGreen = Color(0xFF22C55E);
  static const Color scheduleHeaderMuted = Color(0xFF94A3B8);
  static const Color availabilityCardBg = Color(0xFF202833);
  static const Color availabilityBorder = Color(0xFF334155);
  static const Color availabilityAvailableBg = Color(0xFF22BDC5);
  static const Color pendingBorder = Color(0xFFF5880B);
  static const Color pendingAccent = Color(0xFF935627);

  static const String _emptyBookingsGif = 'assets/images/empty_bookings.webp';

  Stream<List<Map<String, dynamic>>>? _bookingsStream;
  final Map<String, String> _patientNames = {};
  _ScheduleFilter _scheduleFilter = _ScheduleFilter.upcoming;
  DateTime? _selectedDay;
  Map<String, bool> _weeklyAvailability = const {
    'mon': true, 'tue': true, 'wed': true, 'thu': true, 'fri': true, 'sat': true, 'sun': true,
  };
  bool _editingAvailability = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    final uid = AuthService.currentUser?.uid;
    _uid = uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForCaregiver(uid);
      _loadWeeklyAvailability(uid);
    }
  }

  Future<String> _resolvePatientName(String? patientUid) async {
    if (patientUid == null || patientUid.isEmpty) return 'Patient';
    if (_patientNames.containsKey(patientUid)) {
      return _patientNames[patientUid]!;
    }
    final name = await PatientService.getPatientName(patientUid);
    _patientNames[patientUid] = name;
    return name;
  }

  DateTime? _parseShiftStart(String? startDate, String? startTime) {
    if (startDate == null || startTime == null) return null;
    final dateParts = startDate.split('-').map(int.tryParse).toList();
    if (dateParts.length != 3 || dateParts.any((p) => p == null)) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
        .firstMatch(startTime.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(dateParts[0]!, dateParts[1]!, dateParts[2]!, hour, minute);
  }

  Future<void> _loadWeeklyAvailability(String uid) async {
    final profile = await CaregiverService.getCaregiverProfile(uid);
    final raw = profile?['weeklyAvailability'] as Map<String, dynamic>?;
    if (raw == null || !mounted) return;
    setState(() {
      _weeklyAvailability = {
        for (final key in _weekdayKeys) key: raw[key] as bool? ?? true,
      };
    });
  }

  Future<void> _toggleAvailabilityDay(String key) async {
    final uid = _uid;
    if (uid == null) return;
    final updated = {..._weeklyAvailability, key: !(_weeklyAvailability[key] ?? true)};
    setState(() => _weeklyAvailability = updated);
    await CaregiverService.saveCaregiverProfile(uid: uid, data: {'weeklyAvailability': updated});
  }

  Future<void> _handleCantAttend(Map<String, dynamic> booking) async {
    final id = booking['id'] as String;
    if (booking['cantAttend'] == true) {
      await BookingService.clearCantAttend(id);
      return;
    }
    final name = await _resolvePatientName(booking['patientUid'] as String?);
    if (!mounted) return;
    await showReportUnavailabilityDialog(
      context,
      bookingId: id,
      patientName: name,
      careType: booking['careType'] as String? ?? 'Care visit',
      schedule: _scheduleLabel(booking),
    );
  }

  String _scheduleLabel(Map<String, dynamic> booking) {
    final shiftStart = _parseShiftStart(booking['startDate'] as String?, booking['startTime'] as String?);
    final startTime = booking['startTime'] as String?;
    final endTime = booking['endTime'] as String?;
    const weekdayAbbrevs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateLabel = shiftStart != null
        ? '${weekdayAbbrevs[shiftStart.weekday - 1]} ${shiftStart.day} ${_monthAbbrevs[shiftStart.month]}'
        : (booking['startDate'] as String? ?? '');
    final timeRange = [if (startTime != null) startTime, if (endTime != null) endTime].join(' – ');
    return timeRange.isEmpty ? dateLabel : '$dateLabel, $timeRange';
  }

  void _openPatientProfile(Map<String, dynamic> booking) {
    Navigator.pushNamed(
      context,
      '/caregiver-patient-profile',
      arguments: {
        'patientUid': booking['patientUid'],
        'careType': booking['careType'],
        'startDate': booking['startDate'],
        'startTime': booking['startTime'],
        'endTime': booking['endTime'],
      },
    );
  }

  Future<void> _getDirections(String? patientUid) async {
    final name = await _resolvePatientName(patientUid);
    if (!mounted) return;
    Navigator.pushNamed(context, '/caregiver-directions', arguments: {'name': name});
  }

  DateTime? _shiftEnd(Map<String, dynamic> booking, DateTime? shiftStart) {
    if (shiftStart == null) return null;
    final endTime = booking['endTime'] as String?;
    if (endTime == null) return shiftStart.add(const Duration(hours: 8));
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(endTime.trim());
    if (match == null) return shiftStart.add(const Duration(hours: 8));
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    var end = DateTime(shiftStart.year, shiftStart.month, shiftStart.day, hour, minute);
    if (end.isBefore(shiftStart)) end = end.add(const Duration(days: 1));
    return end;
  }

  String _emptyTitleForScheduleFilter(_ScheduleFilter filter) {
    switch (filter) {
      case _ScheduleFilter.upcoming:
        return 'No upcoming shifts';
      case _ScheduleFilter.confirmed:
        return 'No confirmed shifts';
      case _ScheduleFilter.pending:
        return 'No pending shifts';
      case _ScheduleFilter.past:
        return 'No past shifts';
    }
  }

  String _emptyBodyForScheduleFilter(_ScheduleFilter filter) {
    switch (filter) {
      case _ScheduleFilter.upcoming:
        return "You don't have any upcoming shifts scheduled right now.";
      case _ScheduleFilter.confirmed:
        return "You have no confirmed shifts scheduled for this period.";
      case _ScheduleFilter.pending:
        return "You have no pending shifts awaiting confirmation.";
      case _ScheduleFilter.past:
        return "You don't have any completed or past shifts yet.";
    }
  }

  Widget _buildEmptyState({
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Image.asset(
              _emptyBookingsGif,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.event_available_rounded,
                color: Color(0xFFAAA897),
                size: 120,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Color(0xFF462911),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color.fromRGBO(39, 34, 77, 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFAAA897),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF462911),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Your schedule updates automatically when new requests arrive. We'll notify you the moment a patient sends a request.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Color.fromRGBO(0, 0, 0, 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime d) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Text(
                'Schedule',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
              child: Text(
                _formatFullDate(DateTime.now()),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: scheduleHeaderMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildScheduleFilterChips(),
            Expanded(child: _buildUpcomingBody(context)),
            const CaregiverBottomNav(activeTab: CaregiverNavTab.schedule),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleFilterChips() {
    final chips = [
      (filter: _ScheduleFilter.upcoming, label: 'Upcoming'),
      (filter: _ScheduleFilter.confirmed, label: 'Confirmed'),
      (filter: _ScheduleFilter.pending, label: 'Pending'),
      (filter: _ScheduleFilter.past, label: 'Past'),
    ];
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final selected = _scheduleFilter == chip.filter;
          return GestureDetector(
            onTap: () => setState(() => _scheduleFilter = chip.filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? chipActiveBg : Colors.transparent,
                border: selected ? null : Border.all(color: chipInactiveText),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                chip.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: selected ? Colors.white : chipInactiveText,
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

  Widget _buildUpcomingBody(BuildContext context) {
    if (_bookingsStream == null) {
      return _buildUpcomingList(const []);
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingsStream,
      builder: (context, snapshot) => _buildUpcomingList(snapshot.data ?? const []),
    );
  }

  Widget _buildUpcomingList(List<Map<String, dynamic>> bookings) {
    final now = DateTime.now();
    final active = bookings.where((b) => b['status'] != 'cancelled' && b['status'] != 'declined').toList();

    final filtered = active.where((b) {
      final shiftStart = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
      final shiftEnd = _shiftEnd(b, shiftStart);
      final status = b['status'] as String? ?? 'requested';
      final isPast = shiftEnd != null && now.isAfter(shiftEnd);

      if (_selectedDay != null && shiftStart != null) {
        final matchesDay = shiftStart.year == _selectedDay!.year &&
            shiftStart.month == _selectedDay!.month &&
            shiftStart.day == _selectedDay!.day;
        if (!matchesDay) return false;
      }

      switch (_scheduleFilter) {
        case _ScheduleFilter.upcoming:
          return !isPast;
        case _ScheduleFilter.confirmed:
          return status == 'confirmed' && !isPast;
        case _ScheduleFilter.pending:
          return status == 'requested' && !isPast;
        case _ScheduleFilter.past:
          return isPast;
      }
    }).toList();

    final groups = <String, List<Map<String, dynamic>>>{};
    final groupDates = <String, DateTime>{};
    for (final b in filtered) {
      final shiftStart = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
      final key = shiftStart != null ? '${shiftStart.year}-${shiftStart.month}-${shiftStart.day}' : 'unscheduled';
      groups.putIfAbsent(key, () => []).add(b);
      if (shiftStart != null) groupDates[key] = DateTime(shiftStart.year, shiftStart.month, shiftStart.day);
    }
    final orderedKeys = groups.keys.toList()
      ..sort((a, b) {
        final ad = groupDates[a];
        final bd = groupDates[b];
        if (ad == null || bd == null) return 0;
        return ad.compareTo(bd);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 11, 20),
      children: [
        _buildDayStrip(active),
        const SizedBox(height: 12),
        _buildAvailabilityCard(),
        if (orderedKeys.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildEmptyState(
              title: _emptyTitleForScheduleFilter(_scheduleFilter),
              body: _emptyBodyForScheduleFilter(_scheduleFilter),
              actionLabel: _scheduleFilter != _ScheduleFilter.upcoming
                  ? 'Upcoming shifts'
                  : null,
              onAction: _scheduleFilter != _ScheduleFilter.upcoming
                  ? () => setState(() => _scheduleFilter = _ScheduleFilter.upcoming)
                  : null,
            ),
          )
        else
          for (final key in orderedKeys) ...[
            const SizedBox(height: 14),
            _buildDateHeader(groupDates[key], now),
            const SizedBox(height: 8),
            for (final b in groups[key]!) ...[
              GestureDetector(onTap: () => _openPatientProfile(b), child: _buildUpcomingCard(b, now)),
              const SizedBox(height: 10),
            ],
          ],
      ],
    );
  }

  Widget _buildDateHeader(DateTime? date, DateTime now) {
    const weekdayAbbrevs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String label;
    if (date == null) {
      label = 'Unscheduled';
    } else {
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final dateLabel = '${weekdayAbbrevs[date.weekday - 1]} ${date.day} ${_monthAbbrevs[date.month]}';
      label = isToday ? 'Today · $dateLabel' : dateLabel;
    }
    return Text(
      label.toUpperCase(),
      style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }

  Widget _buildDayStrip(List<Map<String, dynamic>> bookings) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    const weekdayAbbrevs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            Expanded(child: _buildDayPill(start.add(Duration(days: i)), weekdayAbbrevs[start.add(Duration(days: i)).weekday - 1], bookings)),
            if (i < 6) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildDayPill(DateTime day, String label, List<Map<String, dynamic>> bookings) {
    final now = DateTime.now();
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
    final selected = _selectedDay != null && _selectedDay!.year == day.year && _selectedDay!.month == day.month && _selectedDay!.day == day.day;
    final highlighted = isToday || selected;

    Color? dotColor;
    for (final b in bookings) {
      final shiftStart = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
      if (shiftStart == null) continue;
      if (shiftStart.year == day.year && shiftStart.month == day.month && shiftStart.day == day.day) {
        final status = b['status'] as String? ?? 'requested';
        if (status == 'confirmed') {
          dotColor = confirmedGreen;
          break;
        }
        dotColor = const Color(0xFFF59E0B);
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedDay = null;
          } else {
            _selectedDay = day;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1F3554)
              : (isToday ? const Color.fromRGBO(31, 53, 84, 0.15) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: isToday && !selected ? Border.all(color: const Color(0xFF1F3554), width: 1.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: selected ? Colors.white : (highlighted ? const Color(0xFF1F3554) : const Color(0xFF64748B)),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: TextStyle(
                fontFamily: 'Inter',
                color: selected ? Colors.white : (highlighted ? const Color(0xFF1F3554) : const Color(0xFF1E293B)),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor ?? Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: availabilityCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: availabilityBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.event_available_rounded, color: Color(0xFF22BDC5), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'WEEKLY AVAILABILITY',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _editingAvailability = !_editingAvailability),
                child: Text(
                  _editingAvailability ? 'Done' : 'Edit',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF22BDC5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                Expanded(
                  child: _buildAvailabilityDay(
                    _weekdayKeys[i],
                    weekdayLabels[i],
                    startOfWeek.add(Duration(days: i)),
                  ),
                ),
                if (i < 6) const SizedBox(width: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityDay(String key, String label, DateTime date) {
    final available = _weeklyAvailability[key] ?? true;
    return Column(
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('${date.day}', style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: _editingAvailability ? () => _toggleAvailabilityDay(key) : null,
          child: Container(
            height: 34,
            width: double.infinity,
            decoration: BoxDecoration(
              color: available ? availabilityAvailableBg : const Color.fromRGBO(148, 163, 184, 0.12),
              border: available ? null : Border.all(color: availabilityBorder),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              available ? Icons.check_rounded : Icons.close_rounded,
              color: available ? const Color(0xFF42413F) : const Color(0xFF64748B),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic> booking, DateTime now) {
    final shiftStart = _parseShiftStart(booking['startDate'] as String?, booking['startTime'] as String?);
    final shiftEnd = _shiftEnd(booking, shiftStart);
    final status = booking['status'] as String? ?? 'requested';
    final arrived = booking['arrivalConfirmed'] == true;
    final onDuty = status == 'confirmed' &&
        arrived &&
        shiftStart != null &&
        shiftEnd != null &&
        now.isAfter(shiftStart) &&
        now.isBefore(shiftEnd);
    final isPast = shiftEnd != null && now.isAfter(shiftEnd);

    if (onDuty) return _upcomingOnDutyCard(booking);
    if (status == 'requested' && !isPast) return _upcomingPendingCard(booking);
    return _upcomingConfirmedCard(booking, isPast: isPast);
  }

  Widget _timeRange(Map<String, dynamic> booking) {
    final startTime = booking['startTime'] as String?;
    final endTime = booking['endTime'] as String?;
    final parts = [if (startTime != null) startTime, if (endTime != null) endTime];
    return Text(
      parts.join(' – '),
      style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF62316C), fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  Widget _upcomingOnDutyCard(Map<String, dynamic> booking) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final startTime = booking['startTime'] as String?;
    final endTime = booking['endTime'] as String?;
    final patientUid = booking['patientUid'] as String?;
    final cantAttend = booking['cantAttend'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF94DEC0), Color(0xFF338462)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: const Color.fromRGBO(239, 68, 68, 0.2), borderRadius: BorderRadius.circular(999)),
                child: const Text('On duty', style: TextStyle(fontFamily: 'Inter', color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(careType, style: const TextStyle(fontFamily: 'Inter', color: Color.fromRGBO(0, 0, 0, 0.6), fontSize: 12, fontWeight: FontWeight.w500)),
          if (startTime != null || endTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF62316C), size: 16),
                const SizedBox(width: 6),
                _timeRange(booking),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => _handleCantAttend(booking),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cantAttend ? Icons.check_circle_rounded : Icons.cancel_outlined, color: const Color(0xFFF87171), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      cantAttend ? 'Unavailability reported' : 'Can\'t attend',
                      style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _getDirections(patientUid),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, color: Color(0xFF818CF8), size: 14),
                    SizedBox(width: 5),
                    Text('Get directions', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upcomingConfirmedCard(Map<String, dynamic> booking, {required bool isPast}) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final startTime = booking['startTime'] as String?;
    final endTime = booking['endTime'] as String?;
    final patientUid = booking['patientUid'] as String?;
    final cantAttend = booking['cantAttend'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15.5),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(207, 202, 190, 0.44),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(100, 116, 139, 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isPast ? const Color.fromRGBO(100, 116, 139, 0.15) : const Color.fromRGBO(34, 197, 94, 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPast ? 'Completed' : 'Confirmed',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isPast ? const Color(0xFF64748B) : confirmedGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(careType, style: const TextStyle(fontFamily: 'Inter', color: scheduleHeaderMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          if (startTime != null || endTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF62316C), size: 16),
                const SizedBox(width: 6),
                _timeRange(booking),
              ],
            ),
          ],
          if (!isPast) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _handleCantAttend(booking),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cantAttend ? Icons.check_circle_rounded : Icons.cancel_outlined, color: const Color(0xFFF87171), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        cantAttend ? 'Unavailability reported' : 'Can\'t attend',
                        style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _getDirections(patientUid),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, color: Color(0xFF818CF8), size: 14),
                      SizedBox(width: 5),
                      Text('Get directions', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _upcomingPendingCard(Map<String, dynamic> booking) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final startTime = booking['startTime'] as String?;
    final endTime = booking['endTime'] as String?;
    final patientUid = booking['patientUid'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15.5),
      decoration: BoxDecoration(border: Border.all(color: pendingBorder, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: const Color.fromRGBO(245, 136, 11, 0.2), borderRadius: BorderRadius.circular(999)),
                child: const Text('Pending', style: TextStyle(fontFamily: 'Inter', color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(careType, style: const TextStyle(fontFamily: 'Inter', color: scheduleHeaderMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          if (startTime != null || endTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF62316C), size: 16),
                const SizedBox(width: 6),
                _timeRange(booking),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _nameText(String? patientUid, {required TextStyle style}) {
    return FutureBuilder<String>(
      future: _resolvePatientName(patientUid),
      builder: (context, snap) => Text(snap.data ?? 'Patient', style: style),
    );
  }
}
