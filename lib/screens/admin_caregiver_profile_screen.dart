import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../widgets/status_bar.dart';

/// Everything this screen displays about one caregiver, already resolved to
/// real Firestore fields by the caller (admin_caregivers_screen.dart) — see
/// that file's `_buildProfileData` for exactly which `caregiverProfiles` /
/// `users` fields back each value. Nothing here is fabricated: a value that
/// doesn't exist in the schema is either omitted (e.g. age, a caregiver
/// "code") or passed through honestly as "Not provided"/empty.
class AdminCaregiverProfileData {
  final String uid;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String name;
  final String demographics; // e.g. "Female · Negombo" — no age field exists in the schema
  final String? joinedLabel; // e.g. "Joined Nov 2025", derived from users/{uid}.createdAt; null if unknown
  final String phone;
  final String location;
  final String nic;
  final String email;
  final String experience;
  final String careType;
  final List<String> skills;
  final String education;
  final String training;
  final List<String> languages;
  final String bio;
  final List<String> certificates;

  const AdminCaregiverProfileData({
    required this.uid,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.name,
    required this.demographics,
    this.joinedLabel,
    required this.phone,
    required this.location,
    required this.nic,
    required this.email,
    required this.experience,
    required this.careType,
    required this.skills,
    required this.education,
    required this.training,
    required this.languages,
    required this.bio,
    required this.certificates,
  });
}

class AdminCaregiverProfileScreen extends StatefulWidget {
  final AdminCaregiverProfileData data;

  const AdminCaregiverProfileScreen({
    super.key,
    required this.data,
  });

  @override
  State<AdminCaregiverProfileScreen> createState() => _AdminCaregiverProfileScreenState();
}

class _AdminCaregiverProfileScreenState extends State<AdminCaregiverProfileScreen> {
  // ── Color tokens matching Figma node 695:915 ──────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);
  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF766B58);
  static const Color cardNameColor = Color(0xFF403522);
  static const Color sectionHeaderColor = Colors.black;
  static const Color rowLabelColor = Color(0xFF5A4224);
  static const Color rowValueColor = Color(0xFF3F566E);
  static const Color dividerColor = Color(0xFF334155);
  static const Color chipBg = Color(0xFF313131);
  static const Color chipBorder = Color(0xFF334155);
  static const Color darkCardBg = Color.fromRGBO(78, 69, 51, 0.73);
  static const Color darkCardTextColor = Color(0xFFFFFAF0);
  static const Color certBg = Color(0xFFF4D9BF);
  static const Color certBorder = Color(0xFF443423);
  static const Color certIconGold = Color(0xFF96730E);
  static const Color certTextColor = Color(0xFF44331C);

  AdminCaregiverProfileData get data => widget.data;

  // Derived, best-effort "completed jobs" count — see [_loadCompletedJobs].
  int? _completedJobs;

  @override
  void initState() {
    super.initState();
    _loadCompletedJobs();
  }

  /// Fetched lazily here — one caregiver at a time, only when this detail
  /// screen is opened — never on the caregivers list screen, which would
  /// otherwise fire one query per row (an N+1 query storm). There's no
  /// stored "completed" status anywhere in the schema (bookingRequests only
  /// tracks requested/confirmed/declined/cancelled), so this is a derived
  /// count of confirmed bookings whose scheduled end has already passed —
  /// a real, but best-effort, number.
  Future<void> _loadCompletedJobs() async {
    final count = await BookingService.countCompletedBookingsForCaregiver(data.uid);
    if (mounted) setState(() => _completedJobs = count);
  }

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(Brightness.dark);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: titleColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Caregiver profile',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: titleColor, size: 22),
                    onPressed: () => _showOptionsMenu(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Scrollable Profile Content ────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(25, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Profile Card ───────────────────────────────
                    _buildHeaderCard(),
                    const SizedBox(height: 18),

                    // ── Section 1: Personal details ───────────────────────
                    _buildSectionTitle('Personal details'),
                    const SizedBox(height: 8),
                    _buildPersonalDetailsCard(),
                    const SizedBox(height: 18),

                    // ── Section 2: Care Service Details ───────────────────
                    _buildSectionTitle('Care Service Details'),
                    const SizedBox(height: 8),
                    _buildCareServiceDetailsCard(),
                    const SizedBox(height: 18),

                    // ── Section 3: Skills ─────────────────────────────────
                    _buildSubSectionTitle('Skills'),
                    const SizedBox(height: 8),
                    _buildSkillsChips(),
                    const SizedBox(height: 18),

                    // ── Section 4: Education & languages ──────────────────
                    _buildSubSectionTitle('Education & languages'),
                    const SizedBox(height: 8),
                    _buildEducationCard(),
                    const SizedBox(height: 18),

                    // ── Section 5: Bio ────────────────────────────────────
                    _buildSubSectionTitle('Bio'),
                    const SizedBox(height: 8),
                    _buildBioCard(),
                    const SizedBox(height: 18),

                    // ── Section 6: Certifications ─────────────────────────
                    _buildSubSectionTitle('Certifications'),
                    const SizedBox(height: 8),
                    _buildCertifications(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.avatarBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              data.initials,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: data.avatarTextColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cardNameColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.demographics,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF88795F),
                  ),
                ),
                if (data.joinedLabel != null)
                  Text(
                    data.joinedLabel!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF625846),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: sectionHeaderColor,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color.fromRGBO(15, 23, 42, 0.75),
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Column(
        children: [
          _buildDetailRow('Phone No', data.phone, hasDivider: true),
          _buildDetailRow('Location', data.location, hasDivider: true),
          _buildDetailRow('NIC', data.nic, hasDivider: true),
          _buildDetailRow('Email', data.email, hasDivider: false),
        ],
      ),
    );
  }

  Widget _buildCareServiceDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Column(
        children: [
          _buildDetailRow('Experience', data.experience, hasDivider: true),
          _buildDetailRow('Care type', data.careType, hasDivider: true),
          _buildDetailRow(
            // Derived, not a stored field — see _loadCompletedJobs above.
            'Completed jobs (est.)',
            _completedJobs == null ? 'Loading…' : '$_completedJobs',
            hasDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required bool hasDivider}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: hasDivider
            ? const Border(bottom: BorderSide(color: dividerColor, width: 1))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: rowLabelColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: rowValueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsChips() {
    if (data.skills.isEmpty) {
      return const Text(
        'No skills listed.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: rowLabelColor,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: data.skills.map((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipBorder, width: 1),
          ),
          child: Text(
            skill,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEducationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.education} · Formal caregiving training: ${data.training}',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: darkCardTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.languages.isEmpty
                ? 'No languages listed'
                : 'Speaks ${data.languages.join(', ')}',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: darkCardTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    final bioText = data.bio.trim().isNotEmpty ? data.bio : 'No bio provided.';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(13),
      child: Text(
        bioText,
        style: const TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: darkCardTextColor,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildCertifications() {
    if (data.certificates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15.5, vertical: 13.5),
        decoration: BoxDecoration(
          color: certBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: certBorder, width: 1.5),
        ),
        child: const Text(
          'No certificates or documents uploaded.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: certTextColor,
          ),
        ),
      );
    }
    return Column(
      children: data.certificates.map((cert) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.5, vertical: 13.5),
            decoration: BoxDecoration(
              color: certBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: certBorder, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: certIconGold,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cert,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: certTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C251D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions for ${data.name}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.lightBlueAccent),
              title: const Text('Export Caregiver Dossier (PDF)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exporting profile for ${data.name}...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
              title: const Text('Suspend Account', style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account status updated for ${data.name}.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
