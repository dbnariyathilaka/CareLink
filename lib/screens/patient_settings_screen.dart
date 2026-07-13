import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Settings Screen
//  Figma node: 46-2983 (P-24 · Settings (Patient))
// ─────────────────────────────────────────────────────────────
class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  static const Color _azure47 = Color(0xFF64748B);
  static const Color _amber = Color(0xFFF59E0B);

  static const List<String> _languages = ['English', 'Sinhala', 'Tamil'];

  bool _bookingUpdates = true;
  bool _emergencyAlerts = true;
  bool _newMessages = true;
  bool _newTopFive = false;
  bool _darkMode = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
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
                        iconColor: AppTheme.primaryGreen,
                        title: 'Edit profile',
                        subtitle: 'Update care requirements',
                        onTap: () {},
                      ),
                      _navRow(
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppTheme.primaryGreen,
                        title: 'Change password',
                        onTap: () {},
                      ),
                      _navRow(
                        icon: Icons.mail_outline_rounded,
                        iconColor: AppTheme.primaryGreen,
                        title: 'Change email',
                        subtitle: 'nipuni@email.com',
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
                        value: _newTopFive,
                        onChanged: (v) => setState(() => _newTopFive = v),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    _buildSectionLabel('PREFERENCES'),
                    const SizedBox(height: 8),
                    _buildGroupCard([
                      _navRow(
                        icon: Icons.language_rounded,
                        iconColor: AppTheme.textSecondary,
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

                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Log out',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _amber,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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
      backgroundColor: AppTheme.cardColor,
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
                  color: selected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryGreen)
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _azure47,
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
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final isLast = i == rows.length - 1;
          return Container(
            decoration: isLast
                ? null
                : const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
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
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (showChevron)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primaryGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.borderColor,
          ),
        ],
      ),
    );
  }
}
