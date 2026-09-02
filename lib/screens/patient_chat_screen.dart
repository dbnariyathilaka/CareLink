import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'call_screen.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/chat_service.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Chat Screen  (Chat Thread — Patient view)
//  Figma node: 388-144
// ─────────────────────────────────────────────────────────────
class PatientChatScreen extends StatefulWidget {
  const PatientChatScreen({super.key});

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  static const Color bg = Color(0xFF0F3326);
  static const Color headerBorder = Color.fromRGBO(53, 157, 119, 0.2);
  static const Color bannerBg = Color.fromRGBO(30, 30, 30, 0.4);
  static const Color bannerText = Color(0xFF94A3B8);
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color receivedBubbleBg = Color(0xFF1E3B30);
  static const Color receivedBubbleText = Color(0xFF5ED5A7);
  static const Color sentBubbleBg = Color(0xFFE8DAC2);
  static const Color sentBubbleText = Color(0xFF42413F);
  static const Color timestampColor = Color(0xFF64748B);
  static const Color callLogBg = Color.fromRGBO(34, 197, 94, 0.1);
  static const Color callLogBorder = Color(0xFF7D6A15);
  static const Color inputBorder = Color(0xFFD7B68C);
  static const Color roundBtnBg = Color(0xFF4C4932);
  static const Color roundBtnBorder = Color(0xFF6D7246);
  static const Color roundBtnIcon = Color(0xFFB69563);
  static const Color callBtnBg = Color.fromRGBO(102, 81, 54, 0.71);
  static const Color callBtnBorder = Color(0xFF6D7246);
  static const Color callBtnIcon = Color(0xFFF5C381);

  final TextEditingController _textController = NoUnderlineTextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> _args = {};
  bool _loadedArgs = false;
  Stream<List<Map<String, dynamic>>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _args = Map<String, dynamic>.from(args);
    }
    final bookingId = _args['bookingId'] as String?;
    if (bookingId != null && bookingId.isNotEmpty) {
      _messagesStream = ChatService.streamMessages(bookingId);
      ChatService.markAsRead(bookingId: bookingId, readerRole: 'patient');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _caregiverName => (_args['caregiverName'] as String?) ?? 'Caregiver';
  String? get _photoUrl => (_args['caregiverPhotoUrl'] as String?)?.trim();
  String? get _caregiverId => _args['caregiverId'] as String?;

  String get _initials {
    final parts = _caregiverName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get _status => (_args['status'] as String?) ?? 'upcoming';

  Color get _statusColor {
    switch (_status) {
      case 'ongoing':
        return accentGreen;
      case 'completed':
        return timestampColor;
      default:
        return const Color(0xFFFFA722);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'ongoing':
        return 'Booking ongoing';
      case 'completed':
        return 'Booking completed';
      default:
        return 'Booking upcoming';
    }
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final bookingId = _args['bookingId'] as String?;
    final senderId = AuthService.currentUser?.uid ?? '';
    _textController.clear();

    if (bookingId != null && bookingId.isNotEmpty) {
      await ChatService.sendMessage(
        bookingId: bookingId,
        senderId: senderId,
        senderRole: 'patient',
        text: text,
      );
    }
    _scrollToBottom();
  }

  Future<void> _startCall(bool isVideo) async {
    final duration = await Navigator.push<Duration?>(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          calleeName: _caregiverName,
          initials: _initials,
          isVideo: isVideo,
        ),
      ),
    );
    if (duration == null || !mounted) return;
    final bookingId = _args['bookingId'] as String?;
    final senderId = AuthService.currentUser?.uid ?? '';
    if (bookingId != null && bookingId.isNotEmpty) {
      await ChatService.logCall(
        bookingId: bookingId,
        senderId: senderId,
        senderRole: 'patient',
        isVideo: isVideo,
        duration: duration,
      );
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _notAvailableYet(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature isn\'t available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildBookingBanner(context),
            Expanded(child: _buildMessageArea()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Header: back, avatar, name, booking status, call/video ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: headerBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
            ),
          ),
          ClipOval(
            child: (_photoUrl != null && _photoUrl!.isNotEmpty)
                ? RemoteOrLocalImage(
                    source: _photoUrl!,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  )
                : (_caregiverId != null && _caregiverId!.isNotEmpty)
                    ? FutureBuilder<Map<String, dynamic>?>(
                        future: CaregiverService.getCaregiverProfile(_caregiverId!),
                        builder: (context, snap) {
                          final pUrl = (snap.data?['photoUrl'] as String?)?.trim();
                          if (pUrl != null && pUrl.isNotEmpty) {
                            return RemoteOrLocalImage(
                              source: pUrl,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                            );
                          }
                          return Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF42413F),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF42413F),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _caregiverName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _startCall(false),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: callBtnBg,
                shape: BoxShape.circle,
                border: Border.all(color: callBtnBorder),
              ),
              child: const Icon(Icons.call_rounded, color: callBtnIcon, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _startCall(true),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: callBtnBg,
                shape: BoxShape.circle,
                border: Border.all(color: callBtnBorder),
              ),
              child: const Icon(Icons.videocam_rounded, color: callBtnIcon, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking banner ───────────────────────────────────────────
  Widget _buildBookingBanner(BuildContext context) {
    final careType = _args['careType'] as String?;
    final startDate = _args['startDate'] as String?;
    final endDate = _args['endDate'] as String?;
    final dateRange = startDate != null && endDate != null ? '$startDate – $endDate' : startDate;
    final parts = [
      if (careType != null && careType.isNotEmpty) careType,
      ?dateRange,
    ];
    final label = parts.isEmpty ? 'Booking details' : 'Booking: ${parts.join(' · ')}';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/my-bookings'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        color: bannerBg,
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: accentGreen, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: bannerText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Text(
              'View',
              style: TextStyle(
                fontFamily: 'Inter',
                color: accentGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Live message area ─────────────────────────────────────────
  Widget _buildMessageArea() {
    if (_messagesStream == null) {
      return _buildEmptyPlaceholder();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const [];

        if (messages.isEmpty) {
          return _buildEmptyPlaceholder();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, i) => _buildEntry(messages[i]),
        );
      },
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'No messages yet. Say hello below, or start a call using the buttons above.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(Map<String, dynamic> message) {
    final type = message['type'] as String? ?? 'text';
    final senderRole = message['senderRole'] as String? ?? 'caregiver';
    final fromMe = senderRole == 'patient';
    final text = message['text'] as String? ?? '';
    final createdAt = message['createdAt'];
    final time = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();

    if (type == 'callLog') {
      final isVideo = text.startsWith('Video');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: callLogBg,
              border: Border.all(color: callLogBorder),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded, color: callLogBorder, size: 15),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    color: callLogBorder,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: fromMe ? sentBubbleBg : receivedBubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(fromMe ? 14 : 4),
                bottomRight: Radius.circular(fromMe ? 4 : 14),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: fromMe ? sentBubbleText : receivedBubbleText,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _formatTime(time),
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: timestampColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: headerBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: inputBorder),
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _textController,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _notAvailableYet('Voice messages'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roundBtnBg,
                shape: BoxShape.circle,
                border: Border.all(color: roundBtnBorder),
              ),
              child: const Icon(Icons.mic_rounded, color: roundBtnIcon, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: roundBtnBg,
                shape: BoxShape.circle,
                border: Border.all(color: roundBtnBorder),
              ),
              child: const Icon(Icons.send_rounded, color: roundBtnIcon, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}
