import 'package:flutter/material.dart';
import '../services/patient_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  "You've been invited to a care circle" popup — shown right after sign-in
//  (see FamilyAccessService.checkAndPromptPendingInvites) whenever the
//  signed-in account's email matches a real, pending
//  patientProfiles/{uid}/familyMembers invite. Same visual language as
//  incomplete_profile_dialog.dart. Accepting performs the real Firestore
//  writes (PatientService.acceptFamilyInvite) that grant delegated access —
//  this isn't cosmetic like the old "Send invite" flow was.
// ─────────────────────────────────────────────────────────────────────────────

/// Shows one prompt per pending invite in [invites], in order. Returns the
/// uid of any patient whose invite was accepted here (the last one, if
/// several were accepted), so the caller can route straight to that
/// patient's Family Access view instead of a generic list when there's
/// exactly one.
Future<String?> showFamilyInvitePrompts(
  BuildContext context, {
  required List<Map<String, dynamic>> invites,
  required String linkedUid,
}) async {
  String? lastAcceptedPatientUid;
  for (final invite in invites) {
    if (!context.mounted) break;
    final accepted = await _showSingleInvitePrompt(context, invite: invite, linkedUid: linkedUid);
    if (accepted) lastAcceptedPatientUid = invite['patientUid'] as String?;
  }
  return lastAcceptedPatientUid;
}

Future<bool> _showSingleInvitePrompt(
  BuildContext context, {
  required Map<String, dynamic> invite,
  required String linkedUid,
}) async {
  final patientUid = invite['patientUid'] as String;
  final memberId = invite['memberId'] as String;
  final role = (invite['role'] as String?) ?? 'Viewer';
  final relation = (invite['relation'] as String?) ?? 'family member';
  final patientName = (invite['patientName'] as String?)?.trim();
  final displayName = (patientName == null || patientName.isEmpty) ? 'a patient' : patientName;
  final roleDescription = role == 'Editor' ? 'Book, pay & message caregivers' : 'See schedule & journal only';

  bool accepted = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color.fromRGBO(0, 0, 0, 0.72),
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF1F3554),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 24)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diversity_3_rounded, color: Color(0xFF7EC8E3), size: 56),
            const SizedBox(height: 16),
            Text(
              "You've been invited to $displayName's care circle",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFFF8FAFC),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'As $relation, with $role access — $roleDescription.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFFB5ADA2),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: const Color(0xFF4ADE80),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    try {
                      await PatientService.acceptFamilyInvite(
                        memberId: memberId,
                        patientUid: patientUid,
                        linkedUid: linkedUid,
                        role: role,
                        patientName: displayName,
                      );
                      accepted = true;
                    } catch (_) {
                      // Leave accepted=false; the invite stays pending and
                      // will be offered again next sign-in.
                    }
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'Accept',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF06402B), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                try {
                  await PatientService.declineFamilyInvite(memberId: memberId, patientUid: patientUid);
                } catch (_) {}
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text(
                'Decline',
                style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFFB5ADA2), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return accepted;
}
