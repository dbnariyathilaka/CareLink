import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 1 of 6
//  Figma node: 423-148 · "What care do you offer?"
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding1Screen extends StatefulWidget {
  const CaregiverOnboarding1Screen({super.key});

  @override
  State<CaregiverOnboarding1Screen> createState() =>
      _CaregiverOnboarding1ScreenState();
}

class _CaregiverOnboarding1ScreenState
    extends State<CaregiverOnboarding1Screen> {
  static const Color bg = Color(0xFFF1F8E1);
  static const Color titleDark = Color(0xFF112541);
  static const Color fieldLabel = Color(0xFF94A3B8);
  static const Color fieldBorder = Color(0xFF334155);
  static const Color fieldHint = Color.fromRGBO(51, 76, 85, 0.42);
  static const Color progressActive = Color(0xFF345058);
  static const Color progressInactive = Color.fromRGBO(137, 171, 199, 0.37);
  static const Color stepperAdd = Color(0xFF293855);
  static const Color chipBg = Color(0xFFB4BDBB);
  static const Color chipBorder = Color(0xFF263C4A);
  static const Color chipText = Color(0xFF263C4A);
  static const Color chipSelectedBg = Color(0xFF323D48);
  static const Color chipSelectedText = Color(0xFFCBD5E1);
  static const Color continueBg = Color(0xFF223A5C);

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  String _selectedGender = 'Male';

  int _yearsExperience = 5;

  final Set<String> _selectedCareTypes = {'Part-time', 'Full-time'};

  final _nicController = TextEditingController();
  final _refPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  void dispose() {
    _nicController.dispose();
    _refPhoneController.dispose();
    super.dispose();
  }

  void _showGenderPicker() {
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
          children: _genderOptions.map((gender) {
            final selected = gender == _selectedGender;
            return ListTile(
              title: Text(
                gender,
                style: TextStyle(
                  color: selected ? continueBg : titleDark,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: continueBg)
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

  void _toggleCareType(String type) {
    setState(() {
      if (_selectedCareTypes.contains(type)) {
        _selectedCareTypes.remove(type);
      } else {
        _selectedCareTypes.add(type);
      }
    });
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
                    'Step 1 of 6',
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
                          fontFamily: 'Open Sans',
                          color: titleDark,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Gender'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showGenderPicker,
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
                                _selectedGender,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: titleDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: fieldBorder, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildLabel('Years of experience'),
                      const SizedBox(height: 12),
                      Container(
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
                              '$_yearsExperience ${_yearsExperience == 1 ? 'year' : 'years'}',
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: titleDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                                  child: const Icon(Icons.remove_rounded, color: fieldLabel, size: 22),
                                ),
                                const SizedBox(width: 14),
                                GestureDetector(
                                  onTap: () => setState(() => _yearsExperience++),
                                  child: const Icon(Icons.add_rounded, color: stepperAdd, size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _buildLabel('Care type'),
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
                      _buildLabel('NIC number'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _nicController,
                        hintText: 'e.g. 200012345678',
                      ),
                      const SizedBox(height: 26),
                      _buildLabel('Reference phone number'),
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
                    color: continueBg,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final draft = AppState.caregiverOnboardingDraft;
                        draft.gender = _selectedGender;
                        draft.yearsExperience = _yearsExperience;
                        draft.careTypes = _selectedCareTypes;
                        draft.nic = _nicController.text.trim();
                        draft.referencePhone = _refPhoneController.text.trim();
                        Navigator.pushNamed(context, '/caregiver-onboarding-2');
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
          color: isSelected ? chipSelectedBg : chipBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? fieldBorder : chipBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: isSelected ? chipSelectedText : chipText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
        border: Border.all(color: fieldBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: titleDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 17.5, vertical: 15.5),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Open Sans',
            color: fieldHint,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
