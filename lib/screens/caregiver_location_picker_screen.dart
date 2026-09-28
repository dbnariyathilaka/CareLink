import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/sri_lankan_cities.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Location Picker — a modal map screen matching the visual
//  language of map_selection_screen.dart (used for patient booking
//  requests), adapted to POP a result back instead of pushing forward
//  through a booking wizard, since this is picking one permanent field on
//  the caregiver's own profile, not a step in a multi-screen flow.
//
//  Returns `{'city': String, 'lat': double, 'lng': double}` via
//  Navigator.pop, or null if dismissed without confirming. The returned
//  city is the nearest known Sri Lankan city name (a real lookup against
//  sriLankanCities), not an invented street address — map_selection_screen
//  fabricates a plausible-looking address for the booking-location flow,
//  which is fine for an ephemeral visit location but not appropriate to
//  carry into a caregiver's own permanent profile field.
// ─────────────────────────────────────────────────────────────
class CaregiverLocationPickerScreen extends StatefulWidget {
  const CaregiverLocationPickerScreen({super.key});

  @override
  State<CaregiverLocationPickerScreen> createState() => _CaregiverLocationPickerScreenState();
}

class _CaregiverLocationPickerScreenState extends State<CaregiverLocationPickerScreen> {
  static const Color _azure11 = Color(0xFF0F172A);
  static const Color _azure17 = Color(0xFF1E293B);
  static const Color _azure27 = Color(0xFF334155);
  static const Color _azure65 = Color(0xFF94A3B8);
  static const Color _grey98 = Color(0xFFF8FAFC);
  static const Color _sheetBg = Color(0xFF313131);
  static const Color _searchFieldBg = Color(0xFFEDE9DE);
  static const Color _accent = Color(0xFF223A5C);
  static const Color _gpsGreen = Color(0xFF205441);

  final MapController _mapController = MapController();
  double _zoomLevel = 14.0;
  bool _isLocating = false;
  bool _usingGPS = false;
  double _currentLat = 6.9271; // Colombo
  double _currentLng = 79.8612;
  String _cityLabel = 'Colombo';

  final TextEditingController _searchController = NoUnderlineTextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, String>> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _cityLabel = _nearestCityName(_currentLat, _currentLng);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _nearestCityName(double lat, double lng) {
    var minDistance = double.infinity;
    var closest = 'Colombo';
    for (final c in sriLankanCities) {
      final cityStr = c['city'];
      final latStr = c['lat'];
      final lngStr = c['lng'];
      if (cityStr == null || latStr == null || lngStr == null) continue;
      final cLat = double.tryParse(latStr) ?? 0.0;
      final cLng = double.tryParse(lngStr) ?? 0.0;
      final dist = math.sqrt(math.pow(lat - cLat, 2) + math.pow(lng - cLng, 2));
      if (dist < minDistance) {
        minDistance = dist;
        closest = cityStr;
      }
    }
    return closest;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      final lower = query.toLowerCase();
      setState(() {
        _searchResults = sriLankanCities
            .where((c) =>
                (c['city'] ?? '').toLowerCase().contains(lower) ||
                (c['district'] ?? '').toLowerCase().contains(lower))
            .take(8)
            .toList();
      });
    });
  }

  void _selectSearchResult(Map<String, String> city) {
    final lat = double.tryParse(city['lat'] ?? '');
    final lng = double.tryParse(city['lng'] ?? '');
    if (lat == null || lng == null) return;
    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _cityLabel = city['city'] ?? _cityLabel;
      _searchResults = [];
      _searchController.text = _cityLabel;
      _usingGPS = false;
    });
    _mapController.move(LatLng(lat, lng), 15.5);
    _searchFocusNode.unfocus();
  }

  Future<void> _useMyLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permission denied.';
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied.';
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      if (!mounted) return;
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _cityLabel = _nearestCityName(_currentLat, _currentLng);
        _usingGPS = true;
      });
      _mapController.move(LatLng(_currentLat, _currentLng), 15.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get your location: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentLat, _currentLng),
                initialZoom: _zoomLevel,
                onPositionChanged: (position, hasGesture) {
                  final center = position.center;
                  if (center == null) return;
                  setState(() {
                    _currentLat = center.latitude;
                    _currentLng = center.longitude;
                    _cityLabel = _nearestCityName(_currentLat, _currentLng);
                    if (hasGesture) _usingGPS = false;
                  });
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
              ],
            ),
          ),

          // Center target pin
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildCenterPin(),
            ),
          ),

          // Back button
          Positioned(
            left: 16,
            top: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _azure17,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _azure27),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: _grey98, size: 22),
                ),
              ),
            ),
          ),

          // Zoom + GPS tools
          Positioned(
            right: 16,
            top: 16,
            child: SafeArea(
              child: Column(
                children: [
                  _buildFloatingTool(
                    icon: Icons.add_rounded,
                    onTap: () {
                      setState(() => _zoomLevel = (_zoomLevel + 1).clamp(3.0, 20.0));
                      _mapController.move(LatLng(_currentLat, _currentLng), _zoomLevel);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFloatingTool(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      setState(() => _zoomLevel = (_zoomLevel - 1).clamp(3.0, 20.0));
                      _mapController.move(LatLng(_currentLat, _currentLng), _zoomLevel);
                    },
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _useMyLocation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _usingGPS ? _accent : _gpsGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel(context)),

          if (_isLocating)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _accent),
                    SizedBox(height: 16),
                    Text('Getting your location…', style: TextStyle(color: _grey98, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

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
        ),
        child: Icon(icon, color: _grey98, size: 22),
      ),
    );
  }

  Widget _buildCenterPin() {
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: DecoratedBox(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _sheetBg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        border: Border(top: BorderSide(color: _azure27, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.37), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 15),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(color: _azure11, borderRadius: BorderRadius.circular(12), border: Border.all(color: _azure27)),
              child: Row(
                children: [
                  const Icon(Icons.location_city_rounded, color: _accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_cityLabel, Sri Lanka',
                      style: const TextStyle(color: _grey98, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_currentLat.toStringAsFixed(5)}° N, ${_currentLng.toStringAsFixed(5)}° E',
                  style: TextStyle(color: _azure65, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: _searchFieldBg)),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Open Sans', color: _searchFieldBg, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: _accent,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () {
                        Navigator.pop(context, {
                          'city': _cityLabel,
                          'lat': _currentLat,
                          'lng': _currentLng,
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          'Use this location',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildSearchBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_searchResults.isNotEmpty)
          Container(
            key: const ValueKey('search_results'),
            constraints: const BoxConstraints(maxHeight: 220),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _searchFieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _azure27),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, _) => Divider(color: _azure27.withValues(alpha: 0.4), height: 1),
                itemBuilder: (context, i) {
                  final city = _searchResults[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_rounded, color: Colors.black54, size: 18),
                    title: Text(city['city'] ?? '', style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(city['district'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                    onTap: () => _selectSearchResult(city),
                  );
                },
              ),
            ),
          ),
        Container(
          key: const ValueKey('search_field'),
          decoration: BoxDecoration(color: _searchFieldBg, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: _azure65, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    filled: false,
                    hintText: 'Search city or district…',
                    hintStyle: TextStyle(fontFamily: 'Open Sans', color: _azure65, fontSize: 13, fontWeight: FontWeight.w700),
                    // The app's ambient theme defines a colored
                    // focusedBorder — without repeating InputBorder.none for
                    // every border state (not just the default `border`),
                    // Flutter falls back to that theme default the moment
                    // this field is focused, painting an unwanted outline.
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
