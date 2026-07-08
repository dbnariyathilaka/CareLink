import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  final List<String> _skills = [
    'Mobility assistance',
    'Medication management',
    'Dementia care',
    'Wound care',
    'Post-Surgery care',
    'Physiotherapy',
    'Mental health support',
    'Pediatric care',
    'Personal hygiene',
    'Elderly Care',
    'Prenatal care',
    'chronic illnes care',
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
                    'Step 2 of 5',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 2, totalSteps: 5),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your caregiving service types',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'More service types = more requests',
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
                          return _buildSkillChip(
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

  /// Skill chip (wrap layout) with checkmark when selected
  Widget _buildSkillChip({
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
