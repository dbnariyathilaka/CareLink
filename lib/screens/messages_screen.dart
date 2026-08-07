import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Messages List Screen  (Patient)
//  Figma node: 378-342
//  Messaging unlocks once a booking is past "requested" — no
//  caregiver-side accept flow or chat backend exists yet, so
//  rows show the real booking/caregiver but an honest "No
//  messages yet" preview instead of a fabricated conversation.
// ─────────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  static const Color bg = Color(0xFF06402B);
  static const Color rowDivider = Color.fromRGBO(41, 139, 103, 0.27);
  static const Color previewText = Color.fromRGBO(195, 188, 179, 0.44);
  static const Color refText = Color.fromRGBO(242, 195, 123, 0.72);
  static const Color statusText = Color(0xFF94A3B8);
  static const Color footerBorder = Color.fromRGBO(138, 117, 84, 0.52);
  static const Color footerText = Color.fromRGBO(203, 186, 136, 0.55);

  // Empty state — Figma node 294-169. A different visual language (light,
  // illustrated) than the populated chat list, so it gets its own palette.
  static const Color emptyBg = Color(0xFFFFF8F1);
  static const Color emptyHeaderGreen = Color(0xFF0F3D2E);
  static const Color emptyTitleBrown = Color(0xFF462911);
  static const Color emptyBodyBrown = Color.fromRGBO(70, 41, 17, 0.67);
  static const Color emptyButtonBg = Color(0xFFAAA897);
  static const Color emptyCaptionColor = Color.fromRGBO(0, 0, 0, 0.67);
  static const String _emptyMessagesAsset = 'assets/images/empty_messages.webp';

  static const _avatarGradients = [
    [Color(0xFF22C55E), Color(0xFF16A34A)],
    [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
  ];

  Stream<List<Map<String, dynamic>>>? _bookingsStream;

  @override
  void initState() {
    super.initState();
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForPatient(uid);
    }
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Messaging is only meaningful once a booking has moved past a bare
  // request — matches the footer's "confirmed bookings" copy.
  bool _isUnlocked(String status) =>
      status == 'upcoming' || status == 'ongoing' || status == 'completed';

  String _statusLabel(String status) {
    switch (status) {
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'upcoming':
        return 'Upcoming';
      default:
        return status;
    }
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
        final docs = snapshot.data ?? const [];
        final unlocked =
            docs.where((d) => _isUnlocked(d['status'] as String? ?? '')).toList();
        if (unlocked.isEmpty) {
          setStatusBarStyle(Brightness.dark);
          return _buildEmptyScaffold(context);
        }
        setStatusBarStyle(Brightness.light);
        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.builder(
                    itemCount: unlocked.length,
                    itemBuilder: (context, i) => _buildRow(context, unlocked[i], i),
                  ),
                ),
                _buildFooterNote(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Page header ───────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Text(
            'Messages',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Conversation row (real booking, honest "no messages yet") ──
  Widget _buildRow(BuildContext context, Map<String, dynamic> booking, int index) {
    final name = (booking['caregiverName'] as String?) ?? 'Caregiver';
    final status = (booking['status'] as String?) ?? '';
    final careType = booking['careType'] as String?;
    final id = booking['id'] as String? ?? '';
    final ref = id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
    final gradient = _avatarGradients[index % _avatarGradients.length];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'caregiverId': booking['caregiverId'],
          'caregiverName': name,
          'bookingId': id,
          'careType': careType,
          'startDate': booking['startDate'],
          'endDate': booking['endDate'],
          'status': status,
        },
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(23, 13, 18, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: rowDivider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initialsFor(name),
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _statusLabel(status),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: statusText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'No messages yet',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: previewText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (ref.isNotEmpty) 'Ref $ref',
                      if (careType != null && careType.isNotEmpty) careType,
                    ].join(' · '),
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: refText,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: footerBorder)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, color: footerText, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Calls & messages are only available for confirmed bookings.',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: footerText,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Honest empty state (no unlocked bookings yet) — Figma node 294-169 ──
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: emptyHeaderGreen, size: 20),
          ),
          const SizedBox(width: 16),
          const Text(
            'Messages',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: emptyHeaderGreen,
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
            width: 220,
            height: 220,
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
            'Once a caregiver accepts your request, you can chat '
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
            onTap: () => Navigator.pushNamed(context, '/my-bookings'),
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
            'You can only message caregivers linked to an active booking.',
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
}
