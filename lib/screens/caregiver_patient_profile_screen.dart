import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Profile Screen  (Caregiver's view of a patient)
//  Figma node: 507-190
//  Reached from a notification about a patient, the schedule
//  screen, or the bookings screen — anywhere a booking tile names
//  a specific patient.
//
//  Figma's mock has an "edit" pencil badge on the avatar and a
//  settings gear in the header — both copied from the patient's
//  own profile template; a caregiver can't edit another patient's
//  photo or settings, so both are dropped. The phone number next
//  to the email is dropped too — patients only ever have a name
//  and email on file, no phone field exists anywhere in this data
//  model. Family members show a chevron instead of a "Primary"
//  badge for the same reason: `addFamilyMember` never records a
//  primary flag or a separate phone number (the "contact" the
//  patient typed in is stored as the member's name).
// ─────────────────────────────────────────────────────────────
class CaregiverPatientProfileScreen extends StatefulWidget {
  const CaregiverPatientProfileScreen({super.key});

  @override
  State<CaregiverPatientProfileScreen> createState() => _CaregiverPatientProfileScreenState();
}

class _CaregiverPatientProfileScreenState extends State<CaregiverPatientProfileScreen> {
  static const Color _bg = Color(0xFFF5EEDE);
  static const Color _titleGreen = Color(0xFF0F3D2E);
  static const Color _nameDark = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _badgeBg = Color(0xFF0F3D2E);
  static const Color _badgeText = Color(0xFF22C55E);
  static const Color _cardBg = Color.fromRGBO(168, 156, 126, 0.47);
  static const Color _cardLabel = Color(0xFF302B20);
  static const Color _rowLabel = Color(0xFF7C7972);
  static const Color _rowValue = Color(0xFF514B3D);
  static const Color _requirementsCardBg = Color(0xFFD1C7B1);
  static const Color _requirementsLabel = Color.fromRGBO(0, 0, 0, 0.49);
  static const Color _requirementsValue = Color(0xFF313131);
  static const Color _requirementsDivider = Color.fromRGBO(110, 95, 62, 0.37);
  static const Color _familyDivider = Color.fromRGBO(0, 0, 0, 0.13);
  static const Color _journeyBg = Color(0xFF1F3048);
  static const Color _journeySub = Color(0xFF858E9B);

  bool _didReadArgs = false;
  Map<String, dynamic> _args = {};
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) _args = Map<String, dynamic>.from(args);
    _loadProfile();
  }

  String? get _patientUid => _args['patientUid'] as String?;

  Future<void> _loadProfile() async {
    final uid = _patientUid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await PatientService.getPatientProfile(uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  String get _name => (_profile?['name'] as String?)?.trim().isNotEmpty == true ? _profile!['name'] as String : 'Patient';

  String _initials() {
    final trimmed = _name.trim();
    if (trimmed.isEmpty || trimmed == 'Patient') return '?';
    return trimmed.split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _titleGreen))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 22, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _titleGreen, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text('Patient profile', style: TextStyle(fontFamily: 'Open Sans', color: _titleGreen, fontSize: 20, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildPersonalDetailsCard(),
                          const SizedBox(height: 24),
                          const Text('Care requirements', style: TextStyle(fontFamily: 'Open Sans', color: _cardLabel, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          _buildCareRequirementsCard(),
                          const SizedBox(height: 24),
                          const Text('Family Members', style: TextStyle(fontFamily: 'Open Sans', color: _cardLabel, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _buildFamilyMembers(),
                          const SizedBox(height: 20),
                          _buildCareJourneyCard(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final photoUrl = _profile?['photoUrl'] as String?;
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromRGBO(109, 66, 117, 0.41),
            border: Border.all(color: const Color(0xFF51203B)),
          ),
          alignment: Alignment.center,
          child: photoUrl != null
              ? ClipOval(child: RemoteOrLocalImage(source: photoUrl, width: 84, height: 84))
              : Text(_initials(), style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF562D43), fontSize: 28, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        Text(_name, style: const TextStyle(fontFamily: 'Open Sans', color: _nameDark, fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          (_profile?['email'] as String?) ?? '',
          style: const TextStyle(fontFamily: 'Open Sans', color: _muted, fontSize: 13, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(999)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, color: _badgeText, size: 15),
              SizedBox(width: 5),
              Text('Patient / Family account', style: TextStyle(fontFamily: 'Open Sans', color: _badgeText, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsCard() {
    final gender = _profile?['patientGender'] as String?;
    final age = _profile?['patientAge'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PERSONAL DETAILS', style: TextStyle(fontFamily: 'Open Sans', color: _cardLabel, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          Container(
            height: 34,
            padding: const EdgeInsets.only(top: 9),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _familyDivider))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gender', style: TextStyle(fontFamily: 'Open Sans', color: _rowLabel, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                Text((gender == null || gender.isEmpty) ? 'Not set' : gender, style: const TextStyle(fontFamily: 'Open Sans', color: _rowValue, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              ],
            ),
          ),
          Container(
            height: 24,
            padding: const EdgeInsets.only(top: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Age', style: TextStyle(fontFamily: 'Open Sans', color: _rowLabel, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                Text(
                  (age == null || age.toString().isEmpty || age.toString() == '0') ? 'Not set' : age.toString(),
                  style: const TextStyle(fontFamily: 'Open Sans', color: _rowValue, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareRequirementsCard() {
    final careType = _profile?['careType'] as String?;
    final careLevel = _profile?['careLevel'] as String?;
    final city = _profile?['city'] as String?;
    final preferredGender = _profile?['preferredCaregiverGender'] as String?;
    final careTypeLabel = [
      if (careType != null && careType.isNotEmpty) careType,
      if (careLevel != null && careLevel.isNotEmpty) careLevel,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _requirementsCardBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _requirementRow('Care type', careTypeLabel.isEmpty ? 'Not set' : careTypeLabel, divider: true),
          _requirementRow('Location', (city == null || city.isEmpty) ? 'Not set' : city, divider: true),
          _requirementRow('Preferred gender', (preferredGender == null || preferredGender.isEmpty) ? 'No preference' : preferredGender, divider: false),
        ],
      ),
    );
  }

  Widget _requirementRow(String label, String value, {required bool divider}) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(top: 9, bottom: 10),
      decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: _requirementsDivider))) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Open Sans', color: _requirementsLabel, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontFamily: 'Open Sans', color: _requirementsValue, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFamilyMembers() {
    final uid = _patientUid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: PatientService.streamFamilyMembers(uid),
      builder: (context, snapshot) {
        final members = snapshot.data ?? const [];
        if (members.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFFD1C7B1), borderRadius: BorderRadius.circular(15)),
            child: const EmptyState(icon: Icons.family_restroom_rounded, message: 'No family members added.', iconColor: _rowLabel, textColor: _rowLabel),
          );
        }
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(color: const Color(0xFFD1C7B1), borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: List.generate(members.length, (i) => _familyMemberRow(members[i], isLast: i == members.length - 1)),
          ),
        );
      },
    );
  }

  Widget _familyMemberRow(Map<String, dynamic> member, {required bool isLast}) {
    final name = (member['name'] as String?)?.trim().isNotEmpty == true ? member['name'] as String : 'Family member';
    final relation = (member['relation'] as String?) ?? '';
    final initials = name.trim().isEmpty ? '?' : name.trim().split(RegExp(r'\s+')).map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: _familyDivider))),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
            ),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF3B2406), fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
                if (relation.isNotEmpty)
                  Text(relation, style: const TextStyle(fontFamily: 'Open Sans', color: _rowLabel, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _rowLabel, size: 20),
        ],
      ),
    );
  }

  Widget _buildCareJourneyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/care-journal',
        arguments: {
          'patientUid': _patientUid,
          'patientName': _name,
          'careType': _args['careType'],
          'startDate': _args['startDate'],
          'startTime': _args['startTime'],
          'endTime': _args['endTime'],
        },
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _journeyBg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
        ),
        child: Row(
          children: [
            const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 25),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('View care journey', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('Daily notes, vitals and activities', style: TextStyle(fontFamily: 'Open Sans', color: _journeySub, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
