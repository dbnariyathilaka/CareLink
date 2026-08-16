import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Care Circle Screen  (Figma node 374-242)
//  Real family members (patientProfiles/{uid}/familyMembers) and a real
//  activity feed logged from genuine events (a member was added, a booking
//  was requested). "Invite" is relabelled "Add" and adds the member
//  directly — there's no email backend, so a fake "pending invite" that
//  could never be delivered isn't shown. Role badges (Admin/Editor/Viewer)
//  are stored and displayed but not yet enforced elsewhere in the app.
// ─────────────────────────────────────────────────────────────────────────────
class CareCircleScreen extends StatefulWidget {
  const CareCircleScreen({super.key});

  @override
  State<CareCircleScreen> createState() => _CareCircleScreenState();
}

class _CareCircleScreenState extends State<CareCircleScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF06402B);
  static const Color subtitleGreen = Color.fromRGBO(6, 64, 43, 0.65);
  static const Color patientCardBg = Color.fromRGBO(171, 144, 137, 0.75);
  static const Color patientNameColor = Color(0xFF6C3E2A);
  static const Color patientDetailColor = Color.fromRGBO(76, 59, 52, 0.81);
  static const Color patientBadgeBg = Color(0xFFAA8B7E);
  static const Color patientBadgeText = Color(0xFF6A4332);
  static const Color sectionLabel = Color(0xFF58614B);
  static const Color addLink = Color(0xFF066D19);
  static const Color memberCardBg = Color.fromRGBO(135, 159, 133, 0.49);
  static const Color memberCardBorder = Color(0xFF4E6A2D);
  static const Color memberName = Color(0xFF27470F);
  static const Color youSuffix = Color(0xFF69735B);
  static const Color memberRelation = Color.fromRGBO(65, 74, 50, 0.68);
  static const Color adminBadgeBg = Color.fromRGBO(41, 106, 65, 0.15);
  static const Color adminBadgeText = Color(0xFF156532);
  static const Color roleBadgeBg = Color(0xFF4E5E34);
  static const Color roleBadgeText = Color(0xFF99B172);
  static const Color activityCardBg = Color.fromRGBO(177, 162, 143, 0.88);
  static const Color activityDivider = Color(0xFF9E8E79);
  static const Color activityIcon = Color(0xFFFBBC05);
  static const Color activityMessage = Color(0xFF57462E);
  static const Color activityTime = Color.fromRGBO(62, 43, 19, 0.4);

  static const _avatarColors = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFFEC4899),
  ];

  Stream<List<Map<String, dynamic>>>? _membersStream;
  Stream<List<Map<String, dynamic>>>? _activityStream;
  String? _uid;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    final uid = AuthService.currentUser?.uid;
    _uid = uid;
    if (uid != null) {
      _membersStream = PatientService.streamFamilyMembers(uid);
      _activityStream = PatientService.streamActivity(uid);
    }
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  String _subtitleFor(String relation, String role) {
    switch (role) {
      case 'Editor':
        return '$relation · can book & pay';
      case 'Viewer':
        return '$relation · view only';
      default:
        return relation;
    }
  }

  IconData _activityIcon(String? icon) {
    switch (icon) {
      case 'person_add':
        return Icons.person_add_alt_1_rounded;
      case 'event_available':
        return Icons.event_available_rounded;
      default:
        return Icons.circle_notifications_rounded;
    }
  }

  // Figma node 378-330. There's no email/SMS backend to actually deliver an
  // invite, so "Send invite" adds the person to the circle directly — using
  // what they typed (email or phone) as their display name until a real
  // multi-account accept flow exists. No fake "pending" state is shown.
  Future<void> _showInviteSheet() async {
    final uid = _uid;
    if (uid == null) return;
    final contactController = NoUnderlineTextEditingController();
    String relation = 'Son';
    String role = 'Editor';

    const relationOptions = [
      'Son', 'Daughter', 'Spouse', 'Sibling', 'Grandchild', 'Niece/Nephew', 'Friend', 'Other',
    ];
    final patientName = AppState.patientName.value.trim();
    final patientFirstName = patientName.isEmpty ? 'the patient' : patientName.split(' ').first;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Padding(
          // viewInsets covers the keyboard; padding.bottom covers the
          // on-screen nav bar — missing the latter is why "Send invite"
          // was getting clipped by it.
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom +
                MediaQuery.of(sheetCtx).padding.bottom,
          ),
          child: StatefulBuilder(
            builder: (builderCtx, setSheetState) {
              return Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF444935),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const Text(
                      'Invite a family member',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color(0xFF444935),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "They'll get access to $patientFirstName's care based on the role you choose.",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color.fromRGBO(68, 73, 53, 0.78),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Email or phone',
                      style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF52593B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(68, 73, 53, 0.26),
                        border: Border.all(color: const Color(0xFF444935), width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: contactController,
                        style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF2B321D), fontSize: 12, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 17.5, vertical: 15.5),
                          hintText: 'tharaka@email.com',
                          hintStyle: TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(43, 50, 29, 0.42), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Relationship with patient',
                      style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF52593B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: builderCtx,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (pickerCtx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: relationOptions.map((r) {
                                final isSelected = r == relation;
                                return ListTile(
                                  title: Text(
                                    r,
                                    style: TextStyle(
                                      color: const Color(0xFF2B321D),
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                  trailing: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF444935)) : null,
                                  onTap: () => Navigator.pop(pickerCtx, r),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                        if (picked != null) setSheetState(() => relation = picked);
                      },
                      child: Container(
                        height: 47,
                        padding: const EdgeInsets.symmetric(horizontal: 15.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFD0CB),
                          border: Border.all(color: const Color(0xFF444935), width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(relation, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF2B321D), fontSize: 12, fontWeight: FontWeight.w500)),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2B321D), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Role',
                      style: TextStyle(fontFamily: 'Inter', color: Color(0xFF52593B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 9),
                    _roleCard(
                      icon: Icons.edit_calendar_rounded,
                      title: 'Editor',
                      description: 'Book, pay & message caregivers',
                      selected: role == 'Editor',
                      onTap: () => setSheetState(() => role = 'Editor'),
                    ),
                    const SizedBox(height: 9),
                    _roleCard(
                      icon: Icons.visibility_rounded,
                      title: 'Viewer',
                      description: 'See schedule & journal only',
                      selected: role == 'Viewer',
                      onTap: () => setSheetState(() => role = 'Viewer'),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: const Color(0xFFBBABA4),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final contact = contactController.text.trim();
                            if (contact.isEmpty) {
                              ScaffoldMessenger.of(builderCtx).showSnackBar(
                                const SnackBar(content: Text('Please enter an email or phone number.')),
                              );
                              return;
                            }
                            await PatientService.addFamilyMember(
                              patientUid: uid,
                              name: contact,
                              relation: relation,
                              role: role,
                            );
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Added to your care circle.')),
                              );
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Send invite',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Inter', color: Color(0xFF44332B), fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF4E4533),
          border: Border.all(color: const Color(0xFF735C2F), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFBBC05), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(description, style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: const Color(0xFFFBBC05),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientCard(),
                    const SizedBox(height: 18),
                    _buildFamilyMembersSection(),
                    const SizedBox(height: 22),
                    _buildActivitySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final patientName = AppState.patientName.value.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Care Circle',
                style: TextStyle(fontFamily: 'Open Sans', color: titleGreen, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 46, top: 2),
            child: Text(
              patientName.isEmpty ? 'Caring for your loved one' : 'Caring for $patientName',
              style: const TextStyle(fontFamily: 'Open Sans', color: subtitleGreen, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    final name = AppState.patientName.value.trim();
    final age = AppState.patientAge.value.trim();
    final address = AppState.patientAddress.value.trim();
    final notes = AppState.additionalCareNotes.value.trim();
    final displayName = name.isEmpty ? 'Patient' : name;
    final nameLine = age.isEmpty ? displayName : '$displayName · $age';
    final detailLine = [address, notes].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: patientCardBg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            alignment: Alignment.center,
            child: Text(
              _initialsOf(displayName),
              style: const TextStyle(fontFamily: 'Inter', color: patientNameColor, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameLine,
                  style: const TextStyle(fontFamily: 'Open Sans', color: patientNameColor, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (detailLine.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailLine,
                    style: const TextStyle(fontFamily: 'Open Sans', color: patientDetailColor, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: patientBadgeBg, borderRadius: BorderRadius.circular(999)),
            child: const Text(
              'PATIENT',
              style: TextStyle(fontFamily: 'Open Sans', color: patientBadgeText, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersSection() {
    final youName = AuthService.currentUser?.displayName?.trim();
    final youRelation = AppState.relationToPatient.value;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _membersStream,
      builder: (context, snapshot) {
        final members = snapshot.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FAMILY MEMBERS · ${members.length + 1}',
                  style: const TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                GestureDetector(
                  onTap: _showInviteSheet,
                  child: const Text(
                    'Add',
                    style: TextStyle(fontFamily: 'Open Sans', color: addLink, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            _buildMemberRow(
              avatarColor: _avatarColors[0],
              initials: _initialsOf(youName?.isNotEmpty == true ? youName! : 'You'),
              name: youName?.isNotEmpty == true ? youName! : 'You',
              isYou: true,
              subtitle: youRelation,
              role: 'Admin',
            ),
            ...List.generate(members.length, (i) {
              final m = members[i];
              final name = (m['name'] as String?) ?? 'Family member';
              final relation = (m['relation'] as String?) ?? '';
              final role = (m['role'] as String?) ?? 'Viewer';
              return Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Dismissible(
                  key: ValueKey(m['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    final uid = _uid;
                    if (uid != null) PatientService.removeFamilyMember(uid, m['id'] as String);
                  },
                  child: _buildMemberRow(
                    avatarColor: _avatarColors[(i + 1) % _avatarColors.length],
                    initials: _initialsOf(name),
                    name: name,
                    isYou: false,
                    subtitle: _subtitleFor(relation, role),
                    role: role,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMemberRow({
    required Color avatarColor,
    required String initials,
    required String name,
    required bool isYou,
    required String subtitle,
    required String role,
  }) {
    final isAdmin = role == 'Admin';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: memberCardBg,
        border: Border.all(color: memberCardBorder, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(shape: BoxShape.circle, color: avatarColor),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Inter', color: memberName, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isYou) ...[
                      const SizedBox(width: 4),
                      const Text('(You)', style: TextStyle(fontFamily: 'Open Sans', color: youSuffix, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
                Text(subtitle, style: const TextStyle(fontFamily: 'Inter', color: memberRelation, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isAdmin ? adminBadgeBg : roleBadgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter',
                color: isAdmin ? adminBadgeText : roleBadgeText,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _activityStream,
      builder: (context, snapshot) {
        final activity = snapshot.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RECENT ACTIVITY',
              style: TextStyle(fontFamily: 'Open Sans', color: sectionLabel, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            if (activity.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: activityCardBg, borderRadius: BorderRadius.circular(12)),
                child: const EmptyState(
                  icon: Icons.history_rounded,
                  message: 'No activity yet.',
                  iconColor: activityMessage,
                  textColor: activityMessage,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: activityCardBg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: List.generate(activity.length, (i) {
                    final entry = activity[i];
                    final isLast = i == activity.length - 1;
                    final createdAt = entry['createdAt'];
                    final timeLabel = createdAt is Timestamp ? _timeAgo(createdAt.toDate()) : '';
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      decoration: isLast
                          ? null
                          : const BoxDecoration(border: Border(bottom: BorderSide(color: activityDivider, width: 1))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_activityIcon(entry['icon'] as String?), color: activityIcon, size: 19),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (entry['message'] as String?) ?? '',
                                  style: const TextStyle(fontFamily: 'Open Sans', color: activityMessage, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                if (timeLabel.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(timeLabel, style: const TextStyle(fontFamily: 'Open Sans', color: activityTime, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}
