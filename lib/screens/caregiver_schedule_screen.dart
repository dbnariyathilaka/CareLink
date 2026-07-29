import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Schedule Screen
//  Real bookings assigned to this caregiver. Each one lets the
//  caregiver confirm arrival and share their real live GPS
//  position with the patient while a shift is in progress —
//  the data behind the patient's "track caregiver" screen.
// ─────────────────────────────────────────────────────────────
class CaregiverScheduleScreen extends StatefulWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  State<CaregiverScheduleScreen> createState() => _CaregiverScheduleScreenState();
}

class _CaregiverScheduleScreenState extends State<CaregiverScheduleScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _green = Color(0xFF22C55E);

  Stream<List<Map<String, dynamic>>>? _bookingsStream;
  String? _sharingBookingId;
  StreamSubscription<Position>? _positionSub;
  bool _requestingPermission = false;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForCaregiver(uid);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    if (_sharingBookingId != null) {
      // Best-effort cleanup — don't block screen teardown on the write.
      BookingService.stopLiveLocation(_sharingBookingId!);
    }
    super.dispose();
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
    if (timeMatch == null) return null;
    var hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final period = timeMatch.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return DateTime(year, month, day, hour, minute);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Text(
                'Schedule',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: _buildBody(context)),
            _buildBottomNav(context),
          ],
        ),
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
        if (docs.isEmpty) {
          return const EmptyState(icon: Icons.calendar_month_rounded, message: 'No bookings yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildBookingCard(docs[i]),
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final id = booking['id'] as String;
    final careType = booking['careType'] as String? ?? 'Care visit';
    final startDate = booking['startDate'] as String?;
    final startTime = booking['startTime'] as String?;
    final location = booking['location'] as String?;
    final arrived = booking['arrivalConfirmed'] == true;
    final isSharing = _sharingBookingId == id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  careType,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (arrived)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Arrived',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (startDate != null) startDate,
              if (startTime != null) startTime,
            ].join(' · '),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (location != null && location.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              location,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (!arrived) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Switch(
                        value: isSharing,
                        activeThumbColor: _indigo,
                        onChanged: _requestingPermission
                            ? null
                            : (v) => _toggleSharing(id, v),
                      ),
                      const Expanded(
                        child: Text(
                          'Share live location',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: _indigo,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _confirmArrival(id),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "I've arrived",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
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
        ),
      ),
    );
  }
}
