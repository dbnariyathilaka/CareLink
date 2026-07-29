import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Family member details
//  Figma node: 372-180 · "Who are you caring for?"
//
//  Shown when the person registering picked "I'm a family member" on the
//  "Who needs care?" sheet. Collects the REGISTRANT's own contact details
//  (not the patient's — those are collected later, during the normal
//  patient-onboarding flow, once the account exists). Continuing here
//  proceeds straight into account registration.
// ─────────────────────────────────────────────────────────────
class PatientFamilyDetailsScreen extends StatefulWidget {
  const PatientFamilyDetailsScreen({super.key});

  @override
  State<PatientFamilyDetailsScreen> createState() =>
      _PatientFamilyDetailsScreenState();
}

class _PatientFamilyDetailsScreenState
    extends State<PatientFamilyDetailsScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color titleBrown = Color(0xFF564732);
  static const Color subtitleBrown = Color(0xFF90867A);
  static const Color fieldBorder = Color(0xFF423423);
  static const Color fieldLabel = Color(0xFF564732);
  static const Color fieldValue = Color(0xFF76634B);
  static const Color bannerBg = Color.fromRGBO(171, 144, 137, 0.47);
  static const Color bannerBorder = Color(0xFF3B2E26);
  static const Color bannerIcon = Color(0xFF352D2A);
  static const Color bannerText = Color(0xFF47312B);
  static const Color continueBg = Color(0xFF746553);

  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

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
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showRelationshipPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgCream,
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
                  fontFamily: 'Open Sans',
                  color: selected ? continueBg : fieldLabel,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: continueBg)
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

  void _continue() {
    AppState.familyMemberName.value = _nameController.text.trim();
    AppState.familyMemberNic.value = _nicController.text.trim();
    AppState.relationToPatient.value = _relationship;
    AppState.familyMemberPhone.value = _phoneController.text.trim();
    AppState.familyMemberEmail.value = _emailController.text.trim();
    AppState.familyMemberAddress.value = _addressController.text.trim();
    Navigator.pushNamed(
      context,
      '/register',
      arguments: {'role': 'patient', 'careRecipient': 'family'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(23, 8, 27, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleBrown, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              const SizedBox(height: 18),
              const Text(
                'Who are you caring for?',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleBrown,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us a little about the patient',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: subtitleBrown,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Your full name'),
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
                                    _buildLabel('NIC Number'),
                                    const SizedBox(height: 7),
                                    _buildTextField(
                                      controller: _nicController,
                                      hintText: '972345678V',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Relationship to patient'),
                                    const SizedBox(height: 7),
                                    GestureDetector(
                                      onTap: _showRelationshipPicker,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: fieldBorder),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _relationship,
                                              style: const TextStyle(
                                                fontFamily: 'Open Sans',
                                                color: fieldValue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: fieldValue,
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

                        _buildLabel('Mobile number'),
                        const SizedBox(height: 7),
                        _buildTextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          hintText: '+94 71 234 5678',
                        ),
                        const SizedBox(height: 13),

                        _buildLabel('Email address'),
                        const SizedBox(height: 7),
                        _buildTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'mala.perera@email.com',
                        ),
                        const SizedBox(height: 13),

                        _buildLabel('Your address'),
                        const SizedBox(height: 7),
                        _buildTextField(
                          controller: _addressController,
                          hintText: '42 Temple Rd, Nugegoda',
                        ),
                        const SizedBox(height: 13),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 15.5, vertical: 13.5),
                          decoration: BoxDecoration(
                            color: bannerBg,
                            border: Border.all(color: bannerBorder, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.verified_user_rounded, color: bannerIcon, size: 19),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Next you'll add the patient details and we'll ask them to confirm your access",
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: bannerText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
                  color: continueBg,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _continue,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
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
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
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
        border: Border.all(color: fieldBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          color: fieldValue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Open Sans',
            color: fieldValue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
