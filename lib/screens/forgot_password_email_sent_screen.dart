import 'dart:async';
import 'package:flutter/material.dart';

class ForgotPasswordEmailSentScreen extends StatefulWidget {
  const ForgotPasswordEmailSentScreen({super.key});

  @override
  State<ForgotPasswordEmailSentScreen> createState() =>
      _ForgotPasswordEmailSentScreenState();
}

class _ForgotPasswordEmailSentScreenState
    extends State<ForgotPasswordEmailSentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  Timer? _cooldownTimer;
  int _resendCooldown = 0;

  static const int _cooldownSeconds = 30;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _fadeController.forward();
    _startCooldown();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = _cooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _resendLink(String email) {
    if (_resendCooldown > 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reset link sent again to $email')),
    );
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        (ModalRoute.of(context)?.settings.arguments as String?) ??
            'nipuni@email.com';

    const Color creamBg = Color(0xFFF6F0E2);
    const Color darkGreen = Color(0xFF06402B);

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button (arrow icon in forest green)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: darkGreen,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title: Check your email
                      const Text(
                        'Check your email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: darkGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Envelope Vector Art
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: darkGreen.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            painter: _EnvelopeIconPainter(color: darkGreen),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              color: darkGreen,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: "We've sent a password reset link to ",
                              ),
                              TextSpan(
                                text: email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    '. Open the email and tap the link to set a new password.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Resend link Button
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _resendCooldown > 0
                              ? darkGreen.withValues(alpha: 0.4)
                              : darkGreen,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: _resendCooldown > 0
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF06402B)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () => _resendLink(email),
                            child: Center(
                              child: Text(
                                _resendCooldown > 0
                                    ? 'Resend link in ${_resendCooldown}s'
                                    : 'Resend link',
                                style: const TextStyle(
                                  color: creamBg,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer Link (centered)
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                              children: [
                                TextSpan(
                                  text: 'Remembered your password? ',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8), // Gull Gray
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Back to log in',
                                  style: TextStyle(
                                    color: darkGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for a stylized envelope icon in vector lines
class _EnvelopeIconPainter extends CustomPainter {
  final Color color;
  _EnvelopeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw outer envelope rectangle
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 70, height: 48);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), strokePaint);

    // Draw envelope folds (triangle)
    final foldPath = Path();
    foldPath.moveTo(cx - 35, cy - 24);
    foldPath.lineTo(cx, cy + 4);
    foldPath.lineTo(cx + 35, cy - 24);
    canvas.drawPath(foldPath, strokePaint);

    // Draw bottom corner folds
    final bottomFolds = Path();
    bottomFolds.moveTo(cx - 35, cy + 24);
    bottomFolds.lineTo(cx - 10, cy + 4);
    bottomFolds.moveTo(cx + 35, cy + 24);
    bottomFolds.lineTo(cx + 10, cy + 4);
    canvas.drawPath(bottomFolds, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
