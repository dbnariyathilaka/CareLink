import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/family_access_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Family Circles — every patient this account has accepted delegated
//  family access to (patient_service.dart's familyLinks). The landing point
//  for a roleless "family-only" account after login/registration, and
//  reachable from a patient/caregiver's own dashboard once they've accepted
//  at least one invite of their own.
// ─────────────────────────────────────────────────────────────────────────────
class FamilyCirclesScreen extends StatefulWidget {
  const FamilyCirclesScreen({super.key});

  @override
  State<FamilyCirclesScreen> createState() => _FamilyCirclesScreenState();
}

class _FamilyCirclesScreenState extends State<FamilyCirclesScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF06402B);
  static const Color cardBg = Color.fromRGBO(135, 159, 133, 0.49);
  static const Color cardBorder = Color(0xFF4E6A2D);
  static const Color cardName = Color(0xFF27470F);
  static const Color cardSub = Color.fromRGBO(65, 74, 50, 0.68);
  static const Color roleBadgeBg = Color(0xFF4E5E34);
  static const Color roleBadgeText = Color(0xFF99B172);

  bool _loading = true;
  List<Map<String, dynamic>> _links = const [];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final links = await FamilyAccessService.fetchAcceptedFamilyLinks(uid);
    if (!mounted) return;
    setState(() {
      _links = links;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  const Text(
                    'Your care circles',
                    style: TextStyle(fontFamily: 'Open Sans', color: titleGreen, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                'Patients whose care you have been given access to.',
                style: TextStyle(fontFamily: 'Inter', color: Color.fromRGBO(6, 64, 43, 0.65), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: titleGreen))
                  : _links.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              "You don't have access to any care circles yet. Ask a patient to invite you by your account email.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: titleGreen.withValues(alpha: 0.65),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          itemCount: _links.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _buildCard(_links[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> link) {
    final patientUid = link['patientUid'] as String;
    final patientName = (link['patientName'] as String?)?.trim();
    final displayName = (patientName == null || patientName.isEmpty) ? 'Patient' : patientName;
    final role = (link['role'] as String?) ?? 'Viewer';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/family-access-home',
        arguments: {'patientUid': patientUid, 'patientName': displayName, 'role': role},
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cardBorder,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontFamily: 'Open Sans', color: cardName, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    role == 'Editor' ? 'Can book & pay' : 'View only',
                    style: const TextStyle(fontFamily: 'Open Sans', color: cardSub, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: roleBadgeBg, borderRadius: BorderRadius.circular(999)),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(fontFamily: 'Inter', color: roleBadgeText, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: cardName),
          ],
        ),
      ),
    );
  }
}
