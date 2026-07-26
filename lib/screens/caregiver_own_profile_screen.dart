import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../widgets/empty_state.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver's own "My profile" screen
//  Figma node: 498-7738 · P-27 · My Profile (Caregiver)
// ─────────────────────────────────────────────────────────────
class CaregiverOwnProfileScreen extends StatefulWidget {
  const CaregiverOwnProfileScreen({super.key});

  @override
  State<CaregiverOwnProfileScreen> createState() => _CaregiverOwnProfileScreenState();
}

class _CaregiverOwnProfileScreenState extends State<CaregiverOwnProfileScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _geyser = Color(0xFFCBD5E1);
  static const Color _red71 = Color(0xFFF87171);

  bool _loading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await CaregiverService.getCaregiverProfile(user.uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 10),
                      _buildAvatarSection(),
                      const SizedBox(height: 16),
                      _buildStatsRow(),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Earnings', actionLabel: 'View details', onAction: () {
                        Navigator.pushNamed(context, '/caregiver-earnings');
                      }),
                      const SizedBox(height: 8),
                      _buildEarningsCard(),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Contact'),
                      const SizedBox(height: 8),
                      _buildContactCard(),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Care type'),
                      const SizedBox(height: 8),
                      _buildPillsWrap(
                        (_profile?['careTypes'] as List?)?.cast<String>() ?? const [],
                        selected: true,
                        emptyMessage: 'No care types set yet.',
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Skills'),
                      const SizedBox(height: 8),
                      _buildPillsWrap(
                        (_profile?['skills'] as List?)?.cast<String>() ?? const [],
                        selected: false,
                        emptyMessage: 'No skills listed yet.',
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Education & languages'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        '${(_profile?['educationalQualification'] as String?)?.trim().isNotEmpty == true ? _profile!['educationalQualification'] : 'Not set'} '
                            '· Formal caregiving training: ${_profile?['formalTraining'] == true ? 'Yes' : 'Not set'}',
                        (_profile?['languagesSpoken'] as List?)?.isNotEmpty == true
                            ? 'Speaks ${(_profile!['languagesSpoken'] as List).cast<String>().join(', ')}'
                            : 'No languages listed yet.',
                      ]),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Bio'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        (_profile?['bio'] as String?)?.trim().isNotEmpty == true
                            ? _profile!['bio'] as String
                            : 'No bio provided yet.',
                      ]),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Certifications'),
                      const SizedBox(height: 8),
                      const EmptyState(
                        icon: Icons.description_outlined,
                        message: 'No certificate documents uploaded yet.',
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Settings'),
                      const SizedBox(height: 8),
                      _buildSettingsCard(context),
                      const SizedBox(height: 12),
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label coming soon!')),
    );
  }

  // ── Header row: title + Requests pill + edit icon ─────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'My profile',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/caregiver-schedule'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Requests',
                  style: TextStyle(color: _geyser, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/caregiver-edit-profile'),
              child: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 22),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 5,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _indigo),
              title: const Text('Take a photo',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _indigo),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (AppState.caregiverProfileImagePath.value != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('Remove photo',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                onTap: () {
                  AppState.caregiverProfileImagePath.value = null;
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final picked = await picker.pickImage(
      source: choice,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked != null) {
      AppState.caregiverProfileImagePath.value = picked.path;
      setState(() {});
    }
  }

  // ── Avatar + name + email + badges ────────────────────────
  Widget _buildAvatarSection() {
    final name = (_profile?['name'] as String?)?.trim() ?? '';
    final email = (_profile?['email'] as String?)?.trim() ?? '';
    final gender = (_profile?['gender'] as String?)?.trim();
    final initials = name.isEmpty
        ? '?'
        : name
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
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: imagePath == null
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_indigo, Color(0xFF4F46E5)],
                              )
                            : null,
                        color: imagePath != null ? Colors.transparent : null,
                      ),
                      child: imagePath != null
                          ? ClipOval(
                              child: Image.file(
                                File(imagePath),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
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
                          color: AppTheme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surfaceColor, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: _indigo, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name.isEmpty ? 'Unnamed caregiver' : name,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                email.isEmpty ? 'No email on file' : email,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  gender?.isNotEmpty == true ? '$gender · Caregiver' : 'Caregiver',
                  style: const TextStyle(color: _indigoLight, fontSize: 10, fontWeight: FontWeight.w700),
                ),
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
              years != null ? '$years years' : 'Not set',
              valueFontSize: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              'NIC number',
              nic?.isNotEmpty == true ? nic! : 'Not provided',
              valueFontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, {required double valueFontSize}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
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
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(color: _indigoLight, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  // ── Earnings card ────────────────────────────────────────
  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const EmptyState(
        icon: Icons.payments_outlined,
        message: 'No earnings yet — this fills in once you complete paid bookings.',
      ),
    );
  }

  // ── Contact card ────────────────────────────────────────────
  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _contactRow(
            Icons.contact_phone_rounded,
            (_profile?['referencePhone'] as String?)?.trim().isNotEmpty == true
                ? 'Reference: ${_profile!['referencePhone']}'
                : 'Reference: Not provided',
          ),
          const SizedBox(height: 12),
          _contactRow(Icons.location_on_rounded, _locationText()),
        ],
      ),
    );
  }

  String _locationText() {
    final city = (_profile?['city'] as String?)?.trim();
    final radius = _profile?['serviceRadiusKm'] as int?;
    if (city == null || city.isEmpty) return 'Location not set yet.';
    return radius != null ? '$city · $radius km radius' : city;
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _indigo, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _geyser, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── Generic pill wrap (Care type / Skills) ─────────────────
  Widget _buildPillsWrap(List<String> items,
      {required bool selected, required String emptyMessage}) {
    if (items.isEmpty) {
      return Text(
        emptyMessage,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _indigo.withValues(alpha: 0.15) : AppTheme.cardColor,
            border: Border.all(color: selected ? _indigo : AppTheme.borderColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _indigoLight : _geyser,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Generic info card (Education / Bio) ────────────────────
  Widget _buildInfoCard(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Text(
              lines[i],
              style: const TextStyle(color: _geyser, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  // ── Certification file row ─────────────────────────────────
  // ── Settings grouped card ──────────────────────────────────
  Widget _buildSettingsCard(BuildContext context) {
    final rows = [
      (icon: Icons.chat_bubble_outline_rounded, label: 'Messages', onTap: () => Navigator.pushNamed(context, '/caregiver-messages')),
      (icon: Icons.notifications_none_rounded, label: 'Notification preferences', onTap: () => _comingSoon(context, 'Notification preferences')),
      (icon: Icons.lock_outline_rounded, label: 'Privacy & security', onTap: () => _comingSoon(context, 'Privacy & security')),
      (icon: Icons.help_outline_rounded, label: 'Help & support', onTap: () => _comingSoon(context, 'Help & support')),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return GestureDetector(
            onTap: row.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: isLast
                  ? null
                  : const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
                    ),
              child: Row(
                children: [
                  Icon(row.icon, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(color: _geyser, fontSize: 13, fontWeight: FontWeight.w500),
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
      onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _red71.withValues(alpha: 0.1),
          border: Border.all(color: _red71.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: _red71, size: 18),
            SizedBox(width: 8),
            Text(
              'Log out',
              style: TextStyle(color: _red71, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav (Profile tab active) ──────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.calendar_month_rounded, label: 'Schedule'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];
    const selectedIndex = 3;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;
          final color = isSelected ? _indigo : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.popUntil(context, ModalRoute.withName('/caregiver-dashboard'));
              } else if (index == 1) {
                Navigator.pushNamed(context, '/caregiver-schedule');
              } else if (index == 2) {
                Navigator.pushNamed(context, '/caregiver-notifications');
              } else if (index != 3) {
                _comingSoon(context, item.label);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
