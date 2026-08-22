// Maps a patient's requested care type to the caregiver `skills` values that
// satisfy it, for use by MatchingService's skill-match criterion (see
// ../services/matching_service.dart).
//
// The two questionnaires were never designed against a shared taxonomy:
// patient_onboarding1_screen.dart offers an 11-option care-type list,
// edit_care_requirements_screen.dart a different 4-option list (including
// 'Child care', aliased below to the same skill as 'Pediatric'), while
// caregiver_onboarding2_screen.dart offers its own 9-option skills list.
// Five care-type strings happen to be identical to a skill value and map to
// themselves; the rest are a judgment call about which caregiver skill
// actually addresses that care need — flagged here for product review
// rather than treated as derived fact.
const Map<String, Set<String>> careTypeSkillMap = {
  'Elder care': {'Mobility assistance', 'Medication management'},
  'Pediatric': {'Pediatric care'},
  'Child care': {'Pediatric care'},
  'Post-surgery': {'Wound care', 'Mobility assistance', 'Rehabilitation'},
  'Physical disability': {
    'Mobility assistance',
    'Rehabilitation',
    'Physiotherapy',
  },
  'Mental health': {'Mental health support'},
  'Dementia': {'Dementia care'},
  'Mobility assistance': {'Mobility assistance'},
  'Medication management': {'Medication management'},
  'Wound care': {'Wound care'},
  'Rehabilitation': {'Rehabilitation'},
  'Physiotherapy': {'Physiotherapy'},
};
