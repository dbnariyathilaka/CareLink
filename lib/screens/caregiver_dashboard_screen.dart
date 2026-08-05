import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../services/review_service.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Caregiver Dashboard  (Figma node 473-152)
//  Every number here is computed from real data — real bookings
//  (BookingService), real reviews (ReviewService) — rather than the fixed
//  mock stats ("85%", "36k", "4.5 from 24 reviews") shown in the Figma file.
//  "Currently on duty" reflects a real booking whose arrival was confirmed
//  and whose shift window contains the current time (see
//  caregiver_schedule_screen.dart's "I've arrived" action). There's no
//  historical snapshot of past ratings, so unlike Figma's rating tile this
//  one omits a week-over-week delta rather than inventing one.
// ─────────────────────────────────────────────────────────────────────────────
class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  static const Color bg = Color(0xFFF1F8E1);
  static const Color headerBg = Color(0xFF1F3554);
  static const Color statCardBg = Color.fromRGBO(85, 70, 58, 0.36);
  static const Color statLabel = Color(0xFF06402B);
  static const Color statCaption = Color(0xFF313131);
  static const Color upGreenBg = Color.fromRGBO(6, 155, 158, 0.3);
  static const Color upGreenText = Color(0xFF225753);
  static const Color downRedBg = Color.fromRGBO(158, 6, 6, 0.3);
  static const Color downRedText = Color(0xFF9E0606);
  static const Color weekCardBorder = Color(0xFF967065);
  static const Color weekBarActive = Color(0xFF967065);
  static const Color weekBarInactive = Color(0xFFCFB9AC);
  static const Color weekDayLabel = Color(0xFF64748B);
  static const Color scheduleTitle = Color(0xFF113341);
  static const Color scheduleCardBg = Color.fromRGBO(193, 163, 140, 0.43);
  static const Color scheduleName = Color(0xFF313131);
  static const Color scheduleSubtitle = Color.fromRGBO(79, 88, 101, 0.66);
  static const Color scheduleBadgeBg = Color.fromRGBO(110, 99, 90, 0.45);
  static const Color scheduleBadgeText = Color(0xFF44431E);

  static const _avatarColors = [
    Color(0xFF0EA5E9),
    Color(0xFF6D4275),
    Color(0xFF44331C),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
  ];

  String _caregiverName = 'Caregiver';
  Stream<List<Map<String, dynamic>>>? _bookingsStream;
  Stream<List<Map<String, dynamic>>>? _reviewsStream;
  final Map<String, String> _patientNames = {};
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForCaregiver(uid);
      _reviewsStream = ReviewService.streamReviewsForCaregiver(uid);
      _loadProfile(uid);
    }
    // Re-evaluate "currently on duty" / "this week" purely because the
    // clock moved, not just when Firestore data changes.
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile(String uid) async {
    final profile = await CaregiverService.getCaregiverProfile(uid);
    AppState.hydrateCaregiverPhoto(profile?['photoUrl'] as String?);
    final name = profile?['name'] as String?;
    if (mounted && name != null && name.isNotEmpty) {
      setState(() => _caregiverName = name);
    }
  }

  Future<String> _resolvePatientName(String? patientUid) async {
    if (patientUid == null) return 'a patient';
    final cached = _patientNames[patientUid];
    if (cached != null) return cached;
    final profile = await PatientService.getPatientProfile(patientUid);
    final name = (profile?['name'] as String?)?.trim();
    final resolved = name != null && name.isNotEmpty ? name : 'a patient';
    _patientNames[patientUid] = resolved;
    if (mounted) setState(() {});
    return resolved;
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = dateStr.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
        .firstMatch(timeStr.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime? _combine(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime? _shiftStart(Map<String, dynamic> b) =>
      _combine(_parseDate(b['startDate'] as String?), _parseTime(b['startTime'] as String?));

  DateTime _shiftEnd(Map<String, dynamic> b, DateTime start) {
    final endDate = _parseDate(b['endDate'] as String?) ?? _parseDate(b['startDate'] as String?);
    final endTime = _parseTime(b['endTime'] as String?);
    final combined = _combine(endDate, endTime);
    if (combined != null && combined.isAfter(start)) return combined;
    return start.add(const Duration(hours: 8));
  }

  String _formatClock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime t) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.day} ${months[t.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _bookingsStream,
              builder: (context, bookingSnap) {
                final bookings = (bookingSnap.data ?? const [])
                    .where((b) => b['status'] != 'cancelled')
                    .toList();
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _reviewsStream,
                  builder: (context, reviewSnap) {
                    final reviews = reviewSnap.data ?? const [];
                    return _buildBody(context, bookings, reviews);
                  },
                );
              },
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> reviews,
  ) {
    final now = DateTime.now();

    // ── Real month/week/total counts ──────────────────────────────────────
    int thisMonth = 0, lastMonth = 0, thisWeek = 0, lastWeek = 0;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    final sundayDate = mondayDate.add(const Duration(days: 6));
    final lastMonday = mondayDate.subtract(const Duration(days: 7));
    final lastSunday = mondayDate.subtract(const Duration(days: 1));
    final lastMonthRef = DateTime(now.year, now.month - 1);

    final weekDutyDays = <int>{};
    Map<String, dynamic>? onDutyBooking;
    DateTime? onDutyStart;
    DateTime? onDutyEnd;
    final upcoming = <MapEntry<Map<String, dynamic>, DateTime>>[];

    for (final b in bookings) {
      final start = _shiftStart(b);
      if (start != null) {
        if (start.year == now.year && start.month == now.month) thisMonth++;
        if (start.year == lastMonthRef.year && start.month == lastMonthRef.month) lastMonth++;
        final startDateOnly = DateTime(start.year, start.month, start.day);
        if (!startDateOnly.isBefore(mondayDate) && !startDateOnly.isAfter(sundayDate)) {
          thisWeek++;
          weekDutyDays.add(start.weekday);
        }
        if (!startDateOnly.isBefore(lastMonday) && !startDateOnly.isAfter(lastSunday)) {
          lastWeek++;
        }
      }

      if (b['arrivalConfirmed'] == true && start != null) {
        final end = _shiftEnd(b, start);
        if (now.isAfter(start) && now.isBefore(end)) {
          onDutyBooking = b;
          onDutyStart = start;
          onDutyEnd = end;
        }
      } else if (start != null && start.isAfter(now)) {
        upcoming.add(MapEntry(b, start));
      }
    }
    upcoming.sort((a, b) => a.value.compareTo(b.value));
    final upcomingTop = upcoming.take(3).toList();

    final ratings = reviews
        .map((r) => (r['rating'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final avgRating = ratings.isEmpty ? null : ratings.reduce((a, b) => a + b) / ratings.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, onDutyBooking != null),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _statCard(
                          label: 'This month',
                          value: '$thisMonth',
                          valueColor: const Color(0xFF3D1678),
                          caption: 'bookings',
                          delta: _deltaFor(thisMonth, lastMonth),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          label: 'Your rating',
                          value: avgRating == null ? '—' : avgRating.toStringAsFixed(1),
                          valueColor: const Color(0xFF6B4814),
                          caption: reviews.isEmpty ? 'No reviews yet' : 'From ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _statCard(
                          label: 'This week',
                          value: '$thisWeek',
                          valueColor: const Color(0xFF0F6466),
                          caption: 'bookings',
                          delta: _deltaFor(thisWeek, lastWeek),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          label: 'Total',
                          value: '${bookings.length}',
                          valueColor: const Color(0xFF313131),
                          caption: 'bookings',
                          trailing: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/caregiver-schedule'),
                            child: const Text(
                              'See all',
                              style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF41311A), fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildWeekCard(mondayDate, sundayDate, weekDutyDays),
                const SizedBox(height: 16),
                if (onDutyBooking != null && onDutyStart != null && onDutyEnd != null)
                  _buildOnDutyBanner(onDutyBooking, onDutyStart, onDutyEnd, now),
                if (onDutyBooking != null) const SizedBox(height: 20),
                const Text(
                  'Upcoming schedule',
                  style: TextStyle(fontFamily: 'Open Sans', color: scheduleTitle, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (upcomingTop.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No upcoming bookings scheduled.',
                      style: TextStyle(fontFamily: 'Open Sans', color: weekDayLabel, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  )
                else
                  ...List.generate(upcomingTop.length, (i) {
                    final entry = upcomingTop[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i == upcomingTop.length - 1 ? 0 : 10),
                      child: _buildUpcomingCard(entry.key, entry.value, _avatarColors[i % _avatarColors.length]),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({bool up, String label})? _deltaFor(int current, int previous) {
    if (previous == 0) return null;
    final change = ((current - previous) / previous * 100);
    return (up: change >= 0, label: '${change.abs().toStringAsFixed(1)}%');
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool onDuty) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(27, topInset + 12, 22, 16),
      decoration: const BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caregiver',
                      style: TextStyle(fontFamily: 'Quattrocento Sans', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _caregiverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Quattrocento Sans', color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<String?>(
                valueListenable: AppState.caregiverProfileImagePath,
                builder: (context, imagePath, _) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: imagePath != null
                        ? ClipOval(child: RemoteOrLocalImage(source: imagePath, width: 50, height: 50))
                        : Center(
                            child: Text(
                              _initialsOf(_caregiverName),
                              style: const TextStyle(fontFamily: 'Quattrocento Sans', color: Color(0xFF06402B), fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: onDuty ? const Color(0xFFFBBC05) : const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                onDuty ? 'On duty' : 'Available',
                style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stat card ────────────────────────────────────────────────────────────
  Widget _statCard({
    required String label,
    required String value,
    required Color valueColor,
    String? caption,
    ({bool up, String label})? delta,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Quattrocento Sans', color: statLabel, fontSize: 14, fontWeight: FontWeight.w700)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontFamily: 'Quattrocento Sans', color: valueColor, fontSize: 32, fontWeight: FontWeight.w700)),
              if (delta != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: delta.up ? upGreenBg : downRedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          delta.up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: delta.up ? upGreenText : downRedText,
                          size: 11,
                        ),
                        Text(
                          delta.label,
                          style: TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            color: delta.up ? upGreenText : downRedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption, style: const TextStyle(fontFamily: 'Open Sans', color: statCaption, fontSize: 9, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  // ── This week duty tracker ───────────────────────────────────────────────
  Widget _buildWeekCard(DateTime monday, DateTime sunday, Set<int> dutyDays) {
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final rangeLabel = monday.month == sunday.month
        ? '${monday.day} – ${sunday.day} ${months[sunday.month]} ${sunday.year}'
        : '${monday.day} ${months[monday.month]} – ${sunday.day} ${months[sunday.month]} ${sunday.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: weekCardBorder, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This week', style: TextStyle(fontFamily: 'Open Sans', color: statCaption, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('${dutyDays.length} days on duty', style: const TextStyle(fontFamily: 'Open Sans', color: headerBg, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(rangeLabel, style: const TextStyle(fontFamily: 'Open Sans', color: weekDayLabel, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 57,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final weekday = i + 1;
                final active = dutyDays.contains(weekday);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
                    child: Column(
                      children: [
                        Container(
                          height: active ? 34 : 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: active ? weekBarActive : weekBarInactive,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(dayLetters[i], style: const TextStyle(fontFamily: 'Inter', color: weekDayLabel, fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Currently on duty banner ─────────────────────────────────────────────
  Widget _buildOnDutyBanner(Map<String, dynamic> booking, DateTime start, DateTime end, DateTime now) {
    final fraction = end.isAfter(start)
        ? (now.difference(start).inSeconds / end.difference(start).inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3D56), Color(0xFF07172E)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.favorite_rounded, color: Color(0xFFFBBC05), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Currently on duty', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    FutureBuilder<String>(
                      future: _resolvePatientName(booking['patientUid'] as String?),
                      builder: (context, snap) {
                        return Text(
                          'Caring for ${snap.data ?? 'a patient'}',
                          style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(255, 255, 255, 0.85), fontSize: 10, fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Started ${_formatDate(start)}, ${_formatClock(start)}', style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(255, 255, 255, 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Ends ${_formatDate(end)}, ${_formatClock(end)}', style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(255, 255, 255, 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(height: 5, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF485465), borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(height: 5, decoration: BoxDecoration(color: const Color(0xFFE3C95D), borderRadius: BorderRadius.circular(3))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Upcoming schedule card ───────────────────────────────────────────────
  Widget _buildUpcomingCard(Map<String, dynamic> booking, DateTime start, Color avatarColor) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final status = (booking['status'] as String? ?? 'requested');
    final statusLabel = status.isEmpty ? 'Requested' : '${status[0].toUpperCase()}${status.substring(1)}';
    final now = DateTime.now();
    final isToday = start.year == now.year && start.month == now.month && start.day == now.day;
    final dateLabel = isToday ? 'Today' : _formatDate(start);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: scheduleCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          FutureBuilder<String>(
            future: _resolvePatientName(booking['patientUid'] as String?),
            builder: (context, snap) {
              final name = snap.data ?? 'Patient';
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_initialsOf(name), style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              );
            },
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _resolvePatientName(booking['patientUid'] as String?),
                  builder: (context, snap) => Text(
                    snap.data ?? 'Patient',
                    style: const TextStyle(fontFamily: 'Open Sans', color: scheduleName, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateLabel, ${_formatClock(start)} · $careType',
                  style: const TextStyle(fontFamily: 'Open Sans', color: scheduleSubtitle, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: scheduleBadgeBg, borderRadius: BorderRadius.circular(999)),
            child: Text(statusLabel, style: const TextStyle(fontFamily: 'Open Sans', color: scheduleBadgeText, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', route: null),
      (icon: Icons.calendar_month_rounded, label: 'Booking', route: '/caregiver-schedule'),
      (icon: Icons.notifications_none_rounded, label: 'Notification', route: '/caregiver-notifications'),
      (icon: Icons.person_outline_rounded, label: 'Profile', route: '/caregiver-own-profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 67,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return GestureDetector(
                onTap: item.route == null ? null : () => Navigator.pushNamed(context, item.route!),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: Colors.white, size: 25),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(fontFamily: 'Quattrocento Sans', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
