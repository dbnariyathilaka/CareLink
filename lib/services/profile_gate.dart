import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'caregiver_service.dart';
import 'patient_service.dart';
import 'profile_completeness_service.dart';
import '../widgets/incomplete_profile_dialog.dart';

/// Call at the top of any action that requires a complete patient profile
/// (matching, sending a caregiver request). Returns true and does nothing
/// if the profile is complete; otherwise shows a popup naming what's
/// missing and returns false, so the caller can bail out of the action.
Future<bool> ensurePatientProfileComplete(BuildContext context) async {
  final uid = AuthService.currentUser?.uid;
  if (uid == null) return true; // not signed in — an unrelated problem

  final profile = await PatientService.getPatientProfile(uid);
  final result = evaluatePatientProfile(profile);
  if (result.isComplete) return true;

  if (!context.mounted) return false;
  if (result.neverOnboarded) {
    await showIncompleteProfileDialog(
      context,
      title: "Your profile setup isn't finished",
      missingSections: const [],
      buttonLabel: 'Continue setup',
      buttonRoute: '/patient-onboarding-1',
    );
  } else {
    await showIncompleteProfileDialog(
      context,
      title: 'Finish your care requirements first',
      missingSections: result.missingSections,
      buttonLabel: 'Complete care requirements',
      buttonRoute: '/edit-care-requirements',
    );
  }
  return false;
}

/// Call at the top of any action that requires a complete caregiver profile
/// (accepting a job). Returns true and does nothing if the profile is
/// complete; otherwise shows a popup naming what's missing and returns
/// false, so the caller can bail out of the action.
Future<bool> ensureCaregiverProfileComplete(BuildContext context) async {
  final uid = AuthService.currentUser?.uid;
  if (uid == null) return true; // not signed in — an unrelated problem

  final profile = await CaregiverService.getCaregiverProfile(uid);
  final onboardingComplete = await AuthService.isCaregiverOnboardingComplete(uid);
  final result = evaluateCaregiverProfile(profile, onboardingComplete: onboardingComplete);
  if (result.isComplete) return true;

  if (!context.mounted) return false;
  if (result.neverOnboarded) {
    await showIncompleteProfileDialog(
      context,
      title: "Your caregiver profile isn't finished",
      missingSections: const [],
      buttonLabel: 'Continue setup',
      buttonRoute: '/caregiver-onboarding-1',
    );
  } else if (result.missingSections.isNotEmpty) {
    await showIncompleteProfileDialog(
      context,
      title: 'Finish your caregiver profile first',
      missingSections: result.missingSections,
      buttonLabel: 'Complete profile',
      buttonRoute: '/caregiver-edit-profile',
    );
  } else {
    // Every tracked section has data, but onboardingComplete is still
    // false — they stalled on photo/police-clearance/terms, steps
    // caregiver-edit-profile can't fix. Send them back into the wizard.
    await showIncompleteProfileDialog(
      context,
      title: "Your caregiver profile isn't finished",
      missingSections: const [],
      buttonLabel: 'Continue setup',
      buttonRoute: '/caregiver-onboarding-1',
    );
  }
  return false;
}
