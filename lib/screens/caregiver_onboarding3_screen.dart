import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';


// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 3 of 7
//  Figma node: 426-362 · "Location & bio"
//  City/area is picked from a real interactive map (CaregiverLocationPickerScreen,
//  the same map UI used for a patient's booking-location step) instead of a
//  typed autocomplete field, so the caregiver's exact coordinates are
//  captured, not just a city name. The "service radius" input that used to
//  live here (and the serviceRadiusKm field it fed) was removed entirely —
//  matching_service.dart now uses a fixed system-wide 30km cap plus the
//  patient's own optional limit instead of a caregiver-declared radius.
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
  static const Color bioBg = Color.fromRGBO(30, 41, 59, 0.43);
  static const Color continueBg = Color(0xFF223A5C);

  final _bioController = NoUnderlineTextEditingController();

  String? _pickedCity;
  double? _pickedLat;
  double? _pickedLng;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.pushNamed(context, '/caregiver-location-picker');
    if (result is Map) {
      setState(() {
        _pickedCity = result['city'] as String?;
        _pickedLat = result['lat'] as double?;
        _pickedLng = result['lng'] as double?;
        _cityError = null;
      });
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                      // ── Map-based location picker ──────────────
                      // Opens CaregiverLocationPickerScreen (the same
                      // interactive-map UI used for a patient's booking
                      // location) instead of a typed field, so the
                      // caregiver's exact coordinates are captured.
                      GestureDetector(
                        onTap: _openLocationPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15.5),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _cityError != null ? Colors.redAccent : fieldBorder,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: locationIcon, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _pickedCity != null
                                      ? '$_pickedCity, Sri Lanka'
                                      : 'Tap to select your location on the map',
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: _pickedCity != null ? titleDark : fieldLabel.withValues(alpha: 0.55),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(Icons.map_outlined, color: locationIcon, size: 20),
                            ],
                          ),
                        ),
                      ),

                      if (_pickedLat != null && _pickedLng != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            '${_pickedLat!.toStringAsFixed(5)}° N, ${_pickedLng!.toStringAsFixed(5)}° E',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: fieldLabel,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
                        if (_pickedCity == null) {
                          setState(() => _cityError = 'Please select your location on the map');
                          return;
                        }
                        final draft = AppState.caregiverOnboardingDraft;
                        draft.city = _pickedCity!;
                        draft.locationLat = _pickedLat;
                        draft.locationLng = _pickedLng;
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
