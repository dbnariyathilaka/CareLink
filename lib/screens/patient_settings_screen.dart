import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Settings Screen
//  Figma node: 171-1189
// ─────────────────────────────────────────────────────────────
class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color sectionLabelColor = Color(0xFF64748B);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF334155);
  static const Color rowTitleColor = Color(0xFFF8FAFC);
  static const Color rowSubtitleColor = Color(0xFF94A3B8);
  static const Color amberIcon = Color(0xFFFBBC05);
  static const Color chevronColor = Color(0xFF64748B);
  static const Color activeSwitchColor = Color(0xFF22C55E);

  static const List<String> _languages = ['English', 'Sinhala', 'Tamil'];

  bool _bookingUpdates = true;
  bool _emergencyAlerts = true;
  bool _newMessages = true;
  bool _newTop5Found = false;
  bool _darkMode = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: darkGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('ACCOUNT'),
                    const SizedBox(height: 8),
                    _buildGroupCard([
                      _navRow(
                        icon: Icons.badge_outlined,
                        iconColor: amberIcon,
                        title: 'Edit profile',
                        subtitle: 'Update care requirements',
                        onTap: () {},
                      ),
                      _navRow(
                        icon: Icons.lock_outline_rounded,
                        iconColor: amberIcon,
                        title: 'Change password',
                        onTap: () {},
                      ),
                      _navRow(
                        icon: Icons.mail_outline_rounded,
                        iconColor: amberIcon,
                        title: 'Change email',
                        subtitle: 'nipuni@email.com',
                        showChevron: false,
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: 18),

                    _buildSectionLabel('NOTIFICATIONS'),
                    const SizedBox(height: 8),
                    _buildGroupCard([
                      _toggleRow(
                        title: 'Booking updates',
                        value: _bookingUpdates,
                        onChanged: (v) => setState(() => _bookingUpdates = v),
                      ),
                      _toggleRow(
                        title: 'Emergency alerts',
                        value: _emergencyAlerts,
                        onChanged: (v) => setState(() => _emergencyAlerts = v),
                      ),
                      _toggleRow(
                        title: 'New messages',
                        value: _newMessages,
                        onChanged: (v) => setState(() => _newMessages = v),
                      ),
                      _toggleRow(
                        title: 'New top 5 found',
                        value: _newTop5Found,
                        onChanged: (v) => setState(() => _newTop5Found = v),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    _buildSectionLabel('PREFERENCES'),
                    const SizedBox(height: 8),
                    _buildGroupCard([
                      _navRow(
                        icon: Icons.language_rounded,
                        iconColor: rowSubtitleColor,
                        title: 'Language',
                        trailingText: _language,
                        showChevron: false,
                        onTap: _showLanguagePicker,
                      ),
                      _toggleRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark mode',
                        value: _darkMode,
                        onChanged: (v) => setState(() => _darkMode = v),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    _buildDeleteAccountButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            final selected = lang == _language;
            return ListTile(
              title: Text(
                lang,
                style: TextStyle(
                  color: selected ? activeSwitchColor : rowTitleColor,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: activeSwitchColor)
                  : null,
              onTap: () {
                setState(() => _language = lang);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return GestureDetector(
      onTap: () => _showDeleteAccountDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(64, 41, 6, 0.37),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: const [
            Text(
              'Delete account',
              style: TextStyle(
                color: Color(0xFF70360D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'This cannot be undone',
              style: TextStyle(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete account?',
                style: TextStyle(
                  color: rowTitleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rowSubtitleColor,
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
                          border: Border.all(color: cardBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: rowSubtitleColor,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account deleted successfully.'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFEF4444),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: sectionLabelColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final isLast = i == rows.length - 1;
          return Container(
            decoration: isLast
                ? null
                : const BoxDecoration(
                    border: Border(bottom: BorderSide(color: cardBorder)),
                  ),
            child: rows[i],
          );
        }),
      ),
    );
  }

  Widget _navRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? trailingText,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: rowTitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: rowSubtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  color: rowSubtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (showChevron)
              const Icon(Icons.chevron_right_rounded, color: chevronColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    IconData? icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: rowSubtitleColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: rowTitleColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: activeSwitchColor,
            inactiveThumbColor: rowSubtitleColor,
            inactiveTrackColor: cardBorder,
          ),
        ],
      ),
    );
  }
}
