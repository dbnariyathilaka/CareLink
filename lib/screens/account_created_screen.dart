import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key});

  @override
  State<AccountCreatedScreen> createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
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

    // Premium entrance animation sequence
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final userName = (args is Map && args['name'] != null && args['name'].toString().trim().isNotEmpty)
        ? args['name'].toString().trim()
        : 'Nipuni';
    final role = (args is Map && args['role'] is String) ? args['role'] as String : null;
    final routeName = ModalRoute.of(context)?.settings.name;
    final isCaregiver = role == 'caregiver' || routeName == '/caregiver-account-created';
    final Color bgColor = isCaregiver ? const Color(0xFF55463A) : const Color(0xFF06402B);
    const Color creamColor = Color(0xFFF6F0E2);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Center content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // MdiTickDecagram icon scale transition
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
                    const SizedBox(height: 36),

                    // Title: Account created!
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
                        'Account created!',
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
                    const SizedBox(height: 16),

                    // Subtitle: Welcome message
                    AnimatedBuilder(
                      animation: _textFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFadeAnimation.value,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "Welcome to CareLink, $userName. Let's set up your profile so we can find your matches.",
                          style: const TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Button Section with entrance slide/fade
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
                      color: bgColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: creamColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCaregiver
                              ? const Color.fromRGBO(85, 70, 58, 0.5)
                              : const Color.fromRGBO(6, 64, 43, 0.5),
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
                          // Family-member details (if any) were already
                          // collected before registration, so both
                          // careRecipient cases land on the same onboarding
                          // flow here.
                          if (isCaregiver) {
                            Navigator.pushNamed(context, '/caregiver-onboarding-1');
                          } else if (role == 'patient') {
                            Navigator.pushNamed(context, '/patient-onboarding-1');
                          } else {
                            Navigator.pushNamed(context, '/role-selection');
                          }
                        },
                        child: const Center(
                          child: Text(
                            'Set my profile',
                            style: TextStyle(
                              color: creamColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
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
