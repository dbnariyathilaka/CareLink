import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/patient_service.dart';
import '../widgets/status_bar.dart';
import 'admin_finance_screen.dart';

enum BookingFilter { unfulfilled, active, upcoming, cancelled }

/// View-model for one booking card — built from a real `bookingRequests` /
/// `cancelledBookings` document (see [_AdminBookingsScreenState._buildCardData]),
/// never from static/mock data.
class AdminBookingData {
  final String id;
  final BookingFilter status;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String title;
  final String subtitle;
  final String? waitingLabel; // real elapsed wait, derived from createdAt (unfulfilled)
  final int? progressPercent; // real on-duty progress, derived from schedule (active)
  final String? cancelledLabel; // real cancellation time, derived from cancelledAt (cancelled)

  const AdminBookingData({
    required this.id,
    required this.status,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.title,
    required this.subtitle,
    this.waitingLabel,
    this.progressPercent,
    this.cancelledLabel,
  });
}

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key, this.initialFilter = BookingFilter.active});

  final BookingFilter initialFilter;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  // ── Color Tokens matching Figma node 641:514 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color filterActiveBg = Color(0xFF585247);
  static const Color filterActiveFg = Colors.white;
  static const Color filterInactiveBorder = Color(0xFF585247);

  static const Color emergencyBg = Color(0x17EF4444); // ~9%
  static const Color emergencyBorder = Color(0x59EF4444); // ~35%
  static const Color emergencyTitle = Color(0xFFEF4444);
  static const Color emergencyWaiting = Color(0xFF6D6B3B);
  static const Color emergencyName = Color(0xFF73513F);
  static const Color emergencySubtitle = Color(0xFF816A52);
  static const Color reviewBtnBg = Color(0xFFEF4444);

  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF412800);
  static const Color cardTitle = Color(0xFF544730);
  static const Color cardSubtitle = Color(0xFFFCE8C3);

  static const Color onDutyBadgeBg = Color(0x2922C55E);
  static const Color onDutyBadgeFg = Color(0xFF2B4A11);
  static const Color upcomingBadgeBg = Color(0x290EA5E9);
  static const Color upcomingBadgeFg = Color(0xFF1C5F7C);

  static const Color progressTrack = Color(0xFF44331C);
  static const Color progressFill = Color(0xFF82571E);
  static const Color progressLabel = Color(0xFF785618);

  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  // Decorative avatar palette — purely visual styling (not backed by any
  // Firestore field), rotated deterministically by booking id so cards
  // still look varied.
  static final List<(Color, Color)> _avatarPalette = [
    (const Color(0xFF784B26), const Color(0xFFFBBC05)),
    (const Color(0xFF357F83), Colors.white),
    (const Color(0xFF6ED5C9), const Color(0xFF04302C)),
    (const Color(0xFF354152), const Color(0xFFCBD5E1)),
  ];

  late BookingFilter _activeFilter;
  late final Stream<List<Map<String, dynamic>>> _bookingsStream;

  // Bookings only store patientUid (+ the denormalized caregiverName), so
  // the patient's display name is joined from PatientService and cached
  // here to avoid re-fetching on every rebuild.
  final Map<String, String> _patientNames = {};
  final Set<String> _fetchingPatientNames = {};
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
    setStatusBarStyle(Brightness.dark);
    _bookingsStream = BookingService.streamAllBookingsForAdmin();
    // Elapsed-wait labels and on-duty progress bars are derived from real
    // timestamps and drift as real time passes, so tick a periodic rebuild.
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _prefetchPatientNames(List<Map<String, dynamic>> bookings) {
    final toFetch = <String>{};
    for (final b in bookings) {
      final uid = b['patientUid'] as String?;
      if (uid != null &&
          uid.isNotEmpty &&
          !_patientNames.containsKey(uid) &&
          !_fetchingPatientNames.contains(uid)) {
        toFetch.add(uid);
      }
    }
    if (toFetch.isEmpty) return;
    _fetchingPatientNames.addAll(toFetch);
    Future(() async {
      for (final uid in toFetch) {
        _patientNames[uid] = await PatientService.getPatientName(uid);
      }
      if (mounted) setState(() {});
    });
  }

  String _patientNameFor(String? uid) {
    if (uid == null || uid.isEmpty) return 'Patient';
    return _patientNames[uid] ?? 'Patient';
  }

  // ── Real status/time categorization into the four booking tabs ─────────
  BookingFilter? _categorize(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'requested';
    if (status == 'cancelled') return BookingFilter.cancelled;
    if (status == 'requested') return BookingFilter.unfulfilled;
    if (status != 'confirmed') return null; // e.g. 'declined' — not shown in any tab
    final start = BookingService.parseBookingDateTime(
      data['startDate'] as String?,
      data['startTime'] as String?,
    );
    if (start != null && DateTime.now().isBefore(start)) return BookingFilter.upcoming;
    return BookingFilter.active;
  }

  void _reviewEmergency(AdminBookingData b) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening emergency review for ${b.title}...'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            final allBookings = snapshot.data ?? const <Map<String, dynamic>>[];
            _prefetchPatientNames(allBookings);

            final counts = {for (final f in BookingFilter.values) f: 0};
            final filtered = <Map<String, dynamic>>[];
            for (final booking in allBookings) {
              final category = _categorize(booking);
              if (category == null) continue;
              counts[category] = (counts[category] ?? 0) + 1;
              if (category == _activeFilter) filtered.add(booking);
            }
            final cards = filtered.map((b) => _buildCardData(b, _activeFilter)).toList();
            final isLoading = !snapshot.hasData && snapshot.connectionState == ConnectionState.waiting;

            return Column(
              children: [
                _buildHeader(),
                _buildFilterBar(counts),
                const SizedBox(height: 8),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: titleColor))
                      : cards.isEmpty
                          ? Center(
                              child: Text(
                                'No bookings in this category',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor.withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                              itemCount: cards.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 11),
                              itemBuilder: (context, index) => _buildBookingCard(cards[index]),
                            ),
                ),
                _buildBottomNav(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'Bookings',
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: titleColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: titleColor),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────
  Widget _buildFilterBar(Map<BookingFilter, int> counts) {
    final filters = [
      (BookingFilter.unfulfilled, 'Unfulfilled ${counts[BookingFilter.unfulfilled] ?? 0}'),
      (BookingFilter.active, 'Active ${counts[BookingFilter.active] ?? 0}'),
      (BookingFilter.upcoming, 'Upcoming'),
      (BookingFilter.cancelled, 'Cancelled'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Wrap(
        spacing: 7,
        runSpacing: 8,
        children: filters.map((f) {
          final isActive = _activeFilter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? filterActiveBg : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: filterInactiveBorder, width: isActive ? 0 : 1),
              ),
              child: Text(
                f.$2,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? filterActiveFg : filterInactiveBorder,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Real-data → view-model mapping ──────────────────────────────────────
  AdminBookingData _buildCardData(Map<String, dynamic> raw, BookingFilter filter) {
    final id = raw['id'] as String? ?? '';
    final rawCaregiverName = (raw['caregiverName'] as String?)?.trim();
    final caregiverName = (rawCaregiverName != null && rawCaregiverName.isNotEmpty) ? rawCaregiverName : 'Caregiver';
    final patientName = _patientNameFor(raw['patientUid'] as String?);
    final rawCareType = (raw['careType'] as String?)?.trim();
    final careType = (rawCareType != null && rawCareType.isNotEmpty) ? rawCareType : 'Care';
    final startDate = raw['startDate'] as String?;
    final startTime = raw['startTime'] as String?;
    final endDate = raw['endDate'] as String?;
    final endTime = raw['endTime'] as String?;
    final location = (raw['location'] as String?)?.trim();
    final duration = (raw['duration'] as String?)?.trim();

    final palette = _avatarPalette[id.hashCode.abs() % _avatarPalette.length];

    String title;
    String subtitle;
    String? waitingLabel;
    int? progressPercent;
    String? cancelledLabel;

    switch (filter) {
      case BookingFilter.unfulfilled:
        title = '$patientName · $careType';
        subtitle =
            '${_scheduleLine(startDate, startTime, endTime, location)} · Awaiting response from $caregiverName';
        waitingLabel = _elapsedSince(raw['createdAt']);
        break;
      case BookingFilter.active:
        title = '$caregiverName → $patientName';
        subtitle = '$careType · ${startTime ?? '--'} – ${endTime ?? '--'}';
        progressPercent = _onDutyProgress(startDate, startTime, endDate, endTime);
        break;
      case BookingFilter.upcoming:
        title = '$caregiverName → $patientName';
        final timing =
            (duration != null && duration.isNotEmpty) ? duration : '${startTime ?? '--'} – ${endTime ?? '--'}';
        subtitle = '$careType · ${startDate ?? 'Date TBC'} · $timing';
        break;
      case BookingFilter.cancelled:
        title = '$caregiverName → $patientName';
        subtitle = '$careType · ${_scheduleLine(startDate, startTime, endTime, location)}';
        cancelledLabel = _cancelledAgo(raw['cancelledAt']);
        break;
    }

    return AdminBookingData(
      id: id,
      status: filter,
      initials: _initialsFor(caregiverName),
      avatarBg: palette.$1,
      avatarTextColor: palette.$2,
      title: title,
      subtitle: subtitle,
      waitingLabel: waitingLabel,
      progressPercent: progressPercent,
      cancelledLabel: cancelledLabel,
    );
  }

  String _scheduleLine(String? date, String? startTime, String? endTime, String? location) {
    final parts = <String>[];
    if (date != null && date.isNotEmpty) parts.add(date);
    if (startTime != null && startTime.isNotEmpty) {
      parts.add((endTime != null && endTime.isNotEmpty) ? '$startTime – $endTime' : startTime);
    }
    if (location != null && location.isNotEmpty) parts.add(location);
    return parts.isEmpty ? 'Schedule not set' : parts.join(' · ');
  }

  String _initialsFor(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  String _elapsedSince(dynamic timestamp) {
    if (timestamp is! Timestamp) return '';
    final elapsed = DateTime.now().difference(timestamp.toDate());
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h';
    return '${elapsed.inDays}d';
  }

  String _cancelledAgo(dynamic timestamp) {
    if (timestamp is! Timestamp) return 'Cancelled';
    final elapsed = DateTime.now().difference(timestamp.toDate());
    if (elapsed.inDays >= 1) return 'Cancelled ${elapsed.inDays}d ago';
    if (elapsed.inHours >= 1) return 'Cancelled ${elapsed.inHours}h ago';
    if (elapsed.inMinutes >= 1) return 'Cancelled ${elapsed.inMinutes} min ago';
    return 'Cancelled just now';
  }

  int? _onDutyProgress(String? startDate, String? startTime, String? endDate, String? endTime) {
    final start = BookingService.parseBookingDateTime(startDate, startTime);
    final end = BookingService.parseBookingDateTime(endDate ?? startDate, endTime);
    if (start == null || end == null) return null;
    final totalMs = end.difference(start).inMilliseconds;
    if (totalMs <= 0) return null;
    final elapsedMs = DateTime.now().difference(start).inMilliseconds.clamp(0, totalMs);
    return elapsedMs * 100 ~/ totalMs;
  }

  // ── Booking cards ───────────────────────────────────────────────────────
  Widget _buildBookingCard(AdminBookingData b) {
    switch (b.status) {
      case BookingFilter.unfulfilled:
        return _buildEmergencyCard(b);
      case BookingFilter.active:
        return _buildActiveCard(b);
      case BookingFilter.upcoming:
        return _buildUpcomingCard(b);
      case BookingFilter.cancelled:
        return _buildCancelledCard(b);
    }
  }

  Widget _buildEmergencyCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: emergencyBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: emergencyBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: emergencyTitle),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Unassigned · awaiting caregiver',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: emergencyTitle),
                ),
              ),
              if (b.waitingLabel != null && b.waitingLabel!.isNotEmpty)
                Text(
                  b.waitingLabel!,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: emergencyWaiting),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            b.title,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: emergencyName),
          ),
          const SizedBox(height: 2),
          Text(
            b.subtitle,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w500, color: emergencySubtitle),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: reviewBtnBg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _reviewEmergency(b),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Center(
                    child: Text(
                      'Review',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeaderRow(b, badgeBg: onDutyBadgeBg, badgeFg: onDutyBadgeFg, badgeText: 'ON DUTY'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(color: progressTrack),
                        FractionallySizedBox(
                          widthFactor: (b.progressPercent ?? 0) / 100,
                          child: Container(color: progressFill),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${b.progressPercent ?? 0}%',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: progressLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: _buildCardHeaderRow(b, badgeBg: upcomingBadgeBg, badgeFg: upcomingBadgeFg, badgeText: 'UPCOMING'),
    );
  }

  Widget _buildCancelledCard(AdminBookingData b) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeaderRow(b),
          if (b.cancelledLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              b.cancelledLabel!,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: cardTitle),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardHeaderRow(AdminBookingData b, {Color? badgeBg, Color? badgeFg, String? badgeText}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: b.avatarBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            b.initials,
            style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: b.avatarTextColor),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.title,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w700, color: cardTitle),
              ),
              Text(
                b.subtitle,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: cardSubtitle),
              ),
            ],
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
            child: Text(
              badgeText,
              style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: badgeFg),
            ),
          ),
      ],
    );
  }

  // ── Bottom Navigation Bar (matching Admin Dashboard) ────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.insights_rounded},
      {'label': 'Users', 'icon': Icons.people_alt_outlined},
      {'label': 'Bookings', 'icon': Icons.calendar_month_outlined},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined},
      {'label': 'More', 'icon': Icons.more_horiz_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: bottomNavBg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == 2; // Bookings tab is active
          final color = isSelected ? navGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (index == 0 || index == 1 || index == 4) {
                Navigator.pop(context);
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminFinanceScreen()),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 22, color: color),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
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
