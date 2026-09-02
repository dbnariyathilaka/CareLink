import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/matching_service.dart';
import '../services/patient_service.dart';
import '../services/profile_gate.dart';
import '../widgets/patient_notification_badge.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';
import 'emergency_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────
  String _userName = 'there';
  int _caregiverCount = 0;

  bool _loadingTopMatches = true;
  List<MatchResult> _topMatches = const [];

  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSub;
  List<Map<String, dynamic>> _bookings = [];

  List<Map<String, dynamic>> _savedCaregivers = [];
  final Map<String, String?> _caregiverPhotos = {};

  Future<String?> _resolveCaregiverPhoto(String? uid) async {
    if (uid == null || uid.isEmpty) return null;
    if (_caregiverPhotos.containsKey(uid)) return _caregiverPhotos[uid];
    final profile = await CaregiverService.getCaregiverProfile(uid);
    final photo = (profile?['photoUrl'] as String?)?.trim();
    final result = (photo != null && photo.isNotEmpty) ? photo : null;
    _caregiverPhotos[uid] = result;
    return result;
  }

  // Real-time ETA from OSRM (only when caregiver has liveLocation)
  int? _etaMinutes;
  DateTime? _lastEtaFetch;
  double? _lastLiveLat;
  double? _lastLiveLng;

  late final AnimationController _matchIconController;
  late final Animation<double> _matchIconRotation;

  // ── Color tokens ─────────────────────────────────────────────────────
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color darkGreenCard = Color(0xFF0C3B2E);
  static const Color emergencyRed = Color(0xFF9E0606);
  static const Color requestCardBg = Color(0xFFD4CDC3);
  static const Color topMatchCardBg = Color(0xFFD4CEC3);
  static const Color atGlanceBg = Color.fromRGBO(129, 117, 102, 0.76);
  static const Color trackBtnYellow = Color(0xFFD8C400);
  static const Color ongoingGreen = Color(0xFFACF4B6);
  static const Color progressDoneLine = Color(0xFF565138);
  static const Color progressActiveLine = Color(0xFFADA56E);
  static const Color progressEmptyLine = Color(0xFFE5E2DC);
  static const Color progressDoneCircle = Color(0xFF8D8357);
  static const Color progressActiveCircle = Color(0xFFE8D9AA);
  static const Color progressEmptyCircle = Color(0xFFE5E2DC);
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);
  static const Color tagGreenBg = Color.fromRGBO(74, 120, 46, 0.15);
  static const Color tagGreenText = Color(0xFF3C4624);
  static const Color tagBrownBg = Color.fromRGBO(120, 107, 46, 0.15);
  static const Color tagBrownText = Color(0xFF44331C);
  static const Color matchBadgeBg = Color.fromRGBO(101, 29, 29, 0.12);
  static const Color matchBadgeText = Color(0xFF651D1D);

  // ── Lifecycle ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _loadUserName();
    _loadOwnPhoto();
    _loadCaregiverCount();
    _loadTopMatches();
    _subscribeBookings();
    _loadSavedCaregivers();

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
    _bookingsSub?.cancel();
    _matchIconController.dispose();
    super.dispose();
  }

  // ── Greeting ──────────────────────────────────────────────────────────
  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_twilight_rounded;
    if (hour < 17) return Icons.wb_sunny_rounded;
    if (hour < 21) return Icons.nights_stay_rounded;
    return Icons.bedtime_rounded;
  }

  // ── Data loading ──────────────────────────────────────────────────────
  Future<void> _loadUserName() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final patientProf = await PatientService.getPatientProfile(user.uid);
    final userProf = await AuthService.getUserProfile(user.uid);
    final name = (patientProf?['patientName'] as String?) ??
        (patientProf?['name'] as String?) ??
        (userProf?['name'] as String?);
    if (name != null && name.isNotEmpty) {
      AppState.patientName.value = name;
      if (mounted) setState(() => _userName = name);
    }
  }

  Future<void> _loadOwnPhoto() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final profile = await PatientService.getPatientProfile(user.uid);
    AppState.hydratePatientPhoto(profile?['photoUrl'] as String?);
  }

  // "Caregivers near you" — real caregivers within 10km of the patient's
  // registered city, via the same city-coordinate + haversine approach
  // MatchingService already uses for proximity scoring (there's no exact
  // GPS stored for either side, only registered city). Also checks the
  // caregiver's `isAvailable` flag — no real presence/online system exists
  // anywhere in this app, so this currently never excludes anyone (the
  // field is never actually written), but keeps the filter honest and
  // ready if a real online toggle is added later.
  Future<void> _loadCaregiverCount() async {
    final uid = AuthService.currentUser?.uid;
    final profile = uid != null ? await PatientService.getPatientProfile(uid) : null;
    final patientCityName = (profile?['city'] as String?)?.split(',').first.trim();
    final patientCity =
        (patientCityName != null && patientCityName.isNotEmpty) ? cityCoords(patientCityName) : null;

    final results = await CaregiverService.searchCaregivers();

    if (patientCity == null) {
      // Patient's location can't be resolved to a known city — showing the
      // full unfiltered count would misrepresent "near you", so this is
      // left at 0 rather than a misleading number.
      if (mounted) setState(() => _caregiverCount = 0);
      return;
    }

    final patientLat = double.parse(patientCity['lat']!);
    final patientLng = double.parse(patientCity['lng']!);

    final nearby = results.where((c) {
      final isAvailable = c['isAvailable'] as bool? ?? true;
      if (!isAvailable) return false;
      final caregiverCity = cityCoords((c['city'] as String?) ?? '');
      if (caregiverCity == null) return false;
      final distanceKm = haversineKm(
        patientLat,
        patientLng,
        double.parse(caregiverCity['lat']!),
        double.parse(caregiverCity['lng']!),
      );
      return distanceKm <= 10.0;
    }).length;

    if (mounted) setState(() => _caregiverCount = nearby);
  }

  Future<void> _loadTopMatches() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingTopMatches = false);
      return;
    }
    final profile = await PatientService.getPatientProfile(uid);
    if (profile == null) {
      if (mounted) setState(() => _loadingTopMatches = false);
      return;
    }
    final matchContext = MatchContext(patientProfile: profile);
    final caregivers = await CaregiverService.searchCaregivers();
    final ranked = MatchingService.rankCaregivers(
      caregivers: caregivers,
      context: matchContext,
      profile: MatchProfile.onboardingPreview,
    );
    if (!mounted) return;
    setState(() {
      _topMatches = ranked.take(1).toList();
      _loadingTopMatches = false;
    });
  }

  void _subscribeBookings() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    _bookingsSub = BookingService.streamBookingsForPatient(uid).listen((bookings) {
      if (!mounted) return;
      setState(() => _bookings = bookings);
      // Update ETA whenever bookings change (live location may have moved)
      final today = _todayBooking;
      if (today != null) _maybeComputeEta(today);
    });
  }

  Future<void> _loadSavedCaregivers() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final ids = await PatientService.getFavoriteCaregiverIds(uid);
    if (ids.isEmpty) return;
    final all = await CaregiverService.searchCaregivers();
    final saved = all.where((c) => ids.contains(c['uid'] as String?)).toList();
    if (mounted) setState(() => _savedCaregivers = saved);
  }

  // ── Real-time ETA via OSRM ────────────────────────────────────────────
  // Only fires when the caregiver's device has written a `liveLocation`
  // field to the booking document — i.e., they are actively sharing GPS.
  // Throttled to 15 seconds between calls (same as TrackCaregiverScreen).
  Future<void> _maybeComputeEta(Map<String, dynamic> booking) async {
    final live = booking['liveLocation'] as Map<String, dynamic>?;
    if (live == null) {
      if (mounted && _etaMinutes != null) setState(() => _etaMinutes = null);
      return;
    }
    final lat = (live['lat'] as num?)?.toDouble();
    final lng = (live['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final destLat = (booking['locationLat'] as num?)?.toDouble();
    final destLng = (booking['locationLng'] as num?)?.toDouble();
    if (destLat == null || destLng == null) return;

    final now = DateTime.now();
    final samePos = _lastLiveLat == lat && _lastLiveLng == lng;
    final tooSoon = _lastEtaFetch != null &&
        now.difference(_lastEtaFetch!) < const Duration(seconds: 15);
    if (samePos && tooSoon) return;

    _lastEtaFetch = now;
    _lastLiveLat = lat;
    _lastLiveLng = lng;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$lng,$lat;$destLng,$destLat'
        '?overview=false',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final route = routes.first as Map<String, dynamic>;
      final seconds = (route['duration'] as num).round();
      final minutes = (seconds / 60).ceil().clamp(1, 999);
      if (mounted) setState(() => _etaMinutes = minutes);
    } catch (_) {
      // OSRM unreachable — keep whatever ETA we last had
    }
  }

  // ── Booking helpers ───────────────────────────────────────────────────
  // Returns the first confirmed booking that is scheduled for today,
  // OR any confirmed booking where the caregiver is actively sharing GPS.
  Map<String, dynamic>? get _todayBooking {
    final now = DateTime.now();
    for (final b in _bookings) {
      if (b['status'] != 'confirmed') continue;
      // Prefer a booking with live location (caregiver is actively on the way)
      if (b['liveLocation'] != null) return b;
      if (_isToday(b['startDate'] as String? ?? '', now)) return b;
    }
    return null;
  }

  // Most recent booking regardless of status (for "Your request" section)
  Map<String, dynamic>? get _latestBooking {
    for (final b in _bookings) {
      if (b['status'] != 'cancelled') return b;
    }
    return _bookings.isNotEmpty ? _bookings.first : null;
  }

  int get _pendingRequestsCount =>
      _bookings.where((b) => b['status'] == 'requested').length;

  int get _upcomingVisitsCount {
    final now = DateTime.now();
    return _bookings.where((b) {
      if (b['status'] != 'confirmed') return false;
      final today = _isToday(b['startDate'] as String? ?? '', now);
      return !today; // Future confirmed bookings only
    }).length;
  }

  bool _isToday(String dateStr, DateTime now) {
    // Handle "Aug 26, 2026" format (from schedule_care_screen)
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    try {
      final parts = dateStr.replaceAll(',', '').split(' ');
      if (parts.length >= 3) {
        final month = months[parts[0]];
        final day = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          return now.year == year && now.month == month && now.day == day;
        }
      }
    } catch (_) {}
    // Fallback: ISO "2026-08-26"
    final iso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return dateStr.contains(iso);
  }

  // Booking step: 1=requested, 2=confirmed, 3=arrived (visit in progress), 4=completed
  int _bookingStep(Map<String, dynamic> b) {
    final status = b['status'] as String? ?? 'requested';
    if (status == 'completed') return 4;
    if (status == 'confirmed') {
      return (b['arrivalConfirmed'] == true) ? 3 : 2;
    }
    return 1;
  }

  String _initialsOf(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  // ── Navigation ────────────────────────────────────────────────────────
  Future<void> _startOrViewMatch() async {
    if (AppState.hasActiveMatch.value) {
      Navigator.pushNamed(context, '/advanced-match-results');
      return;
    }
    if (!await ensurePatientProfileComplete(context)) return;
    if (!mounted) return;
    Navigator.pushNamed(context, '/advanced-match-send-request');
  }

  void _showEmergencySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: EmergencyScreen(),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmergencyBanner(),
                  const SizedBox(height: 16),
                  // ── Today (ongoing visit) ─────────────────────────────
                  if (_todayBooking != null) ...[
                    _buildSectionLabel('Today'),
                    const SizedBox(height: 10),
                    _buildTodayCard(_todayBooking!),
                    const SizedBox(height: 16),
                  ],
                  // ── Your request ──────────────────────────────────────
                  if (_latestBooking != null) ...[
                    _buildYourRequestHeader(),
                    const SizedBox(height: 10),
                    _buildYourRequestCard(_latestBooking!),
                    const SizedBox(height: 16),
                  ],
                  // ── At a glance ───────────────────────────────────────
                  _buildSectionLabel('At a glance'),
                  const SizedBox(height: 10),
                  _buildAtAGlance(),
                  const SizedBox(height: 16),
                  // ── Top match ─────────────────────────────────────────
                  if (!_loadingTopMatches && _topMatches.isNotEmpty) ...[
                    _buildTopMatchHeader(),
                    const SizedBox(height: 10),
                    _buildTopMatchCard(_topMatches.first),
                    const SizedBox(height: 16),
                  ],
                  // ── Saved caregivers ──────────────────────────────────
                  _buildSectionLabel('Saved caregivers'),
                  const SizedBox(height: 10),
                  _buildSavedCaregiversRow(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(22, topInset + 16, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _greetingText,
                      style: const TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(_greetingIcon, color: const Color(0xFFFFC940), size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ValueListenableBuilder<String>(
                    valueListenable: AppState.patientName,
                    builder: (_, name, _) {
                      final display =
                          name.trim().isNotEmpty ? name.trim() : _userName;
                      return Text(
                        display,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Avatar — navigates to patient profile
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(context, '/patient-profile'),
            child: ValueListenableBuilder<String?>(
              valueListenable: AppState.profileImagePath,
              builder: (_, imagePath, _) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: imagePath != null
                      ? ClipOval(
                          child: RemoteOrLocalImage(
                            source: imagePath,
                            width: 50,
                            height: 50,
                          ),
                        )
                      : Center(
                          child: ValueListenableBuilder<String>(
                            valueListenable: AppState.patientName,
                            builder: (_, name, _) => Text(
                              _initialsOf(name.isNotEmpty ? name : _userName),
                              style: const TextStyle(
                                fontFamily: 'Quattrocento Sans',
                                color: darkGreen,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Emergency banner ──────────────────────────────────────────────────
  Widget _buildEmergencyBanner() {
    return GestureDetector(
      onTap: _showEmergencySheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: BoxDecoration(
          color: emergencyRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency - Find a caregiver now',
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Top 3 nearest available caregivers',
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Section helpers ───────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Open Sans',
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Today card (ongoing visit + real ETA) ─────────────────────────────
  Widget _buildTodayCard(Map<String, dynamic> booking) {
    final caregiverName = booking['caregiverName'] as String? ?? 'Caregiver';
    final startTime = booking['startTime'] as String? ?? '';
    final caregiverId = booking['caregiverId'] as String?;
    final bookingId = booking['id'] as String?;
    final hasLiveLocation = booking['liveLocation'] != null;
    final hasArrived = booking['arrivalConfirmed'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkGreenCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Caregiver avatar
          ClipOval(
            child: FutureBuilder<String?>(
              future: _resolveCaregiverPhoto(caregiverId),
              builder: (context, snap) {
                final photoUrl = (booking['caregiverPhotoUrl'] as String?)?.trim() ?? snap.data;
                if (photoUrl != null && photoUrl.isNotEmpty) {
                  return RemoteOrLocalImage(
                    source: photoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                }
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAE48B),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initialsOf(caregiverName),
                    style: const TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Color(0xFF44331C),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "ONGOING VISIT" label — only when caregiver is sharing GPS
                if (hasLiveLocation || hasArrived)
                  const Text(
                    'ONGOING VISIT',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: ongoingGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  )
                else
                  const Text(
                    'TODAY\'S VISIT',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: ongoingGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        caregiverName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (startTime.isNotEmpty)
                      Text(
                        startTime,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                // ETA sub-label — only shows when caregiver is sharing real GPS
                if (hasArrived)
                  const Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: ongoingGreen, size: 10),
                      SizedBox(width: 3),
                      Text(
                        'Arrived',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: ongoingGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                else if (hasLiveLocation && _etaMinutes != null)
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: ongoingGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'On the way · $_etaMinutes min',
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: ongoingGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                else if (hasLiveLocation)
                  const Row(
                    children: [
                      Icon(Icons.my_location_rounded,
                          color: ongoingGreen, size: 10),
                      SizedBox(width: 3),
                      Text(
                        'Computing ETA…',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: ongoingGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Track button — navigates to full TrackCaregiverScreen
          GestureDetector(
            onTap: () {
              if (bookingId == null || caregiverId == null) return;
              Navigator.pushNamed(
                context,
                '/track-caregiver',
                arguments: {
                  'bookingId': bookingId,
                  'caregiverId': caregiverId,
                  'caregiverName': caregiverName,
                  'startTime': startTime,
                  'careType': booking['careType'],
                  'locationLat': booking['locationLat'],
                  'locationLng': booking['locationLng'],
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: trackBtnYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Track',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFF44331C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Your request section header ────────────────────────────────────────
  Widget _buildYourRequestHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel('Your request'),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/my-bookings'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(64, 64, 6, 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Details',
              style: TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: Color(0xFF33440A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Your request card (booking progress tracker) ───────────────────────
  Widget _buildYourRequestCard(Map<String, dynamic> booking) {
    final caregiverName = booking['caregiverName'] as String? ?? 'Caregiver';
    final careType = booking['careType'] as String? ?? '';
    final startDate = booking['startDate'] as String? ?? '';
    final startTime = booking['startTime'] as String? ?? '';
    final endTime = booking['endTime'] as String? ?? '';
    final step = _bookingStep(booking);

    // Build care details line: "Elder care • Mon/Wed/Fri • 8-12 (you set)"
    final timeRange =
        [startTime, endTime].where((t) => t.isNotEmpty).join('–');
    final metaParts = [
      if (careType.isNotEmpty) careType,
      if (startDate.isNotEmpty) startDate,
      if (timeRange.isNotEmpty) timeRange,
    ];

    final statusLabel = switch (step) {
      1 => 'requested',
      2 => 'accepted',
      3 => 'visit in progress',
      _ => 'completed',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: requestCardBg,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata row
          Wrap(
            spacing: 6,
            children: metaParts.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.key > 0)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text('•',
                          style: TextStyle(
                              color: Color.fromRGBO(0, 0, 0, 0.58),
                              fontSize: 12)),
                    ),
                  Text(
                    e.value,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color.fromRGBO(0, 0, 0, 0.58),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Accepted label
          Text(
            '$caregiverName $statusLabel',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Color(0xFF0C3B2E),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Progress stepper
          _buildProgressStepper(step),
          const SizedBox(height: 16),
          // View booking button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/my-bookings'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'View booking',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking progress stepper ──────────────────────────────────────────
  // step: 1=Requested, 2=Accepted, 3=Visit in progress, 4=Completed
  Widget _buildProgressStepper(int step) {
    const labels = ['Requested', 'Accepted', 'Visited', 'Completed'];

    return Row(
      children: List.generate(4, (i) {
        final stepNum = i + 1;
        final isDone = stepNum < step;
        final isCurrent = stepNum == step;
        // Alternate active line shade between segments
        final segmentColor = stepNum == 2
            ? progressDoneLine
            : stepNum == 3
                ? progressActiveLine
                : progressEmptyLine;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < step ? (i == 2 ? progressActiveLine : progressDoneLine) : progressEmptyLine,
                      ),
                    ),
                  _buildStepCircle(
                    stepNum: stepNum,
                    isDone: isDone,
                    isCurrent: isCurrent,
                    step: step,
                  ),
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: stepNum < step ? segmentColor : progressEmptyLine,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: isCurrent
                      ? const Color(0xFF493111)
                      : const Color(0xFF565138),
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepCircle({
    required int stepNum,
    required bool isDone,
    required bool isCurrent,
    required int step,
  }) {
    if (isDone) {
      // Checkmark circle (done)
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: progressDoneCircle,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
      );
    } else if (isCurrent) {
      // Number circle (current — amber/orange)
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: progressActiveCircle,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepNum',
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: Color(0xFF493111),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      // Number circle (future — light grey)
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: progressEmptyCircle,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepNum',
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: Color(0xFF493111),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  // ── At a glance ───────────────────────────────────────────────────────
  Widget _buildAtAGlance() {
    final tiles = [
      ('assets/images/glance_caregivers_icon.png', 'Caregivers near you', _caregiverCount),
      ('assets/images/glance_requests_icon.png', 'Requests pending', _pendingRequestsCount),
      ('assets/images/glance_upcoming_icon.png', 'Upcoming visit', _upcomingVisitsCount),
    ];
    return Column(
      children: tiles.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: atGlanceBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Image.asset(t.$1, width: 33, height: 33),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.$2,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color(0xFF3A332A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${t.$3}',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: Color(0xFF313131),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Top match section header ──────────────────────────────────────────
  Widget _buildTopMatchHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel('Top match for you'),
        GestureDetector(
          onTap: _startOrViewMatch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(64, 64, 6, 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'See all',
              style: TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: Color(0xFF33440A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Top match card ────────────────────────────────────────────────────
  Widget _buildTopMatchCard(MatchResult m) {
    final uid = m.caregiver['uid'] as String?;
    final name = (m.caregiver['name'] as String?) ?? 'Caregiver';
    final photoUrl = (m.caregiver['photoUrl'] as String?)?.trim();
    final years = m.caregiver['yearsExperience'];
    final careType = m.caregiver['careType'] as String? ??
        (m.caregiver['careTypes'] as List?)?.firstOrNull as String? ?? '';
    final rating = m.caregiver['rating'];
    final isAvailable = m.caregiver['isAvailable'] as bool? ?? true;
    final languages = (m.caregiver['languages'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final match = m.matchPercent.round();

    // Build tags: language tags + care type tag
    final tags = <(String, Color, Color)>[];
    for (final lang in languages.take(1)) {
      tags.add(('Speaks $lang', tagGreenBg, tagGreenText));
    }
    if (careType.isNotEmpty) {
      tags.add((careType, tagBrownBg, tagBrownText));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: topMatchCardBg,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name/subtitle + match badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B653E), Color(0xFF624410)],
                  ),
                ),
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: RemoteOrLocalImage(
                          source: photoUrl,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          _initialsOf(name),
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (careType.isNotEmpty) careType,
                        if (years != null) '$years yrs exp',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color.fromRGBO(0, 0, 0, 0.56),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Match % badge
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  border: Border.all(color: matchBadgeText, width: 1.5),
                  shape: BoxShape.circle,
                  color: matchBadgeBg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$match%',
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: matchBadgeText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Match',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color.fromRGBO(101, 29, 29, 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.$2,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    t.$1,
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: t.$3,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color.fromRGBO(0, 0, 0, 0.12)),
          const SizedBox(height: 8),
          // Rating + availability row
          Row(
            children: [
              if (rating != null) ...[
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                const SizedBox(width: 3),
                Text(
                  '$rating',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: Color.fromRGBO(0, 0, 0, 0.66),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isAvailable ? 'Available' : 'Unavailable',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color.fromRGBO(0, 0, 0, 0.66),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Request + Profile buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/send-request',
                    arguments: {if (uid != null) 'caregiverId': uid},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF554F42),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Request',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/caregiver-profile',
                    arguments: {'caregiverId': uid},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF554F42)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: Color(0xFF554F42),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

  // ── Saved caregivers row ──────────────────────────────────────────────
  Widget _buildSavedCaregiversRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._savedCaregivers.map((cg) {
            final name = (cg['name'] as String?) ?? '';
            final uid = cg['uid'] as String?;
            final photoUrl = (cg['photoUrl'] as String?)?.trim();
            final firstName =
                name.trim().split(' ').firstOrNull ?? name;
            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/caregiver-profile',
                arguments: {'caregiverId': uid},
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDD5C8),
                        shape: BoxShape.circle,
                      ),
                      child: (photoUrl != null && photoUrl.isNotEmpty)
                          ? ClipOval(
                              child: RemoteOrLocalImage(
                                source: photoUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                _initialsOf(name),
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: Color(0xFF4A4029),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color.fromRGBO(49, 49, 49, 0.73),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Add button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/search'),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD5C8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBBB0A0),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF4A4029),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Color.fromRGBO(49, 49, 49, 0.73),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar (nav + Match FAB) ───────────────────────────────────────
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
      (icon: Icons.home_outlined, label: 'Home', route: null as String?),
      (icon: Icons.search_rounded, label: 'Search', route: '/search'),
      (icon: Icons.circle_outlined, label: 'Match', route: null as String?), // slot for FAB
      (icon: Icons.calendar_today_outlined, label: 'Booking', route: '/my-bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Notification', route: '/notifications'),
    ];
    return Container(
      width: double.infinity,
      color: darkGreen,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 67,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }
              final color = index == 0 ? navHomeLabel : Colors.white;
              return GestureDetector(
                onTap: item.route != null
                    ? () => Navigator.pushNamed(context, item.route!)
                    : null,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      index == 4
                          ? PatientNotificationIconWithBadge(
                              icon: Icon(item.icon, color: color, size: 25),
                              badgeBorderColor: darkGreen,
                            )
                          : Icon(item.icon, color: color, size: 25),
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
        ),
      ),
    );
  }

  Widget _buildMatchFab() {
    return GestureDetector(
      onTap: _startOrViewMatch,
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
