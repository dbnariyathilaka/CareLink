import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Registration — "Profile set up!" celebration screen
//  Figma node: 496-769
//  Shown after the caregiver accepts the terms & conditions on
//  the final onboarding step (step 7 of 7).
// ─────────────────────────────────────────────────────────────
class CaregiverRegistrationSuccessScreen extends StatefulWidget {
  const CaregiverRegistrationSuccessScreen({super.key});

  @override
  State<CaregiverRegistrationSuccessScreen> createState() =>
      _CaregiverRegistrationSuccessScreenState();
}

class _CaregiverRegistrationSuccessScreenState
    extends State<CaregiverRegistrationSuccessScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF55463A);
  static const Color _cardBg = Color(0xFFE1D5C6);
  static const Color _cardBorder = Color(0xFF334155);
  static const Color _cardLabel = Color(0xFF443219);
  static const Color _verifiedIcon = Color(0xFF74590C);
  static const Color _editIcon = Color(0xFF554F42);
  static const Color _emergencyIcon = Color(0xFF952222);
  static const Color _buttonText = Color(0xFFF6F0E2);

  // ── Animation controllers ──────────────────────────────
  late AnimationController _heroController;
  late AnimationController _cardsController;
  late AnimationController _pulseController;

  late Animation<double> _heroScale;
  late Animation<double> _heroFade;

  late Animation<double> _textFade;
  late Animation<double> _textSlide;

  late Animation<double> _card1Fade;
  late Animation<double> _card2Fade;
  late Animation<double> _card3Fade;

  late Animation<double> _btnFade;

  late Animation<double> _pulse;

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

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _card1Fade = _staggeredFade(0.0, 0.45);
    _card2Fade = _staggeredFade(0.25, 0.65);
    _card3Fade = _staggeredFade(0.50, 0.90);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _heroController.forward().then((_) {
      _cardsController.forward();
      _pulseController.repeat(reverse: true);
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
      backgroundColor: _bg,
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
                    builder: (_, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _heroFade.value,
                          child: Transform.scale(
                            scale: _heroScale.value,
                            child: _buildCheckIcon(),
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                    fontFamily: 'Quattrocento Sans',
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'We\'re matching you with nearby care requests',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
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
                      icon: Icons.verified_outlined,
                      iconColor: _verifiedIcon,
                      label: 'Your profile and skills are saved',
                      fadeAnim: _card1Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.edit_outlined,
                      iconColor: _editIcon,
                      label: 'Edit them anytime in settings',
                      fadeAnim: _card2Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.emergency_rounded,
                      iconColor: _emergencyIcon,
                      label: 'Keep your availability updated to rank higher',
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
                    child: SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () async {
                            // Mark onboarding as complete so login can
                            // distinguish a fully-registered caregiver from
                            // one who abandoned mid-onboarding.
                            final uid = AuthService.currentUser?.uid;
                            if (uid != null) {
                              try {
                                await CaregiverService.saveCaregiverProfile(
                                  uid: uid,
                                  data: {
                                    ...AppState.caregiverOnboardingDraft.toMap(),
                                    'onboardingComplete': true,
                                  },
                                );
                              } catch (_) {
                                // best-effort; dashboard still loads fine
                              }
                            }
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/caregiver-dashboard',
                                (route) => false,
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: _buttonText),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: const Text(
                              'Go to dashboard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Quattrocento Sans',
                                color: _buttonText,
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

  /// White verified-seal badge with a gentle pulse
  Widget _buildCheckIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, _) => Transform.scale(
        scale: _pulse.value,
        child: const Icon(
          Icons.verified_rounded,
          color: Colors.white,
          size: 150,
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
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
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
                    color: _cardLabel,
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
