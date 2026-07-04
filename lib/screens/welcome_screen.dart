import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _buttonsFadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    // Subtle pulsing glow animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.08, end: 0.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Radial green gradient glow at top center
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                top: -120,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.55,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        AppTheme.primaryGreen
                            .withValues(alpha: _pulseAnimation.value),
                        AppTheme.primaryGreen.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  // Center section with logo, title and subtitle
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App icon - green rounded square with caregiving icon
                          _buildAppIcon(),
                          const SizedBox(height: 22),

                          // App name
                          const Text(
                            'CareLink',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subtitle
                          const Text(
                            'Find the right caregiver for your\nneeds',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom buttons section
                  AnimatedBuilder(
                    animation: _buttonsFadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _buttonsFadeAnimation.value,
                        child: Transform.translate(
                          offset:
                              Offset(0, 20 * (1 - _buttonsFadeAnimation.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Log in button - solid green
                          _buildLoginButton(),
                          const SizedBox(height: 12),

                          // Create account button - outlined
                          _buildCreateAccountButton(),
                          const SizedBox(height: 12),

                          // Continue with Google button - white/light
                          _buildGoogleButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -0.8),
          end: Alignment(0.5, 0.8),
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreenDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(52, 62),
          painter: _CaregivingIconPainter(),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pushNamed(context, '/login');
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Log in',
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
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pushNamed(context, '/role-selection');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: const Text(
              'Create account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppTheme.textPrimary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google Sign-In coming soon!'),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'G',
                  style: TextStyle(
                    color: AppTheme.googleBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: AppTheme.ebony,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the caregiving hand + heart icon
class _CaregivingIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw the hand (open palm facing up)
    final handPath = Path();

    // Palm base - curved cup shape
    handPath.moveTo(cx - 16, cy + 10);
    handPath.quadraticBezierTo(cx - 18, cy + 18, cx - 10, cy + 20);
    handPath.lineTo(cx + 10, cy + 20);
    handPath.quadraticBezierTo(cx + 18, cy + 18, cx + 16, cy + 10);

    // Fingers - slight curves going up on right side
    handPath.quadraticBezierTo(cx + 20, cy + 2, cx + 14, cy - 2);

    // Back across the top of the hand
    handPath.quadraticBezierTo(cx + 8, cy + 2, cx, cy + 4);
    handPath.quadraticBezierTo(cx - 8, cy + 2, cx - 14, cy - 2);
    handPath.quadraticBezierTo(cx - 20, cy + 2, cx - 16, cy + 10);

    canvas.drawPath(handPath, strokePaint);

    // Draw the heart above the hand
    final heartSize = 12.0;
    final heartCx = cx;
    final heartCy = cy - 12;

    final heartPath = Path();
    heartPath.moveTo(heartCx, heartCy + heartSize * 0.35);

    // Left half of heart
    heartPath.cubicTo(
      heartCx - heartSize * 0.5, heartCy - heartSize * 0.3,
      heartCx - heartSize, heartCy + heartSize * 0.05,
      heartCx, heartCy + heartSize * 0.7,
    );

    // Right half of heart
    heartPath.cubicTo(
      heartCx + heartSize, heartCy + heartSize * 0.05,
      heartCx + heartSize * 0.5, heartCy - heartSize * 0.3,
      heartCx, heartCy + heartSize * 0.35,
    );

    canvas.drawPath(heartPath, paint);
    canvas.drawPath(heartPath, strokePaint..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
