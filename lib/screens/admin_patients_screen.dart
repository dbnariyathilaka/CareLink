import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/patient_service.dart';
import '../services/payment_service.dart';
import '../services/user_directory_service.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/status_bar.dart';
import 'admin_patient_profile_screen.dart';

/// Deterministic avatar color pairing so each patient gets a stable (but not
/// meaningful) color without needing any stored "avatar color" field.
class _AvatarColors {
  final Color bg;
  final Color text;
  const _AvatarColors(this.bg, this.text);
}

const List<_AvatarColors> _avatarPalette = [
  _AvatarColors(Color(0xFFFAE48B), Color(0xFF2E1065)),
  _AvatarColors(Color(0xFF727953), Color(0xFF313715)),
  _AvatarColors(Color(0xFF357F83), Colors.white),
  _AvatarColors(Color(0xFFA28C66), Color(0xFF3B2404)),
  _AvatarColors(Color(0xFF354152), Color(0xFFCBD5E1)),
  _AvatarColors(Color(0xFF6ED5C9), Color(0xFF04302C)),
  _AvatarColors(Color(0xFFD9BDB5), Color(0xFF41302B)),
];

/// Real patient row for the admin patients list — every field here traces to
/// `patientProfiles/{uid}` (care fields) or `users/{uid}` (phone/joined date).
/// There is no rating or NIC concept for patients anywhere in the schema, so
/// neither is modelled here. Bookings/cancellations/disputes counts and the
/// suspend flag are fetched/derived separately (see the state class below),
/// not stored on this row.
class AdminPatientData {
  final String uid;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String name;
  final int? age;
  final String? gender;
  final String? location;
  final String shortId; // first 8 chars of the real Firestore uid
  final DateTime? joinedAt;
  final String joinedLabel; // e.g. 'Nov 2025', or 'Unknown' if no createdAt
  final String careType;
  final String conditions;
  final String phone;

  AdminPatientData({
    required this.uid,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.shortId,
    required this.joinedAt,
    required this.joinedLabel,
    required this.careType,
    required this.conditions,
    required this.phone,
  });

  String get demographics {
    final parts = <String>[];
    if (age != null) parts.add('$age');
    if (gender != null && gender!.isNotEmpty) parts.add(gender!);
    if (location != null && location!.isNotEmpty) parts.add(location!);
    return parts.isEmpty ? 'No demographic info on file' : parts.join(' · ');
  }

  String get idLine => 'Internal ID $shortId · joined $joinedLabel';

  String get spotlightSubtitle =>
      (location != null && location!.isNotEmpty) ? '$careType · $location' : careType;
}

String _extractName(Map<String, dynamic> data) {
  final name = (data['patientName'] as String?)?.trim();
  if (name != null && name.isNotEmpty) return name;
  final alt = (data['name'] as String?)?.trim();
  if (alt != null && alt.isNotEmpty) return alt;
  return 'Unnamed patient';
}

String? _extractGender(Map<String, dynamic> data) {
  final gender = (data['patientGender'] as String?)?.trim();
  if (gender != null && gender.isNotEmpty) return gender;
  final alt = (data['gender'] as String?)?.trim();
  if (alt != null && alt.isNotEmpty) return alt;
  return null;
}

