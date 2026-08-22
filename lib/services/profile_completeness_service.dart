// Pure profile-completeness evaluation for patients and caregivers — no
// Firestore or Flutter imports, so this is unit-testable on its own. The
// Firestore fetch + popup orchestration lives in profile_gate.dart, which
// calls these evaluators and decides what to show the user.

bool _isBlank(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is List) return value.isEmpty;
  return false;
}

class PatientCompleteness {
  const PatientCompleteness({
    required this.neverOnboarded,
    required this.missingSections,
  });

  /// True when there's no patientProfiles doc at all, or personal details
  /// (name etc.) were never saved — i.e. the onboarding wizard's step 3
  /// never ran. There is no edit-profile screen that can fill these in, so
  /// callers should send the user back into onboarding rather than to an
  /// edit screen.
  final bool neverOnboarded;

  /// Populated only when !neverOnboarded: care-requirement fields (written
  /// together, once, by onboarding step 4) that are still blank. Editable
  /// via /edit-care-requirements.
  final List<String> missingSections;

  bool get isComplete => !neverOnboarded && missingSections.isEmpty;
}

PatientCompleteness evaluatePatientProfile(Map<String, dynamic>? profile) {
  if (profile == null ||
      (_isBlank(profile['patientName']) && _isBlank(profile['name']))) {
    return const PatientCompleteness(neverOnboarded: true, missingSections: []);
  }

  final missing = <String>[
    if (_isBlank(profile['careType'])) 'Care type',
    if (_isBlank(profile['careLevel'])) 'Care schedule',
    if (_isBlank(profile['city'])) 'Location',
  ];

  return PatientCompleteness(neverOnboarded: false, missingSections: missing);
}

class CaregiverCompleteness {
  const CaregiverCompleteness({
    required this.neverOnboarded,
    required this.missingSections,
    required this.onboardingComplete,
  });

  /// True when there's no caregiverProfiles doc at all.
  final bool neverOnboarded;

  /// Onboarding-wizard-step groupings that are missing at least one field.
  /// Editable via /caregiver-edit-profile. Deliberately excludes
  /// photo/police-clearance/certification: certification is legitimately
  /// optional for informal caregivers (see MatchingService's structural-
  /// absence handling), and photo/police-clearance have no confirmed
  /// re-upload path in the edit-profile screen, so flagging them would
  /// point the user somewhere that can't fix the problem.
  final List<String> missingSections;

  /// The existing authoritative flag (caregiverProfiles/{uid}.onboardingComplete),
  /// set only at the very end of the 6-step wizard. This — not
  /// missingSections — is what actually gates job-accepting: a caregiver
  /// can have every field in missingSections filled and still not be
  /// onboardingComplete if they stalled on photo/police-clearance/terms.
  final bool onboardingComplete;

  bool get isComplete => onboardingComplete;
}

CaregiverCompleteness evaluateCaregiverProfile(
  Map<String, dynamic>? profile, {
  required bool onboardingComplete,
}) {
  if (profile == null) {
    return CaregiverCompleteness(
      neverOnboarded: true,
      missingSections: const [],
      onboardingComplete: onboardingComplete,
    );
  }

  final missing = <String>[
    if (_isBlank(profile['gender']) ||
        _isBlank(profile['yearsExperience']) ||
        _isBlank(profile['careTypes']))
      'Basic details',
    if (_isBlank(profile['educationalQualification']) ||
        _isBlank(profile['languagesSpoken']) ||
        _isBlank(profile['skills']))
      'Qualifications & skills',
    if (_isBlank(profile['city']) || _isBlank(profile['serviceRadiusKm']))
      'Location & bio',
  ];

  return CaregiverCompleteness(
    neverOnboarded: false,
    missingSections: missing,
    onboardingComplete: onboardingComplete,
  );
}
