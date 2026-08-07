import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Patient details (self) — "Step 1 of 2" of the patient
//  onboarding flow. Mounted at route '/patient-onboarding-1'.
//  Figma node: 123-418
// ─────────────────────────────────────────────────────────────
class PatientOnboarding2Screen extends StatefulWidget {
  const PatientOnboarding2Screen({super.key});

  @override
  State<PatientOnboarding2Screen> createState() =>
      _PatientOnboarding2ScreenState();
}

class _PatientOnboarding2ScreenState extends State<PatientOnboarding2Screen>
    with SingleTickerProviderStateMixin {
  static const Color bgCream = Color(0xFFF5E8DE);
  static const Color titleGreen = Color(0xFF033724);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color progressActive = Color(0xFF1E8370);
  static const Color progressInactive = Color(0xFFD9D9D9);
  static const Color cardBg = Color.fromRGBO(166, 159, 128, 0.1);
  static const Color fieldBorder = Color.fromRGBO(0, 0, 0, 0.3);
  static const Color fieldLabel = Color.fromRGBO(0, 0, 0, 0.8);
  static const Color fieldValue = Color.fromRGBO(0, 0, 0, 0.85);
  static const Color creamButtonText = Color(0xFFF6F0E2);

  final _formKey = GlobalKey<FormState>();

  // Only show "required" error styling after the user has tried to
  // continue at least once, so the form doesn't look broken on first view.
  bool _submitted = false;

  // Field Controllers
  final _nameController = NoUnderlineTextEditingController();
  final _cityController = NoUnderlineTextEditingController();
  final _notesController = NoUnderlineTextEditingController();

  // Focus Nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  // Lets the special-notes field scroll itself clear of the keyboard when
  // focused, since it sits at the bottom of the form.
  final GlobalKey _notesFieldKey = GlobalKey();

  // Dropdown / Selection Values — start unselected so the user must
  // actively choose; a silent default would let them skip past unnoticed.
  String? _selectedGender;
  final List<String> _genderOptions = ['Female', 'Male', 'Other'];

  String? _preferredCaregiverGender;
  final List<String> _preferredGenderOptions = ['No preference', 'Female', 'Male'];

  List<Map<String, String>> _filteredCities = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);

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

    _nameFocus.addListener(() => setState(() {}));
    _cityFocus.addListener(() {
      setState(() {});
      if (!_cityFocus.hasFocus) {
        setState(() => _filteredCities = []);
      }
    });
    _notesFocus.addListener(() {
      setState(() {});
      if (_notesFocus.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final notesContext = _notesFieldKey.currentContext;
          if (notesContext != null) {
            Scrollable.ensureVisible(
              notesContext,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: 0.2,
            );
          }
        });
      }
    });

    _cityController.addListener(_onCityTextChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _notesController.dispose();

    _nameFocus.dispose();
    _cityFocus.dispose();
    _notesFocus.dispose();

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

  // Full scrollable list of every saved city, opened by tapping the
  // chevron — an alternative to typing to narrow the field's own list.
  void _showCityPicker() {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.isEmpty
                ? sriLankanCities
                : sriLankanCities
                    .where((c) =>
                        c['city']!.toLowerCase().contains(query.toLowerCase()) ||
                        c['district']!.toLowerCase().contains(query.toLowerCase()))
                    .toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select city / area',
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: darkGreen,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close_rounded, color: darkGreen, size: 22),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: fieldBorder),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          onChanged: (v) => setSheetState(() => query = v),
                          style: const TextStyle(color: fieldValue, fontSize: 15),
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                            prefixIcon: Icon(Icons.search_rounded, color: darkGreen, size: 20),
                            hintText: 'Search city or district…',
                            hintStyle: TextStyle(color: fieldLabel, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching cities found',
                                style: TextStyle(color: fieldLabel, fontSize: 14),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: fieldBorder.withValues(alpha: 0.4),
                              ),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final displayText = '${item['city']}, ${item['district']}';
                                return ListTile(
                                  leading: const Icon(Icons.location_on_outlined,
                                      color: darkGreen, size: 20),
                                  title: Text(
                                    displayText,
                                    style: const TextStyle(
                                      fontFamily: 'Open Sans',
                                      color: fieldValue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _cityController.text = displayText;
                                      _cityController.selection = TextSelection.fromPosition(
                                        TextPosition(offset: displayText.length),
                                      );
                                      _filteredCities = [];
                                    });
                                    Navigator.pop(context);
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

  void _showPicker({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isSelected = option == selected;
            return ListTile(
              title: Text(
                option,
                style: TextStyle(
                  color: isSelected ? darkGreen : Colors.black,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded, color: darkGreen)
                  : null,
              onTap: () {
                onSelect(option);
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
      backgroundColor: bgCream,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Patient details',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: titleGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Progress bar — 2 segments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _buildProgressBar(currentStep: 1, totalSteps: 2),
              ),
              const SizedBox(height: 20),

              // Scrollable card with all fields
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: fieldBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(4, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(-4, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Full Name'),
                          const SizedBox(height: 7),
                          _buildTextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            hintText: 'Nipuni Ariyathilaka',
                          ),
                          const SizedBox(height: 18),

                          _buildLabel('Gender'),
                          const SizedBox(height: 7),
                          _buildDropdownField(
                            value: _selectedGender,
                            hintText: 'Select gender',
                            hasError: _submitted && _selectedGender == null,
                            onTap: () => _showPicker(
                              title: 'Gender',
                              options: _genderOptions,
                              selected: _selectedGender,
                              onSelect: (v) => setState(() => _selectedGender = v),
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildLabel('City / area'),
                          const SizedBox(height: 7),
                          _buildCityField(),
                          _buildSuggestionsList(),
                          const SizedBox(height: 18),

                          _buildLabel('Preferred caregiver gender'),
                          const SizedBox(height: 7),
                          _buildDropdownField(
                            value: _preferredCaregiverGender,
                            hintText: 'Select preferred caregiver gender',
                            hasError: _submitted && _preferredCaregiverGender == null,
                            onTap: () => _showPicker(
                              title: 'Preferred caregiver gender',
                              options: _preferredGenderOptions,
                              selected: _preferredCaregiverGender,
                              onSelect: (v) => setState(() => _preferredCaregiverGender = v),
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildLabel('Special notes', required: false),
                          const SizedBox(height: 7),
                          _buildTextAreaField(
                            controller: _notesController,
                            focusNode: _notesFocus,
                            hintText: 'e.g. diabetes, high blood pressure, early-stage dementia…',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.fromLTRB(23, 0, 23, 24),
                child: Container(
                  width: double.infinity,
                  height: 59,
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withValues(alpha: 0.5),
                        blurRadius: 2,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        setState(() => _submitted = true);
                        final formValid = _formKey.currentState!.validate();
                        final missingCity = _cityController.text.trim().isEmpty;
                        final missingGender = _selectedGender == null;
                        final missingPreferredGender = _preferredCaregiverGender == null;
                        if (!formValid || missingCity || missingGender || missingPreferredGender) {
                          final message = !formValid
                              ? 'Please enter your full name.'
                              : missingCity
                                  ? 'Please enter your city / area.'
                                  : missingGender
                                      ? 'Please select a gender.'
                                      : 'Please select a preferred caregiver gender.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                          return;
                        }
                        AppState.patientName.value = _nameController.text.trim();
                        AppState.patientGenderSelf.value = _selectedGender!;
                        AppState.careLocation.value = _cityController.text.trim();
                        AppState.preferredGender.value = _preferredCaregiverGender!;
                        AppState.additionalCareNotes.value = _notesController.text.trim();
                        Navigator.pushNamed(context, '/patient-onboarding-2');
                      },
                      child: const Center(
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: creamButtonText,
                            fontSize: 17,
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

  // ── Widgets Helpers ─────────────────────────────────────────

  Widget _buildLabel(String text, {bool required = true}) => RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: fieldLabel,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          children: [
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red))
            else
              const TextSpan(text: '  (optional)', style: TextStyle(fontWeight: FontWeight.w400, fontStyle: FontStyle.italic)),
          ],
        ),
      );

  Widget _buildProgressBar({required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: isActive ? progressActive : progressInactive,
              borderRadius: BorderRadius.circular(5),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasFocus ? darkGreen : fieldBorder,
          width: hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: fieldValue,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: fieldLabel,
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

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required bool hasError,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError ? Colors.red : fieldBorder,
            width: hasError ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? hintText,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: value == null ? fieldLabel : fieldValue,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCityField() {
    final focused = _cityFocus.hasFocus;
    final hasError = _submitted && _cityController.text.trim().isEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasError ? Colors.red : (focused ? darkGreen : fieldBorder),
          width: (focused || hasError) ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 17),
          const Icon(Icons.location_on_outlined, color: darkGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _cityController,
              focusNode: _cityFocus,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: fieldValue,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 17),
                hintText: 'Negombo, Gampaha District',
                hintStyle: TextStyle(color: fieldLabel, fontSize: 15),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _cityFocus.unfocus();
              _showCityPicker();
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(width: 8),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
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
                      : const Border(bottom: BorderSide(color: fieldBorder, width: 1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: darkGreen, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: fieldValue,
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
    return Container(
      key: _notesFieldKey,
      height: 97,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: fieldBorder),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: fieldValue,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: fieldLabel,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
