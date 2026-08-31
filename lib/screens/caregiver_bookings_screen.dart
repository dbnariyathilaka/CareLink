import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/sri_lankan_cities.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/patient_service.dart';
import '../services/profile_gate.dart';
import '../widgets/caregiver_bottom_nav.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Bookings Screen ("My bookings" / "All requests")
//  Figma nodes: 476-796, 596-389, 596-710
// ─────────────────────────────────────────────────────────────
class CaregiverBookingsScreen extends StatefulWidget {
  const CaregiverBookingsScreen({super.key});

  @override
  State<CaregiverBookingsScreen> createState() => _CaregiverBookingsScreenState();
}

enum _Filter { all, emergency, newRequest, confirmed, missed }

class _CaregiverBookingsScreenState extends State<CaregiverBookingsScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleDark = Color(0xFF113341);
  static const Color chipActiveBg = Color(0xFF1F3554);
  static const Color chipInactiveText = Color(0xFF1F3554);

  static const Color newCardBg = Color.fromRGBO(129, 129, 123, 0.32);
  static const Color newAccent = Color(0xFF6D4275);

  static const Color confirmedCardBg = Color(0xFFCFCABE);
  static const Color confirmedGreen = Color(0xFF22C55E);

  static const Color missedCardBg = Color.fromRGBO(239, 231, 211, 0.87);
  static const Color missedAmber = Color(0xFFF59E0B);
  static const Color onDutyRed = Color(0xFFEF4444);

  static const Color emergencyRed = Color(0xFFDC2626);

  static const String _emptyBookingsGif = 'assets/images/empty_bookings.webp';

  Stream<List<Map<String, dynamic>>>? _bookingsStream;
  final Map<String, ({String name, String? photoUrl})> _patientInfo = {};
  String? _sharingBookingId;
  StreamSubscription<Position>? _positionSub;
  bool _requestingPermission = false;
  Position? _myPosition;
  Timer? _tickTimer;
  _Filter _selectedFilter = _Filter.all;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForCaregiver(uid);
    }
    _loadMyPosition();
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMyPosition() async {
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (mounted) setState(() => _myPosition = pos);
    } catch (_) {}
  }

  // Real patient name + real profile photo (patientProfiles/{uid}.photoUrl,
  // set when a patient uploads one in their own profile) — cached per uid
  // so switching cards/rebuilds doesn't refire the read.
  Future<({String name, String? photoUrl})> _resolvePatientInfo(String? patientUid) async {
    const fallback = (name: 'Patient', photoUrl: null);
    if (patientUid == null || patientUid.isEmpty) return fallback;
    final cached = _patientInfo[patientUid];
    if (cached != null) return cached;
    final profile = await PatientService.getPatientProfile(patientUid);
    final rawName = (profile?['name'] as String?)?.trim();
    final rawAltName = (profile?['patientName'] as String?)?.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (rawAltName != null && rawAltName.isNotEmpty)
            ? rawAltName
            : 'Patient';
    final photoUrl = (profile?['photoUrl'] as String?)?.trim();
    final result = (name: name, photoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null);
    _patientInfo[patientUid] = result;
    return result;
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Real photo when the patient has one, initials otherwise — never the
  // full name text stretched into a small circle.
  Widget _avatarCircle(
    String? patientUid, {
    required double size,
    required Decoration fallbackDecoration,
    required TextStyle initialsStyle,
  }) {
    return ClipOval(
      child: FutureBuilder<({String name, String? photoUrl})>(
        future: _resolvePatientInfo(patientUid),
        builder: (context, snap) {
          final info = snap.data;
          if (info?.photoUrl != null) {
            return RemoteOrLocalImage(source: info!.photoUrl!, width: size, height: size);
          }
          return Container(
            width: size,
            height: size,
            decoration: fallbackDecoration,
            alignment: Alignment.center,
            child: Text(_initialsOf(info?.name ?? 'Patient'), style: initialsStyle),
          );
        },
      ),
    );
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

  bool _isMissed(Map<String, dynamic> booking, DateTime? shiftStart) {
    final status = booking['status'] as String? ?? 'requested';
    if (status == 'missed') return true;
    if (status != 'requested') return false;
    if (shiftStart == null) return false;
    return DateTime.now().isAfter(shiftStart);
  }

  String? _distanceLabel(Map<String, dynamic> booking) {
    final myPos = _myPosition;
    if (myPos == null) return null;
    double? lat;
    double? lng;
    final geo = booking['geoPoint'];
    if (geo is Map) {
      lat = (geo['latitude'] as num?)?.toDouble();
      lng = (geo['longitude'] as num?)?.toDouble();
    } else if (booking['location'] is String) {
      final cityName = (booking['location'] as String).split(',').first.trim();
      final coords = cityCoords(cityName);
      if (coords != null) {
        lat = double.tryParse(coords['lat'] ?? '');
        lng = double.tryParse(coords['lng'] ?? '');
      }
    }
    if (lat == null || lng == null) return null;
    final meters = Geolocator.distanceBetween(myPos.latitude, myPos.longitude, lat, lng);
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  Future<void> _respond(String bookingId, bool accept) async {
    if (accept) {
      final allowed = await ensureCaregiverProfileComplete(context);
      if (!allowed) return;
    }
    await BookingService.respondToRequest(bookingId, accept: accept);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept ? 'Booking accepted' : 'Request declined'),
        backgroundColor: accept ? Colors.green.shade700 : Colors.grey.shade800,
      ),
    );
  }

  Future<void> _toggleSharing(String bookingId, bool start) async {
    if (!start) {
      await _positionSub?.cancel();
      _positionSub = null;
      await BookingService.stopLiveLocation(bookingId);
      if (mounted) setState(() => _sharingBookingId = null);
      return;
    }

    if (_requestingPermission) return;
    _requestingPermission = true;

    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services on your device')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission was denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied')),
          );
        }
        return;
      }

      final initial = await Geolocator.getCurrentPosition();
      await BookingService.updateLiveLocation(
        bookingId: bookingId,
        lat: initial.latitude,
        lng: initial.longitude,
      );

      await _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
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

  String _emptyTitleForFilter(_Filter filter) {
    switch (filter) {
      case _Filter.all:
        return 'No bookings yet';
      case _Filter.emergency:
        return 'No emergency requests';
      case _Filter.newRequest:
        return 'No new requests';
      case _Filter.confirmed:
        return 'No confirmed bookings';
      case _Filter.missed:
        return 'No missed requests';
    }
  }

  String _emptyBodyForFilter(_Filter filter) {
    switch (filter) {
      case _Filter.all:
        return "You haven't received any care requests yet. When patients send requests or schedule care with you, your bookings will appear here.";
      case _Filter.emergency:
        return "You don't have any emergency requests right now.";
      case _Filter.newRequest:
        return "You don't have any new booking requests waiting for your response.";
      case _Filter.confirmed:
        return "You don't have any confirmed bookings at the moment.";
      case _Filter.missed:
        return "You haven't missed any booking requests.";
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
              padding: EdgeInsets.fromLTRB(22, 6, 22, 0),
              child: Text(
                'All requests',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildFilterChips(),
            Expanded(child: _buildBody(context)),
            const CaregiverBottomNav(activeTab: CaregiverNavTab.booking),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = [
      (filter: _Filter.all, label: 'All'),
      (filter: _Filter.emergency, label: 'Emergency'),
      (filter: _Filter.newRequest, label: 'New'),
      (filter: _Filter.confirmed, label: 'Confirmed'),
      (filter: _Filter.missed, label: 'Missed'),
    ];
    return SizedBox(
      height: 38,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  fontSize: 12,
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
      return _buildEmptyState(
        title: _emptyTitleForFilter(_selectedFilter),
        body: _emptyBodyForFilter(_selectedFilter),
      );
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        final docs = snapshot.data ?? const [];
        final filtered = docs.where((b) {
          final shiftStart = _parseShiftStart(b['startDate'] as String?, b['startTime'] as String?);
          final missed = _isMissed(b, shiftStart);
          final status = b['status'] as String? ?? 'requested';
          switch (_selectedFilter) {
            case _Filter.all:
              return true;
            case _Filter.emergency:
              return b['isEmergency'] == true;
            case _Filter.newRequest:
              return status == 'requested' && !missed;
            case _Filter.confirmed:
              return status == 'confirmed';
            case _Filter.missed:
              return missed;
          }
        }).toList();

        if (filtered.isEmpty) {
          final isFiltered = _selectedFilter != _Filter.all;
          return _buildEmptyState(
            title: _emptyTitleForFilter(_selectedFilter),
            body: _emptyBodyForFilter(_selectedFilter),
            actionLabel: isFiltered ? 'All requests' : null,
            onAction: isFiltered ? () => setState(() => _selectedFilter = _Filter.all) : null,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 15, 20),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => _openPatientProfile(filtered[i]),
            child: _buildBookingCard(filtered[i]),
          ),
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
    if (booking['isEmergency'] == true) return _emergencyCard(booking);
    return _newRequestCard(booking);
  }

  Widget _nameText(String? patientUid, {required TextStyle style}) {
    return FutureBuilder<({String name, String? photoUrl})>(
      future: _resolvePatientInfo(patientUid),
      builder: (context, snap) => Text(snap.data?.name ?? 'Patient', style: style),
    );
  }

  // ── Emergency request card (real Accept/Decline) — a booking flagged
  // isEmergency: true, set when the request came from the Emergency
  // screen's "Request" button (see BookingService.createBookingRequest).
  Widget _emergencyCard(Map<String, dynamic> booking) {
    final id = booking['id'] as String;
    final patientUid = booking['patientUid'] as String?;
    final distance = _distanceLabel(booking);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [emergencyRed, Color(0xFF991B1B)],
        ),
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
                  color: Color.fromRGBO(255, 255, 255, 0.18),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Emergency', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, 0.25), borderRadius: BorderRadius.circular(999)),
                          child: const Text('Urgent', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _nameText(
                      patientUid,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: const Color.fromRGBO(255, 255, 255, 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _respond(id, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      child: Text('Accept', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Open Sans', color: emergencyRed, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: const Color.fromRGBO(255, 255, 255, 0.15),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _respond(id, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.35)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Decline',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(255, 255, 255, 0.8), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (distance != null) ...[
            const SizedBox(height: 8),
            Text(distance, style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(255, 255, 255, 0.75), fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
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
              _avatarCircle(
                patientUid,
                size: 44,
                fallbackDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2D4668), Color(0xFF071E40)]),
                ),
                initialsStyle: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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
    // Figma nodes 774:636 (Paid) / 774:643 (Non paid) — billing doesn't
    // exist in this app yet, so no booking ever carries a `paymentStatus`
    // field today. Absence of a recorded payment genuinely means "not
    // paid", so that's shown as the honest default rather than hiding the
    // indicator entirely.
    final isPaid = booking['paymentStatus'] == 'paid';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: confirmedCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatarCircle(
                patientUid,
                size: 44,
                fallbackDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                ),
                initialsStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF42413F), fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            careType,
                            style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: const Color.fromRGBO(34, 197, 94, 0.15), borderRadius: BorderRadius.circular(999)),
                          child: const Text('Confirmed', style: TextStyle(fontFamily: 'Open Sans', color: confirmedGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _nameText(
                      patientUid,
                      style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(0, 0, 0, 0.26), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isPaid ? confirmedGreen : const Color(0xFFBA4242),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isPaid ? 'Paid' : 'Non paid',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: isPaid ? confirmedGreen : const Color(0xFFBA4242),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color.fromRGBO(0, 0, 0, 0.1)),
          const SizedBox(height: 8),
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
              Expanded(
                child: Material(
                  color: isSharing ? Colors.amber.shade700 : const Color(0xFF1F3554),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _toggleSharing(id, !isSharing),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isSharing ? Icons.location_on : Icons.share_location_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isSharing ? 'Sharing...' : 'Share location',
                            style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: confirmedGreen,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _confirmArrival(id),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'I\'ve arrived',
                            style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
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

  // ── On duty card (live session active) ───────────────────
  Widget _onDutyCard(Map<String, dynamic> booking) {
    final patientUid = booking['patientUid'] as String?;
    final startTime = booking['startTime'] as String?;
    final endTime = booking['endTime'] as String?;
    final timeRange = (startTime != null && endTime != null) ? '$startTime–$endTime' : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: missedCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onDutyRed, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: onDutyRed, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('On duty', style: TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          FutureBuilder<({String name, String? photoUrl})>(
            future: _resolvePatientInfo(patientUid),
            builder: (context, snap) {
              final name = snap.data?.name ?? 'Patient';
              return Text(
                ['Caring for $name', if (timeRange != null) timeRange].join(' · '),
                style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(49, 49, 49, 0.79), fontSize: 12, fontWeight: FontWeight.w600),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Missed card ──────────────────────────────────────────
  Widget _missedCard(Map<String, dynamic> booking) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final distance = _distanceLabel(booking);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 19, 17, 17),
      decoration: BoxDecoration(
        color: missedCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: missedAmber, width: 1),
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
          const Text(
            'Request expired while you were busy',
            style: TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            [careType, if (distance != null) distance].join(' · '),
            style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(49, 49, 49, 0.79), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Declined card ────────────────────────────────────────
  Widget _declinedCard(Map<String, dynamic> booking) {
    final careType = booking['careType'] as String? ?? 'Care visit';
    final startDate = booking['startDate'] as String?;
    final patientUid = booking['patientUid'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFCBD5E1)),
            alignment: Alignment.center,
            child: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nameText(patientUid, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  ['Declined', careType, if (startDate != null) startDate].join(' · '),
                  style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
