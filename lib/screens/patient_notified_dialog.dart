import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  "Patient notified" confirmation dialog
//  Figma node: 498-7717 · shown after "Notify patient" is tapped
//  on the Report unavailability dialog.
// ─────────────────────────────────────────────────────────────
Future<void> showPatientNotifiedDialog(
  BuildContext context, {
  required String patientName,
  required String bookingDetail,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PatientNotifiedDialog(
      patientName: patientName,
      bookingDetail: bookingDetail,
    ),
  );
}

class PatientNotifiedDialog extends StatelessWidget {
  final String patientName;
  final String bookingDetail;

  const PatientNotifiedDialog({
    super.key,
    required this.patientName,
    required this.bookingDetail,
  });

  static const Color _indigo = Color(0xFF6366F1);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _geyser = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(27),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Patient notified',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              "$patientName has been told you can't attend "
              '$bookingDetail. CareLink support is arranging a replacement.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded, color: _amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Support will confirm reassignment within 30 minutes.',
                      style: TextStyle(color: _geyser, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: _indigo,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      'Back to schedule',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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
}
