import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  "Start a new search?" confirmation popup — shown when the patient taps the
//  Match button again from the advanced-match results screen. Restarting the
//  5-step wizard regenerates the top-5 list, discarding the current one, so
//  this asks for explicit confirmation first (same visual language as
//  request_sent_dialog.dart).
// ─────────────────────────────────────────────────────────────────────────────
Future<bool> showRestartMatchDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
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
            const Text(
              'Start a new search?',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFFF8FAFC),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "You'll lose your current top 5 caregiver matches — this can't be undone.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Color.fromRGBO(185, 142, 117, 0.69),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: const Color(0xFFB5484B),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.pop(context, true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'Yes, start over',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
              onTap: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
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
  return confirmed ?? false;
}
