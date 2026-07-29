import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  "Who needs care?" bottom sheet
//  Figma node: 296-5888 · shown when "Patient or Family" is
//  tapped on the role selection screen.
//
//  - "I'm the patient"      → straight into account registration.
//  - "I'm a family member"  → family-details screen first (the
//                             registrant's own contact info), then
//                             account registration.
// ─────────────────────────────────────────────────────────────
enum _CareRecipient { patient, familyMember }

Future<void> showWhoNeedsCareSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WhoNeedsCareSheet(),
  );
}

class _WhoNeedsCareSheet extends StatefulWidget {
  const _WhoNeedsCareSheet();

  @override
  State<_WhoNeedsCareSheet> createState() => _WhoNeedsCareSheetState();
}

class _WhoNeedsCareSheetState extends State<_WhoNeedsCareSheet> {
  static const Color bgCream = Color(0xFFF5EEE8);
  static const Color dragHandle = Color(0xFF334155);
  static const Color titleBrown = Color(0xFF564732);
  static const Color subtitleBrown = Color.fromRGBO(85, 73, 57, 0.63);
  static const Color continueBg = Color(0xFF746553);

  // "I'm the patient" — selected style
  static const Color patientCardBg = Color(0xFFAB9089);
  static const Color patientCardBorder = Color(0xFF5A413A);
  static const Color patientIconBg = Color(0xFFD9BDB5);
  static const Color patientIconColor = Color(0xFF41302B);
  static const Color patientTitleColor = Color(0xFF352D2A);
  static const Color patientSubtitleColor = Color.fromRGBO(57, 42, 27, 0.43);

  // "I'm a family member" — unselected style
  static const Color familyCardBg = Color(0xFFB1A28F);
  static const Color familyCardBorder = Color(0xFF44392B);
  static const Color familyIconBg = Color.fromRGBO(133, 107, 74, 0.54);
  static const Color familyIconColor = Color(0xFF4B381F);
  static const Color familyTitleColor = Color(0xFF4B381F);
  static const Color familySubtitleColor = Color.fromRGBO(58, 39, 14, 0.52);

  _CareRecipient _selected = _CareRecipient.patient;

  void _continue() {
    Navigator.pop(context);
    if (_selected == _CareRecipient.familyMember) {
      Navigator.pushNamed(context, '/patient-family-details');
    } else {
      Navigator.pushNamed(
        context,
        '/register',
        arguments: {'role': 'patient', 'careRecipient': 'self'},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: bgCream,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: dragHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Image.asset(
              'assets/images/who_needs_care_avatar.png',
              width: 68,
              height: 68,
            ),
            const SizedBox(height: 15),
            const Text(
              'Who needs care?',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: titleBrown,
                fontSize: 21,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This helps us set up the right profile and permissions.',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: subtitleBrown,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            _buildOption(
              recipient: _CareRecipient.patient,
              icon: Icons.self_improvement_rounded,
              title: "I'm the patient",
              subtitle: 'Care is for me',
              cardBg: patientCardBg,
              cardBorder: patientCardBorder,
              iconBg: patientIconBg,
              iconColor: patientIconColor,
              titleColor: patientTitleColor,
              subtitleColor: patientSubtitleColor,
            ),
            const SizedBox(height: 12),
            _buildOption(
              recipient: _CareRecipient.familyMember,
              icon: Icons.family_restroom_rounded,
              title: "I'm a family member",
              subtitle: 'Booking on behalf of someone',
              cardBg: familyCardBg,
              cardBorder: familyCardBorder,
              iconBg: familyIconBg,
              iconColor: familyIconColor,
              titleColor: familyTitleColor,
              subtitleColor: familySubtitleColor,
            ),

            const SizedBox(height: 22),
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
    );
  }

  Widget _buildOption({
    required _CareRecipient recipient,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color cardBorder,
    required Color iconBg,
    required Color iconColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final isSelected = _selected == recipient;
    return GestureDetector(
      onTap: () => setState(() => _selected = recipient),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: cardBorder, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: titleColor,
                      fontSize: recipient == _CareRecipient.patient ? 20 : 21,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: subtitleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: iconColor,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
