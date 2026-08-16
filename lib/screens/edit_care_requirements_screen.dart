import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Edit Care Requirements Screen (Patient)
//  Figma node: 275-2005
//
//  Consolidates what used to be spread across the two-step
//  onboarding flow (care type, schedule, location, preferred
//  gender) into a single editable page.
// ─────────────────────────────────────────────────────────────
class EditCareRequirementsScreen extends StatefulWidget {
  const EditCareRequirementsScreen({super.key});

  @override
  State<EditCareRequirementsScreen> createState() =>
      _EditCareRequirementsScreenState();
}

class _EditCareRequirementsScreenState
    extends State<EditCareRequirementsScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color sectionLabel = Color.fromRGBO(0, 0, 0, 0.5);
  static const Color chipUnselectedText = Color(0xFF06402B);
  static const Color locationFieldBg = Color(0xFFEFE6D6);
  static const Color notesFieldBg = Color.fromRGBO(168, 156, 126, 0.3);
  static const Color notesPlaceholder = Color(0xFF6E6656);
  static const Color chevronMuted = Color(0xFF6B7A72);

  static const List<String> _careTypes = [
    'Elder care',
    'Post-surgery',
    'Dementia',
    'Child care',
  ];
  static const List<String> _careSchedules = ['Full-time', 'Part-time', 'Live-in'];
  static const List<String> _genderOptions = ['No preference', 'Female', 'Male'];

  late String _selectedCareType;
  late String _selectedSchedule;
  late String _selectedGender;
  late String _location;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _selectedCareType = AppState.careType.value;
    _selectedSchedule = AppState.careSchedule.value;
    _selectedGender = AppState.preferredGender.value;
    _location = AppState.careLocation.value;
    _notesController = TextEditingController(text: AppState.additionalCareNotes.value);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    AppState.careType.value = _selectedCareType;
    AppState.careSchedule.value = _selectedSchedule;
    AppState.preferredGender.value = _selectedGender;
    AppState.careLocation.value = _location;
    AppState.additionalCareNotes.value = _notesController.text.trim();

    final user = AuthService.currentUser;
    if (user != null) {
      PatientService.savePatientProfile(
        uid: user.uid,
        data: {
          'careType': _selectedCareType,
          'careLevel': _selectedSchedule,
          'preferredCaregiverGender': _selectedGender,
          'city': _location,
          'medicalConditions': _notesController.text.trim(),
        },
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Care requirements updated!')),
    );
  }

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
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final matches = query.isEmpty
                ? sriLankanCities
                : sriLankanCities
                    .where((c) => c['city']!.toLowerCase().contains(query.toLowerCase()))
                    .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
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
                          onChanged: (v) => setSheetState(() => query = v),
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: darkGreen,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search city or area',
                            hintStyle: TextStyle(
                              fontFamily: 'Open Sans',
                              color: darkGreen.withValues(alpha: 0.4),
                              fontSize: 15,
                            ),
                            prefixIcon: Icon(Icons.search_rounded, color: darkGreen.withValues(alpha: 0.6)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: darkGreen.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: darkGreen.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: darkGreen, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (_, i) {
                            final item = matches[i];
                            final label = '${item['city']}, ${item['district']}';
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined, color: darkGreen),
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
          },
        );
      },
    );
    if (selected != null) {
      setState(() => _location = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Edit care requirements',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: darkGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildLabel('Care type')),
                    const SizedBox(height: 10),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: _careTypes.map((type) {
                          final isSelected = _selectedCareType == type;
                          return _buildPillChip(
                            label: type,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedCareType = type),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildLabel('Care schedule'),
                    const SizedBox(height: 10),
                    _buildSegmentedRow(
                      options: _careSchedules,
                      selected: _selectedSchedule,
                      onSelect: (v) => setState(() => _selectedSchedule = v),
                    ),
                    const SizedBox(height: 22),

                    _buildLabel('Location'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: locationFieldBg,
                          border: Border.all(color: darkGreen, width: 1.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: darkGreen, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _location.isEmpty ? 'Select your city or area' : _location,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: darkGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded, color: chevronMuted, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    _buildLabel('Preferred gender'),
                    const SizedBox(height: 10),
                    _buildSegmentedRow(
                      options: _genderOptions,
                      selected: _selectedGender,
                      onSelect: (v) => setState(() => _selectedGender = v),
                    ),
                    const SizedBox(height: 22),

                    _buildLabel('Additional notes'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
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
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(15),
                          hintText: 'Prefers a caregiver experienced with mobility '
                              'support and medication reminders.',
                          hintStyle: TextStyle(
                            fontFamily: 'Open Sans',
                            color: notesPlaceholder,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: darkGreen,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _save,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Save requirements',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: sectionLabel,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _buildPillChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? darkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: darkGreen, width: 1.3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: isSelected ? Colors.white : chipUnselectedText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedRow({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(options.length * 2 - 1, (i) {
          if (i.isOdd) return const SizedBox(width: 10);
          final option = options[i ~/ 2];
          final isSelected = option == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isSelected ? darkGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: darkGreen, width: 1.3),
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: isSelected ? Colors.white : chipUnselectedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
