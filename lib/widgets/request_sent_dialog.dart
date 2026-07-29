import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  "Request sent!" confirmation popup  (Figma node 334-848)
//  Shown after a booking request is created from a caregiver card — e.g. the
//  Request button on the advanced-match top-5 results list.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> showRequestSentDialog(BuildContext context) {
  return showDialog(
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
            const Icon(Icons.verified_rounded, color: Colors.white, size: 74),
            const SizedBox(height: 18),
            const Text(
              'Request sent!',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFFF8FAFC),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "Your booking request has been sent to matching caregivers. "
              "We'll notify you as soon as one accepts.",
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
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/my-bookings',
                      (route) => route.settings.name == '/patient-dashboard',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'View booking status',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/patient-dashboard',
                  (route) => false,
                );
              },
              child: const Text(
                'Back to home',
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
