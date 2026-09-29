import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/family_access_service.dart';
import '../widgets/status_bar.dart';

class StartingScreen extends StatefulWidget {
  const StartingScreen({super.key});

  @override
  State<StartingScreen> createState() => _StartingScreenState();
}

class _StartingScreenState extends State<StartingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    // Show splash for at least 2 seconds, then route based on auth state.
    _timer = Timer(const Duration(seconds: 2), _handleInitialRoute);
  }

  Future<void> _handleInitialRoute() async {
    if (!mounted) return;

    final user = AuthService.currentUser;

    // Not signed in → go to welcome screen.
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/welcome');
      return;
    }

    // Signed in → check role + completeness.
    final profile = await AuthService.getUserProfile(user.uid);
    final role = profile?['role'] as String?;

    if (!mounted) return;

    // Same real invite check as login_screen.dart — needed here too since
    // an auto-restored session never goes through that screen at all.
    await FamilyAccessService.checkAndPromptPendingInvites(context, user.email);
    if (!mounted) return;
    final familyLinks = await FamilyAccessService.fetchAcceptedFamilyLinks(user.uid);
    final hasFamilyAccess = familyLinks.isNotEmpty;

    if (role == 'caregiver') {
      // A relaunch is exactly how an account can get stuck mid-onboarding —
      // the Firebase session survives a refresh even though no onboarding
      // screen ever finished. An account this incomplete has never been
      // usable (no dashboard data), so it's wiped here rather than let
      // through to look like a real, working account — unless it has real
      // accepted family access, which is a legitimate reason to never
      // finish onboarding.
      if (await AuthService.isCaregiverOnboardingComplete(user.uid)) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/caregiver-dashboard');
      } else if (hasFamilyAccess) {
        Navigator.pushReplacementNamed(context, '/family-circles');
      } else {
        await AuthService.deleteIncompleteAccount(user.uid, user.email ?? '');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } else if (role == 'patient') {
      if (await AuthService.isPatientOnboardingComplete(user.uid)) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/patient-dashboard');
      } else if (hasFamilyAccess) {
        Navigator.pushReplacementNamed(context, '/family-circles');
      } else {
        await AuthService.deleteIncompleteAccount(user.uid, user.email ?? '');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } else if (hasFamilyAccess) {
      // No patient/caregiver role of their own, but real accepted family
      // access — a legitimate "family-only" account.
      Navigator.pushReplacementNamed(context, '/family-circles');
    } else {
      // Role unknown / not set → welcome.
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06402B), // Dark green background
      body: Center(
        child: Image.asset(
          'assets/images/splash_logo.jpg',
          width: 280,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
