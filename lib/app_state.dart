// Shared in-memory app state for the patient and caregiver profile pictures.
// Using ValueNotifiers so all listening widgets rebuild automatically.
import 'package:flutter/foundation.dart';

class AppState {
  AppState._();
  static final profileImagePath         = ValueNotifier<String?>(null);
  static final caregiverProfileImagePath = ValueNotifier<String?>(null);

  // Advanced match results — true when the user has an active top-5 match list.
  // Match button routes to /advanced-match-results when true; to the wizard when false.
  static final hasActiveMatch = ValueNotifier<bool>(false);
  // Persist the last set of match args so the results screen can reload them.
  static Map<String, dynamic>? lastMatchArgs;

  // Patient care requirements — edited from the single "Edit care
  // requirements" screen and mirrored on the patient profile card.
  static final careType = ValueNotifier<String>('Elder care');
  static final careSchedule = ValueNotifier<String>('Full-time');
  static final careLocation = ValueNotifier<String>('Negombo, Western Province');
  static final preferredGender = ValueNotifier<String>('No preference');
  static final additionalCareNotes = ValueNotifier<String>('');

  // Patient identity fields — filled in during onboarding (the
  // patient-details step), written to patientProfiles/{uid} alongside the
  // care-requirement fields above.
  static final patientName = ValueNotifier<String>('');
  static final patientGenderSelf = ValueNotifier<String>('Female');
  static final patientAge = ValueNotifier<String>('');
  static final patientAddress = ValueNotifier<String>('');
  static final relationToPatient = ValueNotifier<String>('Patient');

  // The phone number provided at account-registration time (stored as
  // +94XXXXXXXXX). Used to enforce that the caregiver's reference phone
  // must be a *different* number from their own registered number.
  static final registeredPhone = ValueNotifier<String>('');

  // The registering family member's own contact details — collected on the
  // family-details step (before account registration) when someone signs up
  // on behalf of a patient. Distinct from the patientXxx fields above, which
  // describe the patient, not the person booking for them.
  static final familyMemberName = ValueNotifier<String>('');
  static final familyMemberNic = ValueNotifier<String>('');
  static final familyMemberPhone = ValueNotifier<String>('');
  static final familyMemberEmail = ValueNotifier<String>('');
  static final familyMemberAddress = ValueNotifier<String>('');

  // Accumulates data across the 6-step caregiver onboarding wizard; written
  // to Firestore (caregiverProfiles/{uid}) once, on the final step.
  static final caregiverOnboardingDraft = CaregiverOnboardingDraft();

  // Backfills a profile picture from Firestore only if nothing has been
  // picked locally yet this session — avoids a stale read clobbering a
  // just-uploaded photo.
  static void hydrateCaregiverPhoto(String? url) {
    if (caregiverProfileImagePath.value == null && url != null && url.isNotEmpty) {
      caregiverProfileImagePath.value = url;
    }
  }

  static void hydratePatientPhoto(String? url) {
    if (profileImagePath.value == null && url != null && url.isNotEmpty) {
      profileImagePath.value = url;
    }
  }
}

/// Draft profile filled in across the 6-step caregiver onboarding wizard;
/// written to Firestore (caregiverProfiles/{uid}) once, on the final step.
class CaregiverOnboardingDraft {
  String gender = 'Male';
  int yearsExperience = 5;
  Set<String> careTypes = {'Part-time', 'Full-time'};
  String nic = '';
  String referencePhone = '';
  String educationalQualification = 'Diploma';
  bool formalTraining = false;
  Set<String> languagesSpoken = {'Sinhala', 'English'};
  Set<String> skills = {
    'Mobility assistance',
    'Medication management',
    'Dementia care',
  };
  String city = 'Negombo, Western Province';
  String serviceRadius = '10 km';
  String bio = '';

  // Storage download URLs — populated as each onboarding step uploads its
  // picked file(s); empty/blank fields mean nothing was uploaded.
  String photoUrl = '';
  List<String> certificateUrls = [];
  String policeClearanceUrl = '';
  List<String> otherDocumentUrls = [];

  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'yearsExperience': yearsExperience,
      'careTypes': careTypes.toList(),
      'nic': nic,
      'referencePhone': referencePhone,
      'educationalQualification': educationalQualification,
      'formalTraining': formalTraining,
      'languagesSpoken': languagesSpoken.toList(),
      'skills': skills.toList(),
      'city': city,
      'serviceRadiusKm':
          int.tryParse(serviceRadius.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10,
      'bio': bio,
      if (photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      if (certificateUrls.isNotEmpty) 'certificateUrls': certificateUrls,
      if (policeClearanceUrl.isNotEmpty) 'policeClearanceUrl': policeClearanceUrl,
      if (otherDocumentUrls.isNotEmpty) 'otherDocumentUrls': otherDocumentUrls,
    };
  }
}
