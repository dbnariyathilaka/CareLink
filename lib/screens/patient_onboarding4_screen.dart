import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

class PatientOnboarding4Screen extends StatefulWidget {
  const PatientOnboarding4Screen({super.key});

  @override
  State<PatientOnboarding4Screen> createState() =>
      _PatientOnboarding4ScreenState();
}

class _PatientOnboarding4ScreenState extends State<PatientOnboarding4Screen>
    with TickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF06402B);
  static const Color creamColor = Color(0xFFF6F0E2);
  static const Color cardBg = Color(0xFFE1D5C6);
  static const Color cardText = Color(0xFF0F3D2E);

  // ── Animation controllers ──────────────────────────────
  late AnimationController _heroController;
  late AnimationController _cardsController;

  // Hero: scale + fade
  late Animation<double> _heroScale;
  late Animation<double> _heroFade;

  // Title + subtitle: fade + slide up
  late Animation<double> _textFade;
  late Animation<double> _textSlide;

  // Info cards: staggered fade + slide up
  late Animation<double> _card1Fade;
  late Animation<double> _card2Fade;
  late Animation<double> _card3Fade;

  // Button: fade in last
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _heroScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Cards animation (staggered, starts after hero) ──
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _card1Fade = _staggeredFade(0.0, 0.45);
    _card2Fade = _staggeredFade(0.25, 0.65);
    _card3Fade = _staggeredFade(0.50, 0.90);

    _heroController.forward().then((_) {
      _cardsController.forward();
    });
  }

  Animation<double> _staggeredFade(double start, double end) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          child: Column(
            children: [
              // ── Upper half: hero (centered vertically) ──
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _heroController,
                    builder: (_, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _heroFade.value,
                          child: Transform.scale(
                            scale: _heroScale.value,
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 150,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: const Column(
                              children: [
                                Text(
                                  'Profile set up!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Quattrocento Sans',
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "We're finding your top caregiver matches",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
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
              ),

              // ── Lower section: info cards + button ──
              AnimatedBuilder(
                animation: _cardsController,
                builder: (_, _) => Column(
                  children: [
                    _buildInfoCard(
                      icon: Icons.verified_rounded,
                      iconColor: const Color(0xFF74590C),
                      label: 'Your care requirements are saved',
                      fadeAnim: _card1Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.edit_rounded,
                      iconColor: const Color(0xFF554F42),
                      label: 'Edit them anytime in settings',
                      fadeAnim: _card2Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.emergency_rounded,
                      iconColor: const Color(0xFF952222),
                      label: 'Use the emergency button for urgent care',
                      fadeAnim: _card3Fade,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── Go to dashboard button ──
              AnimatedBuilder(
                animation: _heroController,
                builder: (_, _) => Opacity(
                  opacity: _btnFade.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      width: double.infinity,
                      height: 59,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: creamColor, width: 1),
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
                              '/patient-dashboard',
                              (route) => false,
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Go to dashboard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Quattrocento Sans',
                                color: creamColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
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

  /// A single info card row with icon + label
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Animation<double> fadeAnim,
  }) {
    return Opacity(
      opacity: fadeAnim.value,
      child: Transform.translate(
        offset: Offset(0, (1 - fadeAnim.value) * 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: cardText,
                    fontSize: 14,
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
}
