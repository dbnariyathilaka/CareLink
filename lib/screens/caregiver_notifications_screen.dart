import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/patient_service.dart';
import '../services/review_service.dart';
import '../widgets/caregiver_bottom_nav.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Notifications Screen
//  Figma node: 475-605
//  Figma mocks a rich feed (emergency requests, payments, a
//  "reach-back" flow, instant Accept/Decline on booking requests)
//  that has no backing data or actions anywhere in this codebase.
//  There's no notifications collection at all, so this feed is
//  computed live from real bookings + reviews instead of being
//  fabricated or persisted:
//   - new booking requests, cancellations and reviews (real events,
//     real timestamps)
//   - "shift starting/ending soon" (computed from the real
//     start/end time vs. now, same logic as the dashboard's
//     on-duty detection)
//   - a patient's pending extension request, with real Agree/
//     Decline actions wired to BookingService.resolveExtension
//  "New booking request" links to the real schedule screen rather
//  than a fake instant Accept/Decline, since no caregiver-side
//  accept flow exists.
// ─────────────────────────────────────────────────────────────
class CaregiverNotificationsScreen extends StatefulWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  State<CaregiverNotificationsScreen> createState() => _CaregiverNotificationsScreenState();
}

class _CaregiverNotificationsScreenState extends State<CaregiverNotificationsScreen> {
  static const Color bg = Color(0xFFFEFBEF);
  static const Color titleDark = Color(0xFF1F3554);
  static const Color cardBg = Color(0xFFEEDEC9);
  static const Color timeMuted = Color(0xFF765F43);
  static const Color subtitleMuted = Color.fromRGBO(0, 0, 0, 0.55);
  static const Color emptyTitleBrown = Color(0xFF462911);
  static const Color emptyBodyColor = Color.fromRGBO(39, 34, 77, 0.67);
  static const String _emptyNotificationGif = 'assets/images/notification.gif';

  static const Color inboxAccent = Color(0xFF424366);
  static const Color extendAccent = Color(0xFF336466);
  static const Color extendAgreeBg = Color.fromRGBO(38, 123, 106, 0.57);
  static const Color extendAgreeText = Color(0xFF11443A);
  static const Color extendDeclineAccent = Color(0xFF267B6A);
  static const Color startingSoonAccent = Color(0xFF521D5F);
  static const Color endingSoonAccent = Color(0xFFA2831C);
  static const Color cancelledAccent = Color(0xFF89456F);
  static const Color reviewAccent = Color(0xFFF59E0B);

