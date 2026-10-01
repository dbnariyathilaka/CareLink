// Canonical "what kind of care" categories a patient can request
// (patient_onboarding1_screen.dart) and a caregiver can declare they serve
// (caregiver_onboarding2_screen.dart / caregiver_edit_profile_screen.dart) —
// a caregiver's `careCategory` must exactly match the patient's `careType`
// for both matching algorithms (MatchingService, OnboardingMatchingService)
// to consider them eligible. Shared here so every screen and both matching
// services stay on the same vocabulary.
const List<String> careCategories = [
  'Elder care',
  'Disability care',
  'Post-surgery care',
  'Chronic illness care',
  'Child care',
];

// Canonical caregiving skills a patient can require (multiple) and a
// caregiver can declare they have (multiple) — a caregiver must have EVERY
// skill the patient asked for to be eligible, not just an overlap. Shared
// the same way as careCategories above.
const List<String> careSkills = [
  'Feeding assistance',
  'Mobility assistance',
  'Personal hygiene assistance',
  'Medication management',
  'Basic first aid',
];
