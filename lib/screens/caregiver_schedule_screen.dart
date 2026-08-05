import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/sri_lankan_cities.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';
import 'report_unavailability_dialog.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Bookings Screen  ("All requests" + "Upcoming")
//  Figma nodes: 476-796 ("All requests"), 478-824 ("Upcoming")
//  Real bookings assigned to this caregiver, filterable by real
//  state. Figma's "Emergency" chip/card has no backing data
//  anywhere in this app (no urgency flag is ever set on a
//  booking), so it's dropped rather than faked. Everything else
//  is real:
//   - New / Confirmed / Missed are computed from the booking's
//     actual status field plus its real start time (a request
//     still 'requested' after its start time has passed is
//     genuinely missed)
//   - Accept/Decline call the real BookingService.respondToRequest
//   - "On duty" reuses the existing real arrival-confirmation +
//     live-location-sharing flow
//   - distance is computed from the caregiver's last-known device
//     position vs. the booking's real location, when both are
//     available — omitted otherwise rather than invented
//
//  The calendar icon next to the title toggles into the "Upcoming"
//  view (Figma 478-824): a day-strip + date-grouped schedule, a
//  weekly-availability editor (real — a `weeklyAvailability` map
//  persisted on the caregiver's profile), and a real "Can't attend"
//  flag per shift (persisted, doesn't auto-cancel or notify anyone
//  since no such messaging pipeline exists — it's just a real
//  record visible on this screen).
// ─────────────────────────────────────────────────────────────
class CaregiverScheduleScreen extends StatefulWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  State<CaregiverScheduleScreen> createState() => _CaregiverScheduleScreenState();
}

enum _Filter { all, newRequest, confirmed, missed }

enum _ScheduleFilter { upcoming, confirmed, pending, past }

const _weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthAbbrevs = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

