import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  "Finish your profile first" popup — shown when a patient tries to match/
//  request a caregiver, or a caregiver tries to accept a job, with a profile
//  that isn't complete yet. Names the missing section(s) so the user knows
//  exactly what to go fill in, rather than a generic "complete your profile"
//  message. Same visual language as restart_match_dialog.dart.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showIncompleteProfileDialog(
  BuildContext context, {
  required String title,
  required List<String> missingSections,
  required String buttonLabel,
  required String buttonRoute,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: const Color.fromRGBO(0, 0, 0, 0.72),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF4E3B30),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBC05), size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFFF8FAFC),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (missingSections.isEmpty)
              const Text(
                "You're almost done — a few final steps are left to finish setting "
                'up your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color.fromRGBO(185, 142, 117, 0.69),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              )
            else ...[
              const Text(
                'Still missing:',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color.fromRGBO(185, 142, 117, 0.69),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...missingSections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '•  $section',
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color(0xFFF8FAFC),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: const Color(0xFFB5484B),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, buttonRoute);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      buttonLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                'Not now',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFFDB956B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
