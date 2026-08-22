import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'who_needs_care_sheet.dart';
import '../services/auth_service.dart';
import '../widgets/status_bar.dart';

const Color _cardSubtitleColor = Color.fromRGBO(0, 0, 0, 0.5);

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF033724);
  static const Color patientCardBg = Color.fromRGBO(111, 70, 26, 0.3);
  static const Color caregiverCardBg = Color.fromRGBO(26, 62, 111, 0.3);
  static const Color patientAccent = Color(0xFFC04B42);
  static const Color caregiverAccent = Color(0xFF073360);

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // This screen serves two different situations that look identical in the
  // UI but need different handling: a brand-new, unauthenticated visitor
  // choosing which signup flow to enter (reached from welcome_screen.dart),
  // and an already-authenticated user resuming an account that has no role
  // set yet (reached from login_screen.dart / starting_screen.dart after
  // sign-in, when users/{uid} has no role). Routing the second case through
  // /register was the root cause of the "email already exists" dead end,
  // since that account's Firebase Auth user already exists — there's
  // nothing left to register, just a role to record.
  Future<void> _selectRole(BuildContext context, String role) async {
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      // Already-authenticated user with no role yet (e.g. returned from a
      // partially-completed registration). Save the role first, then continue
      // through the normal flow — patients still see "Who needs care?" so
      // they can choose self vs. family, rather than jumping straight to
      // onboarding and bypassing that sheet entirely.
      await AuthService.setUserRole(uid, role);
      if (!context.mounted) return;

      if (role == 'caregiver') {
        // Use pushNamed (not pushNamedAndRemoveUntil) so the back button
        // returns to role-selection instead of showing a black screen.
        Navigator.pushNamed(context, '/caregiver-onboarding-1');
      } else {
        // Patient: show the "Who needs care?" sheet first, just as the
        // unauthenticated path does.
        showWhoNeedsCareSheet(context);
      }
      return;
    }

    if (role == 'caregiver') {
      Navigator.pushNamed(context, '/register', arguments: {'role': 'caregiver'});
    } else {
      showWhoNeedsCareSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + title on a single line
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: titleColor,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Select User Type',
                      style: TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // Cards - scaled to fit the remaining space, no scrolling
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 393,
                      height: 369 + 7 + 322,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Patient or Family card
                          _RoleCard(
                            groupHeight: 369,
                            pokeOut: 81,
                            cardBg: patientCardBg,
                            title: 'Patient or Family',
                            subtitle:
                                "Tell us what care you need. We'll find the caregivers who fit.",
                            accentColor: patientAccent,
                            illustrationAsset:
                                'assets/images/patient_illustration.png',
                            illustrationLeft: 60,
                            illustrationWidth: 183,
                            illustrationHeight: 209,
                            onTap: () => _selectRole(context, 'patient'),
                          ),
                          const SizedBox(height: 7),

                          // Caregiver card
                          _RoleCard(
                            groupHeight: 322,
                            pokeOut: 34,
                            cardBg: caregiverCardBg,
                            title: 'Caregiver',
                            subtitle:
                                "Share your skills and schedule. We'll match you with families who need them.",
                            accentColor: caregiverAccent,
                            illustrationAsset:
                                'assets/images/caregiver_illustration.png',
                            illustrationLeft: 58,
                            illustrationWidth: 200,
                            illustrationHeight: 216,
                            onTap: () => _selectRole(context, 'caregiver'),
                          ),
                        ],
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

/// A role selection card matching the Figma design: an illustration that
/// pokes out above a translucent rounded box, with title/subtitle/CTA
/// inside. The whole card is tappable.
class _RoleCard extends StatelessWidget {
  final double groupHeight;
  final double pokeOut;
  final Color cardBg;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String illustrationAsset;
  final double illustrationLeft;
  final double illustrationWidth;
  final double illustrationHeight;
  final VoidCallback onTap;

  const _RoleCard({
    required this.groupHeight,
    required this.pokeOut,
    required this.cardBg,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.illustrationAsset,
    required this.illustrationLeft,
    required this.illustrationWidth,
    required this.illustrationHeight,
    required this.onTap,
  });

  static const double cardWidth = 333;
  static const double boxHeight = 288;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: cardWidth,
          height: groupHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Translucent rounded box
              Positioned(
                top: pokeOut,
                left: 0,
                child: Container(
                  width: cardWidth,
                  height: boxHeight,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Illustration - poking out above the box
              Positioned(
                top: 0,
                left: illustrationLeft,
                child: Image.asset(
                  illustrationAsset,
                  width: illustrationWidth,
                  height: illustrationHeight,
                  fit: BoxFit.contain,
                ),
              ),

              // Title
              Positioned(
                top: pokeOut + 144,
                left: 24,
                right: 24,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              // Subtitle
              Positioned(
                top: pokeOut + 193,
                left: 24,
                width: 287,
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _cardSubtitleColor,
                    letterSpacing: 0.3,
                    height: 1.25,
                  ),
                ),
              ),

              // Get start + arrow
              Positioned(
                top: pokeOut + 244,
                left: 24,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get start',
                      style: TextStyle(
                        fontFamily: 'Quattrocento Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.32,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.rotate(
                      angle: math.pi / 2,
                      child: SvgPicture.asset(
                        'assets/images/arrow_icon.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          accentColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