  Stream<List<Map<String, dynamic>>>? _bookingsStream;
  Stream<List<Map<String, dynamic>>>? _reviewsStream;
  final Map<String, String> _patientNames = {};
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForCaregiver(uid);
      _reviewsStream = ReviewService.streamReviewsForCaregiver(uid);
    }
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
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
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(timeStr.trim());
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

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  String _durationWords(Duration d) {
    if (d.inMinutes < 60) {
      final m = d.inMinutes < 1 ? 1 : d.inMinutes;
      return '$m minute${m == 1 ? '' : 's'}';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '$h hour${h == 1 ? '' : 's'}' : '${h}h ${m}m';
  }

  Future<void> _resolveExtension(String bookingId, bool accept) async {
    await BookingService.resolveExtension(bookingId, accept: accept);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(accept ? 'Extension accepted.' : 'Extension declined.')),
    );
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
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 16, 22, 10),
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: _buildBody(context)),
            const CaregiverBottomNav(activeTab: CaregiverNavTab.notification),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_bookingsStream == null) {
      return _buildEmptyState();
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingsStream,
      builder: (context, bookingSnap) {
        final bookings = bookingSnap.data ?? const [];
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _reviewsStream,
          builder: (context, reviewSnap) {
            final reviews = reviewSnap.data ?? const [];
            final cards = _buildCards(bookings, reviews);
            if (cards.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 16),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => cards[i],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 297,
              height: 297,
              child: Image.asset(
                _emptyNotificationGif,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.notifications_none_rounded,
                  size: 120,
                  color: titleDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Notifications Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: emptyTitleBrown,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 354,
              child: Text(
                "Notifications appear once there's an update. You'll see booking confirmations, reminders, and messages here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: emptyBodyColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 22.4 / 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCards(List<Map<String, dynamic>> bookings, List<Map<String, dynamic>> reviews) {
    final now = DateTime.now();
    final urgent = <_TimedCard>[];
    final events = <_TimedCard>[];

    for (final b in bookings) {
      final status = b['status'] as String?;
      final createdAt = b['createdAt'];
      final createdTime = createdAt is Timestamp ? createdAt.toDate() : now;
      final date = _parseDate(b['startDate'] as String?);
      final startTime = _parseTime(b['startTime'] as String?);
      final endTime = _parseTime(b['endTime'] as String?);
      final shiftStart = _combine(date, startTime);
      final shiftEnd = _combine(date, endTime) ?? shiftStart?.add(const Duration(hours: 8));
      final arrivalConfirmed = b['arrivalConfirmed'] == true;

      if (status == 'requested') {
        events.add(_TimedCard(createdTime, _bookingRequestCard(b)));
      }

      if (status == 'cancelled') {
        final cancelledAt = b['cancelledAt'];
        final time = cancelledAt is Timestamp ? cancelledAt.toDate() : createdTime;
        events.add(_TimedCard(time, _cancelledCard(b, time)));
      }

      final pendingExtension = b['pendingExtension'] as Map<String, dynamic>?;
      if (pendingExtension != null) {
        final requestedAt = pendingExtension['requestedAt'];
        final time = requestedAt is Timestamp ? requestedAt.toDate() : now;
        urgent.add(_TimedCard(time, _extendRequestCard(b, pendingExtension, time)));
      }

      if (status != 'cancelled' && !arrivalConfirmed && shiftStart != null) {
        final until = shiftStart.difference(now);
        if (until > Duration.zero && until <= const Duration(hours: 1)) {
          urgent.add(_TimedCard(now, _shiftStartingSoonCard(b, until)));
        }
      }

      if (status != 'cancelled' && arrivalConfirmed && shiftStart != null && shiftEnd != null) {
        if (now.isAfter(shiftStart) && now.isBefore(shiftEnd)) {
          final until = shiftEnd.difference(now);
          if (until <= const Duration(minutes: 30)) {
            urgent.add(_TimedCard(now, _serviceEndingSoonCard(b, until)));
          }
        }
      }
    }

    for (final r in reviews) {
      final createdAt = r['createdAt'];
      final time = createdAt is Timestamp ? createdAt.toDate() : now;
      events.add(_TimedCard(time, _reviewCard(r, time)));
    }

    events.sort((a, b) => b.time.compareTo(a.time));
    return [...urgent.map((c) => c.card), ...events.map((c) => c.card)];
  }

  // ── Card shell ────────────────────────────────────────────
  Widget _card({
    required IconData icon,
    required Color accent,
    required String title,
    required String timeLabel,
    required Widget subtitle,
    Color? background,
    Widget? actions,
    VoidCallback? onTap,
  }) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 13, 13),
      decoration: BoxDecoration(
        color: background ?? cardBg,
        border: Border(
          top: BorderSide(color: accent, width: 1),
          right: BorderSide(color: accent, width: 1),
          bottom: BorderSide(color: accent, width: 1),
          left: BorderSide(color: accent, width: 4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: timeMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    subtitle,
                  ],
                ),
              ),
            ],
          ),
          if (actions != null) ...[
            const SizedBox(height: 10),
            actions,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _subtitleText(String text, {Color color = subtitleMuted}) {
    return Text(
      text,
      style: TextStyle(fontFamily: 'Open Sans', color: color, fontSize: 11, fontWeight: FontWeight.w500, height: 1.4),
    );
  }

  Widget _nameSubtitle(String? patientUid, String Function(String name) build) {
    return FutureBuilder<String>(
      future: _resolvePatientName(patientUid),
      builder: (context, snap) => _subtitleText(build(snap.data ?? 'Patient')),
    );
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

  // ── New booking request ──────────────────────────────────
  Widget _bookingRequestCard(Map<String, dynamic> booking) {
    final careType = booking['careType'] as String? ?? 'care visit';
    final createdAt = booking['createdAt'];
    final time = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();
    return _card(
      icon: Icons.inbox_rounded,
      accent: inboxAccent,
      title: 'New booking request',
      timeLabel: _relativeTime(time),
      subtitle: _nameSubtitle(booking['patientUid'] as String?, (name) => '$name · $careType'),
      onTap: () => _openPatientProfile(booking),
    );
  }

  // ── Extend service request (real pendingExtension field) ──
  Widget _extendRequestCard(Map<String, dynamic> booking, Map<String, dynamic> pending, DateTime time) {
    final id = booking['id'] as String? ?? '';
    final extraMinutes = pending['extraMinutes'] as int?;
    return _card(
      icon: Icons.alarm_rounded,
      accent: extendAccent,
      title: 'Extend service request',
      timeLabel: _relativeTime(time),
      subtitle: _nameSubtitle(
        booking['patientUid'] as String?,
        (name) => extraMinutes != null
            ? '$name has requested to extend today\'s service by $extraMinutes minutes. Do you agree?'
            : '$name has requested to extend today\'s service time. Do you agree?',
      ),
      actions: Row(
        children: [
          Material(
            color: extendAgreeBg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: id.isEmpty ? null : () => _resolveExtension(id, true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text('Agree', style: TextStyle(fontFamily: 'Open Sans', color: extendAgreeText, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: id.isEmpty ? null : () => _resolveExtension(id, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: extendDeclineAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Decline', style: TextStyle(fontFamily: 'Open Sans', color: extendDeclineAccent, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shift starting soon (computed from real start time) ───
  Widget _shiftStartingSoonCard(Map<String, dynamic> booking, Duration until) {
    return _card(
      icon: Icons.play_circle_outline_rounded,
      accent: startingSoonAccent,
      title: 'Shift starting soon',
      timeLabel: 'Now',
      subtitle: _nameSubtitle(
        booking['patientUid'] as String?,
        (name) => 'You have only ${_durationWords(until)} left to serve $name. Please get ready.',
      ),
      onTap: () => _openPatientProfile(booking),
    );
  }

  // ── Service ending soon (computed from real end time) ─────
  Widget _serviceEndingSoonCard(Map<String, dynamic> booking, Duration until) {
    return _card(
      icon: Icons.schedule_rounded,
      accent: endingSoonAccent,
      title: 'Service ending soon',
      timeLabel: 'Now',
      subtitle: _nameSubtitle(
        booking['patientUid'] as String?,
        (name) => 'You have only ${_durationWords(until)} left to end your service with $name. Please start wrapping up.',
      ),
      onTap: () => _openPatientProfile(booking),
    );
  }

  // ── Booking cancelled ─────────────────────────────────────
  Widget _cancelledCard(Map<String, dynamic> booking, DateTime time) {
    return _card(
      icon: Icons.event_busy_rounded,
      accent: cancelledAccent,
      background: const Color.fromRGBO(231, 206, 180, 0.5),
      title: 'Booking cancelled',
      timeLabel: _relativeTime(time),
      subtitle: _nameSubtitle(booking['patientUid'] as String?, (name) => '$name cancelled the booking.'),
      onTap: () => _openPatientProfile(booking),
    );
  }

  // ── New review (real rating + text) ────────────────────────
  Widget _reviewCard(Map<String, dynamic> review, DateTime time) {
    final rating = review['rating'] as int?;
    final text = (review['text'] as String?)?.trim();
    return _card(
      icon: Icons.star_rounded,
      accent: reviewAccent,
      title: 'New review',
      timeLabel: _relativeTime(time),
      subtitle: _nameSubtitle(
        review['patientUid'] as String?,
        (name) {
          final ratingText = rating != null ? 'gave you $rating star${rating == 1 ? '' : 's'}' : 'left a review';
          final excerpt = text != null && text.isNotEmpty ? ' — "$text"' : '';
          return '$name $ratingText.$excerpt';
        },
      ),
      onTap: () => _openPatientProfile(review),
    );
  }
}

class _TimedCard {
  const _TimedCard(this.time, this.card);
  final DateTime time;
  final Widget card;
}
