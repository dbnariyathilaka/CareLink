import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../data/sri_lankan_cities.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> with SingleTickerProviderStateMixin {
  // Figma design tokens
  static const Color _azure11 = Color(0xFF0F172A);
  static const Color _azure17 = Color(0xFF1E293B);
  static const Color _azure27 = Color(0xFF334155);
  static const Color _azure65 = Color(0xFF94A3B8);
  static const Color _grey98 = Color(0xFFF8FAFC);
  static const Color _sheetBg = Color(0xFF313131);
  static const Color _searchFieldBg = Color(0xFFEDE9DE);
  static const Color _confirmBg = Color(0xFF6F5432);
  static const Color _gpsGreen = Color(0xFF205441);

  // Custom known landmarks for accurate mock geocoding and search autocomplete
  static const List<Map<String, String>> _customLandmarks = [
    {
      'city': 'NSBM Sports Centre',
      'district': 'Colombo District',
      'lat': '6.8220',
      'lng': '80.0407',
    },
    {
      'city': 'NSBM Green University',
      'district': 'Colombo District',
      'lat': '6.8215',
      'lng': '80.0415',
    },
    {
      'city': 'Faculty of Technology, NSBM',
      'district': 'Colombo District',
      'lat': '6.8227',
      'lng': '80.0422',
    },
  ];

  // Advanced match flow
  bool _isAdvanced = false;
  Map<String, dynamic> _bookingArgs = {};

  // Dynamic accent colors based on flow — dark green normally, plum/purple
  // for the "advanced match" flow (Figma node 296-215, matches the other
  // advanced-matching screens).
  Color get _accentColor => _isAdvanced ? const Color(0xFF6D4275) : const Color(0xFF06402B);
  Color get _accentText  => Colors.white;

  // Interactive Map State
  final MapController _mapController = MapController();
  double _zoomLevel = 14.0;
  bool _isLocating = false;
  String _address = 'Colombo';
  double _currentLat = 6.9271; // Colombo initial lat
  double _currentLng = 79.8612; // Colombo initial lng
  bool _usingGPS = false;

  // Search bar state
  final TextEditingController _searchController = NoUnderlineTextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, String>> _searchResults = [];
  bool _showSearchClear = false;
  Timer? _debounce;

  // Real GPS State variables
  double? _gpsLat;
  double? _gpsLng;
  StreamSubscription<Position>? _positionStreamSubscription;
  // Constructed eagerly in initState (not as a lazy `late final` initializer)
  // — it's only ever read from _buildGPSLocationMarker(), which is skipped
  // whenever GPS is never acquired on this screen. A lazy initializer would
  // then have its first read happen inside dispose()'s own
  // `_pulseController.dispose()` call, constructing a brand-new
  // AnimationController(vsync: this) — which needs a live ancestor lookup
  // for its ticker — while the widget is already being torn down. That's
  // what was throwing "Looking up a deactivated widget's ancestor is
  // unsafe" whenever this screen got disposed without GPS ever having been
  // used (e.g. via the mass route-removal from "Edit schedule").
  late final AnimationController _pulseController;

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
    _address = _getFormattedAddress(_currentLat, _currentLng);
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

    // Captured now, while context is definitely still valid — this async
    // flow spans awaits (and a delayed fallback) that can take seconds, by
    // which point a fresh `ScaffoldMessenger.of(context)` ancestor lookup
    // can throw "Looking up a deactivated widget's ancestor is unsafe" even
    // though `mounted` still reads true (the element can be transiently
    // deactivated without being fully disposed yet). Using the captured
    // state object sidesteps the ancestor lookup entirely.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
        scaffoldMessenger.showSnackBar(
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
            _address = _getFormattedAddress(_currentLat, _currentLng);
          });
          _mapController.move(LatLng(_currentLat, _currentLng), _zoomLevel);
          scaffoldMessenger.showSnackBar(
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
        _address = _getFormattedAddress(_currentLat, _currentLng);
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
    _debounce?.cancel();
    _positionStreamSubscription?.cancel();
    _pulseController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getFormattedAddress(double lat, double lng) {
    // Check if near any custom landmarks (like NSBM Sports Centre)
    double distanceTo(double targetLat, double targetLng) {
      return math.sqrt(math.pow(lat - targetLat, 2) + math.pow(lng - targetLng, 2));
    }

    if (distanceTo(6.8220, 80.0407) < 0.0006) {
      return 'NSBM Sports Centre, Temple Road, Pitipana, Homagama';
    }
    if (distanceTo(6.8215, 80.0415) < 0.0012) {
      return 'NSBM Green University, Temple Road, Pitipana, Homagama';
    }
    if (distanceTo(6.8227, 80.0422) < 0.0006) {
      return 'Faculty of Technology, NSBM, Temple Road, Pitipana, Homagama';
    }

    final closestCity = _getClosestCityName(lat, lng);

    final places = [
      'Keells Super', 'Cargills Food City', 'Arpico Supercentre', 'Hemas Hospital', 
      'Softlogic Max', 'Pizza Hut', 'KFC Outlet', 'SLT-MOBITEL Centre',
      'Majestic Apartments', 'Commercial Bank', 'Sampath Bank Branch', 'Singer Mega',
      'People\'s Bank', 'Lanka Hospitals Clinic', 'Nawaloka Medical Centre', 'Odel Mall',
      'NSBM Campus Hub', 'Royal Institute', 'Lyceum School', 'Gateway College Office'
    ];

    final lanes = [
      'Dharmapala Mawatha', 'Anagarika Dharmapala Mawatha', 'Galle Road', 'Kandy Road', 
      'High Level Road', 'Negombo Road', 'Baseline Road', 'Temple Road', 'Station Road', 
      'School Lane', 'Church Road', 'Lewis Place', 'Porutota Road', 'Lake Road', 
      'Flower Road', 'Duplication Road', 'Havelock Road', 'Ward Place', 'Bullers Lane'
    ];

    // Use lat/lng as seed to deterministically choose place and road names
    final seed = (lat.abs() * 100000 + lng.abs() * 100000).round();
    final randPlaceIdx = seed % places.length;
    final randLaneIdx = (seed ~/ 3) % lanes.length;
    final number = (seed % 150) + 1;

    final String place = places[randPlaceIdx];
    final String lane = lanes[randLaneIdx];

    if (seed % 3 == 0) {
      return '$place, No. $number, $lane, $closestCity';
    } else if (seed % 3 == 1) {
      return '$place, $lane, $closestCity';
    } else {
      return 'No. $number, $lane, $closestCity';
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchClear = false;
      });
      return;
    }
    setState(() {
      _showSearchClear = true;
    });

    final lowercaseQuery = query.toLowerCase();
    
    // First, find local matching cities/landmarks
    final allLocalLocations = [...sriLankanCities, ..._customLandmarks];
    final localMatches = allLocalLocations.where((loc) {
      final name = loc['city'] ?? '';
      final districtName = loc['district'] ?? '';
      return name.toLowerCase().contains(lowercaseQuery) ||
             districtName.toLowerCase().contains(lowercaseQuery);
    }).toList();

    // Show local results instantly
    setState(() {
      _searchResults = localMatches;
    });

    // Fetch matching places from Nominatim API for general landmarks, restaurants, hospitals, universities, etc.
    try {
      final client = HttpClient();
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}+Sri+Lanka&format=json&limit=6&addressdetails=1'
      );
      final request = await client.getUrl(uri);
      request.headers.set('user-agent', 'com.example.carematch');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(content);
        
        final List<Map<String, String>> apiResults = [];
        for (final item in data) {
          final displayName = item['display_name'] ?? '';
          final lat = item['lat'] ?? '';
          final lon = item['lon'] ?? '';
          
          final parts = displayName.split(',');
          final shortName = parts.isNotEmpty ? parts[0].trim() : displayName;
          final subtitle = parts.length > 1 
              ? '${parts[1].trim()}, ${parts[parts.length - 2].trim()}' 
              : 'Sri Lanka';
          
          apiResults.add({
            'city': shortName,
            'district': subtitle,
            'lat': lat,
            'lng': lon,
          });
        }

        if (mounted && query == _searchController.text) {
          setState(() {
            final seenNames = <String>{};
            final combined = <Map<String, String>>[];
            
            for (final m in localMatches) {
              final name = m['city']!.toLowerCase();
              if (!seenNames.contains(name)) {
                seenNames.add(name);
                combined.add(m);
              }
            }
            
            for (final m in apiResults) {
              final name = m['city']!.toLowerCase();
              if (!seenNames.contains(name)) {
                seenNames.add(name);
                combined.add(m);
              }
            }

            _searchResults = combined;
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching Nominatim API: $e');
    }
  }

  void _selectSearchResult(Map<String, String> city) {
    final latStr = city['lat'];
    final lngStr = city['lng'];
    final cityName = city['city'] ?? '';

    if (latStr != null && lngStr != null) {
      final lat = double.tryParse(latStr) ?? 6.9271;
      final lng = double.tryParse(lngStr) ?? 79.8612;

      setState(() {
        _currentLat = lat;
        _currentLng = lng;
        _address = _getFormattedAddress(lat, lng);
        _searchResults = [];
        _searchController.text = cityName;
        _showSearchClear = true;
      });

      _mapController.move(LatLng(lat, lng), 15.5);
      _searchFocusNode.unfocus();
    }
  }

  // Search field lives inside the bottom sheet now (matches Figma), with
  // its results dropdown floating just above it.
  Widget _buildSearchBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_searchResults.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _searchFieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _azure27, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(
                  color: _azure27.withValues(alpha: 0.4),
                  height: 1,
                  thickness: 0.5,
                ),
                itemBuilder: (context, index) {
                  final city = _searchResults[index];
                  final cityName = city['city'] ?? '';
                  final districtName = city['district'] ?? '';

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectSearchResult(city),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.black54,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cityName,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    districtName,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 11,
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
                },
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: _searchFieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _azure27, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: _azure65, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    hintText: 'Search location',
                    hintStyle: TextStyle(
                      fontFamily: 'Open Sans',
                      color: _azure65,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_showSearchClear)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      _searchResults = [];
                      _showSearchClear = false;
                    });
                  },
                  child: const Icon(Icons.close_rounded, color: Colors.black54, size: 18),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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
                      _address = _getFormattedAddress(_currentLat, _currentLng);
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
                  userAgentPackageName: 'com.example.flutter_application_1',
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint('Map tile failed to load: $error');
                  },
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

          // 2. Center target pin, offset so its tip points at the map center
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildCenterTargetPin(),
            ),
          ),

          // 3. Floating map tools on the right (Zoom, Location GPS)
          Positioned(
            right: 16,
            top: 20,
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
    final active = _usingGPS;
    return GestureDetector(
      onTap: _initiateRealTimeLocation,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? _accentColor : _gpsGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.my_location_rounded,
          color: active ? _accentText : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // Center target pin widget — a squircle "map pin" badge matching Figma,
  // rotated 45° with a white dot at its center.
  Widget _buildCenterTargetPin() {
    return Transform.rotate(
      angle: -math.pi / 4,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _azure11,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(17),
            topRight: Radius.circular(17),
            bottomRight: Radius.circular(17),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  // Bottom panel details sheet
  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _sheetBg,
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
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.37),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 15),

          _buildSearchBar(),
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

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
                        border: Border.all(color: _searchFieldBg),
                      ),
                      child: const Text(
                        'Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: _searchFieldBg,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Confirm Button
              Expanded(
                child: Material(
                  color: _isAdvanced ? _accentColor : _confirmBg,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      // Captured now (context is guaranteed valid inside a
                      // synchronous tap handler) rather than re-querying
                      // `context` inside the Timer below — see the matching
                      // comment on _initiateRealTimeLocation for why a
                      // fresh `Navigator.of(context)` after a delay can
                      // throw even when `mounted` is still true.
                      final navigator = Navigator.of(context);
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
                            navigator.pushNamed(
                              '/qualifications-intro',
                              arguments: _bookingArgs,
                            );
                          } else {
                            navigator.pushNamed(
                              '/confirm-booking',
                              arguments: _bookingArgs,
                            );
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: const Text(
                        'Confirm',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: _searchFieldBg,
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