class _CaregiverScheduleScreenState extends State<CaregiverScheduleScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleDark = Color(0xFF113341);
  static const Color chipActiveBg = Color(0xFF1F3554);
  static const Color chipInactiveText = Color(0xFF1F3554);
  static const Color indigo = Color(0xFF6366F1);

  static const Color newCardBg = Color.fromRGBO(129, 129, 123, 0.32);
  static const Color newAccent = Color(0xFF6D4275);

  static const Color confirmedCardBg = Color(0xFFCFCABE);
  static const Color confirmedGreen = Color(0xFF22C55E);

  static const Color missedCardBg = Color.fromRGBO(239, 231, 211, 0.87);
  static const Color missedAmber = Color(0xFFF59E0B);
  static const Color onDutyRed = Color(0xFFEF4444);

  static const Color scheduleHeaderMuted = Color(0xFF94A3B8);
  static const Color availabilityCardBg = Color(0xFF202833);
  static const Color availabilityBorder = Color(0xFF334155);
  static const Color availabilityAvailableBg = Color(0xFF22BDC5);
  static const Color pendingBorder = Color(0xFFF5880B);
  static const Color pendingAccent = Color(0xFF935627);

  Stream<List<Map<String, dynamic>>>? _bookingsStream;
  final Map<String, String> _patientNames = {};
  String? _sharingBookingId;
  StreamSubscription<Position>? _positionSub;
  bool _requestingPermission = false;
  Position? _myPosition;
  Timer? _tickTimer;
  _Filter _selectedFilter = _Filter.all;

  bool _showUpcoming = false;
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
    _loadMyPosition();
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _tickTimer?.cancel();
    if (_sharingBookingId != null) {
      // Best-effort cleanup — don't block screen teardown on the write.
      BookingService.stopLiveLocation(_sharingBookingId!);
    }
    super.dispose();
  }

  Future<void> _loadMyPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 5));
      if (mounted) setState(() => _myPosition = pos);
    } catch (_) {
      // Distance is simply omitted if we can't get a position.
    }
  }

  Future<String> _resolvePatientName(String? patientUid) async {
    if (patientUid == null) return 'Patient';
    final cached = _patientNames[patientUid];
    if (cached != null) return cached;
    final profile = await PatientService.getPatientProfile(patientUid);
    final name = (profile?['name'] as String?)?.trim();
    final resolved = name != null && name.isNotEmpty ? name : 'Patient';
    _patientNames[patientUid] = resolved;
    if (mounted) setState(() {});
    return resolved;
  }

  String? _distanceLabel(Map<String, dynamic> booking) {
    final lat = booking['locationLat'] as double?;
    final lng = booking['locationLng'] as double?;
    final pos = _myPosition;
    if (lat == null || lng == null || pos == null) return null;
    final km = haversineKm(pos.latitude, pos.longitude, lat, lng);
    return '${km.toStringAsFixed(1)} km away';
  }

  DateTime? _parseShiftStart(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return null;
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final dateParts = dateStr.trim().split(RegExp(r'\s+'));
    if (dateParts.length != 3) return null;
    final day = int.tryParse(dateParts[0]);
    final month = months[dateParts[1]];
    final year = int.tryParse(dateParts[2]);
    if (day == null || month == null || year == null) return null;

    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
        .firstMatch(timeStr.trim());
    if (timeMatch == null) return DateTime(year, month, day);
    var hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final period = timeMatch.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return DateTime(year, month, day, hour, minute);
  }

  bool _isMissed(Map<String, dynamic> booking, DateTime? shiftStart) {
    final status = booking['status'] as String? ?? 'requested';
    return status == 'requested' && shiftStart != null && DateTime.now().isAfter(shiftStart);
  }

  Future<void> _respond(String bookingId, bool accept) async {
    await BookingService.respondToRequest(bookingId, accept: accept);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(accept ? 'Request accepted.' : 'Request declined.')),
    );
  }

  Future<void> _toggleSharing(String bookingId, bool enable) async {
    if (!enable) {
      await _positionSub?.cancel();
      _positionSub = null;
      if (_sharingBookingId == bookingId) {
        await BookingService.stopLiveLocation(bookingId);
        setState(() => _sharingBookingId = null);
      }
      return;
    }

    // Only one shift can be actively shared at a time.
    await _positionSub?.cancel();
    if (_sharingBookingId != null) {
      await BookingService.stopLiveLocation(_sharingBookingId!);
    }

    setState(() => _requestingPermission = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission was denied.';
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Turn on location services to share your position.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      await BookingService.updateLiveLocation(
        bookingId: bookingId,
        lat: position.latitude,
        lng: position.longitude,
      );

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (pos) => BookingService.updateLiveLocation(
          bookingId: bookingId,
          lat: pos.latitude,
          lng: pos.longitude,
        ),
        onError: (_) {},
      );

      if (mounted) setState(() => _sharingBookingId = bookingId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t start sharing location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
  }

  Future<void> _confirmArrival(String bookingId) async {
    await _toggleSharing(bookingId, false);
    await BookingService.confirmArrival(bookingId);
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showUpcoming ? 'Schedule' : 'All requests',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: _showUpcoming ? const Color(0xFF1F3554) : titleDark,
                      fontSize: _showUpcoming ? 20 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showUpcoming = !_showUpcoming),
                    child: Icon(
                      _showUpcoming ? Icons.view_agenda_outlined : Icons.calendar_today_rounded,
                      color: scheduleHeaderMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            if (_showUpcoming) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
                child: Text(
                  _formatFullDate(DateTime.now()),
                  style: const TextStyle(fontFamily: 'Inter', color: scheduleHeaderMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              _buildScheduleFilterChips(),
              Expanded(child: _buildUpcomingBody(context)),
            ] else ...[
              const SizedBox(height: 10),
              _buildFilterChips(),
              Expanded(child: _buildBody(context)),
            ],
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime d) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  // ═══════════════════════════════════════════════════════════
  //  "Upcoming" view (Figma 478-824)
  // ═══════════════════════════════════════════════════════════

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
                style: TextStyle(fontFamily: 'Inter', color: selected ? Colors.white : chipInactiveText, fontSize: 11, fontWeight: FontWeight.w600),
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
    }).where((b) {
      if (_selectedDay == null) return true;
      final shiftStart = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
      if (shiftStart == null) return false;
      final day = _selectedDay!;
      return shiftStart.year == day.year && shiftStart.month == day.month && shiftStart.day == day.day;
    }).toList()
      ..sort((a, b) {
        final at = _parseShiftStart(a['startDate'] as String?, a['startTime'] as String?);
        final bt = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
        if (at == null || bt == null) return 0;
        return at.compareTo(bt);
      });

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
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No bookings here yet.',
                style: const TextStyle(fontFamily: 'Open Sans', color: scheduleHeaderMuted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
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
      height: 60,
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
        dotColor ??= const Color(0xFFF59E0B);
      }
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = selected ? null : day),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFF285B51) : const Color.fromRGBO(40, 91, 81, 0.24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Open Sans', color: highlighted ? const Color(0xFFA9E4D8) : const Color(0xFF20413B), fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text('${day.day}', style: TextStyle(fontFamily: 'Open Sans', color: highlighted ? Colors.white : const Color(0xFF06402B), fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            if (dotColor != null)
              Container(width: 5, height: 5, decoration: BoxDecoration(color: highlighted ? Colors.white : dotColor, shape: BoxShape.circle))
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));
    const monthNames = [
      '', 'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: availabilityCardBg, border: Border.all(color: availabilityBorder), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly availability', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => setState(() => _editingAvailability = !_editingAvailability),
                child: Text(
                  _editingAvailability ? 'Done' : 'Edit',
                  style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFFBBC05), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Days you're open to work vs. unavailable",
            style: TextStyle(fontFamily: 'Open Sans', color: scheduleHeaderMuted, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Text('${monthNames[now.month]} ${now.year}', style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                Expanded(child: _buildAvailabilityDay(_weekdayKeys[i], _weekdayLabels[i], weekDates[i])),
                if (i < 6) const SizedBox(width: 6),
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
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                child: const Text('On duty', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(careType, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF2C6852), fontSize: 11, fontWeight: FontWeight.w700)),
          if (startTime != null || endTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF313131), size: 16),
                const SizedBox(width: 6),
                Text(
                  [if (startTime != null) startTime, if (endTime != null) endTime].join(' – '),
                  style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF313131), fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () => _handleCantAttend(booking),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_rounded, color: cantAttend ? const Color(0xFFEF4444) : const Color(0xFFFBBC05), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      cantAttend ? "Marked can't attend" : "Can't attend",
                      style: TextStyle(fontFamily: 'Open Sans', color: cantAttend ? const Color(0xFFEF4444) : const Color(0xFFFBBC05), fontSize: 11, fontWeight: FontWeight.w700),
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
                    Icon(Icons.location_on_rounded, color: Color(0xFFDC9F6C), size: 14),
                    SizedBox(width: 5),
                    Text('Get directions', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFFDC9F6C), fontSize: 11, fontWeight: FontWeight.w700)),
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
    final status = booking['status'] as String? ?? 'requested';
    final badgeLabel = status.isEmpty ? 'Confirmed' : '${status[0].toUpperCase()}${status.substring(1)}';

    return Opacity(
      opacity: isPast ? 0.6 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15.5),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF44331C), width: 1.5), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF44331C), fontSize: 13, fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: const Color.fromRGBO(31, 53, 84, 0.46), borderRadius: BorderRadius.circular(999)),
                  child: Text(badgeLabel, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF1F3554), fontSize: 10, fontWeight: FontWeight.w700)),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _handleCantAttend(booking),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_busy_rounded, color: Color(0xFFF87171), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          cantAttend ? "Marked can't attend" : "Can't attend",
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
      ),
    );
  }

  Widget _upcomingPendingCard(Map<String, dynamic> booking) {
    final id = booking['id'] as String;
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: pendingAccent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _respond(id, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Accept', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _respond(id, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(border: Border.all(color: pendingAccent), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Decline', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Inter', color: pendingAccent, fontSize: 11, fontWeight: FontWeight.w600)),
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

  // ═══════════════════════════════════════════════════════════
  //  "All requests" view (Figma 476-796)
  // ═══════════════════════════════════════════════════════════

  Widget _buildFilterChips() {
    final chips = [
      (filter: _Filter.all, label: 'All'),
      (filter: _Filter.newRequest, label: 'New'),
      (filter: _Filter.confirmed, label: 'Confirmed'),
      (filter: _Filter.missed, label: 'Missed'),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final selected = _selectedFilter == chip.filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = chip.filter),
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
                  fontFamily: 'Open Sans',
                  color: selected ? Colors.white : chipInactiveText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_bookingsStream == null) {
      return const EmptyState(icon: Icons.calendar_month_rounded, message: 'No bookings yet.');
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        final docs = (snapshot.data ?? const [])
            .where((b) => b['status'] != 'cancelled')
            .toList()
          ..sort((a, b) {
            final at = _parseShiftStart(a['startDate'] as String?, a['startTime'] as String?);
            final bt = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
            if (at == null || bt == null) return 0;
            return at.compareTo(bt);
          });

        final filtered = docs.where((b) {
          final shiftStart = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
          final missed = _isMissed(b, shiftStart);
          final status = b['status'] as String? ?? 'requested';
          switch (_selectedFilter) {
            case _Filter.all:
              return true;
            case _Filter.newRequest:
              return status == 'requested' && !missed;
            case _Filter.confirmed:
              return status == 'confirmed';
            case _Filter.missed:
              return missed;
          }
        }).toList();

        if (filtered.isEmpty) {
          return const EmptyState(icon: Icons.calendar_month_rounded, message: 'No bookings here yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 15, 20),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => GestureDetector(onTap: () => _openPatientProfile(filtered[i]), child: _buildBookingCard(filtered[i])),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final shiftStart = _parseShiftStart(booking['startDate'] as String?, booking['startTime'] as String?);
    final status = booking['status'] as String? ?? 'requested';
    final missed = _isMissed(booking, shiftStart);
    final arrived = booking['arrivalConfirmed'] == true;
    final shiftEnd = shiftStart?.add(const Duration(hours: 8));
    final onDuty = status == 'confirmed' &&
        arrived &&
        shiftStart != null &&
        shiftEnd != null &&
        DateTime.now().isAfter(shiftStart) &&
        DateTime.now().isBefore(shiftEnd);

    if (missed) return _missedCard(booking);
    if (status == 'declined') return _declinedCard(booking);
    if (status == 'confirmed') return onDuty ? _onDutyCard(booking) : _confirmedCard(booking);
    return _newRequestCard(booking);
  }

  Widget _nameText(String? patientUid, {required TextStyle style}) {
    return FutureBuilder<String>(
      future: _resolvePatientName(patientUid),
      builder: (context, snap) => Text(snap.data ?? 'Patient', style: style),
    );
  }

  // ── New request card (real Accept/Decline) ────────────────
  Widget _newRequestCard(Map<String, dynamic> booking) {
    final id = booking['id'] as String;
    final careType = booking['careType'] as String? ?? 'Care visit';
    final startDate = booking['startDate'] as String?;
    final patientUid = booking['patientUid'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: newCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(99, 102, 241, 0.2), blurRadius: 30, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2D4668), Color(0xFF071E40)]),
                ),
                alignment: Alignment.center,
                child: _nameText(patientUid, style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color.fromRGBO(109, 66, 117, 0.44), borderRadius: BorderRadius.circular(999)),
                          child: const Text('New request', style: TextStyle(fontFamily: 'Open Sans', color: newAccent, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [careType, if (startDate != null) startDate].join(' · '),
                      style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(0, 0, 0, 0.36), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: newAccent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _respond(id, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      child: Text('Accept', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
                    onTap: () => _respond(id, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(border: Border.all(color: newAccent), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Decline', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Open Sans', color: newAccent, fontSize: 14, fontWeight: FontWeight.w700)),
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

  // ── Confirmed card (+ real arrival / live-location controls) ──
  Widget _confirmedCard(Map<String, dynamic> booking) {
    final id = booking['id'] as String;
    final careType = booking['careType'] as String? ?? 'Care visit';
    final startDate = booking['startDate'] as String?;
    final duration = booking['duration'] as String?;
    final patientUid = booking['patientUid'] as String?;
    final distance = _distanceLabel(booking);
    final isSharing = _sharingBookingId == id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: confirmedCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                ),
                alignment: Alignment.center,
                child: _nameText(patientUid, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF42413F), fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(careType, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                    _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(0, 0, 0, 0.26), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: const Color.fromRGBO(34, 197, 94, 0.15), borderRadius: BorderRadius.circular(999)),
                child: const Text('Confirmed', style: TextStyle(fontFamily: 'Open Sans', color: confirmedGreen, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            [
              if (startDate != null) 'Starts $startDate',
              if (duration != null) duration,
              if (distance != null) distance,
            ].join(' · '),
            style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF424346), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: isSharing,
                activeThumbColor: indigo,
                onChanged: _requestingPermission ? null : (v) => _toggleSharing(id, v),
              ),
              const Expanded(
                child: Text('Share live location', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF424346), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: indigo,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _confirmArrival(id),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("I've arrived", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── On duty card (arrival already confirmed, shift in progress) ──
  Widget _onDutyCard(Map<String, dynamic> booking) {
    final startTime = booking['startTime'] as String?;
    final endTime = booking['endTime'] as String?;
    final patientUid = booking['patientUid'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: missedCardBg,
        border: Border.all(color: onDutyRed),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 9, height: 9, decoration: const BoxDecoration(color: onDutyRed, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('On duty', style: TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          FutureBuilder<String>(
            future: _resolvePatientName(patientUid),
            builder: (context, snap) {
              final name = snap.data ?? 'Patient';
              final range = [
                if (startTime != null) startTime,
                if (endTime != null) endTime,
              ].join('–');
              return Text(
                range.isEmpty ? 'Caring for $name' : 'Caring for $name · $range',
                style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(49, 49, 49, 0.79), fontSize: 12, fontWeight: FontWeight.w600),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Missed card (real: still 'requested' after its start time) ──
  Widget _missedCard(Map<String, dynamic> booking) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final duration = booking['duration'] as String?;
    final distance = _distanceLabel(booking);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 17),
      decoration: BoxDecoration(
        color: missedCardBg,
        border: Border.all(color: missedAmber),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: const Color.fromRGBO(245, 158, 11, 0.18), borderRadius: BorderRadius.circular(999)),
            child: const Text('Missed', style: TextStyle(fontFamily: 'Open Sans', color: missedAmber, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          const Text('Request expired while you were busy', style: TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            [careType, if (duration != null) duration, if (distance != null) distance].join(' · '),
            style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(49, 49, 49, 0.79), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Declined card (real, not in Figma's mock but real data) ──
  Widget _declinedCard(Map<String, dynamic> booking) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final patientUid = booking['patientUid'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: const Color(0xFF94A3B8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(careType, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(0, 0, 0, 0.36), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Text('Declined', style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Bottom nav (Schedule tab active) ──────────────────────
  Widget _buildBottomNav(BuildContext context) {
    const muted = Color(0xFF94A3B8);
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.calendar_month_rounded, label: 'Schedule'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_outline_rounded, label: 'Profile'),
    ];
    const selectedIndex = 1;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F3554),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              final color = isSelected ? indigo : muted;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (index == 0) {
                    Navigator.popUntil(context, ModalRoute.withName('/caregiver-dashboard'));
                  } else if (index == 2) {
                    Navigator.pushNamed(context, '/caregiver-notifications');
                  } else if (index == 3) {
                    Navigator.pushNamed(context, '/caregiver-own-profile');
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
                        fontFamily: 'Inter',
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
        ),
      ),
    );
  }
}
