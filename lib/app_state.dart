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
}
