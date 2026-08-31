import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';


// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 3 of 7
//  Figma node: 426-362 · "Location & bio"
//  "Areas covered" is computed for real from sriLankanCities lat/lng via
//  haversineKm — not a hardcoded list — so it reflects whatever city and
//  radius the caregiver actually picks.
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding3Screen extends StatefulWidget {
  const CaregiverOnboarding3Screen({super.key});

  @override
  State<CaregiverOnboarding3Screen> createState() =>
      _CaregiverOnboarding3ScreenState();
}

class _CaregiverOnboarding3ScreenState
    extends State<CaregiverOnboarding3Screen> {
  static const Color bg = Color(0xFFF1F8E1);
  static const Color titleDark = Color(0xFF112541);
  static const Color fieldLabel = Color(0xFF627590);
  static const Color stepLabel = Color(0xFF94A3B8);
  static const Color fieldBorder = Color(0xFF334155);
  static const Color locationIcon = Color(0xFF323D48);
  static const Color progressActive = Color(0xFF345058);
  static const Color progressInactive = Color.fromRGBO(137, 171, 199, 0.37);
  static const Color coverageBg = Color.fromRGBO(2, 33, 64, 0.18);
  static const Color coverageBorder = Color(0xFF323D48);
  static const Color coverageLabel = Color(0xFF4D607B);
  static const Color chipBg = Color(0xFF323D48);
  static const Color chipText = Color(0xFFCBD5E1);
  static const Color bioBg = Color.fromRGBO(30, 41, 59, 0.43);
  static const Color continueBg = Color(0xFF223A5C);

  final _cityController = TextEditingController();
  final _bioController = NoUnderlineTextEditingController();
  final FocusNode _cityFocus = FocusNode();
  List<Map<String, String>> _filteredCities = [];

  static const List<String> _radiusOptions = [
    '5 km',
    '10 km',
    '15 km',
    '20 km',
    '25 km',
    '30 km',
  ];
  String _radius = '10 km';
  String? _cityError;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _cityController.addListener(_onCityTextChanged);
    _cityFocus.addListener(() {
      setState(() {});
      if (!_cityFocus.hasFocus) {
        setState(() => _filteredCities = []);
      }
    });
  }

  // ── Autocomplete city search ──────────────────────────────
  void _onCityTextChanged() {
    final query = _cityController.text.trim();
    if (_cityError != null && query.isNotEmpty) {
      setState(() => _cityError = null);
    }
    if (query.isEmpty || !_cityFocus.hasFocus) {
      if (_filteredCities.isNotEmpty) setState(() => _filteredCities = []);
      return;
    }
    final matches = sriLankanCities
        .where((item) =>
            item['city']!.toLowerCase().contains(query.toLowerCase()) ||
            item['district']!.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final limited = matches.take(5).toList();
    final exactMatch = limited.any((item) =>
        '${item['city']}, ${item['district']}'.toLowerCase() ==
        query.toLowerCase());
    setState(() => _filteredCities = exactMatch ? [] : limited);
  }

  // Full scrollable list opened by tapping the chevron.
  void _showCityPicker() {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final filtered = query.isEmpty
                ? sriLankanCities
                : sriLankanCities
                    .where((c) =>
                        c['city']!.toLowerCase().contains(query.toLowerCase()) ||
                        c['district']!
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                    .toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select city / area',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: titleDark,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(sheetCtx),
                            child: Icon(Icons.close_rounded,
                                color: titleDark, size: 22),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: fieldBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setSheet(() => query = v),
                          style: TextStyle(
                            color: titleDark,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 17, vertical: 14),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: locationIcon, size: 20),
                            hintText: 'Search city or district…',
                            hintStyle: TextStyle(
                                color: Color.fromRGBO(0, 0, 0, 0.4),
                                fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching cities found',
                                style: TextStyle(
                                    color: coverageLabel, fontSize: 14),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: fieldBorder.withValues(alpha: 0.35),
                              ),
                              itemBuilder: (ctx, i) {
                                final item = filtered[i];
                                final display =
                                    '${item['city']}, ${item['district']}';
                                return ListTile(
                                  leading: Icon(
                                    Icons.location_on_outlined,
                                    color: locationIcon,
                                    size: 20,
                                  ),
                                  title: Text(
                                    display,
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      color: titleDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _cityController.text = display;
                                      _cityController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(
                                            offset: display.length),
                                      );
                                      _filteredCities = [];
                                    });
                                    Navigator.pop(sheetCtx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _cityFocus.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _radiusOptions.map((r) {
            final selected = r == _radius;
            return ListTile(
              title: Text(
                r,
                style: TextStyle(
                  color: selected ? continueBg : titleDark,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected ? const Icon(Icons.check_rounded, color: continueBg) : null,
              onTap: () {
                setState(() => _radius = r);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Real nearby cities within the chosen radius of the typed city, computed
  /// from sriLankanCities lat/lng via the haversine formula — empty (rather
  /// than a guess) if the typed text doesn't match a known city.
  List<String> _computeCoveredAreas() {
    final cityName = _cityController.text.split(',').first.trim();
    final origin = cityCoords(cityName);
    if (origin == null) return const [];
    final radiusKm = double.tryParse(_radius.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 10;
    final originLat = double.parse(origin['lat']!);
    final originLng = double.parse(origin['lng']!);

    final matches = <MapEntry<String, double>>[];
    for (final c in sriLankanCities) {
      final lat = double.parse(c['lat']!);
      final lng = double.parse(c['lng']!);
      final dist = haversineKm(originLat, originLng, lat, lng);
      if (dist <= radiusKm) {
        matches.add(MapEntry(c['city']!, dist));
      }
    }
    matches.sort((a, b) => a.value.compareTo(b.value));
    return matches.map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final coveredAreas = _computeCoveredAreas();
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Top row: back arrow + step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleDark, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 3 of 7',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: stepLabel,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 3, totalSteps: 7),

              const SizedBox(height: 24),

              const Text(
                'Location & bio',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleDark,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),

                      _buildLabel('City / area'),
                      const SizedBox(height: 8),

                      // ── Autocomplete city field ──────────────
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _cityError != null
                                ? Colors.redAccent
                                : (_cityFocus.hasFocus
                                    ? continueBg
                                    : fieldBorder),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.location_on_rounded,
                                color: locationIcon, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _cityController,
                                focusNode: _cityFocus,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: titleDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15.5),
                                  hintText: 'e.g. Negombo, Colombo…',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: fieldLabel.withValues(alpha: 0.55),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _cityFocus.unfocus();
                                _showCityPicker();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: locationIcon,
                                    size: 22),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),
                      ),

                      // Inline suggestions dropdown
                      if (_filteredCities.isNotEmpty && _cityFocus.hasFocus)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: fieldBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              children: List.generate(
                                _filteredCities.length,
                                (i) {
                                  final item = _filteredCities[i];
                                  final display =
                                      '${item['city']}, ${item['district']}';
                                  final isLast =
                                      i == _filteredCities.length - 1;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _cityController.text = display;
                                        _cityController.selection =
                                            TextSelection.fromPosition(
                                          TextPosition(
                                              offset: display.length),
                                        );
                                        _filteredCities = [];
                                      });
                                      _cityFocus.unfocus();
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: isLast
                                            ? null
                                            : Border(bottom: BorderSide(
                                                color: fieldBorder
                                                    .withValues(alpha: 0.4),
                                                width: 1)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on_rounded,
                                              color: locationIcon, size: 16),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              display,
                                              style: TextStyle(
                                                fontFamily: 'Open Sans',
                                                color: titleDark,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                      if (_cityError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            _cityError!,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              color: Colors.redAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 18),

                      _buildLabel('Service radius'),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _showRadiusPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 17.5, vertical: 15.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: fieldBorder, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _radius,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: titleDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: stepLabel, size: 22),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 15.5, vertical: 13.5),
                        decoration: BoxDecoration(
                          color: coverageBg,
                          border: Border.all(color: coverageBorder, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Areas covered within $_radius',
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: coverageLabel,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (coveredAreas.isEmpty)
                              const Text(
                                'Enter a recognised Sri Lankan city to see the areas within range.',
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: coverageLabel,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: coveredAreas
                                    .map((area) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 13, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: chipBg,
                                            border: Border.all(color: fieldBorder),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            area,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              color: chipText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      _buildLabel('Short bio'),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: bioBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _bioController,
                          maxLines: 4,
                          minLines: 4,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: titleDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13.25),
                            hintText: 'Compassionate elder-care nurse with 5 years supporting '
                                'families across the Western Province. I specialise in '
                                'dementia and post-surgery recovery.',
                            hintStyle: TextStyle(
                              fontFamily: 'Open Sans',
                              color: locationIcon.withValues(alpha: 0.5),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: continueBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        if (_cityController.text.trim().isEmpty) {
                          setState(() => _cityError = 'City / area is required');
                          return;
                        }
                        final draft = AppState.caregiverOnboardingDraft;
                        draft.city = _cityController.text.trim();
                        draft.serviceRadius = _radius;
                        draft.bio = _bioController.text.trim();
                        Navigator.pushNamed(
                            context, '/caregiver-onboarding-4');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: fieldLabel,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  /// Progress bar with segmented steps
  Widget _buildProgressBar({required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? progressActive : progressInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
