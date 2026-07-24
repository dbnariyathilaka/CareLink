import 'package:flutter/material.dart';

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

  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF033724);
  static const Color textColor = Color(0xFF06402B);
  static const Color buttonTextColor = Color(0xFFF6F0E2);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // MAMÁ Y LA HIJA 1 - full-bleed square illustration
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    'assets/images/screen2_obj.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 15),

                // Title: Welcome to CareLink
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Welcome to CareLink',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 19),
                  child: Text(
                    "Tell us what care you need, and we'll rank the caregivers who match you best.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Login button - darkGreen capsule, cream text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPillButton(
                    text: 'Login',
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Sign in button - darkGreen capsule, cream text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildPillButton(
                    text: 'Sign in',
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Or divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 37),
                  child: _buildOrDivider(),
                ),
                const SizedBox(height: 18),

                // Continue with google - outlined capsule, no icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildGoogleButton(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: textColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.5),
            blurRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onTap,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: buttonTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: textColor, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/register',
              arguments: {'triggerGoogle': true},
            );
          },
          child: const Center(
            child: Text(
              'Continue with google',
              style: TextStyle(
                fontFamily: 'Quattrocento Sans',
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: Colors.black.withValues(alpha: 0.3)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or',
            style: TextStyle(
              fontFamily: 'Quattrocento Sans',
              color: Color.fromRGBO(0, 0, 0, 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: Colors.black.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}
