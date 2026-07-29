import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Patient details (family member)
//  Figma node: 498-5517 · P-03c · "Who are you caring for?"
//
//  Shown when the person registering picked "I'm a family member"
//  on the "Who needs care?" sheet. Collects the patient's basic
//  details, then continues into the normal onboarding flow.
// ─────────────────────────────────────────────────────────────
class PatientFamilyDetailsScreen extends StatefulWidget {
  const PatientFamilyDetailsScreen({super.key});

  @override
  State<PatientFamilyDetailsScreen> createState() =>
      _PatientFamilyDetailsScreenState();
}

class _PatientFamilyDetailsScreenState
    extends State<PatientFamilyDetailsScreen> {
  static const Color _teal = Color(0xFF01D3A8);

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _relationships = [
    'Mother',
    'Father',
    'Spouse',
    'Child',
    'Sibling',
    'Other',
  ];
  String _relationship = 'Mother';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showRelationshipPicker() {
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
          children: _relationships.map((r) {
            final selected = r == _relationship;
            return ListTile(
              title: Text(
                r,
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
                setState(() => _relationship = r);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              const SizedBox(height: 18),
              const Text(
                'Who are you caring for?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us a little about the patient',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Patient's full name"),
                        const SizedBox(height: 7),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'Mala Perera',
                        ),
                        const SizedBox(height: 13),

                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Age'),
                                    const SizedBox(height: 7),
                                    _buildTextField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      hintText: '78',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Relationship'),
                                    const SizedBox(height: 7),
                                    GestureDetector(
                                      onTap: _showRelationshipPicker,
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
                                              _relationship,
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Color(0xFF64748B),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),

                        _buildLabel('Care address'),
                        const SizedBox(height: 7),
                        _buildTextField(
                          controller: _addressController,
                          hintText: '42 Temple Rd, Nugegoda',
                        ),
                        const SizedBox(height: 13),

                        Row(
                          children: [
                            const Text(
                              'Conditions / notes ',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              '(optional)',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.inputBackground,
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 2,
                            minLines: 2,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                              hintText: 'e.g. diabetic, limited mobility…',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                          decoration: BoxDecoration(
                            color: _teal.withValues(alpha: 0.08),
                            border: Border.all(color: _teal.withValues(alpha: 0.25)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.verified_user_rounded, color: _teal, size: 19),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "We'll ask the patient to confirm access once their profile is set up.",
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      AppState.patientName.value = _nameController.text.trim();
                      AppState.relationToPatient.value = _relationship;
                      AppState.patientAge.value = _ageController.text.trim();
                      AppState.patientAddress.value =
                          _addressController.text.trim();
                      AppState.additionalCareNotes.value =
                          _notesController.text.trim();
                      Navigator.pushNamed(context, '/patient-onboarding-1');
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
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
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
