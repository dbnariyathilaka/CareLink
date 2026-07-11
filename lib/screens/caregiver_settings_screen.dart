import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Settings Screen
//  Figma node: 46-4874
//  Key difference from patient: toggle accent = indigo #6366F1
//  Sections: ACCOUNT · AVAILABILITY · NOTIFICATIONS · SUPPORT
// ─────────────────────────────────────────────────────────────
class CaregiverSettingsScreen extends StatefulWidget {
  const CaregiverSettingsScreen({super.key});

  @override
  State<CaregiverSettingsScreen> createState() =>
      _CaregiverSettingsScreenState();
}

class _CaregiverSettingsScreenState extends State<CaregiverSettingsScreen> {
  // ── Colour tokens ─────────────────────────────────────────
  static const Color _azure11   = AppTheme.surfaceColor;   // #0F172A
  static const Color _azure17   = AppTheme.cardColor;      // #1E293B
  static const Color _azure27   = AppTheme.borderColor;    // #334155
  static const Color _azure47   = Color(0xFF64748B);
  static const Color _azure65   = AppTheme.textSecondary;  // #94A3B8
  static const Color _grey98    = AppTheme.textPrimary;    // #F8FAFC
  static const Color _indigo    = Color(0xFF6366F1);       // caregiver toggle ON
  static const Color _amber     = Color(0xFFF59E0B);       // Log out
  static const Color _red       = Color(0xFFEF4444);       // Delete account
  static const Color _redBg     = Color(0x14EF4444);       // 8 %
  static const Color _redBorder = Color(0x4DEF4444);       // 30 %

  // ── State ─────────────────────────────────────────────────
  bool _availableEmergency = true;
  bool _doNotDisturb       = false;
  bool _newBookingRequests = true;
  bool _paymentReceived    = true;
  bool _newReviewReceived  = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── ACCOUNT ──────────────────────────
                    _sectionLabel('ACCOUNT'),
                    const SizedBox(height: 8),
                    _buildAccountCard(),
                    const SizedBox(height: 16),
                    // ── AVAILABILITY ─────────────────────
                    _sectionLabel('AVAILABILITY'),
                    const SizedBox(height: 8),
                    _buildAvailabilityCard(),
                    const SizedBox(height: 16),
                    // ── NOTIFICATIONS ─────────────────────
                    _sectionLabel('NOTIFICATIONS'),
                    const SizedBox(height: 8),
                    _buildNotificationsCard(),
                    const SizedBox(height: 16),
                    // ── SUPPORT ───────────────────────────
                    _sectionLabel('SUPPORT'),
                    const SizedBox(height: 8),
                    _buildSupportCard(),
                    const SizedBox(height: 16),
                    // ── Log out ───────────────────────────
                    _buildLogOutButton(context),
                    const SizedBox(height: 10),
                    // ── Delete account ────────────────────
                    _buildDeleteCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'Settings',
            style: TextStyle(
              color: _grey98,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _azure47,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  // ── Shared grouped card ───────────────────────────────────
  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _azure27),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _azure27);

  // ── ACCOUNT ───────────────────────────────────────────────
  Widget _buildAccountCard() {
    return _card(children: [
      _navRow(
        icon: Icons.person_outline_rounded,
        label: 'Edit profile',
        subtitle: 'Skills, availability, service area',
        onTap: () {},
      ),
      _divider(),
      _navRow(
        icon: Icons.lock_outline_rounded,
        label: 'Change password',
        onTap: () {},
      ),
    ]);
  }

  // ── AVAILABILITY ──────────────────────────────────────────
  Widget _buildAvailabilityCard() {
    return _card(children: [
      _toggleRow(
        icon: Icons.flash_on_rounded,
        iconColor: _red,           // emergency = red flash icon
        label: 'Available for emergency',
        subtitle: 'Appear in emergency top 3',
        value: _availableEmergency,
        onChanged: (v) => setState(() => _availableEmergency = v),
        divider: true,
      ),
      _toggleRow(
        icon: Icons.do_not_disturb_on_outlined,
        iconColor: _azure65,
        label: 'Do not disturb',
        subtitle: 'Pause all incoming requests',
        value: _doNotDisturb,
        onChanged: (v) => setState(() => _doNotDisturb = v),
        divider: false,
      ),
    ]);
  }

  // ── NOTIFICATIONS ─────────────────────────────────────────
  Widget _buildNotificationsCard() {
    return _card(children: [
      _toggleRow(
        label: 'New booking requests',
        value: _newBookingRequests,
        onChanged: (v) => setState(() => _newBookingRequests = v),
        divider: true,
      ),
      _toggleRow(
        label: 'Payment received',
        value: _paymentReceived,
        onChanged: (v) => setState(() => _paymentReceived = v),
        divider: true,
      ),
      _toggleRow(
        label: 'New review received',
        value: _newReviewReceived,
        onChanged: (v) => setState(() => _newReviewReceived = v),
        divider: false,
      ),
    ]);
  }

  // ── SUPPORT ───────────────────────────────────────────────
  Widget _buildSupportCard() {
    return _card(children: [
      _navRow(
        icon: Icons.help_outline_rounded,
        label: 'Help & FAQ',
        onTap: () {},
      ),
      _divider(),
      _navRow(
        icon: Icons.shield_outlined,
        label: 'Privacy policy',
        onTap: () {},
      ),
    ]);
  }

  // ── Log out button ────────────────────────────────────────
  Widget _buildLogOutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogOutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _azure27),
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
    );
  }

  // ── Delete account card ───────────────────────────────────
  Widget _buildDeleteCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDeleteDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _redBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _redBorder),
        ),
        child: Column(
          children: const [
            Text(
              'Delete account',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'This cannot be undone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _azure65,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nav row (with chevron) ────────────────────────────────
  Widget _navRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? _indigo, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _grey98,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _azure65,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _azure65,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle row ────────────────────────────────────────────
  Widget _toggleRow({
    IconData? icon,
    Color? iconColor,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool divider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? _azure65, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _grey98,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _azure65,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildToggle(value, onChanged),
            ],
          ),
        ),
        if (divider) _divider(),
      ],
    );
  }

  // ── Custom animated toggle (42×24, indigo accent) ─────────
  Widget _buildToggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 42,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? _indigo : _azure27,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? Colors.white : _azure65,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ),
    );
  }

  // ── Log out dialog ────────────────────────────────────────
  void _showLogOutDialog(BuildContext context) {
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
                  color: _amber.withValues(alpha: 0.12),
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
                'Are you sure you want to log out of your caregiver account?',
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
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.12),
                          border: Border.all(
                              color: _amber.withValues(alpha: 0.4)),
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

  // ── Delete account dialog ─────────────────────────────────
  void _showDeleteDialog(BuildContext context) {
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
                  color: _redBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: _red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete account?',
                style: TextStyle(
                  color: _grey98,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
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
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _redBg,
                          border: Border.all(color: _redBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _red,
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
}
