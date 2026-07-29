import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Messages List Screen  (Patient)
//  Figma node: 294-169
//  Messaging unlocks once a real booking is confirmed — no
//  caregiver-side accept flow exists yet, so this is always the
//  empty state today.
// ─────────────────────────────────────────────────────────────
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF0F3D2E);
  static const Color heading = Color(0xFF462911);
  static const Color body = Color.fromRGBO(70, 41, 17, 0.67);
  static const Color caption = Color.fromRGBO(0, 0, 0, 0.67);
  static const Color buttonBg = Color(0xFFAAA897);

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(Brightness.dark);
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: Image.asset(
                        'assets/images/empty_messages.webp',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: buttonBg,
                          size: 120,
                        ),
                      ),
                    ),
                    const Text(
                      'No messages yet',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: heading,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Messages are unlocked when a booking is confirmed. '
                      'Once a caregiver accepts your request, you can chat '
                      'with them here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: body,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/my-bookings'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                        decoration: BoxDecoration(
                          color: buttonBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'View my bookings',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: heading,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'You can only message caregivers linked to an active booking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: caption,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
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

  // ── Page header ───────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 20),
          ),
          const SizedBox(width: 16),
          const Text(
            'Messages',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: titleGreen,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
