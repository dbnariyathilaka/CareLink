import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

class ForgotPasswordResetSuccessScreen extends StatefulWidget {
  const ForgotPasswordResetSuccessScreen({super.key});

  @override
  State<ForgotPasswordResetSuccessScreen> createState() =>
      _ForgotPasswordResetSuccessScreenState();
}

class _ForgotPasswordResetSuccessScreenState
    extends State<ForgotPasswordResetSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
    );

    _buttonFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF06402B);
    const Color creamColor = Color(0xFFF6F0E2);
    const Color offWhite = Color(0xFFFCF9F2);

    return Scaffold(
      backgroundColor: darkGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 20),
          child: Column(
            children: [
              // Center content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tick decagram icon scale transition
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 150,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Title: Password Reset!
                    AnimatedBuilder(
                      animation: _textFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 15 * (1 - _textFadeAnimation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: const Text(
                        'Password Reset!',
                        style: TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subtitle
                    AnimatedBuilder(
                      animation: _textFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFadeAnimation.value,
                          child: child,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Your password has been updated. Use your new password the next time you log in.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: offWhite,
                            height: 1.38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Back to login button with entrance slide/fade
              AnimatedBuilder(
                animation: _buttonFadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _buttonFadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _buttonFadeAnimation.value)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Container(
                    width: double.infinity,
                    height: 59,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: creamColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: darkGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        child: const Center(
                          child: Text(
                            'Back to login',
                            style: TextStyle(
                              color: creamColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Quattrocento Sans',
                            ),
                          ),
                        ),
                      ),
                    ),
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
