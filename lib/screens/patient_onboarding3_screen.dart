import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PatientOnboarding3Screen extends StatefulWidget {
  const PatientOnboarding3Screen({super.key});

  @override
  State<PatientOnboarding3Screen> createState() =>
      _PatientOnboarding3ScreenState();
}

class _PatientOnboarding3ScreenState extends State<PatientOnboarding3Screen>
    with SingleTickerProviderStateMixin {
  // Field controllers
  final TextEditingController _cityController =
      TextEditingController(text: 'Negombo, Western Province');
  final TextEditingController _notesController = TextEditingController();

  // Gender dropdown
  String _selectedGender = 'No preference';
  final List<String> _genderOptions = [
    'No preference',
    'Male',
    'Female',
  ];

  // Focus nodes
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  // Entrance animation
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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    // Rebuild on focus change so border highlights correctly
    _cityFocus.addListener(() => setState(() {}));
    _notesFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _cityFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      // Keeps layout stable when keyboard appears
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

                // ── Top row: back arrow + step label ──
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
                      'Step 3 of 4',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Progress bar: 3 of 4 filled ──
                _buildProgressBar(currentStep: 3, totalSteps: 4),

                const SizedBox(height: 24),

                // ── Title ──
                const Text(
                  'Location & notes',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 22),

                // ── Scrollable form fields ──
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── City / area ──
                        _buildFieldLabel('City / area'),
                        const SizedBox(height: 8),
                        _buildCityField(),

                        const SizedBox(height: 18),

                        // ── Preferred caregiver gender ──
                        _buildFieldLabel('Preferred caregiver gender'),
                        const SizedBox(height: 8),
                        _buildGenderDropdown(),

                        const SizedBox(height: 18),

                        // ── Special notes ──
                        _buildFieldLabel('Special notes'),
                        const SizedBox(height: 8),
                        _buildNotesField(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // ── Continue button ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/patient-onboarding-4');
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

  // ── Helpers ──────────────────────────────────────────────

  /// Segmented progress bar
  Widget _buildProgressBar(
      {required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryGreen : AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  /// Small muted label above each field
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary, // #94A3B8
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// City / area text field with a location-pin icon on the left
  Widget _buildCityField() {
    final focused = _cityFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground, // #1E293B
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: focused ? AppTheme.primaryGreen : const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 17),
          Icon(
            Icons.location_on_outlined,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
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
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                hintText: 'Enter your city or area',
                hintStyle: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 17),
        ],
      ),
    );
  }

  /// Preferred caregiver gender dropdown
  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textPrimary,
            size: 22,
          ),
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
          ),
          items: _genderOptions.map((g) {
            return DropdownMenuItem<String>(
              value: g,
              child: Text(g),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedGender = val);
          },
        ),
      ),
    );
  }

  /// Special notes multiline textarea
  Widget _buildNotesField() {
    final focused = _notesFocus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 110,
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: focused ? AppTheme.primaryGreen : const Color(0xFF334155),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: TextField(
        controller: _notesController,
        focusNode: _notesFocus,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText:
              'e.g. patient uses a wheelchair, needs help\nwith morning medication and meals…',
          hintStyle: TextStyle(
            color: Color(0xFF64748B), // Slate Gray
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          hintMaxLines: 3,
        ),
      ),
    );
  }
}
