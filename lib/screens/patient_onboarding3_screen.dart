import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PatientOnboarding3Screen extends StatefulWidget {
  const PatientOnboarding3Screen({super.key});

  @override
  State<PatientOnboarding3Screen> createState() =>
      _PatientOnboarding3ScreenState();
}

class _PatientOnboarding3ScreenState extends State<PatientOnboarding3Screen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────
  late AnimationController _heroController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;

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

  // Pulse glow on the outer ring
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // ── Hero animation (0 → 900 ms) ──
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

    // ── Pulse glow (infinite loop) ──
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start sequence
    _heroController.forward().then((_) {
      if (mounted) {
        _cardsController.forward();
        _pulseController.repeat(reverse: true);
      }
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // ── Upper half: hero (centered vertically) ──
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _heroController,
                    builder: (_, child) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Checkmark icon with glow ──
                        Opacity(
                          opacity: _heroFade.value,
                          child: Transform.scale(
                            scale: _heroScale.value,
                            child: _buildCheckIcon(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Title + subtitle ──
                        Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: Column(
                              children: [
                                const Text(
                                  'Profile set up!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "We're finding your top caregiver matches",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
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
                builder: (_, child) => Column(
                  children: [
                    _buildInfoCard(
                      icon: Icons.verified_outlined,
                      iconColor: AppTheme.primaryGreen,
                      label: 'Your care requirements are saved',
                      fadeAnim: _card1Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.edit_outlined,
                      iconColor: AppTheme.primaryGreen,
                      label: 'Edit them anytime in settings',
                      fadeAnim: _card2Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFEF4444),
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
                builder: (_, child) => Opacity(
                  opacity: _btnFade.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/patient-dashboard',
                              (route) => false,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Go to dashboard',
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Outer translucent glow ring → solid green disc → white checkmark
  Widget _buildCheckIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.bottleGreen,
                size: 36,
              ),
            ),
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
            color: AppTheme.inputBackground, // #1E293B
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF334155), // Pickled Bluewood
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1), // Geyser
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
