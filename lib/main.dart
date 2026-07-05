import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/account_details_screen.dart';
import 'screens/login_screen.dart';
import 'screens/account_created_screen.dart';
import 'screens/patient_onboarding1_screen.dart';
import 'screens/patient_onboarding2_screen.dart';
import 'screens/patient_onboarding3_screen.dart';

void main() {
  runApp(const CareMatchApp());
}

class CareMatchApp extends StatelessWidget {
  const CareMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/account-details': (context) => const AccountDetailsScreen(),
        '/account-created': (context) => const AccountCreatedScreen(),
        '/patient-onboarding-1': (context) => const PatientOnboarding1Screen(),
        '/patient-onboarding-2': (context) => const PatientOnboarding2Screen(),
        '/patient-onboarding-3': (context) => const PatientOnboarding3Screen(),
      },
    );
  }
}
