import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/family_invite_prompt_dialog.dart';
import 'auth_service.dart';
import 'patient_service.dart';

/// Orchestrates the delegated-family-access UI flow — the pieces that need
/// a BuildContext, on top of PatientService's plain Firestore reads/writes.
/// Kept separate from PatientService (which stays a data-only service, no
/// Flutter/UI imports) the same way the rest of this app splits services
/// from screens.
class FamilyAccessService {
  FamilyAccessService._();

  /// Checks whether the signed-in account's email matches any pending
  /// family-circle invite and, if so, prompts accept/decline for each in
  /// turn. Called right after sign-in/registration (login_screen.dart,
  /// starting_screen.dart, account_created_screen.dart) and again, as a
  /// cheap no-op safety net, from the patient/caregiver dashboards' own
  /// initState.
  ///
  /// Returns the uid of a patient whose invite was just accepted here, so
  /// the caller can route straight to that patient's Family Access view
  /// when there's exactly one — or null if nothing was accepted (including
  /// when there was nothing pending at all).
  static Future<String?> checkAndPromptPendingInvites(
    BuildContext context,
    String? email,
  ) async {
    final uid = AuthService.currentUser?.uid;
    if (email == null || email.trim().isEmpty || uid == null) return null;

    List<Map<String, dynamic>> invites;
    try {
      invites = await PatientService.fetchPendingInvitesForEmail(email);
    } catch (_) {
      return null;
    }
    if (invites.isEmpty || !context.mounted) return null;

    return showFamilyInvitePrompts(context, invites: invites, linkedUid: uid);
  }

  /// One-shot read of every patient this account already has accepted
  /// delegated access to — used to decide routing for a roleless account
  /// (straight to Family Circles instead of role selection/welcome) and by
  /// family_circles_screen.dart's initial load.
  static Future<List<Map<String, dynamic>>> fetchAcceptedFamilyLinks(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('familyLinks')
        .doc(uid)
        .collection('patients')
        .get();
    return snap.docs.map((d) => {'patientUid': d.id, ...d.data()}).toList();
  }
}
