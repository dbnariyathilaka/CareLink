import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  "Who needs care?" bottom sheet
//  Figma node: 498-5466 · shown when "Patient or Family" is
//  tapped on the role selection screen.
//
//  - "I'm the patient"      → straight into patient onboarding.
//  - "I'm a family member"  → patient details form first, then
//                             the same onboarding flow.
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
  static const Color _indigo = Color(0xFF6366F1);

  _CareRecipient _selected = _CareRecipient.patient;

  void _continue() {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/register',
      arguments: {
        'role': 'patient',
        'careRecipient':
            _selected == _CareRecipient.patient ? 'self' : 'family',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(top: BorderSide(color: AppTheme.cardColor)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: AppTheme.primaryGreen, size: 28),
            ),
            const SizedBox(height: 18),
            const Text(
              'Who needs care?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This helps us set up the right profile and permissions.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            _buildOption(
              recipient: _CareRecipient.patient,
              icon: Icons.self_improvement_rounded,
              iconColor: AppTheme.primaryGreen,
              title: "I'm the patient",
              subtitle: 'Care is for me',
            ),
            const SizedBox(height: 12),
            _buildOption(
              recipient: _CareRecipient.familyMember,
              icon: Icons.family_restroom_rounded,
              iconColor: _indigo,
              title: "I'm a family member",
              subtitle: 'Booking on behalf of someone',
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppTheme.primaryGreen,
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
    );
  }

  Widget _buildOption({
    required _CareRecipient recipient,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selected == recipient;
    return GestureDetector(
      onTap: () => setState(() => _selected = recipient),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.all(isSelected ? 17 : 18),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border.all(
            color: isSelected ? iconColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
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
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? iconColor : const Color(0xFF475569),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
