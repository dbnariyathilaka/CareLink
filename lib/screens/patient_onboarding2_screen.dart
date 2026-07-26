import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../data/sri_lankan_cities.dart';

class PatientOnboarding2Screen extends StatefulWidget {
  const PatientOnboarding2Screen({super.key});

  @override
  State<PatientOnboarding2Screen> createState() =>
      _PatientOnboarding2ScreenState();
}

class _PatientOnboarding2ScreenState extends State<PatientOnboarding2Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Field Controllers
  final _nameController = TextEditingController(text: 'Nipuni Ariyathilaka');
  final _ageController = TextEditingController(text: '72');
  final _cityController = TextEditingController(text: 'Negombo, Gampaha District');
  final _medicalController = TextEditingController();

  // Focus Nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _medicalFocus = FocusNode();

  // Dropdown / Selection Values
  String _selectedGender = 'Female';
  final List<String> _genderOptions = ['Female', 'Male', 'Other'];

  List<Map<String, String>> _filteredCities = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    // Listeners for focus changes to trigger border highlights
    _nameFocus.addListener(() => setState(() {}));
    _ageFocus.addListener(() => setState(() {}));
    _cityFocus.addListener(() {
      setState(() {});
      if (!_cityFocus.hasFocus) {
        setState(() => _filteredCities = []);
      }
    });
    _medicalFocus.addListener(() => setState(() {}));

    _cityController.addListener(_onCityTextChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _medicalController.dispose();

    _nameFocus.dispose();
    _ageFocus.dispose();
    _cityFocus.dispose();
    _medicalFocus.dispose();

    super.dispose();
  }

  // ── Autocomplete City Search ──────────────────────────────
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

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _genderOptions.map((g) {
            final selected = g == _selectedGender;
            return ListTile(
              title: Text(
                g,
                style: TextStyle(
                  color: selected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryGreen)
                  : null,
              onTap: () {
                setState(() => _selectedGender = g);
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) => Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Top navigation row
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
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                    const Text(
                      'Step 1 of 2',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildProgressBar(currentStep: 1, totalSteps: 2),
                const SizedBox(height: 24),

                const Text(
                  'Patient details',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 18),

                // Scrollable fields
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full name
                          _buildLabel('Full name'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            hintText: 'Enter patient full name',
                          ),
                          const SizedBox(height: 18),

                          // Gender Selection Dropdown
                          _buildLabel('Gender'),
                          const SizedBox(height: 8),
                          _buildDropdownSelector(
                            value: _selectedGender,
                            onTap: _showGenderPicker,
                          ),
                          const SizedBox(height: 18),

                          // Age
                          _buildLabel('Age'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _ageController,
                            focusNode: _ageFocus,
                            hintText: 'Enter age',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 18),

                          // City / Area
                          _buildLabel('City / area'),
                          const SizedBox(height: 8),
                          _buildCityField(),
                          _buildSuggestionsList(),
                          const SizedBox(height: 18),

                          // Special medical conditions
                          _buildLabel('Special medical conditions'),
                          const SizedBox(height: 8),
                          _buildTextAreaField(
                            controller: _medicalController,
                            focusNode: _medicalFocus,
                            hintText:
                                'e.g. diabetes, high blood pressure, early-stage dementia...',
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // Button Continue
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            AppState.patientName.value =
                                _nameController.text.trim();
                            AppState.patientGenderSelf.value = _selectedGender;
                            AppState.patientAge.value =
                                _ageController.text.trim();
                            AppState.careLocation.value =
                                _cityController.text.trim();
                            AppState.additionalCareNotes.value =
                                _medicalController.text.trim();
                            Navigator.pushNamed(context, '/patient-onboarding-2');
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.bottleGreen,
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
      ),
    );
  }

  // ── Widgets Helpers ─────────────────────────────────────────

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _buildProgressBar({required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryGreen : AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final hasFocus = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasFocus ? AppTheme.primaryGreen : AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
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
            color: Color(0xFF64748B),
            fontSize: 15,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textPrimary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityField() {
    final focused = _cityFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: focused ? AppTheme.primaryGreen : AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 17),
          const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _cityController,
              focusNode: _cityFocus,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                hintText: 'Enter your city or area',
                hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
            ),
          ),
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
                    TextPosition(offset: displayText.length),
                  );
                  _filteredCities = [];
                });
                _cityFocus.unfocus();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                        ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildTextAreaField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
  }) {
    final hasFocus = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasFocus ? AppTheme.primaryGreen : AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
