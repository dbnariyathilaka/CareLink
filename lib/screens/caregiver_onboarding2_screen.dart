import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import 'certificate_upload_dialog.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 2 of 6
//  Figma node: 498-6436 · "Education & languages" + "Your skills"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding2Screen extends StatefulWidget {
  const CaregiverOnboarding2Screen({super.key});

  @override
  State<CaregiverOnboarding2Screen> createState() =>
      _CaregiverOnboarding2ScreenState();
}

class _CaregiverOnboarding2ScreenState
    extends State<CaregiverOnboarding2Screen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);

  String _selectedQualification = 'Diploma';

  String? _formalTraining; // 'Yes' or 'No'
  List<XFile> _certificates = [];

  final List<String> _languages = ['Sinhala', 'English', 'Tamil'];
  final Set<String> _selectedLanguages = {'Sinhala', 'English'};

  final List<String> _skills = [
    'Mobility assistance',
    'Medication management',
    'Dementia care',
    'Wound care',
    'Rehabilitation',
    'Physiotherapy',
    'Mental health support',
    'Pediatric care',
    'Sign language',
  ];

  final Set<String> _selectedSkills = {
    'Mobility assistance',
    'Medication management',
    'Dementia care',
  };

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
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 2 of 6',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 2, totalSteps: 6),

              const SizedBox(height: 24),

              const Text(
                'Education & languages',
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
                      const SizedBox(height: 18),

                      const Text(
                        'Educational qualification',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildPillButton(
                              label: 'Primary',
                              isSelected: _selectedQualification == 'Primary',
                              onTap: () => setState(() => _selectedQualification = 'Primary'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPillButton(
                              label: 'Secondary',
                              isSelected: _selectedQualification == 'Secondary',
                              onTap: () => setState(() => _selectedQualification = 'Secondary'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPillButton(
                              label: 'Diploma',
                              isSelected: _selectedQualification == 'Diploma',
                              onTap: () => setState(() => _selectedQualification = 'Diploma'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPillButton(
                              label: 'Degree or higher',
                              isSelected: _selectedQualification == 'Degree or higher',
                              onTap: () =>
                                  setState(() => _selectedQualification = 'Degree or higher'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'Formal caregiving training',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildPillButton(
                              label: 'Yes',
                              isSelected: _formalTraining == 'Yes',
                              onTap: _handleFormalTrainingYes,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPillButton(
                              label: 'No',
                              isSelected: _formalTraining == 'No',
                              onTap: () => setState(() {
                                _formalTraining = 'No';
                                _certificates = [];
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (_formalTraining == 'Yes' && _certificates.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: _indigo, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_certificates.length} certificate${_certificates.length > 1 ? 's' : ''} attached',
                              style: const TextStyle(
                                color: _indigoLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 26),

                      const Text(
                        'Languages spoken',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _languages.map((lang) {
                          final isSelected = _selectedLanguages.contains(lang);
                          return _buildCheckChip(
                            label: lang,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedLanguages.remove(lang);
                                } else {
                                  _selectedLanguages.add(lang);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Your skills',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),

                      const Text(
                        'More skills = more requests',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _skills.map((skill) {
                          final isSelected = _selectedSkills.contains(skill);
                          return _buildCheckChip(
                            label: skill,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedSkills.remove(skill);
                                } else {
                                  _selectedSkills.add(skill);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: _indigo,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final draft = AppState.caregiverOnboardingDraft;
                        draft.educationalQualification = _selectedQualification;
                        draft.formalTraining = _formalTraining == 'Yes';
                        draft.languagesSpoken = _selectedLanguages;
                        draft.skills = _selectedSkills;
                        Navigator.pushNamed(context, '/caregiver-onboarding-3');
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

  Future<void> _handleFormalTrainingYes() async {
    setState(() => _formalTraining = 'Yes');
    final result = await showCertificateUploadDialog(context);
    if (!mounted) return;
    if (result == null || result.isEmpty) {
      // Cancelled without submitting a certificate — don't leave "Yes"
      // selected without the required verification.
      setState(() => _formalTraining = null);
    } else {
      setState(() => _certificates = result);
    }
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

  /// Equal-width single-select pill (no checkmark) — qualification / training
  Widget _buildPillButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? _indigo.withValues(alpha: 0.15) : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _indigo : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? _indigoLight : const Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Multi-select chip with checkmark (wrap layout) — languages / skills
  Widget _buildCheckChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _indigo.withValues(alpha: 0.15) : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _indigo : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: _indigoLight, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _indigoLight : const Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
