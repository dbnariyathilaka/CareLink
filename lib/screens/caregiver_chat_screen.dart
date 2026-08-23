import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'call_screen.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/patient_service.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Chat Screen (Chat Thread — Caregiver view)
//  Figma node: 355-2086
// ─────────────────────────────────────────────────────────────
class CaregiverChatScreen extends StatefulWidget {
  const CaregiverChatScreen({super.key});

  @override
  State<CaregiverChatScreen> createState() => _CaregiverChatScreenState();
}

class _CaregiverChatScreenState extends State<CaregiverChatScreen> {
  static const Color bg = Color(0xFF162131);
  static const Color headerBorder = Color(0xFF1E293B);
  static const Color bannerBg = Color.fromRGBO(99, 102, 241, 0.1);
  static const Color bannerAccent = Color(0xFF6366F1);
  static const Color bannerText = Color(0xFF94A3B8);
  static const Color nameText = Color(0xFFF8FAFC);
  static const Color callIcon = Color(0xFF818CF8);
  static const Color receivedBubbleBg = Color(0xFF303F57);
  static const Color receivedBubbleText = Color(0xFFCBD5E1);
  static const Color sentBubbleBg = Color(0xFF76769F);
  static const Color sentBubbleText = Colors.black;
  static const Color timestampColor = Color(0xFF64748B);
  static const Color callLogBg = Color.fromRGBO(99, 102, 241, 0.1);
  static const Color callLogBorder = Color(0xFF6366F1);
  static const Color inputBorder = Color(0xFF334155);
  static const Color inputHint = Color(0xFF64748B);
  static const Color roundBtnBg = Color(0xFF4A5F93);
  static const Color roundBtnBorder = Color(0xFF92A2C9);
  static const Color roundBtnIcon = Color(0xFF0F172A);

  final TextEditingController _textController = NoUnderlineTextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic> _args = {};
  bool _loadedArgs = false;
  String? _patientName;
  bool _isPlayingAudio = false;
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
      ChatService.markAsRead(bookingId: bookingId, readerRole: 'caregiver');
    }
    _resolvePatientName();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _resolvePatientName() async {
    final uid = _args['patientUid'] as String?;
    if (uid == null) return;
    final profile = await PatientService.getPatientProfile(uid);
    final name = (profile?['name'] as String?)?.trim();
    if (!mounted) return;
    setState(() => _patientName = name != null && name.isNotEmpty ? name : null);
  }

  String get _patientDisplayName => _patientName ?? (_args['patientName'] as String? ?? 'Patient');

  String get _initials {
    final parts = _patientDisplayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
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
        senderRole: 'caregiver',
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
          calleeName: _patientDisplayName,
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
        senderRole: 'caregiver',
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

  // ── Header: back, avatar, name, online status, call/video ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 18, 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: headerBorder, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          Container(
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _patientDisplayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: nameText,
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
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online now',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF6366F1),
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
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.call_rounded, color: callIcon, size: 22),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _startCall(true),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.videocam_rounded, color: callIcon, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking banner ───────────────────────────────────────────
  Widget _buildBookingBanner(BuildContext context) {
    final careType = _args['careType'] as String? ?? 'Elder care';
    final startDate = _args['startDate'] as String? ?? '20 Dec 2025';
    final shiftType = _args['shiftType'] as String? ?? 'Full-time';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/caregiver-schedule'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        color: bannerBg,
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: bannerAccent, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Booking: $careType · $startDate · $shiftType',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: bannerText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Text(
              'View',
              style: TextStyle(
                fontFamily: 'Inter',
                color: bannerAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Real-time message thread ─────────────────────────────────
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
    final senderRole = message['senderRole'] as String? ?? 'patient';
    final fromMe = senderRole == 'caregiver';
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

    if (type == 'audio') {
      return _buildAudioBubble(fromMe, message['audioDuration'] as String? ?? '0:08', time);
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

  Widget _buildAudioBubble(bool fromMe, String audioDuration, DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _isPlayingAudio = !_isPlayingAudio);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: fromMe ? sentBubbleBg : receivedBubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(fromMe ? 14 : 4),
                  bottomRight: Radius.circular(fromMe ? 4 : 14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: fromMe ? const Color(0xFF42413F) : const Color(0xFFCBD5E1),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _waveBar(9, true, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(16, true, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(11, true, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(20, true, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(14, true, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(8, false, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(13, false, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(18, false, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(10, false, fromMe),
                      const SizedBox(width: 2),
                      _waveBar(15, false, fromMe),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    audioDuration,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: fromMe ? const Color(0xFF42413F) : const Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

  Widget _waveBar(double height, bool active, bool fromMe) {
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: active
            ? (fromMe ? const Color(0xFF42413F) : const Color(0xFF5ED5A7))
            : (fromMe ? const Color.fromRGBO(6, 36, 15, 0.4) : const Color.fromRGBO(94, 213, 167, 0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: headerBorder, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: inputBorder, width: 1),
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 2),
              child: TextField(
                controller: _textController,
                style: const TextStyle(
                  fontFamily: 'Inter',
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
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: inputHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _notAvailableYet('Voice messages'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: roundBtnBg,
                shape: BoxShape.circle,
                border: Border.all(color: roundBtnBorder, width: 1),
              ),
              child: const Icon(Icons.mic_rounded, color: roundBtnIcon, size: 21),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: roundBtnBg,
                shape: BoxShape.circle,
                border: Border.all(color: roundBtnBorder, width: 1),
              ),
              child: const Icon(Icons.send_rounded, color: roundBtnIcon, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
