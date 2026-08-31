import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/payment_service.dart';
import '../services/storage_service.dart';
import '../widgets/caregiver_bottom_nav.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver's own "My profile" screen (Figma node 487-406)
// ─────────────────────────────────────────────────────────────
class CaregiverOwnProfileScreen extends StatefulWidget {
  const CaregiverOwnProfileScreen({super.key});

  @override
  State<CaregiverOwnProfileScreen> createState() => _CaregiverOwnProfileScreenState();
}

class _CaregiverOwnProfileScreenState extends State<CaregiverOwnProfileScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color headerBg = Color(0xFF1F3554);
  static const Color titleDark = Color(0xFF0F172A);
  static const Color sectionTitleColor = Color.fromRGBO(15, 23, 42, 0.75);

  static const Color editIconColor = Color(0xFF1A3253);

  static const Color statsCardBg = Color(0xFFCCCCC4);
  static const Color statsValueColor = Color(0xFF2F4357);

  static const Color contactCardBg = Color.fromRGBO(106, 110, 76, 0.21);
  static const Color contactIconColor = Color(0xFF73580C);
  static const Color contactTextColor = Color(0xFF2E2910);

  static const Color chipPrimaryBg = Color(0xFF223A5C);

  static const Color infoCardBg = Color.fromRGBO(78, 69, 51, 0.73);
  static const Color infoCardText = Color(0xFFFFFAF0);

  static const Color certBg = Color(0xFFF4D9BF);
  static const Color certBorder = Color(0xFF443423);
  static const Color certIconColor = Color(0xFF96730E);
  static const Color certTextColor = Color(0xFF443423);

  static const Color settingsBg = Color(0xFFD1C7B1);
  static const Color settingsBorder = Color(0xFFA09376);
  static const Color settingsIconColor = Color(0xFFBE9213);
  static const Color settingsTextColor = Color(0xFF443423);

  static const Color logoutBg = Color.fromRGBO(239, 68, 68, 0.1);
  static const Color logoutBorder = Color(0xFFE72A2A);

  bool _loading = true;
  Map<String, dynamic>? _profile;
  Stream<List<Map<String, dynamic>>>? _paymentsStream;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _paymentsStream = PaymentService.streamPaymentsForCaregiver(user.uid);

    final cgProfile = await CaregiverService.getCaregiverProfile(user.uid);
    final userDoc = await AuthService.getUserProfile(user.uid);

    if (!mounted) return;

    final merged = <String, dynamic>{
      if (userDoc != null) ...userDoc,
      if (cgProfile != null) ...cgProfile,
    };

    final name = (merged['name'] as String?)?.trim() ??
        (userDoc?['name'] as String?)?.trim() ??
        user.displayName?.trim() ??
        '';
    merged['name'] = name;

    final email = (merged['email'] as String?)?.trim() ??
        (userDoc?['email'] as String?)?.trim() ??
        user.email?.trim() ??
        '';
    merged['email'] = email;

    final phone = (merged['phone'] as String?)?.trim() ??
        (userDoc?['phone'] as String?)?.trim() ??
        AppState.registeredPhone.value;
    merged['phone'] = phone;

    AppState.hydrateCaregiverPhoto(merged['photoUrl'] as String?);

    setState(() {
      _profile = merged;
      _loading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final picked = await pickImageOrDocument(
      context,
      allowPdf: false,
      allowRemove: AppState.caregiverProfileImagePath.value != null,
      onRemove: () => AppState.caregiverProfileImagePath.value = null,
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
      AppState.caregiverProfileImagePath.value = url;
      await CaregiverService.saveCaregiverProfile(uid: uid, data: {'photoUrl': url});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo. Please try again.')),
      );
    }
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: chipPrimaryBg),
                    )
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _paymentsStream,
                      builder: (context, snapshot) {
                        final payments = snapshot.data ?? const [];
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(context),
                                const SizedBox(height: 16),
                                _buildAvatarSection(),
                                const SizedBox(height: 20),
                                _buildStatsRow(),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Earnings', actionLabel: 'View details', onAction: () {
                                  Navigator.pushNamed(context, '/caregiver-earnings');
                                }),
                                const SizedBox(height: 10),
                                _buildEarningsCard(payments),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Contact'),
                                const SizedBox(height: 10),
                                _buildContactCard(),
                                const SizedBox(height: 16),
                                _buildCareTypeBanner(),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Skills'),
                                const SizedBox(height: 10),
                                _buildSkillsWrap(),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Education & languages'),
                                const SizedBox(height: 10),
                                _buildEducationCard(),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Bio'),
                                const SizedBox(height: 10),
                                _buildBioCard(),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Certifications'),
                                const SizedBox(height: 10),
                                _buildCertificationsSection(),
                                const SizedBox(height: 20),
                                _buildSectionTitle('Settings'),
                                const SizedBox(height: 10),
                                _buildSettingsCard(context),
                                const SizedBox(height: 16),
                                _buildLogoutButton(context),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const CaregiverBottomNav(),
        ],
      ),
    );
  }

  // ── Header row: title + edit icon ────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My profile',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: titleDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.pushNamed(context, '/caregiver-edit-profile');
            _loadProfile();
          },
          child: const Icon(
            Icons.edit_outlined,
            color: editIconColor,
            size: 22,
          ),
        ),
      ],
    );
  }

  // ── Avatar + name + email + badges ────────────────────────
  Widget _buildAvatarSection() {
    final name = (_profile?['name'] as String?)?.trim() ?? '';
    final email = (_profile?['email'] as String?)?.trim() ?? '';
    final gender = (_profile?['gender'] as String?)?.trim() ?? 'Caregiver';
    final displayName = name.isNotEmpty ? name : 'Caregiver';
    final displayEmail = email.isNotEmpty ? email : 'No email provided';

    final initials = displayName.isEmpty
        ? '?'
        : displayName
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();

    return ValueListenableBuilder<String?>(
      valueListenable: AppState.caregiverProfileImagePath,
      builder: (context, imagePath, _) {
        return Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: imagePath == null
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                              )
                            : null,
                      ),
                      child: imagePath != null
                          ? ClipOval(
                              child: RemoteOrLocalImage(
                                source: imagePath,
                                width: 88,
                                height: 88,
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: chipPrimaryBg, size: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                displayName,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.black,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayEmail,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // No verification-status field exists anywhere in the
                  // schema (see the admin verification-queue work), so an
                  // "Identity verified" badge was removed here rather than
                  // shown unconditionally regardless of real status.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF19963).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$gender · Caregiver',
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color(0xFFE56C3D),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Stats row: Experience · NIC number ────────────────────
  Widget _buildStatsRow() {
    final years = _profile?['yearsExperience'] as int?;
    final nic = (_profile?['nic'] as String?)?.trim();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statCard(
              'Experience',
              years != null ? '$years years' : '0 years',
              isExtraBold: true,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              'NIC number',
              nic?.isNotEmpty == true ? nic! : 'Not provided',
              isExtraBold: false,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, {required bool isExtraBold, required double fontSize}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: statsCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: statsValueColor,
              fontSize: fontSize,
              fontWeight: isExtraBold ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable section title (+ optional action link) ───────
  Widget _buildSectionTitle(String title, {String? actionLabel, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: sectionTitleColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF44331C),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ── Earnings card ────────────────────────────────────────
  // Real sums from the `payments` collection — there's no billing feature
  // yet, so this collection is empty today and both figures honestly show
  // LKR 0 rather than a guessed flat rate per booking.
  Widget _buildEarningsCard(List<Map<String, dynamic>> payments) {
    final now = DateTime.now();
    double monthEarned = 0;
    double totalEarned = 0;
    for (final p in payments) {
      if (p['status'] != 'completed') continue;
      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
      totalEarned += amount;
      final createdAt = p['createdAt'];
      if (createdAt is Timestamp) {
        final dt = createdAt.toDate();
        if (dt.year == now.year && dt.month == now.month) {
          monthEarned += amount;
        }
      }
    }

    String formatCurrency(double amount) {
      final rounded = amount.round();
      if (rounded == 0) return 'LKR 0';
      final str = rounded.toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formatted = str.replaceAllMapped(reg, (m) => '${m[1]},');
      return 'LKR $formatted';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD38763), Color(0xFF622407)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This month',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF462F24),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                formatCurrency(monthEarned),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 11),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total earned',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF462F24),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatCurrency(totalEarned),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact card ────────────────────────────────────────────
  Widget _buildContactCard() {
    final rawPhone = (_profile?['phone'] as String?)?.trim();
    final regPhone = AppState.registeredPhone.value.trim();
    final phone = (rawPhone != null && rawPhone.isNotEmpty)
        ? rawPhone
        : (regPhone.isNotEmpty ? regPhone : 'Not provided');

    final refPhone = (_profile?['referencePhone'] as String?)?.trim();
    final city = (_profile?['city'] as String?)?.trim() ?? 'Negombo, Western Province';
    final radius = _profile?['serviceRadiusKm'] as int? ?? 10;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: contactCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _contactRow(Icons.call_rounded, phone),
          const SizedBox(height: 10),
          _contactRow(
            Icons.badge_outlined,
            refPhone?.isNotEmpty == true
                ? 'Reference No: $refPhone'
                : 'Reference No: Not provided',
          ),
          const SizedBox(height: 10),
          _contactRow(Icons.location_on_outlined, '$city - $radius km radius'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: contactIconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: contactTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Care type banner ─────────────────────────────────────────
  Widget _buildCareTypeBanner() {
    final careTypes = (_profile?['careTypes'] as List?)?.cast<String>() ?? const [];
    final singleType = _profile?['careType'] as String?;
    final String careTypeLabel;
    if (careTypes.isNotEmpty) {
      careTypeLabel = careTypes.join(' / ');
    } else if (singleType != null && singleType.trim().isNotEmpty) {
      careTypeLabel = singleType.trim();
    } else {
      careTypeLabel = 'Part-time';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF525359),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            'Care type :   ',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              careTypeLabel,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFFF59E0B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Skills pills ────────────────────────────────────────────
  Widget _buildSkillsWrap() {
    final skills = (_profile?['skills'] as List?)?.cast<String>() ?? const [];

    if (skills.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
        decoration: BoxDecoration(
          border: Border.all(color: chipPrimaryBg),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'No skills listed',
          style: TextStyle(
            fontFamily: 'Inter',
            color: chipPrimaryBg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: chipPrimaryBg,
            border: Border.all(color: const Color(0xFF334155)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            skill,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Education & languages card ─────────────────────────────
  Widget _buildEducationCard() {
    final qual = (_profile?['educationalQualification'] as String?)?.trim() ?? 'Diploma';
    final formal = _profile?['formalTraining'] == true ? 'Yes' : 'Not set';
    final languages = (_profile?['languagesSpoken'] as List?)?.cast<String>() ?? const [];
    final langStr = languages.isNotEmpty ? languages.join(', ') : 'Not specified';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: infoCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$qual · Formal caregiving training: $formal',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: infoCardText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Speaks $langStr',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: infoCardText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bio card ────────────────────────────────────────────────
  Widget _buildBioCard() {
    final bioText = (_profile?['bio'] as String?)?.trim();
    final text = bioText?.isNotEmpty == true
        ? bioText!
        : 'No bio provided yet. Tap the edit icon at the top to add your summary.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: infoCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Open Sans',
          color: bioText?.isNotEmpty == true
              ? infoCardText
              : infoCardText.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontStyle: bioText?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
          height: 1.4,
        ),
      ),
    );
  }

  // ── Certifications section ────────────────────────────────
  Widget _buildCertificationsSection() {
    final certUrls = (_profile?['certificateUrls'] as List?)?.cast<String>() ?? [];
    final policeUrl = (_profile?['policeClearanceUrl'] as String?)?.trim() ?? '';
    final otherUrls = (_profile?['otherDocumentUrls'] as List?)?.cast<String>() ?? [];

    final docItems = <({String title, String type})>[];

    if (policeUrl.isNotEmpty) {
      docItems.add((title: 'Police Clearance Certificate', type: 'Verified Document'));
    }
    for (int i = 0; i < certUrls.length; i++) {
      docItems.add((title: 'Qualification Certificate ${i + 1}', type: 'Professional Cert'));
    }
    for (int i = 0; i < otherUrls.length; i++) {
      docItems.add((title: 'Supporting Document ${i + 1}', type: 'Document'));
    }

    if (docItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: certBg,
          border: Border.all(color: certBorder, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No certificates or documents uploaded yet.',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: certTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(docItems.length, (i) {
        final item = docItems[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i == docItems.length - 1 ? 0 : 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15.5, vertical: 13.5),
            decoration: BoxDecoration(
              color: certBg,
              border: Border.all(color: certBorder, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: certIconColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: certTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.type,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: certTextColor.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Settings grouped card ──────────────────────────────────
  Widget _buildSettingsCard(BuildContext context) {
    final rows = [
      (
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        onTap: () => Navigator.pushNamed(context, '/caregiver-messages')
      ),
      (
        icon: Icons.notifications_none_rounded,
        label: 'Notification preferences',
        onTap: () => _comingSoon('Notification preferences')
      ),
      (
        icon: Icons.lock_outline_rounded,
        label: 'Privacy & security',
        onTap: () => _comingSoon('Privacy & security')
      ),
      (
        icon: Icons.help_outline_rounded,
        label: 'Help & support',
        onTap: () => _comingSoon('Help & support')
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: settingsBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return GestureDetector(
            onTap: row.onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: isLast
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: settingsBorder, width: 1),
                      ),
                    ),
              child: Row(
                children: [
                  Icon(row.icon, color: settingsIconColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: settingsTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 18),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Log out button ─────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Navigate away first so every still-mounted screen's Firestore
        // listeners are disposed and cancelled before the auth token is
        // revoked — signing out first left them all live to receive a
        // simultaneous permission-denied error storm, which could block
        // the main thread long enough to trip an ANR on logout.
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
        await AuthService.signOut();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15.5),
        decoration: BoxDecoration(
          color: logoutBg,
          border: Border.all(color: logoutBorder, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: logoutBorder, size: 18),
            SizedBox(width: 8),
            Text(
              'Log out',
              style: TextStyle(
                fontFamily: 'Inter',
                color: logoutBorder,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
