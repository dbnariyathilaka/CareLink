import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/sri_lankan_cities.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  // Colors (Figma tokens mapped to AppTheme)
  static const Color _green45 = AppTheme.primaryGreen; // #22C55E
  static const Color _green8 = AppTheme.bottleGreen;   // #06240F
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _azure17 = AppTheme.cardColor;    // #1E293B
  static const Color _azure27 = AppTheme.borderColor;  // #334155
  static const Color _azure47 = Color(0xFF64748B);
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8
  static const Color _azure84 = Color(0xFFCBD5E1);
  static const Color _grey98 = AppTheme.textPrimary;    // #F8FAFC

  // Location State
  String? _selectedCity;
  double? _selectedLat;
  double? _selectedLng;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

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
  Widget build(BuildContext context) {
    final hasLocation = _selectedCity != null;

    return Scaffold(
      backgroundColor: _azure11,
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
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const Text(
            'Location',
            style: TextStyle(
              color: _grey98,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 24), // empty spacer to balance
        ],
      ),
    );
  }

  // ── 2. 4-step progress indicator ──
  Widget _buildStepIndicator() {
    const steps = [
      _StepInfo('1', 'Request', _StepState.done),
      _StepInfo('2', 'Schedule', _StepState.done),
      _StepInfo('3', 'Location', _StepState.active),
      _StepInfo('4', 'Confirm', _StepState.inactive),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 1.5,
                color: _green45,
              ),
            );
          }
          return _buildStepBubble(steps[i ~/ 2]);
        }),
      ),
    );
  }

  Widget _buildStepBubble(_StepInfo s) {
    final isActive = s.state == _StepState.active;
    final isDone = s.state == _StepState.done;

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? _green45 : _azure17,
            border: Border.all(
              color: isActive || isDone ? _green45 : _azure27,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              s.number,
              style: TextStyle(
                color: isActive ? _green8 : (isDone ? _green45 : _azure47),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.label,
          style: TextStyle(
            color: isActive || isDone ? _green45 : _azure47,
            fontSize: 8,
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
        Navigator.pushNamed(context, '/map-selection');
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _azure27),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_azure17, _azure11],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Simulated Radar / grid streets background
            CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _MapGridPainter(hasLocation: hasLocation),
            ),
            if (hasLocation) ...[
              // Pulse circle centered at user location
              _buildPulseRadar(),
              // Location Pin widget
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _green8,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _green45, width: 1),
                    ),
                    child: Text(
                      _selectedCity!,
                      style: const TextStyle(
                        color: _green45,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on_rounded,
                    color: _green45,
                    size: 38,
                  ),
                ],
              ),
              // Nearby caregivers simulation
              const Positioned(
                top: 40,
                left: 60,
                child: Icon(Icons.person_pin_circle_rounded, color: Colors.blue, size: 28),
              ),
              const Positioned(
                bottom: 30,
                right: 80,
                child: Icon(Icons.person_pin_circle_rounded, color: Colors.tealAccent, size: 28),
              ),
            ] else ...[
              // Generic center pin
              const Icon(
                Icons.location_off_rounded,
                color: _azure47,
                size: 40,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRadar() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _green45.withValues(alpha: 0.1),
        border: Border.all(
          color: _green45.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
    );
  }

  // ── 4. Intro Text when no location is selected ──
  Widget _buildIntroSection() {
    return Column(
      children: const [
        Text(
          'No location set yet',
          style: TextStyle(
            color: _grey98,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Add your care location so we can match you with nearby caregivers and calculate accurate travel times.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _azure65,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── 5. Benefits List (Figma specifications) ──
  Widget _buildBenefitsList() {
    final benefits = [
      _BenefitData(
        icon: Icons.location_searching_rounded,
        text: 'Faster, more accurate caregiver matches',
      ),
      _BenefitData(
        icon: Icons.directions_car_rounded,
        text: 'See real distance and travel time',
      ),
      _BenefitData(
        icon: Icons.health_and_safety_rounded,
        text: 'Faster response during emergencies',
      ),
    ];

    return Column(
      children: benefits.map((b) => _buildBenefitRow(b)).toList(),
    );
  }

  Widget _buildBenefitRow(_BenefitData b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _azure27),
        ),
        child: Row(
          children: [
            Icon(b.icon, color: _green45, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                b.text,
                style: const TextStyle(
                  color: _azure84,
                  fontSize: 12.5,
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
        color: _green45.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green45, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _green45, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Care Location',
                  style: TextStyle(
                    color: _green45,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedCity!}, Sri Lanka',
                  style: const TextStyle(
                    color: _grey98,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GPS Coordinates: ${_selectedLat!.toStringAsFixed(4)}° N, ${_selectedLng!.toStringAsFixed(4)}° E',
                  style: const TextStyle(
                    color: _azure65,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
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
            child: const Icon(Icons.close_rounded, color: _green45, size: 20),
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
          style: TextStyle(
            color: _azure65,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _azure17,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _azure27),
          ),
          child: Row(
            children: const [
              Icon(Icons.check_rounded, color: _green45, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nearby caregivers matches generated successfully.',
                  style: TextStyle(color: _azure84, fontSize: 12),
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
              color: _azure17,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      autofocus: true,
                      style: const TextStyle(color: _grey98),
                      decoration: InputDecoration(
                        hintText: 'Search city/town in Sri Lanka...',
                        hintStyle: const TextStyle(color: _azure65),
                        prefixIcon: const Icon(Icons.search_rounded, color: _azure65),
                        filled: true,
                        fillColor: _azure11,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _azure27),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _azure27),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _green45),
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: _green45, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Results list
            Expanded(
              child: Container(
                color: _azure11,
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching cities found',
                          style: TextStyle(color: _azure65, fontSize: 14),
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
                            leading: const Icon(Icons.location_on_rounded, color: _azure65),
                            title: Text(name, style: const TextStyle(color: _grey98)),
                            subtitle: Text('Lat: $lat, Lng: $lng', style: const TextStyle(color: _azure65, fontSize: 11)),
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
            _azure11.withValues(alpha: 0),
            _azure11,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: SafeArea(
        top: false,
        child: Material(
          color: _green45,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (!hasLocation) {
                // Navigate to full map selection screen
                Navigator.pushNamed(context, '/map-selection');
              } else {
                // Route to next step (Confirm Booking)
                Navigator.pushNamed(context, '/confirm-booking');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasLocation) ...[
                    const Icon(Icons.pin_drop_rounded, color: _green8, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    hasLocation ? 'Continue' : 'Set Location',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _green8,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom Painter to simulate map grids and streets ──
class _MapGridPainter extends CustomPainter {
  final bool hasLocation;
  _MapGridPainter({required this.hasLocation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double step = 20.0;
    // Draw grid lines
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += step) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }

    if (hasLocation) {
      // Draw simulated street avenues
      final streetPaint = Paint()
        ..color = const Color(0xFF334155)
        ..strokeWidth = 3.0;

      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), streetPaint);
      canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), streetPaint);

      // Draw radius circle
      final radiusPaint = Paint()
        ..color = AppTheme.primaryGreen.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, radiusPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
