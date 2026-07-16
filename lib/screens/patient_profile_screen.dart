import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../app_state.dart';

// ─────────────────────────────────────────────────────────────
//  Patient My Profile Screen
//  Figma node: 160-1861
// ─────────────────────────────────────────────────────────────
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  // ── Figma colour tokens ──────────────────────────────────
  static const Color _green45   = AppTheme.primaryGreen;
  static const Color _green36   = AppTheme.primaryGreenDark;
  static const Color _green8    = AppTheme.bottleGreen;
  static const Color _azure11   = AppTheme.surfaceColor;
  static const Color _azure17   = AppTheme.cardColor;
  static const Color _azure27   = AppTheme.borderColor;
  static const Color _azure47   = Color(0xFF64748B);
  static const Color _azure65   = AppTheme.textSecondary;
  static const Color _grey98    = AppTheme.textPrimary;
  static const Color _red44     = Color(0xFFEF4444);
  static const Color _amber     = Color(0xFFF59E0B);

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _azure17,
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
                color: _azure27,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _green45),
              title: const Text('Take a photo',
                  style: TextStyle(color: _grey98, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _green45),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: _grey98, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (AppState.profileImagePath.value != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: _red44),
                title: const Text('Remove photo',
                    style: TextStyle(color: _red44, fontWeight: FontWeight.w600)),
                onTap: () {
                  AppState.profileImagePath.value = null;
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
      AppState.profileImagePath.value = picked.path;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeaderSection(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 12),
                          _buildSectionLabel('Care requirements'),
                          const SizedBox(height: 8),
                          _buildCareRequirementsCard(context),
                          const SizedBox(height: 12),
                          _buildSectionLabel('Favourite caregivers'),
                          const SizedBox(height: 8),
                          _buildFavouriteCard(context),
                          const SizedBox(height: 12),
                          _menuRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Messages',
                            badge: '2',
                            onTap: () => Navigator.pushNamed(context, '/messages'),
                          ),
                          const SizedBox(height: 12),
                          _menuRow(
                            icon: Icons.shield_outlined,
                            label: 'Privacy policy',
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _menuRow(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & FAQ',
                            onTap: () {},
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
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Header: title + avatar + name + badge ────────────────
  Widget _buildHeaderSection(BuildContext context) {
    final imagePath = AppState.profileImagePath.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      child: Column(
        children: [
          // "My profile" title row with settings icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My profile',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: const Icon(
                  Icons.settings_outlined,
                  color: _grey98,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Avatar with pencil badge
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Circle avatar
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: imagePath == null
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_green45, _green36],
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
                      : const Center(
                          child: Text(
                            'NA',
                            style: TextStyle(
                              color: _green8,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                // Edit pencil badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _green45,
                      shape: BoxShape.circle,
                      border: Border.all(color: _azure11, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: _green8,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nipuni Ariyathilaka',
            style: TextStyle(
              color: _grey98,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'nipuni@email.com · +94 77 123 4567',
            style: TextStyle(
              color: _azure65,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _green45.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_rounded, color: _green45, size: 15),
                SizedBox(width: 5),
                Text(
                  'Patient / Family account',
                  style: TextStyle(
                    color: _green45,
                    fontSize: 11,
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

  // ── Stats row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard('3', 'Bookings')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('2', 'Reviews given')),
        const SizedBox(width: 10),
        Expanded(child: _statCard('1', 'Favourite')),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _azure27),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: _grey98, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _azure65, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _azure65,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Care requirements card ────────────────────────────────
  Widget _buildCareRequirementsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _azure27),
      ),
      child: Column(
        children: [
          _requirementRow('Care type', 'Elder care · Full-time', divider: true),
          _requirementRow('Location', 'Negombo, Western Province', divider: true),
          _requirementRow('Preferred gender', 'No preference', divider: false),
          const SizedBox(height: 10),
          // Navigate to onboarding to edit preferences
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/patient-onboarding-1'),
            child: const Text(
              'Edit requirements',
              style: TextStyle(
                color: _green45,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementRow(String label, String value, {required bool divider}) {
    return Container(
      height: 35,
      decoration: divider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: _azure27, width: 1)))
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _azure65, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  color: _grey98, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Favourite caregiver card ──────────────────────────────
  Widget _buildFavouriteCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/caregiver-profile',
          arguments: const {'caregiverName': 'Alice Fernando'},
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _azure27),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_green45, _green36],
                ),
              ),
              child: const Center(
                child: Text('AF',
                    style: TextStyle(
                        color: _green8,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alice Fernando',
                      style: TextStyle(
                          color: _grey98,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 3),
                  Text('Elder care · ★4.8',
                      style: TextStyle(
                          color: _azure65,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                // Heart icon toggles (prevent propagation if needed, but in Flutter onTap on child doesn't bubble up if behavior is set or child consumes it)
              },
              child: const Icon(Icons.favorite_border, color: _red44, size: 20),
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
        backgroundColor: _azure17,
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
                  color: _amber.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _amber,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Log out?',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _azure65,
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
                          border: Border.all(color: _azure27),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _azure65,
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
                          color: _amber.withOpacity(0.12),
                          border: Border.all(color: _amber.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Log out',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _amber,
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
          color: _azure17,
          border: Border.all(color: _azure27),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Log out',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: _amber, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _azure27),
        ),
        child: Row(
          children: [
            Icon(icon, color: _green45, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: _grey98,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            if (badge != null) ...[
              Container(
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: _green45,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(badge,
                    style: const TextStyle(
                        color: _green8,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, color: _azure65, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav (matches dashboard) ────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: null, label: 'Match'),
      (icon: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.notifications_none_rounded, label: 'Alerts'),
    ];
    // No tab highlighted on profile screen since it's a sub-page
    const selectedIndex = -1;

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          if (index == 2) {
            return GestureDetector(
              onTap: () {
                if (AppState.hasActiveMatch.value) {
                  Navigator.pushNamed(context, '/advanced-match-results');
                } else {
                  Navigator.pushNamed(context, '/advanced-match-send-request');
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF01D3A8), // Caribbean Green
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF01D3A8).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diversity_3_rounded,
                      color: Color(0xFF06240F), // Bottle green
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Match',
                    style: TextStyle(
                      color: Color(0xFF01D3A8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }

          final color = isSelected ? AppTheme.primaryGreen : const Color(0xFF64748B);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/patient-dashboard', (r) => false);
              } else if (index == 1) {
                Navigator.pushNamed(context, '/search');
              } else if (index == 3) {
                Navigator.pushNamed(context, '/my-bookings');
              } else if (index == 4) {
                Navigator.pushNamed(context, '/notifications');
              }
            },
            child: SizedBox(
              width: 60,
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
            ),
          );
        }),
      ),
    );
  }
}
