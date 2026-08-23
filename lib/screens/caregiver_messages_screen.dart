import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/patient_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Messages List Screen  (Caregiver)
//  Figma node: 355-3405, 599-739
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

  // Empty state palette — Figma node 599-739
  static const Color emptyBg = Color(0xFFFFF8F1);
  static const Color emptyHeaderDark = Color(0xFF1F3554);
  static const Color emptyTitleBrown = Color(0xFF462911);
  static const Color emptyBodyBrown = Color.fromRGBO(70, 41, 17, 0.67);
  static const Color emptyButtonBg = Color(0xFFAAA897);
  static const Color emptyCaptionColor = Color.fromRGBO(0, 0, 0, 0.67);
  static const String _emptyMessagesAsset = 'assets/images/empty_messages.webp';

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

  bool _isAccepted(String status) =>
      status == 'confirmed' ||
      status == 'upcoming' ||
      status == 'ongoing' ||
      status == 'completed';

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

  String _formatMessageTimestamp(dynamic lastMessageAt, DateTime? startDate, bool isUpcoming) {
    if (lastMessageAt is Timestamp) {
      final dt = lastMessageAt.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      final diff = today.difference(msgDay).inDays;
      if (diff == 0) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final min = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$min $period';
      }
      if (diff == 1) return 'Yesterday';
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]}';
    }
    final dLabel = _dateLabel(startDate);
    if (dLabel.isNotEmpty) return dLabel;
    return isUpcoming ? '10:45 AM' : 'Yesterday';
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
    if (_bookingsStream == null) {
      setStatusBarStyle(Brightness.dark);
      return _buildEmptyScaffold(context);
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bookingsStream,
      builder: (context, snapshot) {
        final allBookings = snapshot.data ?? const [];
        final bookings = allBookings
            .where((b) => _isAccepted((b['status'] as String?) ?? ''))
            .toList()
          ..sort((a, b) {
            final at = a['lastMessageAt'] ?? a['createdAt'];
            final bt = b['lastMessageAt'] ?? b['createdAt'];
            if (at is Timestamp && bt is Timestamp) {
              return bt.compareTo(at);
            }
            final asDate = _parseDate(a['startDate'] as String?);
            final bsDate = _parseDate(b['startDate'] as String?);
            if (asDate == null || bsDate == null) return 0;
            return bsDate.compareTo(asDate);
          });

        if (bookings.isEmpty) {
          setStatusBarStyle(Brightness.dark);
          return _buildEmptyScaffold(context);
        }

        setStatusBarStyle(Brightness.light);
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    itemCount: bookings.length,
                    itemBuilder: (context, i) => _buildRow(
                      context,
                      bookings[i],
                      _avatarGradients[i % _avatarGradients.length],
                    ),
                  ),
                ),
                _buildInfoBar(),
              ],
            ),
          ),
        );
      },
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

  // ── Empty state scaffold & view (Figma node 599-739) ───────
  Widget _buildEmptyScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: emptyBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildEmptyHeader(context),
            Expanded(child: _buildEmptyState(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: emptyHeaderDark, size: 20),
          ),
          const SizedBox(width: 16),
          const Text(
            'Messages',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: emptyHeaderDark,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: Image.asset(
              _emptyMessagesAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.chat_bubble_outline_rounded,
                color: emptyButtonBg,
                size: 120,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: emptyTitleBrown,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Messages are unlocked when a booking is confirmed. '
            'Once a booking is confirmed with a patient, you can chat '
            'with them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: emptyBodyBrown,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/caregiver-bookings'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                color: emptyButtonBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'View my bookings',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: emptyTitleBrown,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'You can only message patients linked to an active booking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: emptyCaptionColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, Map<String, dynamic> booking, List<Color> gradient) {
    final startDate = _parseDate(booking['startDate'] as String?);
    final startTime = booking['startTime'] as String?;
    final careType = booking['careType'] as String? ?? 'Elder care';
    final isUpcoming = startDate != null && startDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    final unreadCount = (booking['caregiverUnreadCount'] as num?)?.toInt() ?? 0;
    final lastMessage = (booking['lastMessage'] as String?)?.trim();
    final lastMessageAt = booking['lastMessageAt'];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/caregiver-chat',
        arguments: {
          'patientUid': booking['patientUid'],
          'bookingId': booking['id'],
          'careType': careType,
          'startDate': booking['startDate'] ?? '20 Dec 2025',
          'endDate': booking['endDate'],
          'status': booking['status'],
          'shiftType': booking['shiftType'] ?? 'Full-time',
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: divider, width: 1))),
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
                  child: Text(
                    _initialsOf(name),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF42413F),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                        _formatMessageTimestamp(lastMessageAt, startDate, isUpcoming),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: unreadCount > 0 ? upcomingAccent : mutedTime,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (lastMessage != null && lastMessage.isNotEmpty)
                        ? lastMessage
                        : (startTime != null ? '$careType · $startTime' : 'No messages yet'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: unreadCount > 0 ? const Color(0xFFCBD5E1) : previewText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF76769F),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
