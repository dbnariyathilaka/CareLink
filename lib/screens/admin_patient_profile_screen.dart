import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

/// Data model for a patient profile (admin view)
class AdminPatientProfileData {
  final String initials;
  final Color avatarColor;
  final Color avatarTextColor;
  final String name;
  final String demographics; // e.g. "72 · Female · Negombo"
  final String patientId; // e.g. "ID PT-10428 · joined Nov 2025"
  final String careType;
  final String assignedCaregiver;
  final String conditions;
  final List<CareCircleMember> careCircle;
  final int bookings;
  final int cancellations;
  final int disputes;

  const AdminPatientProfileData({
    required this.initials,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.name,
    required this.demographics,
    required this.patientId,
    required this.careType,
    required this.assignedCaregiver,
    required this.conditions,
    required this.careCircle,
    required this.bookings,
    required this.cancellations,
    required this.disputes,
  });
}

class CareCircleMember {
  final String initials;
  final Color avatarBg;
  final Color avatarText;
  final String name;
  final String roleAndContact;

  const CareCircleMember({
    required this.initials,
    required this.avatarBg,
    required this.avatarText,
    required this.name,
    required this.roleAndContact,
  });
}

class AdminPatientProfileScreen extends StatelessWidget {
  final AdminPatientProfileData data;

  const AdminPatientProfileScreen({super.key, required this.data});

  // ── Color tokens matching Figma node 628:686 ──────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF766B58);
  static const Color sectionDivider = Color(0xFF334155);

  static const Color nameColor = Color(0xFF403522);
  static const Color demoColor = Color(0xFF88795F);
  static const Color idColor = Color(0xFF625846);
  static const Color headerTitleColor = Color(0xFF544730);

  static const Color rowLabelColor = Color(0xFF5A4224);
  static const Color careTypeValue = Color(0xFFFFE6CA);
  static const Color caregiverValue = Color(0xFF28566A);
  static const Color conditionValue = Color(0xFFFFE6CA);

  static const Color circleMemberName = Color(0xFF544730);
  static const Color circleMemberSub = Color(0xFFF3E9DE);

  static const Color statValue = Color(0xFFFFEF85);
  static const Color statLabel = Color(0xFF544730);

  static const Color editBtnBg = Color(0xFF44331C);
  static const Color editBtnText = Color(0xFFF8FAFC);
  static const Color deactivateBorder = Color(0xFF44331C);
  static const Color deactivateText = Color(0xFF44331C);

  static const Color manageLinkColor = Color(0xFF44606C);
  static const Color sectionHeaderColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(Brightness.dark);
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientCard(),
                    const SizedBox(height: 14),
                    _buildSectionLabel('CARE REQUIREMENTS'),
                    const SizedBox(height: 8),
                    _buildCareRequirementsCard(),
                    const SizedBox(height: 14),
                    _buildCareCirleHeader(context),
                    const SizedBox(height: 8),
                    _buildCareCircleCard(),
                    const SizedBox(height: 14),
                    _buildSectionLabel('ACCOUNT HISTORY'),
                    const SizedBox(height: 8),
                    _buildAccountHistoryRow(),
                    const SizedBox(height: 14),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────── Top App Bar ──────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: headerTitleColor, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Patient profile',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: headerTitleColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.more_vert, color: headerTitleColor, size: 22),
          ),
        ],
      ),
    );
  }

  // ────────────────── Patient Identity Card ──────────────────
  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.avatarColor,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
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
          ),
          const SizedBox(width: 12),
          // Info
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
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.demographics,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: demoColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.patientId,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: idColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── Section label ──────────────────
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: sectionHeaderColor,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ────────────────── Care Requirements Card ──────────────────
  Widget _buildCareRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          _buildRequirementRow(
            label: 'Care type',
            value: data.careType,
            valueColor: careTypeValue,
            hasDivider: true,
          ),
          _buildRequirementRow(
            label: 'Assigned caregiver',
            value: data.assignedCaregiver,
            valueColor: caregiverValue,
            hasDivider: true,
          ),
          _buildRequirementRow(
            label: 'Conditions',
            value: data.conditions,
            valueColor: conditionValue,
            hasDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow({
    required String label,
    required String value,
    required Color valueColor,
    required bool hasDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
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
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: sectionDivider.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  // ────────────────── Care Circle Header ──────────────────
  Widget _buildCareCirleHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CARE CIRCLE · ${data.careCircle.length} MEMBERS',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: sectionHeaderColor,
              letterSpacing: 0.6,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Manage',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: manageLinkColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── Care Circle Card ──────────────────
  Widget _buildCareCircleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Column(
        children: data.careCircle.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isLast = index == data.careCircle.length - 1;
          return Column(
            children: [
              _buildCareCircleMemberRow(member),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: sectionDivider.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCareCircleMemberRow(CareCircleMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: member.avatarBg,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(
                member.initials,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: member.avatarText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: circleMemberName,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  member.roleAndContact,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: circleMemberSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── Account History Row ──────────────────
  Widget _buildAccountHistoryRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(data.bookings.toString(), 'Bookings')),
        const SizedBox(width: 9),
        Expanded(child: _buildStatCard(data.cancellations.toString(), 'Cancellations')),
        const SizedBox(width: 9),
        Expanded(child: _buildStatCard(data.disputes.toString(), 'Disputes')),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionDivider.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: statValue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: statLabel,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── Action Buttons ──────────────────
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: editBtnBg,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Center(
                    child: Text(
                      'Edit requirements',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: editBtnText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _showDeactivateDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: deactivateBorder, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Deactivate',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: deactivateText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Deactivate Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to deactivate ${data.name}\'s account? They will no longer be able to access the app.',
          style: const TextStyle(color: Color(0xFFD4CDC3), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65555),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}
