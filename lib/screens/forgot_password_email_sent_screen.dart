import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

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
    setStatusBarStyle(Brightness.dark);
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

    const Color darkGreen = Color(0xFF06402B);
    const Color darkGreenBorder = Color(0xFF033724);

    return Scaffold(
      backgroundColor: Colors.white,
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
                          fontFamily: 'Quattrocento Sans',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: darkGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Envelope illustration
                      Center(
                        child: Image.asset(
                          'assets/images/check_email_envelope.png',
                          width: 300,
                          height: 276,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              color: darkGreen.withValues(alpha: 0.9),
                              height: 1.6,
                            ),
                            children: [
                              const TextSpan(
                                text: "We've sent a password reset link to ",
                              ),
                              TextSpan(
                                text: email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
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
                      const SizedBox(height: 32),

                      // Resend link Button
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          color: _resendCooldown > 0
                              ? darkGreen.withValues(alpha: 0.4)
                              : darkGreen,
                          border: Border.all(
                            color: darkGreenBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: _resendCooldown > 0
                              ? null
                              : [
                                  BoxShadow(
                                    color: darkGreen.withValues(alpha: 0.5),
                                    blurRadius: 2,
                                    offset: const Offset(2, 2),
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
                                  color: Colors.white,
                                  fontSize: 18,
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
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Remembered your password? ',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8), // Gull Gray
                                  ),
                                ),
                                TextSpan(
                                  text: 'Back to log in',
                                  style: TextStyle(
                                    color: darkGreen,
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
