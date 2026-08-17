import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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

    if (role == 'caregiver') {
      final complete = await AuthService.isCaregiverOnboardingComplete(user.uid);
      if (!complete) {
        // Incomplete caregiver account — wipe it and send to welcome.
        final email = (profile?['email'] as String?) ?? user.email ?? '';
        await AuthService.deleteIncompleteAccount(user.uid, email);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
        // Show snackbar after the new screen is rendered.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your previous registration was incomplete. '
                'Please sign up again to create a full account.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        });
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/caregiver-dashboard');
    } else if (role == 'patient') {
      Navigator.pushReplacementNamed(context, '/patient-dashboard');
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
          'assets/images/splash_logo.png',
          width: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
