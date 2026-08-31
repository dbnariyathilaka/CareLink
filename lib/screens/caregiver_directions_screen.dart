import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../data/patient_locations.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Get Directions Screen (Caregiver)
//  Figma node: 485-256 · "Directions to {patient}"
//
//  Renders a real OpenStreetMap of Sri Lanka and requests an
//  actual driving route (via the public OSRM routing engine)
//  from the caregiver's current GPS position to the patient's
//  saved care address — real road geometry, distance and ETA,
//  not the fictional POI-labeled map illustration or hardcoded
//  "18 min / Light traffic" Figma mocks up. Traffic conditions
//  in particular are dropped entirely — OSRM's routing has no
//  live-traffic data, so there's nothing real to show there.
// ─────────────────────────────────────────────────────────────
class CaregiverDirectionsScreen extends StatefulWidget {
  const CaregiverDirectionsScreen({super.key});

  @override
  State<CaregiverDirectionsScreen> createState() => _CaregiverDirectionsScreenState();
}

class _CaregiverDirectionsScreenState extends State<CaregiverDirectionsScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);
  static const Color _headerCardBg = Color(0xFF202833);
  static const Color _sheetBg = Color(0xFF223A5C);
  static const Color _sheetBorder = Color(0xFF334155);
  static const Color _textPrimary = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _instructionBg = Color(0xFF459B8F);
  static const Color _instructionIconColor = Color(0xFFFBBC05);
  static const Color _navigateBg = Color(0xFFBB6B46);

  // Reasonable default origin (Colombo Fort) used only if GPS is
  // unavailable/denied, so the screen still shows a real route.
  static const LatLng _fallbackOrigin = LatLng(6.9344, 79.8428);

  final MapController _mapController = MapController();
  bool _didReadArgs = false;

  String _patientName = 'Nipuni Ariyathilaka';
  late PatientLocation _destination;

  LatLng? _origin;
  List<LatLng> _routePoints = [];
  double? _distanceMeters;
  double? _durationSeconds;
  String _instruction = '';
  IconData _instructionIcon = Icons.straight_rounded;
  bool _loading = true;
  bool _usedFallbackRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _patientName = args['name'] as String? ?? _patientName;
    }
    _destination = patientLocations[_patientName] ?? defaultPatientLocation;
    _loadRoute();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<LatLng> _resolveOrigin() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallbackOrigin;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallbackOrigin;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return _fallbackOrigin;
    }
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
    });

    final origin = await _resolveOrigin();
    final destLatLng = LatLng(_destination.lat, _destination.lng);

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destLatLng.longitude},${destLatLng.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Routing service returned ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No route found');
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List;
      final points = coords
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();

      final legs = route['legs'] as List;
      final steps = (legs.first as Map<String, dynamic>)['steps'] as List;
      final instructionData = _buildInstruction(steps, (route['distance'] as num).toDouble());

      if (!mounted) return;
      setState(() {
        _origin = origin;
        _routePoints = points;
        _distanceMeters = (route['distance'] as num).toDouble();
        _durationSeconds = (route['duration'] as num).toDouble();
        _instruction = instructionData.$1;
        _instructionIcon = instructionData.$2;
        _usedFallbackRoute = false;
        _loading = false;
      });
      _fitToRoute();
    } catch (e) {
      // Routing service unreachable — fall back to a straight-line
      // estimate so the screen still shows something useful.
      if (!mounted) return;
      final distance = const Distance().as(LengthUnit.Meter, origin, destLatLng);
      setState(() {
        _origin = origin;
        _routePoints = [origin, destLatLng];
        _distanceMeters = distance;
        _durationSeconds = distance / (30 * 1000 / 3600); // ~30 km/h estimate
        _instruction = 'Head toward ${_destination.address}';
        _instructionIcon = Icons.straight_rounded;
        _usedFallbackRoute = true;
        _loading = false;
      });
      _fitToRoute();
    }
  }

  (String, IconData) _buildInstruction(List steps, double totalDistanceMeters) {
    if (steps.length < 2) {
      return ('Head toward ${_destination.address}', Icons.straight_rounded);
    }
    final step = steps[1] as Map<String, dynamic>;
    final maneuver = step['maneuver'] as Map<String, dynamic>;
    final modifier = maneuver['modifier'] as String?;
    final type = maneuver['type'] as String?;
    final roadName = (step['name'] as String?)?.trim();

    String verb;
    switch (type) {
      case 'turn':
        verb = modifier != null ? 'Turn ${modifier.replaceAll('_', ' ')}' : 'Turn';
      case 'merge':
        verb = 'Merge';
      case 'roundabout':
      case 'rotary':
        verb = 'Enter the roundabout';
      case 'fork':
        verb = 'Keep ${modifier ?? 'straight'}';
      case 'arrive':
        verb = 'Arrive at destination';
      default:
        verb = 'Continue';
    }
    final ontoPart = (roadName != null && roadName.isNotEmpty) ? ' onto $roadName' : '';
    final remainingKm = (totalDistanceMeters / 1000).toStringAsFixed(1);
    final text = '$verb$ontoPart, then continue $remainingKm km';
    return (text, _iconForModifier(modifier));
  }

  IconData _iconForModifier(String? modifier) {
    switch (modifier) {
      case 'left':
        return Icons.turn_left_rounded;
      case 'right':
        return Icons.turn_right_rounded;
      case 'slight left':
        return Icons.turn_slight_left_rounded;
      case 'slight right':
        return Icons.turn_slight_right_rounded;
      case 'sharp left':
        return Icons.turn_sharp_left_rounded;
      case 'sharp right':
        return Icons.turn_sharp_right_rounded;
      case 'uturn':
        return Icons.u_turn_left_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  void _fitToRoute() {
    if (_routePoints.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints(_routePoints);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(50, 160, 50, 260),
          ),
        );
      } catch (_) {
        // Map not attached yet — ignore, initial center already covers it.
      }
    });
  }

  Future<void> _startNavigation() async {
    if (_origin == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_origin!.latitude},${_origin!.longitude}'
      '&destination=${_destination.lat},${_destination.lng}'
      '&travelmode=driving',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open a maps app on this device.')),
      );
    }
  }

  String get _durationLabel {
    if (_durationSeconds == null) return '--';
    final minutes = (_durationSeconds! / 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  String get _distanceLabel {
    if (_distanceMeters == null) return '--';
    return '${(_distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
  }

  @override
  Widget build(BuildContext context) {
    final center = _origin != null
        ? LatLng(
            (_origin!.latitude + _destination.lat) / 2,
            (_origin!.longitude + _destination.lng) / 2,
          )
        : LatLng(_destination.lat, _destination.lng);

    return Scaffold(
      backgroundColor: _sheetBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flutter_application_1',
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint('Map tile failed to load: $error');
                  },
                ),
                if (_routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: _indigo,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_origin != null)
                      Marker(
                        point: _origin!,
                        width: 22,
                        height: 22,
                        child: _buildDot(_green),
                      ),
                    Marker(
                      point: LatLng(_destination.lat, _destination.lng),
                      width: 22,
                      height: 22,
                      child: _buildDot(_red),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x660F172A),
                child: Center(child: CircularProgressIndicator(color: _indigo)),
              ),
            ),

          // Header card
          Positioned(
            left: 16,
            right: 16,
            top: 0,
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: _headerCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Directions to $_patientName',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: _textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _destination.address,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: _textSecondary,
                              fontSize: 11,
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
          ),

          // Bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _sheetBg,
                border: Border(top: BorderSide(color: _sheetBorder)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _durationLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: _textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _usedFallbackRoute
                                  ? '$_distanceLabel · Estimated route'
                                  : '$_distanceLabel · Fastest route',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: _textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _instructionBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(_instructionIcon, color: _instructionIconColor, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _instruction,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: _navigateBg,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _loading ? null : _startNavigation,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Start navigation',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1),
        ],
      ),
    );
  }
}
