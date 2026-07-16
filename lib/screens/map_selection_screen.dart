import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../data/sri_lankan_cities.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> with SingleTickerProviderStateMixin {
  // Figma design tokens mapped to AppTheme
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _azure17 = AppTheme.cardColor;    // #1E293B
  static const Color _azure27 = AppTheme.borderColor;  // #334155
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8
  static const Color _grey98 = AppTheme.textPrimary;    // #F8FAFC

  // Advanced match flow
  bool _isAdvanced = false;
  Map<String, dynamic> _bookingArgs = {};

  // Dynamic accent colors based on flow
  Color get _accentColor => _isAdvanced ? const Color(0xFF3DB498) : AppTheme.primaryGreen;
  Color get _accentText  => _isAdvanced ? const Color(0xFF06291F) : AppTheme.bottleGreen;

  // Interactive Map State
  final MapController _mapController = MapController();
  double _zoomLevel = 14.0;
  bool _isLocating = false;
  String _address = 'Colombo';
  double _currentLat = 6.9271; // Colombo initial lat
  double _currentLng = 79.8612; // Colombo initial lng
  bool _usingGPS = false;

  // Real GPS State variables
  double? _gpsLat;
  double? _gpsLng;
  StreamSubscription<Position>? _positionStreamSubscription;
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  bool _showLocationChangedPopup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _isAdvanced = args['isAdvanced'] ?? false;
      _bookingArgs = Map<String, dynamic>.from(args);
    }
    // Set initial address matching initial coordinates
    _address = _getClosestCityName(_currentLat, _currentLng);
  }

  String _getClosestCityName(double lat, double lng) {
    double minDistance = double.infinity;
    String closestCity = 'Colombo';

    for (final cityMap in sriLankanCities) {
      final String? cityStr = cityMap['city'];
      final String? latStr = cityMap['lat'];
      final String? lngStr = cityMap['lng'];

      if (cityStr != null && latStr != null && lngStr != null) {
        final cityLat = double.tryParse(latStr) ?? 0.0;
        final cityLng = double.tryParse(lngStr) ?? 0.0;

        // Simple Euclidean distance approximation
        final double dist = math.sqrt(
          math.pow(lat - cityLat, 2) + math.pow(lng - cityLng, 2),
        );

        if (dist < minDistance) {
          minDistance = dist;
          closestCity = cityStr;
        }
      }
    }
    return closestCity;
  }

  Future<void> _initiateRealTimeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLocating = true;
    });

    try {
      // 1. Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // 2. Check permission status
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      // 3. Retrieve current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      _updateGPSLocation(position);

      // 4. Start listening to position updates
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (Position position) {
          _updateGPSLocation(position);
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Real-time GPS tracking active!'),
            backgroundColor: _accentColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Real GPS error, falling back to simulated location: $e');
      
      // Fallback simulation: Homagama location
      Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _usingGPS = true;
            _gpsLat = 6.8438; // Homagama Lat
            _gpsLng = 80.0000; // Homagama Lng
            _currentLat = 6.8438;
            _currentLng = 80.0000;
            _zoomLevel = 15.0;
            _address = _getClosestCityName(_currentLat, _currentLng);
          });
          _mapController.move(LatLng(_currentLat, _currentLng), _zoomLevel);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('GPS unavailable ($e). Using simulated location.'),
              backgroundColor: _accentColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _updateGPSLocation(Position position) {
    if (mounted) {
      setState(() {
        _usingGPS = true;
        _gpsLat = position.latitude;
        _gpsLng = position.longitude;
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _address = _getClosestCityName(_currentLat, _currentLng);
      });
      _mapController.move(LatLng(_currentLat, _currentLng), _zoomLevel);
    }
  }

  Widget _buildGPSLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring
            Container(
              width: 36 * _pulseController.value,
              height: 36 * _pulseController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor.withValues(alpha: 0.4 * (1.0 - _pulseController.value)),
              ),
            ),
            // Outer white border
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            // Inner core
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationChangedPopup() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFB5484B),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Location changed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_currentLat.toStringAsFixed(6)}, ${_currentLng.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          // 1. Full-screen OpenStreetMap tile background
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentLat, _currentLng),
                initialZoom: _zoomLevel,
                onPositionChanged: (position, hasGesture) {
                  if (position.center != null) {
                    setState(() {
                      _currentLat = position.center!.latitude;
                      _currentLng = position.center!.longitude;
                      _address = _getClosestCityName(_currentLat, _currentLng);
                      if (hasGesture) {
                        _usingGPS = false;
                      }
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.carematch',
                ),
                if (_gpsLat != null && _gpsLng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_gpsLat!, _gpsLng!),
                        width: 40,
                        height: 40,
                        child: _buildGPSLocationMarker(),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 2. Pulsing target indicator at map center
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // offset for visual pin tip
              child: _buildCenterTargetPin(),
            ),
          ),

          // 3. Status Bar Spacer & Back top-left overlay
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: Text(
                '9:41',
                style: TextStyle(
                  color: _grey98.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 4. Floating map tools on the right (Zoom, Location GPS)
          Positioned(
            right: 16,
            top: 60,
            child: SafeArea(
              child: Column(
                children: [
                  _buildFloatingTool(
                    icon: Icons.add_rounded,
                    onTap: () {
                      setState(() {
                        _zoomLevel = (_zoomLevel + 1).clamp(3.0, 20.0);
                        _mapController.move(LatLng(_currentLat, _currentLng), _zoomLevel);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFloatingTool(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      setState(() {
                        _zoomLevel = (_zoomLevel - 1).clamp(3.0, 20.0);
                        _mapController.move(LatLng(_currentLat, _currentLng), _zoomLevel);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  // Active state for GPS location
                  _buildGPSFloatingButton(),
                ],
              ),
            ),
          ),

          // 5. Bottom Panel Sheet / Location Changed Popup
          if (!_showLocationChangedPopup)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(context),
            )
          else
            _buildLocationChangedPopup(),

          // 6. Loading screen/GPS loader overlay
          if (_isLocating) _buildLocatingOverlay(),
        ],
      ),
    );
  }

  // ── Floating tools helper ──
  Widget _buildFloatingTool({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _azure27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _grey98, size: 22),
      ),
    );
  }

  Widget _buildGPSFloatingButton() {
    return GestureDetector(
      onTap: _initiateRealTimeLocation,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _usingGPS ? _accentColor : _azure17,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _usingGPS ? _accentColor : _azure27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.gps_fixed_rounded,
          color: _usingGPS ? _accentText : _grey98,
          size: 20,
        ),
      ),
    );
  }

  // Center target pin widget
  Widget _buildCenterTargetPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 12,
          width: 12,
          decoration: BoxDecoration(
            color: _accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          Icons.location_on_rounded,
          color: _accentColor,
          size: 42,
        ),
      ],
    );
  }

  // Bottom panel details sheet
  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: _azure27, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 15),

          // Selected location display bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: _azure11,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _azure27),
            ),
            child: Row(
              children: [
                Icon(Icons.location_city_rounded, color: _accentColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _address,
                    style: const TextStyle(
                      color: _grey98,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons Row
          Row(
            children: [
              // Back Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _azure27),
                      ),
                      child: const Text(
                        'Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _grey98,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Select Button
              Expanded(
                child: Material(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      setState(() {
                        _showLocationChangedPopup = true;
                        _bookingArgs['city'] = _address;
                        _bookingArgs['location'] = _address;
                        _bookingArgs['lat'] = _currentLat;
                        _bookingArgs['lng'] = _currentLng;
                      });

                      Timer(const Duration(milliseconds: 3500), () {
                        if (mounted) {
                          if (_isAdvanced) {
                            Navigator.pushNamed(
                              context,
                              '/qualifications-intro',
                              arguments: _bookingArgs,
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              '/confirm-booking',
                              arguments: _bookingArgs,
                            );
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Text(
                        'Select',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _accentText,
                          fontSize: 13,
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

  // Locate simulation spinner
  Widget _buildLocatingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acquiring Mobile GPS location...',
              style: TextStyle(
                color: _grey98,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
