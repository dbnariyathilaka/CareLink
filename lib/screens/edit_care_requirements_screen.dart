import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Edit Care Requirements Screen (Patient)
//  Route: /edit-care-requirements
//
//  Covers all editable patient parameters:
//    • Personal: name, email, age, gender
//    • Care: care type (all 11 options), schedule (all 4 options),
//            location, preferred caregiver gender, additional notes
//
//  On save: writes to Firestore patientProfiles/{uid} and users/{uid},
//  and updates AppState so that all screens (dashboard, profile, etc.)
//  update dynamically across the entire app.
// ─────────────────────────────────────────────────────────────

class EditCareRequirementsScreen extends StatefulWidget {
  const EditCareRequirementsScreen({super.key});

  @override
  State<EditCareRequirementsScreen> createState() =>
      _EditCareRequirementsScreenState();
}

class _EditCareRequirementsScreenState
    extends State<EditCareRequirementsScreen> {
  // ── Design tokens ────────────────────────────────────────────
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color sectionLabel = Color(0xFF06402B);
  static const Color fieldBg = Color(0xFFEFE6D6);
  static const Color chipUnselected = Color(0xFF06402B);
  static const Color notesFieldBg = Color.fromRGBO(168, 156, 126, 0.3);

  // ── All 11 Care Types from Onboarding ─────────────────────────
  static const List<String> _careTypes = [
    'Elder care',
    'Pediatric',
    'Post-surgery',
    'Physical disability',
    'Mental health',
    'Dementia',
    'Mobility assistance',
    'Medication management',
    'Wound care',
    'Rehabilitation',
    'Physiotherapy',
  ];

  // ── All 4 Care Schedules from Onboarding ──────────────────────
  static const List<String> _careSchedules = [
    'Full-time',
    'Part-time',
    'Live-in',
    'Flexible',
  ];

  static const List<String> _genderOptions = ['Female', 'Male', 'Other'];
  static const List<String> _preferredGenderOptions = [
    'No preference',
    'Female',
    'Male',
  ];

  // ── Controllers / state ──────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Female';
  String _selectedCareType = 'Elder care';
  String _selectedSchedule = 'Full-time';
  String _selectedPreferredGender = 'No preference';
  String _location = '';

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Load from Firestore ──────────────────────────────────────
  Future<void> _loadProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final emailFallback = user.email ?? '';

    // Load from Firestore (patientProfiles)
    final profile = await PatientService.getPatientProfile(user.uid);

    // Also check users collection for name/email
    final userProfile = await AuthService.getUserProfile(user.uid);

    if (!mounted) return;
    setState(() {
      _nameController.text =
          (profile?['name'] as String?) ??
          (profile?['patientName'] as String?) ??
          (userProfile?['name'] as String?) ??
          AppState.patientName.value;

      _emailController.text =
          (profile?['email'] as String?) ??
          (userProfile?['email'] as String?) ??
          emailFallback;

      final rawAge = profile?['patientAge'] ?? profile?['age'];
      _ageController.text = rawAge != null && rawAge != 0
          ? rawAge.toString().replaceAll('.0', '')
          : AppState.patientAge.value;

      _selectedGender =
          (profile?['patientGender'] as String?) ??
          (profile?['gender'] as String?) ??
          AppState.patientGenderSelf.value;

      _selectedCareType =
          (profile?['careType'] as String?) ??
          AppState.careType.value;

      _selectedSchedule =
          (profile?['careLevel'] as String?) ??
          AppState.careSchedule.value;

      _selectedPreferredGender =
          (profile?['preferredCaregiverGender'] as String?) ??
          AppState.preferredGender.value;

      _location =
          (profile?['city'] as String?) ??
          AppState.careLocation.value;

      _notesController.text =
          (profile?['medicalConditions'] as String?) ??
          AppState.additionalCareNotes.value;

      _loading = false;
    });
  }

  // ── Save to Firestore + AppState ─────────────────────────────
  Future<void> _save() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final age = _ageController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter your full name.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final parsedAge = int.tryParse(age);

      // 1. Write to Firestore patientProfiles collection
      await PatientService.savePatientProfile(
        uid: user.uid,
        data: {
          'name': name,
          'patientName': name,
          if (email.isNotEmpty) 'email': email,
          'age': parsedAge ?? (age.isNotEmpty ? age : null),
          'patientAge': parsedAge ?? 0,
          'gender': _selectedGender,
          'patientGender': _selectedGender,
          'careType': _selectedCareType,
          'careLevel': _selectedSchedule,
          'preferredCaregiverGender': _selectedPreferredGender,
          'city': _location,
          'medicalConditions': notes,
        },
      );

      // 2. Also update users/{uid} document so dashboard, auth & message queries pick up the name
      await AuthService.updateUserProfile(
        uid: user.uid,
        name: name,
        email: email.isNotEmpty ? email : (user.email ?? ''),
      );

      // 3. Attempt to update Firebase Auth user email if changed and valid
      if (email.isNotEmpty && email != user.email) {
        try {
          await user.verifyBeforeUpdateEmail(email);
        } on FirebaseAuthException catch (_) {
          // Ignore if recent-login is required or unsupported
        } catch (_) {}
      }

      // 4. Update in-memory AppState so all listening UI elements immediately re-render
      AppState.patientName.value = name;
      AppState.patientAge.value = age;
      AppState.patientGenderSelf.value = _selectedGender;
      AppState.careType.value = _selectedCareType;
      AppState.careSchedule.value = _selectedSchedule;
      AppState.preferredGender.value = _selectedPreferredGender;
      AppState.careLocation.value = _location;
      AppState.additionalCareNotes.value = notes;

      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, true);
      _showSnack('Profile updated successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Failed to update profile: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Open Sans')),
        backgroundColor: isError ? const Color(0xFF9E0606) : darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Location picker bottom-sheet ─────────────────────────────
  Future<void> _showLocationPicker() async {
    String query = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          final matches = query.isEmpty
              ? sriLankanCities
              : sriLankanCities
                  .where((c) => c['city']!
                      .toLowerCase()
                      .contains(query.toLowerCase()))
                  .toList();
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) => setS(() => query = v),
                        style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: darkGreen,
                            fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search city or area',
                          hintStyle: TextStyle(
                              fontFamily: 'Open Sans',
                              color: darkGreen.withValues(alpha: 0.4),
                              fontSize: 15),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: darkGreen.withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: darkGreen.withValues(alpha: 0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: darkGreen.withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: darkGreen, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (_, i) {
                          final item = matches[i];
                          final label =
                              '${item['city']}, ${item['district']}';
                          return ListTile(
                            leading: const Icon(
                                Icons.location_on_outlined,
                                color: darkGreen),
                            title: Text(label,
                                style: const TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: darkGreen,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            onTap: () => Navigator.pop(ctx, label),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    if (selected != null) setState(() => _location = selected);
  }

  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          _buildHeader(topInset),
          if (_loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: darkGreen),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Personal information ─────────────────
                    _sectionTitle('Personal information'),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Full name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Your full name',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Email address',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      hint: 'your.email@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: 'Age',
                      controller: _ageController,
                      icon: Icons.cake_outlined,
                      hint: 'e.g. 72',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Gender'),
                    const SizedBox(height: 10),
                    _buildChipRow(
                      options: _genderOptions,
                      selected: _selectedGender,
                      onSelect: (v) =>
                          setState(() => _selectedGender = v),
                    ),

                    const SizedBox(height: 28),
                    const Divider(color: Color(0xFFD5C9B5)),
                    const SizedBox(height: 20),

                    // ── Care requirements ────────────────────
                    _sectionTitle('Care requirements'),
                    const SizedBox(height: 16),

                    _buildLabel('Type of care needed (All 11 Types)'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _careTypes.map((type) {
                        final isSelected = _selectedCareType == type;
                        return _buildPillChip(
                          label: type,
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedCareType = type),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 22),
                    _buildLabel('Care schedule (All 4 Options)'),
                    const SizedBox(height: 10),
                    // 2×2 grid for all 4 schedule options including Flexible
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _careSchedules.length,
                      itemBuilder: (_, i) {
                        final s = _careSchedules[i];
                        final isSelected = _selectedSchedule == s;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSchedule = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? darkGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: darkGreen, width: 1.3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: isSelected
                                    ? Colors.white
                                    : chipUnselected,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),
                    _buildLabel('Location'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: fieldBg,
                          border: Border.all(
                              color: darkGreen, width: 1.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: darkGreen, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _location.isEmpty
                                    ? 'Select your city or area'
                                    : _location,
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: _location.isEmpty
                                      ? darkGreen.withValues(alpha: 0.45)
                                      : darkGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded,
                                color: Color(0xFF6B7A72), size: 22),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
                    _buildLabel('Preferred caregiver gender'),
                    const SizedBox(height: 10),
                    _buildChipRow(
                      options: _preferredGenderOptions,
                      selected: _selectedPreferredGender,
                      onSelect: (v) =>
                          setState(() => _selectedPreferredGender = v),
                    ),

                    const SizedBox(height: 22),
                    _buildLabel('Additional notes'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: notesFieldBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        minLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: darkGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(15),
                          hintText:
                              'Any special medical conditions, mobility needs, or preferences…',
                          hintStyle: TextStyle(
                            fontFamily: 'Open Sans',
                            color: darkGreen.withValues(alpha: 0.4),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Save button ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _saving ? null : _save,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 17),
                          decoration: BoxDecoration(
                            color: _saving
                                ? darkGreen.withValues(alpha: 0.6)
                                : darkGreen,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _saving
                                ? []
                                : [
                                    BoxShadow(
                                      color: darkGreen.withValues(
                                          alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              if (_saving) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('Saving…',
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ] else ...[
                                const Icon(Icons.save_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Text('Save profile & requirements',
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(double topInset) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding:
          EdgeInsets.fromLTRB(20, topInset + 14, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit requirements & profile',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Update your care details and personal info',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFFB2DFCC),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────
  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: darkGreen,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      );

  // ── Field label ───────────────────────────────────────────────
  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: sectionLabel,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  // ── Editable text field ───────────────────────────────────────
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: darkGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Open Sans',
              color: darkGreen.withValues(alpha: 0.35),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: darkGreen, size: 20),
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: darkGreen.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: darkGreen.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: darkGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pill chip (wrap layout) ───────────────────────────────────
  Widget _buildPillChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? darkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: darkGreen, width: 1.3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: isSelected ? Colors.white : chipUnselected,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Segmented row (gender / preferred gender) ─────────────────
  Widget _buildChipRow({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? darkGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: darkGreen, width: 1.3),
            ),
            child: Text(
              o,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color:
                    isSelected ? Colors.white : chipUnselected,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
