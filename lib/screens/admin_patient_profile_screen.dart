import 'dart:async';

import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/patient_service.dart';
import '../services/user_directory_service.dart';
import '../widgets/status_bar.dart';

/// Data model for a patient profile (admin view). Only fields that are
/// already known from the patients list are passed in here — anything that
/// requires an extra Firestore round trip (care circle, booking counts,
/// assigned caregiver, phone/email) is loaded lazily by this screen itself,
/// once, for this one patient — never in a loop over the whole list.
class AdminPatientProfileData {
  final String patientUid;
  final String initials;
  final Color avatarColor;
  final Color avatarTextColor;
  final String name;
  final String demographics; // e.g. "72 · Female · Negombo"
  final String patientId; // e.g. "Internal ID a1b2c3d4 · joined Nov 2025"
  final String careType;
  final String conditions;

  const AdminPatientProfileData({
    required this.patientUid,
    required this.initials,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.name,
    required this.demographics,
    required this.patientId,
    required this.careType,
    required this.conditions,
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

  factory CareCircleMember.fromDoc(Map<String, dynamic> doc) {
    final name = (doc['name'] as String?)?.trim();
    final relation = (doc['relation'] as String?)?.trim();
    final role = (doc['role'] as String?)?.trim();
    final isPrimary = doc['isPrimary'] == true;

    final subtitleParts = <String>[
      if (relation != null && relation.isNotEmpty) relation,
      if (role != null && role.isNotEmpty) role,
      if (isPrimary) 'Primary contact',
    ];

    final displayName = (name != null && name.isNotEmpty) ? name : 'Unnamed member';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final initials = parts.length == 1
        ? parts[0].substring(0, 1).toUpperCase()
        : (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();

    return CareCircleMember(
      initials: initials,
      avatarBg: const Color(0xFF727953),
      avatarText: const Color(0xFF313715),
      name: displayName,
      roleAndContact: subtitleParts.isEmpty ? 'No role specified' : subtitleParts.join(' · '),
    );
  }
}

class AdminPatientProfileScreen extends StatefulWidget {
  final AdminPatientProfileData data;

  const AdminPatientProfileScreen({super.key, required this.data});

  @override
  State<AdminPatientProfileScreen> createState() => _AdminPatientProfileScreenState();
}

class _AdminPatientProfileScreenState extends State<AdminPatientProfileScreen> {
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
  static const Color contactValue = Color(0xFF28566A);

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

  StreamSubscription<List<Map<String, dynamic>>>? _careCircleSub;
  List<CareCircleMember> _careCircle = [];
  bool _careCircleLoading = true;

  String? _phone;
  String? _email;
  bool _contactLoading = true;

  String? _assignedCaregiver;
  bool _assignedCaregiverLoading = true;

  int? _bookings;
  int? _cancellations;
  bool _bookingCountsLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToCareCircle();
    _loadContactInfo();
    _loadAssignedCaregiver();
    _loadBookingCounts();
  }

  @override
  void dispose() {
    _careCircleSub?.cancel();
    super.dispose();
  }

  void _listenToCareCircle() {
    _careCircleSub = PatientService.streamFamilyMembers(widget.data.patientUid).listen((docs) {
      if (!mounted) return;
      setState(() {
        _careCircle = docs.map((d) => CareCircleMember.fromDoc(d)).toList();
        _careCircleLoading = false;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _careCircleLoading = false);
    });
  }

  Future<void> _loadContactInfo() async {
    try {
      final user = await UserDirectoryService.getUser(widget.data.patientUid);
      if (!mounted) return;
      setState(() {
        _phone = (user?['phone'] as String?)?.trim();
        _email = (user?['email'] as String?)?.trim();
        _contactLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _contactLoading = false);
    }
  }

  Future<void> _loadAssignedCaregiver() async {
    try {
      final name = await BookingService.getLatestConfirmedCaregiverName(widget.data.patientUid);
      if (!mounted) return;
      setState(() {
        _assignedCaregiver = name;
        _assignedCaregiverLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _assignedCaregiverLoading = false);
    }
  }

  Future<void> _loadBookingCounts() async {
    try {
      final counts = await BookingService.countBookingsForPatient(widget.data.patientUid);
      if (!mounted) return;
      setState(() {
        _bookings = counts.active;
        _cancellations = counts.cancelled;
        _bookingCountsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bookingCountsLoading = false);
    }
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: widget.data.avatarColor,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: Text(
                widget.data.initials,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: widget.data.avatarTextColor,
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
                  widget.data.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.data.demographics,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: demoColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.data.patientId,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: idColor,
                  ),
                ),
                if (!_contactLoading && ((_phone != null && _phone!.isNotEmpty) || (_email != null && _email!.isNotEmpty))) ...[
                  const SizedBox(height: 4),
                  if (_phone != null && _phone!.isNotEmpty)
                    Text(
                      _phone!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: idColor,
                      ),
                    ),
                  if (_email != null && _email!.isNotEmpty)
                    Text(
                      _email!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: idColor,
                      ),
                    ),
                ],
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
    final assignedCaregiverText = _assignedCaregiverLoading
        ? 'Loading...'
        : (_assignedCaregiver != null && _assignedCaregiver!.isNotEmpty)
            ? _assignedCaregiver!
            : 'Not yet assigned';

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
            value: widget.data.careType,
            valueColor: careTypeValue,
            hasDivider: true,
          ),
          _buildRequirementRow(
            label: 'Assigned caregiver',
            value: assignedCaregiverText,
            valueColor: caregiverValue,
            hasDivider: true,
          ),
          _buildRequirementRow(
            label: 'Conditions',
            value: widget.data.conditions,
            valueColor: conditionValue,
            hasDivider: true,
          ),
          _buildRequirementRow(
            label: 'Phone',
            value: _contactLoading
                ? 'Loading...'
                : (_phone != null && _phone!.isNotEmpty)
                    ? _phone!
                    : 'Not provided',
            valueColor: contactValue,
            hasDivider: true,
          ),
          _buildRequirementRow(
            label: 'Email',
            value: _contactLoading
                ? 'Loading...'
                : (_email != null && _email!.isNotEmpty)
                    ? _email!
                    : 'Not provided',
            valueColor: contactValue,
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
            'CARE CIRCLE · ${_careCircle.length} MEMBERS',
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
    if (_careCircleLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: cardBorder, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: circleMemberName),
        ),
      );
    }

    if (_careCircle.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: cardBorder, width: 1.5),
        ),
        child: const Text(
          'No care circle members added yet.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: circleMemberName,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Column(
        children: _careCircle.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isLast = index == _careCircle.length - 1;
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
    final bookingsText = _bookingCountsLoading ? '—' : '${_bookings ?? 0}';
    final cancellationsText = _bookingCountsLoading ? '—' : '${_cancellations ?? 0}';
    final careCircleText = _careCircleLoading ? '—' : '${_careCircle.length}';

    return Row(
      children: [
        Expanded(child: _buildStatCard(bookingsText, 'Bookings')),
        const SizedBox(width: 9),
        Expanded(child: _buildStatCard(cancellationsText, 'Cancellations')),
        const SizedBox(width: 9),
        Expanded(child: _buildStatCard(careCircleText, 'Care circle')),
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
          "Are you sure you want to deactivate ${widget.data.name}'s account? They will no longer be able to access the app.",
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
