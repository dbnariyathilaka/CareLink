import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 3 of 6
//  Figma node: 498-6556 · "Location & bio"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding3Screen extends StatefulWidget {
  const CaregiverOnboarding3Screen({super.key});

  @override
  State<CaregiverOnboarding3Screen> createState() =>
      _CaregiverOnboarding3ScreenState();
}

class _CaregiverOnboarding3ScreenState
    extends State<CaregiverOnboarding3Screen> {
  static const Color _indigo = Color(0xFF6366F1);

  final _cityController = TextEditingController(text: 'Negombo, Western Province');
  final _bioController = TextEditingController(
    text: 'Compassionate elder-care nurse with 5 years supporting families '
        'across the Western Province. I specialise in dementia and '
        'post-surgery recovery.',
  );

  static const List<String> _radiusOptions = [
    '5 km',
    '10 km',
    '15 km',
    '20 km',
    '25 km',
    '30 km',
  ];
  String _radius = '10 km';

  static const Map<String, List<String>> _coveredAreas = {
    '5 km': ['Negombo', 'Katunayake'],
    '10 km': ['Negombo', 'Katunayake', 'Ja-Ela', 'Seeduwa', 'Wennappuwa'],
    '15 km': ['Negombo', 'Katunayake', 'Ja-Ela', 'Seeduwa', 'Wennappuwa', 'Kochchikade'],
    '20 km': [
      'Negombo', 'Katunayake', 'Ja-Ela', 'Seeduwa', 'Wennappuwa', 'Kochchikade', 'Marawila',
    ],
    '25 km': [
      'Negombo', 'Katunayake', 'Ja-Ela', 'Seeduwa', 'Wennappuwa', 'Kochchikade', 'Marawila',
      'Chilaw',
    ],
    '30 km': [
      'Negombo', 'Katunayake', 'Ja-Ela', 'Seeduwa', 'Wennappuwa', 'Kochchikade', 'Marawila',
      'Chilaw', 'Waikkal',
    ],
  };

  @override
  void dispose() {
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showRadiusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
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
                  color: selected ? _indigo : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected ? const Icon(Icons.check_rounded, color: _indigo) : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 3 of 6',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 3, totalSteps: 6),

              const SizedBox(height: 24),

              const Text(
                'Location & bio',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),

                      const Text(
                        'City / area',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 17),
                            const Icon(Icons.location_on, color: _indigo, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _cityController,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Service radius',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: _showRadiusPicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                          decoration: BoxDecoration(
                            color: AppTheme.inputBackground,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _radius,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.textSecondary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(
                          color: _indigo.withValues(alpha: 0.08),
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Areas covered within $_radius',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_coveredAreas[_radius] ?? const [])
                                  .map((area) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 13, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: AppTheme.inputBackground,
                                          border: Border.all(color: AppTheme.borderColor),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          area,
                                          style: const TextStyle(
                                            color: Color(0xFFCBD5E1),
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

                      const Text(
                        'Short bio',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
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
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 15),
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
                    color: _indigo,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
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
              color: isActive ? _indigo : AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
