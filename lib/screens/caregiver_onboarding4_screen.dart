import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/sri_lankan_cities.dart';

class CaregiverOnboarding4Screen extends StatefulWidget {
  const CaregiverOnboarding4Screen({super.key});

  @override
  State<CaregiverOnboarding4Screen> createState() =>
      _CaregiverOnboarding4ScreenState();
}

class _CaregiverOnboarding4ScreenState
    extends State<CaregiverOnboarding4Screen>
    with SingleTickerProviderStateMixin {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFFA5B4FC);

  static const List<String> _radiusOptions = [
    '5 km', '10 km', '15 km', '20 km', '25 km', '30 km',
  ];

  final _cityController =
      TextEditingController(text: 'Negombo, Gampaha District');
  final _bioController = TextEditingController(
    text: 'Compassionate elder-care nurse with 5 years supporting families '
        'across the Western Province. I specialise in dementia and '
        'post-surgery recovery.',
  );

  final FocusNode _cityFocus = FocusNode();
  List<Map<String, String>> _filteredCities = [];

  String _serviceRadius = '10 km';

  /// Currently selected city data (includes lat/lng)
  Map<String, String>? _selectedCity;

  /// Cities within radius, sorted by distance
  List<({Map<String, String> city, double distKm})> _citiesInRadius = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cityFocus.addListener(() {
      setState(() {});
      if (!_cityFocus.hasFocus) {
        setState(() => _filteredCities = []);
      }
    });

    _cityController.addListener(_onCityTextChanged);

    // Resolve the pre-filled city
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveCity());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  // ── Autocomplete ──────────────────────────────────────────
  void _onCityTextChanged() {
    final query = _cityController.text.trim();
    if (query.isEmpty || !_cityFocus.hasFocus) {
      if (_filteredCities.isNotEmpty) setState(() => _filteredCities = []);
      return;
    }
    final matches = sriLankanCities.where((item) =>
        item['city']!.toLowerCase().contains(query.toLowerCase())).toList();
    final limited = matches.take(5).toList();
    final exactMatch = limited.any((item) =>
        '${item['city']}, ${item['district']}'.toLowerCase() ==
        query.toLowerCase());
    setState(() => _filteredCities = exactMatch ? [] : limited);
  }

  void _resolveCity() {
    final raw = _cityController.text.trim();
    final cityName =
        raw.contains(',') ? raw.split(',').first.trim() : raw;
    final data = cityCoords(cityName);
    setState(() {
      _selectedCity = data;
      if (data != null) {
        _updateCitiesInRadius(data);
      } else {
        _citiesInRadius = [];
      }
    });
  }

  int _radiusKm() =>
      int.parse(_serviceRadius.replaceAll(' km', ''));

  void _updateCitiesInRadius(Map<String, String> center) {
    final cLat = double.parse(center['lat']!);
    final cLng = double.parse(center['lng']!);
    final km = _radiusKm().toDouble();

    final results = <({Map<String, String> city, double distKm})>[];
    for (final c in sriLankanCities) {
      final lat = double.tryParse(c['lat'] ?? '');
      final lng = double.tryParse(c['lng'] ?? '');
      if (lat == null || lng == null) continue;
      final dist = haversineKm(cLat, cLng, lat, lng);
      if (dist > 0.3 && dist <= km) {
        results.add((city: c, distKm: dist));
      }
    }
    results.sort((a, b) => a.distKm.compareTo(b.distKm));
    _citiesInRadius = results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text('Step 4 of 5',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),

              const SizedBox(height: 16),
              _buildProgressBar(currentStep: 4, totalSteps: 5),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location & bio',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4)),
                      const SizedBox(height: 22),

                      // ── City / area ──
                      _buildLabel('City / area'),
                      const SizedBox(height: 8),
                      _buildCityField(),
                      _buildSuggestionsList(),
                      const SizedBox(height: 18),

                      // ── Service radius ──
                      _buildLabel('Service radius'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showRadiusPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 17, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppTheme.inputBackground,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_serviceRadius,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400)),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textPrimary, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Coverage visualizer ──
                      _buildLabel('Coverage area preview'),
                      const SizedBox(height: 8),
                      _buildCoverageCard(),
                      const SizedBox(height: 18),

                      // ── Short bio ──
                      _buildLabel('Short bio'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 17, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _bioController,
                          maxLines: 4,
                          minLines: 4,
                          style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.5),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: _indigo,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pushNamed(
                          context, '/caregiver-onboarding-5'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Coverage card ─────────────────────────────────────────
  Widget _buildCoverageCard() {
    if (_selectedCity == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(
          child: Text(
            'Select a city above to see your coverage area',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _indigo.withValues(alpha: 0.35), width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Canvas radar diagram
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _CoveragePainter(
                  centerCity: _selectedCity!,
                  citiesInRadius: _citiesInRadius,
                  radiusKm: _radiusKm().toDouble(),
                  pulseScale: _pulseAnimation.value,
                ),
              ),
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: _indigo.withValues(alpha: 0.2),
          ),

          // Towns list
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_city_rounded,
                        color: _indigo, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${_citiesInRadius.length} town${_citiesInRadius.length == 1 ? '' : 's'} within $_serviceRadius',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (_citiesInRadius.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _citiesInRadius.take(24).map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _indigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _indigo.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${entry.city['city']} · ${entry.distKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: _indigoLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_citiesInRadius.length > 24)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+ ${_citiesInRadius.length - 24} more towns…',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'No other towns found in this radius',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── City autocomplete field ────────────────────────────────
  Widget _buildCityField() {
    final focused = _cityFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: focused ? _indigo : AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 17),
          const Icon(Icons.location_on_outlined, color: _indigo, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _cityController,
              focusNode: _cityFocus,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                hintText: 'Enter your city or area',
                hintStyle:
                    TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 17),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_filteredCities.isEmpty || !_cityFocus.hasFocus) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: List.generate(_filteredCities.length, (index) {
            final item = _filteredCities[index];
            final displayText = '${item['city']}, ${item['district']}';
            final isLast = index == _filteredCities.length - 1;
            return InkWell(
              onTap: () {
                setState(() {
                  _cityController.text = displayText;
                  _cityController.selection = TextSelection.fromPosition(
                      TextPosition(offset: displayText.length));
                  _filteredCities = [];
                });
                _cityFocus.unfocus();
                Future.delayed(
                    const Duration(milliseconds: 80), _resolveCity);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 17, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                              color: AppTheme.borderColor, width: 1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: _indigo, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(displayText,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _radiusOptions.map((option) {
            final selected = option == _serviceRadius;
            return ListTile(
              title: Text(option,
                  style: TextStyle(
                      color: selected ? _indigo : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: _indigo)
                  : null,
              onTap: () {
                setState(() {
                  _serviceRadius = option;
                  if (_selectedCity != null) {
                    _updateCitiesInRadius(_selectedCity!);
                  }
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500));

  Widget _buildProgressBar(
      {required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: index < currentStep ? _indigo : AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

// ── Custom Painter — radar-style coverage diagram ──────────
class _CoveragePainter extends CustomPainter {
  final Map<String, String> centerCity;
  final List<({Map<String, String> city, double distKm})> citiesInRadius;
  final double radiusKm;
  final double pulseScale;

  _CoveragePainter({
    required this.centerCity,
    required this.citiesInRadius,
    required this.radiusKm,
    required this.pulseScale,
  });

  static const _indigo = Color(0xFF6366F1);
  static const _indigoLight = Color(0xFFA5B4FC);
  static const _indigo10 = Color(0x1A6366F1);
  static const _indigo20 = Color(0x336366F1);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) - 20;

    // ── Background rings ──
    for (int ring = 1; ring <= 3; ring++) {
      final r = maxR * ring / 3;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF334155)
          ..strokeWidth = 1,
      );
      // Ring labels (distance fraction)
      final label =
          '${(radiusKm * ring / 3).toStringAsFixed(0)} km';
      _drawText(canvas, label, Offset(cx + 4, cy - r - 2), 9,
          const Color(0xFF64748B));
    }

    // ── Cross-hair lines ──
    final dashPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx, cy - maxR - 4), Offset(cx, cy + maxR + 4),
        dashPaint);
    canvas.drawLine(Offset(cx - maxR - 4, cy), Offset(cx + maxR + 4, cy),
        dashPaint);

    // ── Pulsing fill circle ──
    canvas.drawCircle(
      Offset(cx, cy),
      maxR * pulseScale,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _indigo10,
    );

    // ── Outer radius circle ──
    canvas.drawCircle(
      Offset(cx, cy),
      maxR,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _indigo
        ..strokeWidth = 1.5,
    );

    // ── Other cities as dots ──
    final cLat = double.parse(centerCity['lat']!);
    final cLng = double.parse(centerCity['lng']!);

    // Compute bearing and distance for each city
    for (final entry in citiesInRadius) {
      final lat = double.parse(entry.city['lat']!);
      final lng = double.parse(entry.city['lng']!);

      // Bearing from center to this city
      final bearing = _bearing(cLat, cLng, lat, lng);
      // Distance fraction within the radius
      final fraction = (entry.distKm / radiusKm).clamp(0.05, 1.0);

      final dotX = cx + math.sin(bearing) * maxR * fraction;
      final dotY = cy - math.cos(bearing) * maxR * fraction;

      // Dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()
          ..style = PaintingStyle.fill
          ..color = _indigoLight.withValues(alpha: 0.8),
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        4,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _indigo
          ..strokeWidth = 1,
      );

      // City name label for nearby towns (< 60% radius)
      if (fraction < 0.62 || citiesInRadius.length <= 6) {
        _drawText(
          canvas,
          entry.city['city']!,
          Offset(dotX + 6, dotY - 7),
          9,
          _indigoLight,
        );
      }
    }

    // ── Centre dot (caregiver) ──
    canvas.drawCircle(
      Offset(cx, cy),
      7,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _indigo,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      11,
      Paint()
        ..style = PaintingStyle.fill
        ..color = _indigo20,
    );
    // Centre label
    _drawText(
      canvas,
      centerCity['city']!,
      Offset(cx + 14, cy - 8),
      11,
      Colors.white,
      bold: true,
    );
  }

  /// Compass bearing in radians from point 1 → point 2.
  double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * math.pi / 180;
    final l1 = lat1 * math.pi / 180;
    final l2 = lat2 * math.pi / 180;
    final y = math.sin(dLng) * math.cos(l2);
    final x =
        math.cos(l1) * math.sin(l2) - math.sin(l1) * math.cos(l2) * math.cos(dLng);
    return math.atan2(y, x);
  }

  void _drawText(Canvas canvas, String text, Offset position, double fontSize,
      Color color,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_CoveragePainter old) =>
      old.pulseScale != pulseScale ||
      old.radiusKm != radiusKm ||
      old.citiesInRadius != citiesInRadius ||
      old.centerCity != centerCity;
}
