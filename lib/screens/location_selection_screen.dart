import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/sri_lankan_cities.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF033724);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color stepLineInactive = Color(0xFFD9D9D9);
  static const Color stepInactiveBg = Color(0xFFDCD9CF);
  static const Color creamButtonText = Color(0xFFF6F0E2);

  // Kept dark — Figma leaves the benefit/info cards on the dark panel
  // treatment, same pattern used across the rest of this design.
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color amberIcon = Color(0xFFFBBC05);

  // Primary accent — dark green normally, plum/purple for the "advanced
  // match" flow (Figma node 296-284, matches schedule_care_screen.dart).
  Color get _accent => _isAdvanced ? const Color(0xFF6D4275) : darkGreen;
  Color get _accentOnColor => Colors.white;
  Color get _stepLineInactiveColor => _isAdvanced ? const Color(0xFFD1BAC6) : stepLineInactive;

  // Location State
  String? _selectedCity;
  double? _selectedLat;
  double? _selectedLng;
  bool _showSearch = false;
  final TextEditingController _searchController = NoUnderlineTextEditingController();

  bool _isAdvanced = false;
  Map<String, dynamic> _bookingArgs = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _isAdvanced = args['isAdvanced'] ?? false;
      _bookingArgs = args;
    }
  }

  List<Map<String, dynamic>> _searchResults = [];

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final lowercaseQuery = query.toLowerCase();
    final matches = sriLankanCities.where((city) {
      final cityName = city['name'] as String;
      return cityName.toLowerCase().contains(lowercaseQuery);
    }).toList();

    setState(() {
      _searchResults = matches;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _selectedCity != null;

    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
                    child: Column(
                      children: [
                        _buildMapSection(hasLocation),
                        const SizedBox(height: 24),
                        if (!hasLocation) ...[
                          _buildIntroSection(),
                          const SizedBox(height: 24),
                          _buildBenefitsList(),
                        ] else ...[
                          _buildSelectedLocationCard(),
                          const SizedBox(height: 24),
                          _buildBenefitsListShort(),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Autocomplete Overlay for city search
          if (_showSearch) _buildSearchOverlay(),
          // Bottom sticky button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomButton(context, hasLocation),
          ),
        ],
      ),
    );
  }

  // ── 1. Title Row ──
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 22),
          ),
          const Text(
            'Location',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: titleGreen,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 22), // balances the back icon so the title is centered
        ],
      ),
    );
  }

  // ── 2. Progress step indicator ──
  Widget _buildStepIndicator() {
    final steps = _isAdvanced
        ? const [
            _StepInfo('1', 'Request', _StepState.done),
            _StepInfo('2', 'Schedule', _StepState.done),
            _StepInfo('3', 'Location', _StepState.active),
            _StepInfo('4', 'Qualifications', _StepState.inactive),
            _StepInfo('5', 'Confirm', _StepState.inactive),
          ]
        : const [
            _StepInfo('1', 'Request', _StepState.done),
            _StepInfo('2', 'Schedule', _StepState.done),
            _StepInfo('3', 'Location', _StepState.active),
            _StepInfo('4', 'Confirm', _StepState.inactive),
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = steps[i ~/ 2].state != _StepState.inactive;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 3,
                  decoration: BoxDecoration(
                    color: leftDone ? _accent : _stepLineInactiveColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }
          return _buildStepBubble(steps[i ~/ 2]);
        }),
      ),
    );
  }

  Widget _buildStepBubble(_StepInfo s) {
    final isFilled = s.state != _StepState.inactive;

    return Column(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? _accent : stepInactiveBg,
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: isFilled ? _accentOnColor : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.label,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: titleGreen,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── 3. Map Section ──
  Widget _buildMapSection(bool hasLocation) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/map-selection', arguments: _bookingArgs);
      },
      child: Container(
        width: double.infinity,
        height: hasLocation ? 200 : 260,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: hasLocation ? darkCardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: hasLocation ? Border.all(color: darkBorder) : null,
        ),
        child: hasLocation && _selectedLat != null && _selectedLng != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Real mini map preview using OpenStreetMap!
                  Positioned.fill(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(_selectedLat!, _selectedLng!),
                        initialZoom: 14.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none, // Disable all gestures for static preview
                        ),
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
                  Icon(Icons.location_on_rounded, color: _accent, size: 38),
                ],
              )
            : Center(
                child: Image.asset(
                  'assets/images/location_map_illustration.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }

  // ── 4. Intro Text when no location is selected ──
  Widget _buildIntroSection() {
    return const Column(
      children: [
        Text(
          'No location set yet',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: darkGreen,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Add your care location so we can match you with nearby caregivers and calculate accurate travel times.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. Benefits List (kept on the dark card treatment per Figma) ──
  Widget _buildBenefitsList() {
    final benefits = [
      _BenefitData(icon: Icons.bolt_rounded, text: 'Faster, more accurate caregiver matches'),
      _BenefitData(icon: Icons.route_rounded, text: 'See real distance and travel time'),
      _BenefitData(icon: Icons.emergency_rounded, text: 'Faster response during emergencies'),
    ];

    return Column(
      children: benefits.map((b) => _buildBenefitRow(b)).toList(),
    );
  }

  Widget _buildBenefitRow(_BenefitData b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: darkCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: darkBorder),
        ),
        child: Row(
          children: [
            Icon(b.icon, color: amberIcon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                b.text,
                style: const TextStyle(
                  color: darkTextSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Selected Location Card ──
  Widget _buildSelectedLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: _accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Care Location',
                  style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedCity!}, Sri Lanka',
                  style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'GPS Coordinates: ${_selectedLat!.toStringAsFixed(4)}° N, ${_selectedLng!.toStringAsFixed(4)}° E',
                  style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCity = null;
                _selectedLat = null;
                _selectedLng = null;
              });
            },
            child: Icon(Icons.close_rounded, color: _accent, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsListShort() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location settings applied',
          style: TextStyle(color: darkGreen, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: darkCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: darkBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.check_rounded, color: _accent, size: 16),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Nearby caregivers matches generated successfully.',
                  style: TextStyle(color: darkTextSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Search overlay ──
  Widget _buildSearchOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: SafeArea(
        child: Column(
          children: [
            // Search Input Row
            Container(
              color: bgCream,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search city/town in Sri Lanka...',
                        hintStyle: const TextStyle(color: Colors.black38),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: darkGreen.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: darkGreen.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearch = false;
                        _searchController.clear();
                        _searchResults = [];
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Results list
            Expanded(
              child: Container(
                color: bgCream,
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching cities found',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final city = _searchResults[index];
                          final name = city['name'] as String;
                          final lat = city['lat'] as double;
                          final lng = city['lng'] as double;
                          return ListTile(
                            leading: const Icon(Icons.location_on_rounded, color: Colors.black54),
                            title: Text(name, style: const TextStyle(color: Colors.black)),
                            subtitle: Text('Lat: $lat, Lng: $lng', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            onTap: () {
                              setState(() {
                                _selectedCity = name;
                                _selectedLat = lat;
                                _selectedLng = lng;
                                _showSearch = false;
                                _searchController.clear();
                                _searchResults = [];
                              });
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sticky button ──
  Widget _buildBottomButton(BuildContext context, bool hasLocation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgCream.withValues(alpha: 0),
            bgCream,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 24),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: _accent.withValues(alpha: 0.5), blurRadius: 2, offset: const Offset(2, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                if (!hasLocation) {
                  Navigator.pushNamed(context, '/map-selection', arguments: _bookingArgs);
                } else {
                  final updatedArgs = {
                    ..._bookingArgs,
                    'location': _selectedCity,
                  };
                  if (_isAdvanced) {
                    Navigator.pushNamed(context, '/qualifications-selection', arguments: updatedArgs);
                  } else {
                    Navigator.pushNamed(context, '/confirm-booking', arguments: updatedArgs);
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: creamButtonText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Models ──
enum _StepState { done, active, inactive }

class _StepInfo {
  final String number;
  final String label;
  final _StepState state;
  const _StepInfo(this.number, this.label, this.state);
}

class _BenefitData {
  final IconData icon;
  final String text;
  const _BenefitData({required this.icon, required this.text});
}
