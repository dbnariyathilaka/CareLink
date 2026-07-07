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
import 'screens/patient_onboarding4_screen.dart';
import 'screens/patient_dashboard_screen.dart';
import 'screens/top_matches_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/caregiver_profile_screen.dart';
import 'screens/add_review_screen.dart';
import 'screens/my_bookings_screen.dart';
import 'screens/patient_search_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/caregiver_onboarding1_screen.dart';
import 'screens/caregiver_onboarding2_screen.dart';
import 'screens/caregiver_onboarding3_screen.dart';
import 'screens/caregiver_onboarding4_screen.dart';
import 'screens/caregiver_onboarding5_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/send_request_screen.dart';
import 'screens/schedule_care_screen.dart';
import 'screens/confirm_booking_screen.dart';

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
        '/patient-onboarding-4': (context) => const PatientOnboarding4Screen(),
        '/patient-dashboard': (context) => const PatientDashboardScreen(),
        '/top-matches': (context) => const TopMatchesScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/caregiver-profile': (context) => const CaregiverProfileScreen(),
        '/add-review': (context) => const AddReviewScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),
        '/search': (context) => const PatientSearchScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/caregiver-onboarding-1': (context) =>
            const CaregiverOnboarding1Screen(),
        '/caregiver-onboarding-2': (context) =>
            const CaregiverOnboarding2Screen(),
        '/caregiver-onboarding-3': (context) =>
            const CaregiverOnboarding3Screen(),
        '/caregiver-onboarding-4': (context) =>
            const CaregiverOnboarding4Screen(),
        '/caregiver-onboarding-5': (context) =>
            const CaregiverOnboarding5Screen(),
        '/caregiver-dashboard': (context) => const CaregiverDashboardScreen(),
        '/send-request': (context) => const SendRequestScreen(),
        '/schedule-care': (context) => const ScheduleCareScreen(),
        '/confirm-booking': (context) => const ConfirmBookingScreen(),
      },
    );
  }
}
