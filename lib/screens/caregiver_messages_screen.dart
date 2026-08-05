import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/patient_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Messages List Screen  (Caregiver)
//  Figma node: 355-3405
//  There's no persisted message-thread backend (patient_chat_screen.dart's
//  chat is a local, non-persisted simulation), so this can't show real
//  "last message" previews, timestamps, or unread counts like Figma's mock.
//  Instead each row is a real booking assigned to this caregiver — real
//  patient name, real care type/schedule in place of a fabricated message
//  preview, and a real "Upcoming" flag computed from the booking's actual
//  start time.
// ─────────────────────────────────────────────────────────────
class CaregiverMessagesScreen extends StatefulWidget {
  const CaregiverMessagesScreen({super.key});

  @override
  State<CaregiverMessagesScreen> createState() => _CaregiverMessagesScreenState();
}

class _CaregiverMessagesScreenState extends State<CaregiverMessagesScreen> {
  static const Color bg = Color(0xFF162131);
  static const Color divider = Color(0xFF1F3554);
  static const Color titleText = Color(0xFFF8FAFC);
  static const Color nameText = Color(0xFFF8FAFC);
  static const Color upcomingAccent = Color(0xFF6366F1);
  static const Color mutedTime = Color(0xFF64748B);
  static const Color previewText = Color(0xFF94A3B8);
  static const Color infoText = Color(0xFF64748B);

  static const _avatarGradients = [
    [Color(0xFF22C55E), Color(0xFF16A34A)],
    [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    [Color(0xFF6D4275), Color(0xFF44145A)],
    [Color(0xFFF59E0B), Color(0xFFDF8007)],
  ];

  Stream<List<Map<String, dynamic>>>? _bookingsStream;
  final Map<String, String> _patientNames = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForCaregiver(uid);
    }
  }

  Future<String> _resolvePatientName(String? patientUid) async {
    if (patientUid == null) return 'Patient';
    final cached = _patientNames[patientUid];
    if (cached != null) return cached;
    final profile = await PatientService.getPatientProfile(patientUid);
    final name = (profile?['name'] as String?)?.trim();
    final resolved = name != null && name.isNotEmpty ? name : 'Patient';
    _patientNames[patientUid] = resolved;
    if (mounted) setState(() {});
    return resolved;
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = dateStr.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
            _buildInfoBar(),
          ],
        ),
      ),
    );
  }

  // ── Page header ───────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 8, 22, 12),
      child: Text(
        'Messages',
        style: TextStyle(fontFamily: 'Inter', color: titleText, fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_bookingsStream == null) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        message: 'No conversations yet — messaging unlocks once you have a confirmed booking.',
      );
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        final bookings = (snapshot.data ?? const [])
            .where((b) => b['status'] != 'cancelled')
            .toList()
          ..sort((a, b) {
            final at = _parseDate(a['startDate'] as String?);
            final bt = _parseDate(b['startDate'] as String?);
            if (at == null || bt == null) return 0;
            return bt.compareTo(at);
          });

        if (bookings.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            message: 'No conversations yet — messaging unlocks once you have a confirmed booking.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: bookings.length,
          itemBuilder: (context, i) => _buildRow(context, bookings[i], _avatarGradients[i % _avatarGradients.length]),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, Map<String, dynamic> booking, List<Color> gradient) {
    final startDate = _parseDate(booking['startDate'] as String?);
    final startTime = booking['startTime'] as String?;
    final careType = booking['careType'] as String? ?? 'Care visit';
    final isUpcoming = startDate != null && startDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/caregiver-chat',
        arguments: {
          'patientUid': booking['patientUid'],
          'bookingId': booking['id'],
          'careType': careType,
          'startDate': booking['startDate'],
          'endDate': booking['endDate'],
          'status': booking['status'],
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: divider))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<String>(
              future: _resolvePatientName(booking['patientUid'] as String?),
              builder: (context, snap) {
                final name = snap.data ?? 'Patient';
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
                  ),
                  alignment: Alignment.center,
                  child: Text(_initialsOf(name), style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _resolvePatientName(booking['patientUid'] as String?),
                          builder: (context, snap) => Text(
                            snap.data ?? 'Patient',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Inter', color: nameText, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateLabel(startDate),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isUpcoming ? upcomingAccent : mutedTime,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    startTime != null ? '$careType · $startTime' : careType,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', color: previewText, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (isUpcoming) ...[
                    const SizedBox(height: 3),
                    const Text(
                      'Upcoming',
                      style: TextStyle(fontFamily: 'Inter', color: upcomingAccent, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom info bar ───────────────────────────────────────
  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: divider, width: 1))),
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 14),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: infoText, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Messages are only available for confirmed bookings.',
              style: TextStyle(fontFamily: 'Inter', color: infoText, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
