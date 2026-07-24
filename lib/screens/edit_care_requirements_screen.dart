import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../app_state.dart';
import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────
//  Edit Care Requirements Screen (Patient)
//  Figma node: 498-3870 · P-28 · Edit Care Requirements (Patient)
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
  static const Color _azure17 = AppTheme.cardColor;
  static const Color _azure27 = AppTheme.borderColor;
  static const Color _azure47 = Color(0xFF64748B);
  static const Color _azure65 = AppTheme.textSecondary;
  static const Color _grey98 = AppTheme.textPrimary;
  static const Color _green45 = AppTheme.primaryGreen;
  static const Color _green8 = AppTheme.bottleGreen;
  static const Color _geyser = Color(0xFFCBD5E1);

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
      backgroundColor: _azure17,
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
                          color: _azure27,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setSheetState(() => query = v),
                          style: const TextStyle(color: _grey98, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search city or area',
                            hintStyle: const TextStyle(color: _azure47, fontSize: 15),
                            prefixIcon: const Icon(Icons.search_rounded, color: _azure65),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _azure27),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _azure27),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _green45, width: 1.5),
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
                              leading: const Icon(Icons.location_on_outlined, color: _green45),
                              title: Text(label,
                                  style: const TextStyle(
                                      color: _grey98, fontSize: 14, fontWeight: FontWeight.w500)),
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
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Edit care requirements',
                    style: TextStyle(
                      color: _grey98,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Care type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _careTypes.map((type) {
                        final isSelected = _selectedCareType == type;
                        return _buildPillChip(
                          label: type,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedCareType = type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('Care schedule'),
                    const SizedBox(height: 8),
                    _buildSegmentedRow(
                      options: _careSchedules,
                      selected: _selectedSchedule,
                      onSelect: (v) => setState(() => _selectedSchedule = v),
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('Location'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showLocationPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: _azure17,
                          border: Border.all(color: _azure27),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: _green45, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _location,
                                style: const TextStyle(
                                  color: _grey98,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded, color: _azure47, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('Preferred gender'),
                    const SizedBox(height: 8),
                    _buildSegmentedRow(
                      options: _genderOptions,
                      selected: _selectedGender,
                      onSelect: (v) => setState(() => _selectedGender = v),
                    ),
                    const SizedBox(height: 18),

                    _buildLabel('Additional notes'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 56),
                      decoration: BoxDecoration(
                        color: _azure17,
                        border: Border.all(color: _azure27),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        minLines: 2,
                        style: const TextStyle(
                          color: _grey98,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(15),
                          hintText: 'Prefers a caregiver experienced with mobility '
                              'support and medication reminders.',
                          hintStyle: TextStyle(
                            color: _azure47,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: _green45,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _save,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Text(
                              'Save requirements',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _green8,
                                fontSize: 15,
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
          color: _azure65,
          fontSize: 13,
          fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _green45.withValues(alpha: 0.15) : _azure17,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _green45 : _azure27,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _green45 : _geyser,
            fontSize: 12,
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
          if (i.isOdd) return const SizedBox(width: 8);
          final option = options[i ~/ 2];
          final isSelected = option == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _green45.withValues(alpha: 0.15) : _azure17,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? _green45 : _azure27,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? _green45 : _geyser,
                    fontSize: 12,
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