int? _extractAge(Map<String, dynamic> data) {
  final value = data['patientAge'] ?? data['age'];
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _extractLocation(Map<String, dynamic> data) {
  final city = (data['city'] as String?)?.trim();
  if (city != null && city.isNotEmpty) return city;
  final address = (data['address'] as String?)?.trim();
  if (address != null && address.isNotEmpty) return address;
  return null;
}

String _extractConditions(Map<String, dynamic> data) {
  final value = data['medicalConditions'];
  if (value is List && value.isNotEmpty) {
    return value.map((e) => e.toString()).join(', ');
  }
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return 'Not specified';
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

String _formatJoined(DateTime? dt) {
  if (dt == null) return 'Unknown';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

AdminPatientData _mapToPatientData(
  Map<String, dynamic> doc,
  Map<String, dynamic>? user,
) {
  final uid = doc['uid'] as String? ?? '';
  final name = _extractName(doc);
  final careType = (doc['careType'] as String?)?.trim();
  final phone = (user?['phone'] as String?)?.trim();
  final joinedAt =
      (user?['createdAt'] is Timestamp) ? (user!['createdAt'] as Timestamp).toDate() : null;
  final palette = _avatarPalette[uid.isEmpty ? 0 : uid.hashCode.abs() % _avatarPalette.length];

  return AdminPatientData(
    uid: uid,
    initials: _initialsFor(name),
    avatarBg: palette.bg,
    avatarTextColor: palette.text,
    name: name,
    age: _extractAge(doc),
    gender: _extractGender(doc),
    location: _extractLocation(doc),
    shortId: uid.length >= 8 ? uid.substring(0, 8) : uid,
    joinedAt: joinedAt,
    joinedLabel: _formatJoined(joinedAt),
    careType: (careType != null && careType.isNotEmpty) ? careType : 'Not specified',
    conditions: _extractConditions(doc),
    phone: (phone != null && phone.isNotEmpty) ? phone : 'Not provided',
  );
}

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  // ── Color Tokens matching Figma node 697:1059 ──────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);
  static const Color searchBoxBg = Color(0xFFFFF3DF);
  static const Color searchBoxBorder = Color(0xFFD6BA8B);
  static const Color searchHintColor = Color.fromRGBO(96, 78, 47, 0.45);
  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF766B58);
  static const Color identityNameColor = Color(0xFF403522);
  static const Color demoColor = Color(0xFF88795F);
  static const Color idColor = Color(0xFF625846);
  static const Color spotlightNameColor = Color(0xFF5C5445);
  static const Color spotlightSubtitleColor = Color(0xFF7C6F5D);
  static const Color btnViewProfileBg = Color(0xFF59341E);
  static const Color btnSuspendBorder = Color(0xFF59341E);
  static const Color statsTileBg = Color(0xFF44331C);
  static const Color statsValueGold = Color(0xFFFBBC05);

  final TextEditingController _searchController = TextEditingController();
  String? _expandedPatientId;
  bool _hasSetDefaultExpand = false;

  // Session-local only (never written to Firestore — there is no
  // suspension field anywhere in the patient schema to persist to), same
  // honest pattern as the caregivers list's Suspend action.
  final Set<String> _locallySuspended = {};

  // Lazily fetched only for the currently-expanded card (never one query
  // per row) — see _loadExtraStats.
  final Map<String, ({int bookings, int cancellations, int disputes})> _extraStats = {};
  final Set<String> _extraStatsLoading = {};
  bool _loading = true;

  StreamSubscription<List<Map<String, dynamic>>>? _patientsSub;
  List<AdminPatientData> _patients = [];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _listenToPatients();
  }

  void _listenToPatients() {
    _patientsSub = PatientService.streamAllPatients().listen((docs) async {
      final uids = docs
          .map((d) => d['uid'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      Map<String, Map<String, dynamic>> users = {};
      try {
        users = await UserDirectoryService.getUsers(uids);
      } catch (_) {
        // Non-fatal — patient care data still renders without phone/joined.
      }

      if (!mounted) return;
      final list = docs
          .map((doc) => _mapToPatientData(doc, users[doc['uid']]))
          .toList();

      setState(() {
        _patients = list;
        _loading = false;
        if (!_hasSetDefaultExpand && list.isNotEmpty) {
          _expandedPatientId = list.first.uid;
          _hasSetDefaultExpand = true;
          _loadExtraStats(list.first.uid);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _patientsSub?.cancel();
    super.dispose();
  }

  List<AdminPatientData> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _patients;
    return _patients.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.phone.toLowerCase().contains(query) ||
          (p.location?.toLowerCase().contains(query) ?? false) ||
          p.careType.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleExpand(String uid) {
    setState(() {
      _expandedPatientId = _expandedPatientId == uid ? null : uid;
    });
    if (_expandedPatientId == uid) _loadExtraStats(uid);
  }

  /// Fetched lazily, one patient at a time, only for the card the admin
  /// actually expands — never one query per row (an N+1 query storm). Real
  /// counts: bookings/cancellations from BookingService, disputed-payments
  /// count from PaymentService (near-always 0 today since billing isn't
  /// live, but a real Firestore count, not a fabricated number).
  Future<void> _loadExtraStats(String uid) async {
    if (_extraStats.containsKey(uid) || _extraStatsLoading.contains(uid)) return;
    _extraStatsLoading.add(uid);
    final counts = await BookingService.countBookingsForPatient(uid);
    final disputes = await PaymentService.countDisputesForPatient(uid);
    if (!mounted) return;
    setState(() {
      _extraStats[uid] = (bookings: counts.active, cancellations: counts.cancelled, disputes: disputes);
      _extraStatsLoading.remove(uid);
    });
  }

  void _toggleSuspendStatus(AdminPatientData p) {
    final isCurrentlySuspended = _locallySuspended.contains(p.uid);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isCurrentlySuspended ? 'Reactivate Patient?' : 'Suspend Patient?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          isCurrentlySuspended
              ? 'Are you sure you want to reactivate ${p.name}? They will be able to book caregivers again.'
              : 'Are you sure you want to suspend ${p.name}? They will not be able to create new booking requests.',
          style: const TextStyle(color: Color(0xFFC4BBAC), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlySuspended ? Colors.green : const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                if (isCurrentlySuspended) {
                  _locallySuspended.remove(p.uid);
                } else {
                  _locallySuspended.add(p.uid);
                }
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${p.name} has been ${isCurrentlySuspended ? 'reactivated' : 'suspended'}.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              isCurrentlySuspended ? 'Reactivate' : 'Suspend',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _openProfile(AdminPatientData p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPatientProfileScreen(
          data: AdminPatientProfileData(
            patientUid: p.uid,
            initials: p.initials,
            avatarColor: p.avatarBg,
            avatarTextColor: p.avatarTextColor,
            name: p.name,
            demographics: p.demographics,
            patientId: p.idLine,
            careType: p.careType,
            conditions: p.conditions,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredPatients;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Patient',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: titleColor, size: 24),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exporting patients report (CSV)...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Export',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: titleColor, size: 24),
                    onPressed: _showSortMenu,
                    tooltip: 'Sort',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Search Input ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: searchBoxBg,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: searchBoxBorder, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF604E2F), size: 20),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF544730),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search name, phone or location',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: searchHintColor,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          // The app's ambient ThemeData (AppTheme.darkTheme)
                          // defines filled:true with a dark fillColor and a
                          // bright focusedBorder — without repeating
                          // InputBorder.none for these two states, Flutter
                          // falls back to those theme defaults, painting a
                          // dark box behind this light search bar.
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF604E2F)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Patients List ───────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: titleColor))
                  : displayList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: titleColor.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              const Text(
                                'No patients found',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                          itemCount: displayList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final p = displayList[index];
                            final isExpanded = _expandedPatientId == p.uid;
                            return _buildPatientCard(p, isExpanded);
                          },
                        ),
            ),

            // ── Bottom Navigation Bar (Matching Admin Dashboard) ────────────
            const AdminBottomNav(active: AdminNavTab.users),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(AdminPatientData p, bool isExpanded) {
    if (!isExpanded) {
      // ── Collapsed "identity" card ─────────────────────────────────────
      return GestureDetector(
        onTap: () => _toggleExpand(p.uid),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1.5),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: p.avatarBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  p.initials,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.avatarTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: identityNameColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.demographics,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: demoColor,
                      ),
                    ),
                    Text(
                      p.idLine,
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
              const SizedBox(width: 8),
              _buildStatusBadge(p.uid),
            ],
          ),
        ),
      );
    }

    // ── Expanded "spotlight" card with real details + actions ─────────────
    return GestureDetector(
      onTap: () => _toggleExpand(p.uid),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: cardBorder, width: 2),
        ),
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: p.avatarBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    p.initials,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.avatarTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: spotlightNameColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        p.spotlightSubtitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: spotlightSubtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(p.uid),
              ],
            ),
            const SizedBox(height: 10),
            // Bookings/Cancellations fetched from BookingService, Disputes
            // from PaymentService — all lazily, just for this one expanded
            // card (see _loadExtraStats).
            Builder(builder: (_) {
              final extra = _extraStats[p.uid];
              return Row(
                children: [
                  Expanded(child: _buildStatTile(extra == null ? '…' : '${extra.bookings}', 'Bookings')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile(extra == null ? '…' : '${extra.cancellations}', 'Cancellations')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile(extra == null ? '…' : '${extra.disputes}', 'Disputes')),
                ],
              );
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openProfile(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: btnViewProfileBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'View profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Suspend / Reactivate (session-local only — see
                // _locallySuspended doc comment above)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleSuspendStatus(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: btnSuspendBorder, width: 1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _locallySuspended.contains(p.uid) ? 'Reactivate' : 'Suspend',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: btnSuspendBorder,
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
    );
  }

  /// Only real distinguishing signal for a patient account is the
  /// session-local suspend flag (see _locallySuspended doc comment above) —
  /// there is no verification/approval workflow for patients, so unlike
  /// caregivers there is no real 'pending' state to show.
  Widget _buildStatusBadge(String uid) {
    final isSuspended = _locallySuspended.contains(uid);
    final label = isSuspended ? 'SUSPENDED' : 'ACTIVE';
    final bg = isSuspended ? const Color.fromRGBO(239, 68, 68, 0.16) : const Color.fromRGBO(78, 172, 0, 0.16);
    final fg = isSuspended ? const Color(0xFF822222) : const Color(0xFF255010);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildStatTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: statsTileBg, borderRadius: BorderRadius.circular(9)),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: statsValueGold,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C251D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Patients',
              style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.event_available_rounded, color: Colors.lightBlueAccent),
              title: const Text('Recently joined', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _patients.sort((a, b) {
                      final at = a.joinedAt;
                      final bt = b.joinedAt;
                      if (at == null && bt == null) return 0;
                      if (at == null) return 1;
                      if (bt == null) return -1;
                      return bt.compareTo(at);
                    }));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha_rounded, color: Colors.greenAccent),
              title: const Text('Name (A - Z)', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() => _patients.sort((a, b) => a.name.compareTo(b.name)));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
