import 'package:flutter/material.dart';
import '../app_state.dart';
import 'certificate_upload_dialog.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 2 of 6
//  Figma node: 425-215 · "Education & languages" + "Your skills"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding2Screen extends StatefulWidget {
  const CaregiverOnboarding2Screen({super.key});

  @override
  State<CaregiverOnboarding2Screen> createState() =>
      _CaregiverOnboarding2ScreenState();
}

class _CaregiverOnboarding2ScreenState
    extends State<CaregiverOnboarding2Screen> {
  static const Color bg = Color(0xFFF1F8E1);
  static const Color titleDark = Color(0xFF112541);
  static const Color fieldLabel = Color(0xFF94A3B8);
  static const Color fieldBorder = Color(0xFF334155);
  static const Color progressActive = Color(0xFF345058);
  static const Color progressInactive = Color.fromRGBO(137, 171, 199, 0.37);
  static const Color chipSelectedBg = Color(0xFF323D48);
  static const Color chipSelectedText = Color(0xFFCBD5E1);
  static const Color chipUnselectedBg = Color(0xFFB4BDBB);
  static const Color chipUnselectedText = Color(0xFF334155);
  static const Color skillsTitle = Color(0xFF1E293B);
  static const Color continueBg = Color(0xFF223A5C);

  String _selectedQualification = 'Diploma';

  String? _formalTraining; // 'Yes' or 'No'
  List<String> _certificates = [];

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
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
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
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 2 of 6',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: fieldLabel,
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
                      const SizedBox(height: 18),

                      _buildLabel('Educational qualification'),
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

                      _buildLabel('Formal caregiving training'),
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
                            const Icon(Icons.check_circle_rounded, color: progressActive, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_certificates.length} certificate${_certificates.length > 1 ? 's' : ''} attached',
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: titleDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 26),

                      _buildLabel('Languages spoken'),
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
                          fontFamily: 'Open Sans',
                          color: skillsTitle,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),

                      _buildLabel('More skills = more requests'),
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
                    color: continueBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final draft = AppState.caregiverOnboardingDraft;
                        draft.educationalQualification = _selectedQualification;
                        draft.formalTraining = _formalTraining == 'Yes';
                        draft.languagesSpoken = _selectedLanguages;
                        draft.skills = _selectedSkills;
                        draft.certificateUrls = _certificates;
                        Navigator.pushNamed(context, '/caregiver-onboarding-3');
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
          color: isSelected ? chipSelectedBg : chipUnselectedBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: fieldBorder,
            width: isSelected ? 1 : 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: isSelected ? chipSelectedText : chipUnselectedText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
          color: isSelected ? chipSelectedBg : chipUnselectedBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: fieldBorder,
            width: isSelected ? 1 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: isSelected ? Colors.white : chipUnselectedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
