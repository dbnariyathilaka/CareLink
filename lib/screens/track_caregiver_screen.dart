import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'call_screen.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Track Caregiver Screen  (Figma node 393-163)
//  Real map (OpenStreetMap tiles), real caregiver position (from the
//  liveLocation the caregiver's device writes while sharing — see
//  caregiver_schedule_screen.dart), and a real fastest-route/ETA/distance
//  computed against the public OSRM routing API. Figma's illustrated map
//  background and fixed "8 min / 1.4 km" numbers are replaced with an
//  actually-functioning map — when the caregiver hasn't started sharing
//  their location yet, this honestly says so instead of showing fake
//  numbers.
// ─────────────────────────────────────────────────────────────────────────────
class TrackCaregiverScreen extends StatefulWidget {
  const TrackCaregiverScreen({super.key});

  @override
  State<TrackCaregiverScreen> createState() => _TrackCaregiverScreenState();
}

class _TrackCaregiverScreenState extends State<TrackCaregiverScreen> {
  static const Color destinationRed = Color(0xFFA40505);
  static const Color statusPillBg = Color.fromRGBO(15, 23, 42, 0.85);
  static const Color statusDot = Color(0xFF22C55E);
  static const Color cardBg = Color(0xFF313131);
  static const Color cardBorder = Color(0xFF334155);
  static const Color cardValue = Color(0xFFEDE9DE);
  static const Color cardSubtext = Color.fromRGBO(237, 233, 222, 0.72);
  static const Color etaColor = Color(0xFFA1A339);
  static const Color etaSub = Color(0xFFB9B6AE);
  static const Color arrivingBg = Color.fromRGBO(111, 84, 50, 0.54);
  static const Color arrivingBorder = Color(0xFF6F5432);
  static const Color btnBg = Color(0xFF6F6C54);

  final MapController _mapController = MapController();

  Map<String, dynamic> _args = {};
  bool _loadedArgs = false;

