import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key});

  @override
  State<AccountCreatedScreen> createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main entrance animation sequence
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    );

    _buttonFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    // Subtle glow pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.10, end: 0.16).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Stack(
        children: [
          // Radial green gradient glow behind the checkmark area
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.2,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        AppTheme.primaryGreen.withValues(
                          alpha: _pulseAnimation.value,
                        ),
                        AppTheme.primaryGreen.withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  // Center section with checkmark, title and description
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Checkmark icon with animated entrance
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
                          child: _buildCheckmarkIcon(),
                        ),
                        const SizedBox(height: 24),

                        // Title with fade-in
                        AnimatedBuilder(
                          animation: _textFadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textFadeAnimation.value,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  15 * (1 - _textFadeAnimation.value),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: const Text(
                            'Account created!',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description with fade-in
                        AnimatedBuilder(
                          animation: _textFadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textFadeAnimation.value,
                              child: child,
                            );
                          },
                          child: const SizedBox(
                            width: 275,
                            child: Text(
                              "Welcome to CareLink, Nipuni. Let's set up your profile so we can find your matches.",
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.55,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom buttons with fade-in
                  AnimatedBuilder(
                    animation: _buttonFadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _buttonFadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            20 * (1 - _buttonFadeAnimation.value),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Set up my profile button
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  // TODO: Navigate to profile setup
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Profile setup coming soon!',
                                      ),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'Set up my profile',
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
                          ),
                          const SizedBox(height: 12),

                          // Skip for now
                          GestureDetector(
                            onTap: () {
                              // TODO: Navigate to home/dashboard
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Skipping for now...'),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Skip for now',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  /// Builds the checkmark icon matching Figma:
  /// 110px outer tinted circle + 78px inner solid green circle + white check icon
  Widget _buildCheckmarkIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: AppTheme.bottleGreen,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
