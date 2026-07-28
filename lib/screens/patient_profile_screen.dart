import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Patient My Profile Screen
//  Figma node: 262-1634
//
//  "Family Members" and "Care circle" are new concepts this design
//  introduces — no add/manage flow exists for either yet (those
//  screens are coming separately), so both sections render honestly
//  empty today instead of showing fabricated example people.
// ─────────────────────────────────────────────────────────────
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Figma colour tokens ──────────────────────────────────
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF0F3D2E);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color nameColor = Color(0xFF1E293B);
  static const Color emailColor = Color(0xFF94A3B8);
  static const Color badgeText = Color(0xFF22C55E);
  static const Color avatarBg = Color.fromRGBO(109, 66, 117, 0.41);
  static const Color avatarBorder = Color(0xFF51203B);
  static const Color avatarInitials = Color(0xFF562D43);
  static const Color editBadgeBg = Color(0xFF3B4844);
  static const Color personalCardBg = Color.fromRGBO(168, 156, 126, 0.47);
  static const Color personalLabel = Color(0xFF302B20);
  static const Color personalRowLabel = Color(0xFF7C7972);
  static const Color personalRowValue = Color(0xFF514B3D);
  static const Color personalDivider = Color.fromRGBO(0, 0, 0, 0.13);
  static const Color statCardBg = Color(0xFF313131);
  static const Color statCardBorder = Color(0xFF334155);
  static const Color statValue = Color(0xFFF8FAFC);
  static const Color statLabel = Color(0xFFF2F2F2);
  static const Color familyCardBg = Color(0xFFD1C7B1);
  static const Color familySub = Color(0xFF736A57);
  static const Color primaryBadgeBg = Color(0xFFCAAB8C);
  static const Color primaryBadgeText = Color(0xFF6A441E);
  static const Color addLink = Color(0xFFC9321B);
  static const Color careCircleBg = Color(0xFF164939);
  static const Color careCircleBorder = Color(0xFF3F9E80);
  static const Color careCircleMuted = Color(0xFFBAAF99);
  static const Color requirementsCardBg = Color(0xFFD1C7B1);
  static const Color requirementsDivider = Color.fromRGBO(110, 95, 62, 0.37);
  static const Color requirementsLabel = Color.fromRGBO(0, 0, 0, 0.49);
  static const Color requirementsValue = Color(0xFF313131);
  static const Color editReqLink = Color(0xFF584A2A);
  static const Color favCardBg = Color(0xFF989A99);
  static const Color favAvatarBg = Color.fromRGBO(35, 106, 84, 0.57);
  static const Color favAvatarText = Color(0xFF0B1A16);
  static const Color heartRed = Color(0xFF992B2B);
  static const Color menuCardBg = Color(0xFF3B4844);
  static const Color menuBorder = Color(0xFF334155);
  static const Color menuAmber = Color(0xFFFBBC05);
  static const Color menuChevron = Color(0xFF64748B);
  static const Color logoutBorder = Color(0xFF4E4513);
  static const Color logoutText = Color(0xFF81622E);
  static const Color navMatchLabel = Color(0xFFFFA722);

  bool _loading = true;
  String _name = '';
  String _email = '';
  Map<String, dynamic>? _patientProfile;
  List<Map<String, dynamic>> _favoriteCaregivers = [];
  List<Map<String, dynamic>> _familyMembers = [];
  int? _bookingsCount;

  late final AnimationController _matchIconController;
  late final Animation<double> _matchIconRotation;

  @override
  void initState() {
    super.initState();
    _matchIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _matchIconRotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 2),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
    ]).animate(_matchIconController);
    _loadProfile();
  }

  @override
  void dispose() {
    _matchIconController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final results = await Future.wait([
      AuthService.getUserProfile(user.uid),
      PatientService.getPatientProfile(user.uid),
      PatientService.getFavoriteCaregiverIds(user.uid),
      PatientService.getFamilyMembers(user.uid),
      BookingService.streamBookingsForPatient(user.uid).first,
    ]);
    final userProfile = results[0] as Map<String, dynamic>?;
    final patientProfile = results[1] as Map<String, dynamic>?;
    final favoriteIds = results[2] as List<String>;
    final familyMembers = results[3] as List<Map<String, dynamic>>;
    final bookings = results[4] as List<Map<String, dynamic>>;

    final favorites = <Map<String, dynamic>>[];
    for (final id in favoriteIds) {
      final profile = await CaregiverService.getCaregiverProfile(id);
      if (profile != null) favorites.add({...profile, 'id': id});
    }

    if (patientProfile != null) {
      AppState.careType.value =
          (patientProfile['careType'] as String?) ?? AppState.careType.value;
      AppState.careSchedule.value =
          (patientProfile['careLevel'] as String?) ?? AppState.careSchedule.value;
      AppState.careLocation.value =
          (patientProfile['city'] as String?) ?? AppState.careLocation.value;
      AppState.preferredGender.value =
          (patientProfile['preferredCaregiverGender'] as String?) ??
              AppState.preferredGender.value;
    }

    if (!mounted) return;
    AppState.hydratePatientPhoto(patientProfile?['photoUrl'] as String?);
    setState(() {
      _name = (userProfile?['name'] as String?) ?? '';
      _email = (userProfile?['email'] as String?) ?? user.email ?? '';
      _patientProfile = patientProfile;
      _favoriteCaregivers = favorites;
      _familyMembers = familyMembers;
      _bookingsCount = bookings.length;
      _loading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final picked = await pickImageOrDocument(
      context,
      allowPdf: false,
      allowRemove: AppState.profileImagePath.value != null,
      onRemove: () => AppState.profileImagePath.value = null,
    );
    if (picked == null || !mounted) return;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.profilePhotoPath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      AppState.profileImagePath.value = url;
      await PatientService.savePatientProfile(uid: uid, data: {'photoUrl': url});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo. Please try again.')),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: darkGreen))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeaderSection(context),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPersonalDetailsCard(),
                                const SizedBox(height: 12),
                                _buildStatsRow(),
                                const SizedBox(height: 20),
                                _buildFamilyMembersSection(),
                                const SizedBox(height: 20),
                                _buildCareCircleSection(),
                                const SizedBox(height: 20),
                                _buildSectionLabel('Care requirements'),
                                const SizedBox(height: 8),
                                _buildCareRequirementsCard(context),
                                const SizedBox(height: 20),
                                _buildSectionLabel('Favourite caregivers'),
                                const SizedBox(height: 8),
                                _buildFavouriteCard(context),
                                const SizedBox(height: 12),
                                _menuRow(
                                  icon: Icons.chat_bubble_rounded,
                                  label: 'Messages',
                                  onTap: () => Navigator.pushNamed(context, '/messages'),
                                ),
                                const SizedBox(height: 12),
                                _menuRow(
                                  icon: Icons.shield_rounded,
                                  label: 'Privacy policy',
                                  onTap: () => _showComingSoon('Privacy policy'),
                                ),
                                const SizedBox(height: 12),
                                _menuRow(
                                  icon: Icons.help_rounded,
                                  label: 'Help & FAQ',
                                  onTap: () => _showComingSoon('Help & FAQ'),
                                ),
                                const SizedBox(height: 16),
                                _buildLogoutButton(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header: title + avatar + name + badge ────────────────
  Widget _buildHeaderSection(BuildContext context) {
    final imagePath = AppState.profileImagePath.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 18, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My profile',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Icon(
                  Icons.settings_rounded,
                  color: Colors.black.withValues(alpha: 0.43),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarBg,
                    border: Border.all(color: avatarBorder),
                  ),
                  child: imagePath != null
                      ? ClipOval(
                          child: RemoteOrLocalImage(
                            source: imagePath,
                            width: 84,
                            height: 84,
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: avatarInitials,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: editBadgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: badgeText,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _name.isEmpty ? 'Unnamed patient' : _name,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: nameColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _email.isEmpty ? 'No email on file' : _email,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: emailColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: titleGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: badgeText, size: 15),
                SizedBox(width: 5),
                Text(
                  'Patient / Family account',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: badgeText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials() {
    final trimmed = _name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  // ── Personal details card ─────────────────────────────────
  Widget _buildPersonalDetailsCard() {
    final gender = _patientProfile?['patientGender'] as String?;
    final age = _patientProfile?['patientAge'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: personalCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONAL DETAILS',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: personalLabel,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            height: 34,
            padding: const EdgeInsets.only(top: 9),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: personalDivider, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: personalRowLabel,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  (gender == null || gender.isEmpty) ? 'Not set' : gender,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: personalRowValue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 24,
            padding: const EdgeInsets.only(top: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Age',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: personalRowLabel,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  (age == null || age.toString().isEmpty || age.toString() == '0')
                      ? 'Not set'
                      : age.toString(),
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: personalRowValue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard(_bookingsCount?.toString() ?? '—', 'Bookings')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('—', 'Reviews given')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('${_favoriteCaregivers.length}', 'Favourite')),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statCardBorder),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  color: statValue,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: statLabel,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Open Sans',
        color: personalLabel,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Family Members section ────────────────────────────────
  Widget _buildFamilyMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Family Members'),
            GestureDetector(
              onTap: () => _showComingSoon('Adding family members'),
              child: const Text(
                'Add',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: addLink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_familyMembers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: familyCardBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const EmptyState(
              icon: Icons.family_restroom_rounded,
              message: 'No family members added yet.',
              iconColor: familySub,
              textColor: familySub,
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: familyCardBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: List.generate(_familyMembers.length, (i) {
                final member = _familyMembers[i];
                final isLast = i == _familyMembers.length - 1;
                return _familyMemberRow(member, isLast: isLast);
              }),
            ),
          ),
      ],
    );
  }

  Widget _familyMemberRow(Map<String, dynamic> member, {required bool isLast}) {
    final name = (member['name'] as String?) ?? 'Family member';
    final relation = (member['relation'] as String?) ?? '';
    final phone = (member['phone'] as String?) ?? '';
    final isPrimary = member['isPrimary'] == true;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: personalDivider, width: 1)),
            ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF3B2406),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(
                  [relation, phone].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: familySub,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: primaryBadgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Primary',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: primaryBadgeText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const Icon(Icons.chevron_right_rounded, color: familySub, size: 20),
        ],
      ),
    );
  }

  // ── Care circle section ────────────────────────────────────
  Widget _buildCareCircleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Care circle'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: careCircleBg,
            border: Border.all(color: careCircleBorder),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 30),
              const SizedBox(height: 10),
              const Text(
                'No care circle yet',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Your care circle brings family and your caregiver together "
                "once a booking is confirmed.",
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: careCircleMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _showComingSoon('Adding family members'),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Add family member',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Care requirements card ────────────────────────────────
  Widget _buildCareRequirementsCard(BuildContext context) {
    if (_patientProfile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: requirementsCardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const EmptyState(
              icon: Icons.assignment_outlined,
              message: 'Care requirements not set yet.',
              iconColor: editReqLink,
              textColor: editReqLink,
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/edit-care-requirements'),
              child: const Text(
                'Set requirements',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: editReqLink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppState.careType,
        AppState.careSchedule,
        AppState.careLocation,
        AppState.preferredGender,
      ]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: requirementsCardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _requirementRow(
                'Care type',
                '${AppState.careType.value} · ${AppState.careSchedule.value}',
                divider: true,
              ),
              _requirementRow('Location', AppState.careLocation.value, divider: true),
              _requirementRow('Preferred gender', AppState.preferredGender.value,
                  divider: false),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/edit-care-requirements'),
                child: const Text(
                  'Edit requirements',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: editReqLink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _requirementRow(String label, String value, {required bool divider}) {
    return Container(
      height: 35,
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: requirementsDivider, width: 1)))
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: requirementsLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: requirementsValue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Favourite caregiver card(s) ───────────────────────────
  Widget _buildFavouriteCard(BuildContext context) {
    if (_favoriteCaregivers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: favCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const EmptyState(
          icon: Icons.favorite_border_rounded,
          message: 'No favourite caregivers yet.',
          iconColor: Colors.black,
          textColor: Colors.black,
        ),
      );
    }
    return Column(
      children: [
        for (final caregiver in _favoriteCaregivers) ...[
          _favouriteRow(context, caregiver),
          if (caregiver != _favoriteCaregivers.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _favouriteRow(BuildContext context, Map<String, dynamic> caregiver) {
    final id = caregiver['id'] as String;
    final name = (caregiver['name'] as String?)?.trim() ?? '';
    final initials = name.isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();
    final careTypes = (caregiver['careTypes'] as List?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/caregiver-profile',
          arguments: {'caregiverId': id},
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: favCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: favAvatarBg,
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        color: favAvatarText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Unnamed caregiver' : name,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    careTypes.isEmpty ? 'No care types listed' : careTypes.join(', '),
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF313131),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final user = AuthService.currentUser;
                if (user == null) return;
                await PatientService.toggleFavorite(
                  patientUid: user.uid,
                  caregiverUid: id,
                  isFavorite: false,
                );
                setState(() {
                  _favoriteCaregivers.removeWhere((c) => c['id'] == id);
                });
              },
              child: const Icon(Icons.favorite_rounded, color: heartRed, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── Log out confirmation dialog ────────────────────────────
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: bgCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: logoutText.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: logoutText,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log out?',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleGreen,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: titleGreen.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: titleGreen.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: titleGreen.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/welcome',
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: logoutText.withValues(alpha: 0.12),
                          border: Border.all(color: logoutText.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Log out',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: logoutText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Log out button ─────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutConfirmationDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: logoutBorder, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Log out',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Open Sans',
              color: logoutText,
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: menuCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: menuBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: menuAmber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      color: menuAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right_rounded, color: menuChevron, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav (matches dashboard/bookings/notifications) ─
  Widget _buildBottomBar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        _buildBottomNav(),
        Positioned(top: -22, child: _buildMatchFab()),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', route: '/patient-dashboard'),
      (icon: Icons.search_rounded, label: 'Search', route: '/search'),
      (icon: null, label: 'Match', route: null),
      (icon: Icons.calendar_month_outlined, label: 'Booking', route: '/my-bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Notification', route: '/notifications'),
    ];
    return Container(
      width: double.infinity,
      height: 67,
      color: darkGreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];

          if (index == 2) {
            return const SizedBox(
              width: 60,
              child: Padding(
                padding: EdgeInsets.only(top: 41),
                child: Text(
                  'Match',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: navMatchLabel,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          // No tab highlighted — profile is a sub-page, not a main nav tab.
          return GestureDetector(
            onTap: item.route != null
                ? () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      item.route!,
                      (route) => route.settings.name == '/patient-dashboard',
                    )
                : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: Colors.white, size: 25),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMatchFab() {
    return GestureDetector(
      onTap: () {
        if (AppState.hasActiveMatch.value) {
          Navigator.pushNamed(context, '/advanced-match-results');
        } else {
          Navigator.pushNamed(context, '/advanced-match-send-request');
        }
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: RotationTransition(
          turns: _matchIconRotation,
          child: SvgPicture.asset(
            'assets/images/match_target_icon.svg',
            width: 65,
            height: 65,
          ),
        ),
      ),
    );
  }
}
