import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Registration — "Profile live!" celebration screen
//  Shown after the caregiver accepts the terms & conditions on
//  the final onboarding step (step 6 of 6).
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
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _red = Color(0xFFEF4444);

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

    _saveCaregiverProfile();
  }

  Future<void> _saveCaregiverProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    try {
      final userProfile = await AuthService.getUserProfile(user.uid);
      final data = AppState.caregiverOnboardingDraft.toMap();
      data['agreedToTermsAt'] = FieldValue.serverTimestamp();
      // Denormalized so search/profile views (readable by any signed-in
      // user) don't need to read the owner-only users/{uid} document.
      data['name'] = userProfile?['name'] ?? '';
      data['email'] = userProfile?['email'] ?? user.email ?? '';
      await CaregiverService.saveCaregiverProfile(uid: user.uid, data: data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your profile: $e')),
        );
      }
    }
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
                                  'Profile live!',
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
                                  'Families can now find and request you',
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
                builder: (_, _) => Column(
                  children: [
                    _buildInfoCard(
                      icon: Icons.update_rounded,
                      iconColor: _indigo,
                      label: 'Keep your availability updated',
                      fadeAnim: _card1Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.military_tech_outlined,
                      iconColor: _indigo,
                      label: 'More skills = more requests',
                      fadeAnim: _card2Fade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: _red,
                      label: 'Turn on emergency availability',
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
                        color: _indigo,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/caregiver-dashboard',
                              (route) => false,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Go to dashboard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
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

  /// Outer translucent glow ring → solid indigo disc → white checkmark
  Widget _buildCheckIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, _) => Transform.scale(
        scale: _pulse.value,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _indigo.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _indigo,
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
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
            color: AppTheme.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF334155),
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
                    color: Color(0xFFCBD5E1),
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
