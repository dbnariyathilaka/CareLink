import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/starting_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/account_created_screen.dart';
import 'screens/patient_onboarding1_screen.dart';
import 'screens/patient_onboarding2_screen.dart';
import 'screens/patient_onboarding3_screen.dart';
import 'screens/patient_onboarding4_screen.dart';
import 'screens/patient_family_details_screen.dart';
import 'screens/patient_dashboard_screen.dart';
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
import 'screens/caregiver_onboarding6_screen.dart';
import 'screens/caregiver_registration_success_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/send_request_screen.dart';
import 'screens/schedule_care_screen.dart';
import 'screens/confirm_booking_screen.dart';
import 'screens/patient_profile_screen.dart';
import 'screens/care_circle_screen.dart';
import 'screens/edit_care_requirements_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/patient_chat_screen.dart';
import 'screens/track_caregiver_screen.dart';
import 'screens/caregiver_messages_screen.dart';
import 'screens/caregiver_chat_screen.dart';
import 'screens/patient_settings_screen.dart';
import 'screens/caregiver_schedule_screen.dart';
import 'screens/caregiver_directions_screen.dart';
import 'screens/caregiver_patient_profile_screen.dart';
import 'screens/care_journal_screen.dart';
import 'screens/caregiver_own_profile_screen.dart';
import 'screens/caregiver_earnings_screen.dart';
import 'screens/caregiver_reviews_screen.dart';
import 'screens/caregiver_edit_profile_screen.dart';
import 'screens/caregiver_notifications_screen.dart';
import 'screens/caregiver_settings_screen.dart';
import 'screens/forgot_password_step1_screen.dart';
import 'screens/forgot_password_email_sent_screen.dart';
import 'screens/forgot_password_reset_success_screen.dart';
import 'screens/location_selection_screen.dart';
import 'screens/map_selection_screen.dart';
import 'screens/advanced_match_send_request_screen.dart';
import 'screens/qualifications_selection_screen.dart';
import 'screens/qualifications_intro_screen.dart';
import 'screens/matching_analysis_screen.dart';
import 'screens/advanced_match_results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebase_core.Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        '/': (context) => const StartingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/register': (context) => const RegisterScreen(),
        '/account-created': (context) => const AccountCreatedScreen(),
        '/patient-onboarding-1': (context) => const PatientOnboarding2Screen(),
        '/patient-onboarding-2': (context) => const PatientOnboarding1Screen(),
        '/patient-onboarding-3': (context) => const PatientOnboarding3Screen(),
        '/patient-onboarding-4': (context) => const PatientOnboarding4Screen(),
        '/patient-family-details': (context) =>
            const PatientFamilyDetailsScreen(),
        '/patient-dashboard': (context) => const PatientDashboardScreen(),
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
        '/caregiver-onboarding-6': (context) =>
            const CaregiverOnboarding6Screen(),
        '/caregiver-registration-success': (context) =>
            const CaregiverRegistrationSuccessScreen(),
        '/caregiver-dashboard': (context) => const CaregiverDashboardScreen(),
        '/send-request': (context) => const SendRequestScreen(),
        '/advanced-match-send-request': (context) =>
            const AdvancedMatchSendRequestScreen(),
        '/schedule-care': (context) => const ScheduleCareScreen(),
        '/location-selection': (context) => const LocationSelectionScreen(),
        '/map-selection': (context) => const MapSelectionScreen(),
        '/qualifications-intro': (context) => const QualificationsIntroScreen(),
        '/qualifications-selection': (context) =>
            const QualificationsSelectionScreen(),
        '/matching-analysis': (context) => const MatchingAnalysisScreen(),
        '/advanced-match-results': (context) =>
            const AdvancedMatchResultsScreen(),
        '/confirm-booking': (context) => const ConfirmBookingScreen(),
        '/patient-profile': (context) => const PatientProfileScreen(),
        '/care-circle': (context) => const CareCircleScreen(),
        '/edit-care-requirements': (context) =>
            const EditCareRequirementsScreen(),
        '/messages': (context) => const MessagesScreen(),
        '/chat': (context) => const PatientChatScreen(),
        '/track-caregiver': (context) => const TrackCaregiverScreen(),
        '/settings': (context) => const PatientSettingsScreen(),
        '/caregiver-schedule': (context) => const CaregiverScheduleScreen(),
        '/caregiver-directions': (context) => const CaregiverDirectionsScreen(),
        '/caregiver-patient-profile': (context) => const CaregiverPatientProfileScreen(),
        '/care-journal': (context) => const CareJournalScreen(),
        '/caregiver-own-profile': (context) =>
            const CaregiverOwnProfileScreen(),
        '/caregiver-earnings': (context) => const CaregiverEarningsScreen(),
        '/caregiver-reviews': (context) => const CaregiverReviewsScreen(),
        '/caregiver-edit-profile': (context) =>
            const CaregiverEditProfileScreen(),
        '/caregiver-notifications': (context) =>
            const CaregiverNotificationsScreen(),
        '/caregiver-settings': (context) => const CaregiverSettingsScreen(),
        '/caregiver-messages': (context) => const CaregiverMessagesScreen(),
        '/caregiver-chat': (context) => const CaregiverChatScreen(),
        '/forgot-password': (context) => const ForgotPasswordStep1Screen(),
        '/forgot-password-email-sent': (context) =>
            const ForgotPasswordEmailSentScreen(),
        '/forgot-password-reset-success': (context) =>
            const ForgotPasswordResetSuccessScreen(),
      },
    );
  }
}
