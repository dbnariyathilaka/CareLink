import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/care_journal_service.dart';
import '../services/patient_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Family Access Home — a delegated family member's view of one patient's
//  care, scoped by the real role they were granted (Editor/Viewer) on
//  acceptance (see PatientService.acceptFamilyInvite / firestore.rules'
//  familyLinks checks). Both roles get read access to the patient's basic
//  info, bookings and care journal; only Editor gets the "Book care" action,
//  which reuses the existing booking flow end-to-end with
//  onBehalfOfPatientUid threaded through so the real booking is created
//  under the patient's own uid (see confirm_booking_screen.dart).
//
//  Messaging and payment on the patient's behalf are a deliberate follow-up,
//  not built here — see the plan this screen was built from.
// ─────────────────────────────────────────────────────────────────────────────
class FamilyAccessHomeScreen extends StatefulWidget {
  const FamilyAccessHomeScreen({super.key});

  @override
  State<FamilyAccessHomeScreen> createState() => _FamilyAccessHomeScreenState();
}

class _FamilyAccessHomeScreenState extends State<FamilyAccessHomeScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF06402B);
  static const Color patientCardBg = Color.fromRGBO(171, 144, 137, 0.75);
  static const Color patientNameColor = Color(0xFF6C3E2A);
  static const Color sectionLabel = Color(0xFF58614B);
  static const Color cardBg = Color.fromRGBO(177, 162, 143, 0.55);
  static const Color cardBorder = Color(0xFF9E8E79);
  static const Color cardTitle = Color(0xFF44331C);
  static const Color cardSub = Color.fromRGBO(68, 51, 28, 0.65);
  static const Color editorAccent = Color(0xFF223A5C);

  bool _loadedArgs = false;
  String _patientUid = '';
  String _patientName = 'Patient';
  String _role = 'Viewer';
  Map<String, dynamic>? _patientProfile;
  bool _loadingProfile = true;

  bool get _isEditor => _role == 'Editor';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    setStatusBarStyle(Brightness.dark);
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _patientUid = (args['patientUid'] as String?) ?? '';
      _patientName = (args['patientName'] as String?)?.trim().isNotEmpty == true
          ? args['patientName'] as String
          : 'Patient';
      _role = (args['role'] as String?) ?? 'Viewer';
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_patientUid.isEmpty) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }
    final profile = await PatientService.getPatientProfile(_patientUid);
    if (!mounted) return;
    setState(() {
      _patientProfile = profile;
      _loadingProfile = false;
    });
  }

  void _bookCare() {
    Navigator.pushNamed(
      context,
      '/send-request',
      arguments: {
        'onBehalfOfPatientUid': _patientUid,
        'onBehalfOfPatientName': _patientName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_patientProfile?['name'] as String?)?.trim();
    final displayName = (name == null || name.isEmpty) ? _patientName : name;
    final age = _patientProfile?['age'];
    final bio = (_patientProfile?['bio'] as String?)?.trim();
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Open Sans', color: titleGreen, fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: titleGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _role.toUpperCase(),
                      style: const TextStyle(fontFamily: 'Inter', color: titleGreen, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingProfile
                  ? const Center(child: CircularProgressIndicator(color: titleGreen))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: patientCardBg, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Text(initials, style: const TextStyle(color: patientNameColor, fontWeight: FontWeight.w700, fontSize: 20))),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        age != null ? '$displayName · $age' : displayName,
                                        style: const TextStyle(fontFamily: 'Open Sans', color: patientNameColor, fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      if (bio != null && bio.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(76, 59, 52, 0.81), fontSize: 12.5)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isEditor) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: editorAccent,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: _bookCare,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text(
                                      'Book care',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Text('BOOKINGS', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          _buildBookingsList(),
                          const SizedBox(height: 22),
                          const Text('CARE JOURNAL', style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          _buildJournalList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: BookingService.streamBookingsForPatient(_patientUid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(color: titleGreen)));
        }
        final bookings = snap.data!;
        if (bookings.isEmpty) return _emptyCard('No bookings yet.');
        return Column(
          children: bookings.take(10).map((b) {
            final caregiverName = (b['caregiverName'] as String?) ?? 'Caregiver';
            final status = (b['status'] as String?) ?? 'requested';
            final careType = (b['careType'] as String?) ?? '';
            final startDate = (b['startDate'] as String?) ?? '';
            final startTime = (b['startTime'] as String?) ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(caregiverName, style: const TextStyle(fontFamily: 'Open Sans', color: cardTitle, fontSize: 13.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          [careType, startDate, startTime].where((s) => s.isNotEmpty).join(' · '),
                          style: const TextStyle(fontFamily: 'Open Sans', color: cardSub, fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Text(status, style: const TextStyle(fontFamily: 'Inter', color: cardSub, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildJournalList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: CareJournalService.streamEntries(_patientUid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator(color: titleGreen)));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _emptyCard('No journal entries yet.');
        return Column(
          children: docs.take(10).map((d) {
            final data = d.data();
            final text = (data['text'] as String?) ?? '';
            final category = (data['category'] as String?) ?? 'Note';
            final authorName = (data['authorName'] as String?) ?? 'Caregiver';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$category · $authorName', style: const TextStyle(fontFamily: 'Open Sans', color: cardTitle, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(fontFamily: 'Open Sans', color: cardSub, fontSize: 12.5, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
      child: Text(message, style: const TextStyle(fontFamily: 'Open Sans', color: cardSub, fontSize: 12.5, fontWeight: FontWeight.w500)),
    );
  }
}
