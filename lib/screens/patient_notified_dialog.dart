import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  "Report submitted" confirmation dialog
//  Figma node: 355-2813 · shown after submitting the "Report
//  unavailability" dialog. Figma titles this "Patient notified"
//  and claims "CareLink support is arranging a replacement" /
//  "Support will confirm reassignment within 30 minutes" — none
//  of that exists (no notification pipeline, no support queue),
//  so the copy below says what's actually true: the report was
//  saved, and reaching the patient is on the caregiver.
// ─────────────────────────────────────────────────────────────
Future<void> showPatientNotifiedDialog(
  BuildContext context, {
  required String patientName,
  required String schedule,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PatientNotifiedDialog(patientName: patientName, schedule: schedule),
  );
}

class PatientNotifiedDialog extends StatelessWidget {
  const PatientNotifiedDialog({super.key, required this.patientName, required this.schedule});

  final String patientName;
  final String schedule;

  static const Color _dialogBg = Color(0xFF4E3B30);
  static const Color _titleText = Color(0xFFF8FAFC);
  static const Color _bodyText = Color(0xFF987460);
  static const Color _infoBg = Color(0xFFBEA495);
  static const Color _infoIcon = Color(0xFFFBBC05);
  static const Color _infoText = Color(0xFF371E0F);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: _dialogBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 20)),
          ],
        ),
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 74),
            const SizedBox(height: 18),
            const Text(
              'Report submitted',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Open Sans', color: _titleText, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            Text(
              "You've recorded that you can't attend $schedule with $patientName. It's saved on your schedule.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Open Sans', color: _bodyText, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: _infoBg, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent_rounded, color: _infoIcon, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "CareLink doesn't send this automatically — message or call the patient yourself to let them know.",
                      style: TextStyle(fontFamily: 'Open Sans', color: _infoText, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Back to schedule',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
