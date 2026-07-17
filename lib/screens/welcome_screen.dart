import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  static const Color bgColor = Color(0xFFF5EFE1);
  static const Color brandGreen = Color(0xFF0F3D2E);
  static const Color linen = Color(0xFFFDFAF3);
  static const Color dividerLine = Color.fromRGBO(15, 61, 46, 0.25);
  static const Color orTextColor = Color.fromRGBO(15, 61, 46, 0.6);

  @override
  void initState() {
    super.initState();

    // Main entrance animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mother and daughter embracing in a garden
                  SizedBox(
                    height: 360,
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/screen2_obj.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Title: Welcome to CareLink
                  const Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: Text(
                      'Welcome to CareLink',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: brandGreen,
                        letterSpacing: -0.3,
                        height: 1.0,
                      ),
                    ),
                  ),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: const Text(
                        "Tell us what care you need, and we'll rank the caregivers who match you best.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: brandGreen,
                          height: 21 / 14,
                        ),
                      ),
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPillButton(
                          text: 'Login',
                          filled: true,
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPillButton(
                          text: 'Sign in',
                          filled: true,
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildOrDivider(),
                        const SizedBox(height: 14),
                        _buildGoogleButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required String text,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? brandGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Quattrocento Sans',
              color: filled ? linen : brandGreen,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/register',
            arguments: {'triggerGoogle': true},
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: brandGreen, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/google_logo.svg',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 10),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  fontFamily: 'Quattrocento Sans',
                  color: brandGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: dividerLine)),
        ),
        const SizedBox(width: 9.8),
        const Text(
          'Or',
          style: TextStyle(
            fontFamily: 'Quattrocento Sans',
            color: orTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 9.8),
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: dividerLine)),
        ),
      ],
    );
  }
}
