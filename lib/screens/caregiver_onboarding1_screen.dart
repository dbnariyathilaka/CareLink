import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 1 of 6
//  Figma node: 498-6360 · "What care do you offer?"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding1Screen extends StatefulWidget {
  const CaregiverOnboarding1Screen({super.key});

  @override
  State<CaregiverOnboarding1Screen> createState() =>
      _CaregiverOnboarding1ScreenState();
}

class _CaregiverOnboarding1ScreenState
    extends State<CaregiverOnboarding1Screen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  String _selectedGender = 'Male';

  int _yearsExperience = 5;

  final Set<String> _selectedCareTypes = {'Part-time', 'Full-time'};

  final _nicController = TextEditingController();
  final _refPhoneController = TextEditingController();

  @override
  void dispose() {
    _nicController.dispose();
    _refPhoneController.dispose();
    super.dispose();
  }

  void _showGenderPicker() {
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
          children: _genderOptions.map((gender) {
            final selected = gender == _selectedGender;
            return ListTile(
              title: Text(
                gender,
                style: TextStyle(
                  color: selected ? _indigo : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: _indigo)
                  : null,
              onTap: () {
                setState(() => _selectedGender = gender);
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
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 1 of 6',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildProgressBar(currentStep: 1, totalSteps: 6),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What care do you offer?',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Gender',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: _showGenderPicker,
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
                                _selectedGender,
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

                      const SizedBox(height: 26),

                      const Text(
                        'Years of experience',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
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
                              '$_yearsExperience ${_yearsExperience == 1 ? 'year' : 'years'}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_yearsExperience > 0) {
                                      setState(() => _yearsExperience--);
                                    }
                                  },
                                  child: const Icon(Icons.remove_rounded, color: AppTheme.textSecondary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                GestureDetector(
                                  onTap: () => setState(() => _yearsExperience++),
                                  child: const Icon(Icons.add_rounded, color: _indigo, size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'Care type',
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
                            child: _buildCareTypeChip(
                              label: 'Part-time',
                              isSelected: _selectedCareTypes.contains('Part-time'),
                              onTap: () => _toggleCareType('Part-time'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCareTypeChip(
                              label: 'Full-time',
                              isSelected: _selectedCareTypes.contains('Full-time'),
                              onTap: () => _toggleCareType('Full-time'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCareTypeChip(
                              label: 'Live-in',
                              isSelected: _selectedCareTypes.contains('Live-in'),
                              onTap: () => _toggleCareType('Live-in'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCareTypeChip(
                              label: 'Flexible',
                              isSelected: _selectedCareTypes.contains('Flexible'),
                              onTap: () => _toggleCareType('Flexible'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'NIC number',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _nicController,
                        hintText: 'e.g. 200012345678',
                      ),

                      const SizedBox(height: 26),

                      const Text(
                        'Reference phone number',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _refPhoneController,
                        hintText: 'e.g. 077 123 4567',
                        keyboardType: TextInputType.phone,
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
                        Navigator.pushNamed(context, '/caregiver-onboarding-2');
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

  void _toggleCareType(String type) {
    setState(() {
      if (_selectedCareTypes.contains(type)) {
        _selectedCareTypes.remove(type);
      } else {
        _selectedCareTypes.add(type);
      }
    });
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

  /// Equal-width pill for care type selection (multi-select)
  Widget _buildCareTypeChip({
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