  Map<String, dynamic>? _caregiverProfile;
  StreamSubscription<Map<String, dynamic>?>? _bookingSub;
  Map<String, dynamic>? _booking;

  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  Duration? _routeDuration;
  DateTime? _lastRouteFetch;
  LatLng? _lastRouteOrigin;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _args = Map<String, dynamic>.from(args);
    }
    final bookingId = _args['bookingId'] as String?;
    if (bookingId != null) {
      _bookingSub = BookingService.streamBooking(bookingId).listen(_onBookingUpdate);
    }
    final caregiverId = _args['caregiverId'] as String?;
    if (caregiverId != null) {
      CaregiverService.getCaregiverProfile(caregiverId).then((profile) {
        if (mounted) setState(() => _caregiverProfile = profile);
      });
    }
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    super.dispose();
  }

  void _onBookingUpdate(Map<String, dynamic>? booking) {
    if (!mounted) return;
    setState(() => _booking = booking);
    final live = booking?['liveLocation'] as Map<String, dynamic>?;
    final destLat = (_args['locationLat'] as num?)?.toDouble();
    final destLng = (_args['locationLng'] as num?)?.toDouble();
    if (live == null || destLat == null || destLng == null) return;
    final lat = (live['lat'] as num?)?.toDouble();
    final lng = (live['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    _maybeFetchRoute(LatLng(lat, lng), LatLng(destLat, destLng));
  }

  void _maybeFetchRoute(LatLng from, LatLng to) {
    final now = DateTime.now();
    final movedEnough = _lastRouteOrigin == null ||
        const Distance().as(LengthUnit.Meter, _lastRouteOrigin!, from) > 30;
    final longEnoughSinceLastFetch = _lastRouteFetch == null ||
        now.difference(_lastRouteFetch!) > const Duration(seconds: 15);
    if (!movedEnough && !longEnoughSinceLastFetch) return;
    if (!movedEnough && _routePoints.isNotEmpty) return;
    _lastRouteFetch = now;
    _lastRouteOrigin = from;
    unawaited(_fetchRoute(from, to));
  }

  // Real routing via the public OSRM demo server — no API key required.
  // Only the "driving" profile is available on the public demo instance.
  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = (geometry['coordinates'] as List).map((c) {
        final pair = c as List;
        return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();
      if (!mounted) return;
      setState(() {
        _routePoints = coords;
        _routeDistanceKm = (route['distance'] as num).toDouble() / 1000;
        _routeDuration = Duration(seconds: (route['duration'] as num).round());
      });
    } catch (_) {
      // Real routing failed (offline, or the free demo server is rate
      // limiting) — keep whatever route/ETA we last had rather than
      // fabricating one.
    }
  }

  String get _caregiverName => (_args['caregiverName'] as String?) ?? 'Caregiver';

  String get _initials {
    final parts = _caregiverName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _formatClock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  LatLng? get _destination {
    final lat = (_args['locationLat'] as num?)?.toDouble();
    final lng = (_args['locationLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _caregiverPosition {
    final live = _booking?['liveLocation'] as Map<String, dynamic>?;
    final lat = (live?['lat'] as num?)?.toDouble();
    final lng = (live?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final arrived = _booking?['arrivalConfirmed'] == true;
    final destination = _destination;
    final caregiverPos = _caregiverPosition;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: destination == null
                ? const Center(
                    child: Text(
                      'No destination set for this booking.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: caregiverPos ?? destination,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        // Must match the app's real applicationId — OSM's
                        // free tile servers identify/throttle clients by
                        // this header, and a made-up name here was sending
                        // an inaccurate one on every request.
                        userAgentPackageName: 'com.example.flutter_application_1',
                        // A handful of tile requests failing (flaky
                        // connection, OSM's free server under load) is
                        // normal and not fatal — flutter_map just leaves
                        // that tile blank and retries on the next pan/zoom.
                        // Without this, each failure surfaced as a loud
                        // uncaught exception.
                        errorTileCallback: (tile, error, stackTrace) {
                          debugPrint('Map tile failed to load: $error');
                        },
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(points: _routePoints, strokeWidth: 4, color: destinationRed),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: destination,
                            width: 90,
                            height: 60,
                            child: _buildDestinationMarker(),
                          ),
                          if (caregiverPos != null)
                            Marker(
                              point: caregiverPos,
                              width: 40,
                              height: 40,
                              child: _buildCaregiverMarker(),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 12, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: statusPillBg,
                        border: Border.all(color: const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: caregiverPos != null ? statusDot : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              arrived
                                  ? '$_caregiverName has arrived'
                                  : caregiverPos != null
                                      ? '$_caregiverName is on the way'
                                      : 'Waiting for $_caregiverName to share location',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: Color(0xFFF8FAFC),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomCard(context, arrived: arrived, hasLivePosition: caregiverPos != null),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8F8F),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 5)],
          ),
          child: const Text(
            'Home',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF6A1818),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.location_on_rounded, color: destinationRed, size: 34),
      ],
    );
  }

  Widget _buildCaregiverMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF6D28D9),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
      ),
      child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildBottomCard(BuildContext context, {required bool arrived, required bool hasLivePosition}) {
    final rating = _caregiverProfile?['rating'];
    final careType = _args['careType'] as String?;
    final startTime = _args['startTime'] as String?;
    final caregiverId = _args['caregiverId'] as String?;
    final bookingId = _args['bookingId'] as String?;

    String? etaLabel;
    String? distanceLabel;
    String? arrivingLabel;
    if (hasLivePosition && _routeDuration != null && _routeDistanceKm != null) {
      final minutes = _routeDuration!.inMinutes;
      etaLabel = minutes < 1 ? '<1 min' : '$minutes min';
      distanceLabel = '${_routeDistanceKm!.toStringAsFixed(1)} km away';
      final arrival = DateTime.now().add(_routeDuration!);
      arrivingLabel = _formatClock(arrival);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 20),
      decoration: const BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: cardBorder)),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.4), blurRadius: 15, offset: Offset(0, -10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.37),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC57122), Color(0xFFA36B16)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF42413F),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _caregiverName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: cardValue,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (rating != null) ...[
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '$rating',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: cardValue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (careType != null && careType.isNotEmpty)
                          Text(
                            rating != null ? ' · $careType' : careType,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: cardSubtext,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (etaLabel != null && distanceLabel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      etaLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: etaColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      distanceLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: etaSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: arrivingBg,
              border: Border.all(color: arrivingBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFFFBBC05), size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: arrived
                              ? 'Arrived — '
                              : arrivingLabel != null
                                  ? 'Arriving around '
                                  : 'Not sharing location yet — ',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!arrived && arrivingLabel != null)
                          TextSpan(
                            text: arrivingLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFFF8FAFC),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        TextSpan(
                          text: startTime != null
                              ? (arrived ? 'shift was $startTime' : ' for the $startTime shift')
                              : '',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: btnBg,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CallScreen(
                            calleeName: _caregiverName,
                            initials: _initials,
                            isVideo: false,
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_rounded, color: Color(0xFF3B360F), size: 19),
                          SizedBox(width: 7),
                          Text(
                            'Call',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF3B360F),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: btnBg,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'caregiverId': caregiverId,
                          'caregiverName': _caregiverName,
                          'bookingId': bookingId,
                          'careType': careType,
                        },
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_rounded, color: Color(0xFF3B360F), size: 19),
                          SizedBox(width: 7),
                          Text(
                            'Message',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF3B360F),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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
}
