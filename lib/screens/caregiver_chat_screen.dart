import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'call_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Chat Screen  (Chat Thread — Caregiver view)
//  Figma node: 498-6977 · Chat Thread (Caregiver)
// ─────────────────────────────────────────────────────────────
class CaregiverChatScreen extends StatefulWidget {
  const CaregiverChatScreen({super.key});

  @override
  State<CaregiverChatScreen> createState() => _CaregiverChatScreenState();
}

class _CaregiverChatScreenState extends State<CaregiverChatScreen> {
  // ── Colour tokens ─────────────────────────────────────────
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A bg
  static const Color _azure17 = AppTheme.cardColor; // #1E293B received bubble / input
  static const Color _azure27 = AppTheme.borderColor; // #334155 input border / header divider
  static const Color _azure47 = Color(0xFF64748B); // timestamps
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8 booking text
  static const Color _azure84 = Color(0xFFCBD5E1); // received bubble text
  static const Color _grey98 = AppTheme.textPrimary; // #F8FAFC
  static const Color _green45 = AppTheme.primaryGreen; // #22C55E patient avatar
  static const Color _green36 = AppTheme.primaryGreenDark; // #16A34A
  static const Color _green8 = AppTheme.bottleGreen; // #06240F
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _indigoBannerBg = Color(0x1A6366F1); // indigo 10%

  static const BorderRadius _receivedRadius = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(14),
    bottomRight: Radius.circular(14),
    bottomLeft: Radius.circular(4),
  );
  static const BorderRadius _sentRadius = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(14),
    bottomLeft: Radius.circular(14),
    bottomRight: Radius.circular(4),
  );

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hi Brian, looking forward to your help with mum.',
      isMine: false,
      time: '10:40 AM',
    ),
    const _ChatMessage(
      text: 'Happy to help! Should I bring the BP monitor?',
      isMine: true,
      time: '10:43 AM',
    ),
    const _ChatMessage(
      text: 'Yes please! Medication at 8AM and 6PM.',
      isMine: false,
      time: '10:45 AM',
    ),
  ];

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String _patientName = 'Nipuni Ariyathilaka';
  String _patientInitials = 'NA';
  bool _didReadArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _patientName = args['name'] as String? ?? _patientName;
      _patientInitials = args['initials'] as String? ?? _patientInitials;
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isMine: true,
        time: _currentTime(),
      ));
      _inputCtrl.clear();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<void> _startCall({required bool isVideo}) async {
    final result = await Navigator.push<Duration?>(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          calleeName: _patientName,
          initials: _patientInitials,
          isVideo: isVideo,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !mounted) return;
    final label = isVideo ? 'Video call' : 'Voice call';
    setState(() {
      _messages.add(_ChatMessage(
        type: _MessageType.callLog,
        callLabel: '$label · ${_formatCallDuration(result)}',
        isMine: true,
        time: '',
      ));
    });
    _scrollToBottom();
  }

  String _formatCallDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(context),
            _buildBookingBanner(),
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Chat header ───────────────────────────────────────────
  Widget _buildChatHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _azure17, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_green45, _green36],
              ),
            ),
            child: Center(
              child: Text(
                _patientInitials,
                style: const TextStyle(
                  color: _green8,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
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
                  _patientName,
                  style: const TextStyle(
                    color: _grey98,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _indigo,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online now',
                      style: TextStyle(
                        color: _indigo,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _headerIconButton(Icons.call_rounded, () => _startCall(isVideo: false)),
          const SizedBox(width: 14),
          _headerIconButton(Icons.videocam_rounded, () => _startCall(isVideo: true)),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: _indigoLight, size: 22),
    );
  }

  // ── Booking banner ────────────────────────────────────────
  Widget _buildBookingBanner() {
    return Container(
      color: _indigoBannerBg,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          const Icon(Icons.event_rounded, color: _indigo, size: 17),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Booking: Elder care · 20 Dec 2025 · Full-time',
              style: TextStyle(
                color: _azure65,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'View',
              style: TextStyle(
                color: _indigo,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      itemCount: _messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMessageItem(_messages[index]),
    );
  }

  Widget _buildMessageItem(_ChatMessage msg) {
    if (msg.type == _MessageType.callLog) return _buildCallLogPill(msg);
    return _buildTextBubble(msg);
  }

  Widget _buildCallLogPill(_ChatMessage msg) {
    final isVideo = msg.callLabel!.startsWith('Video');
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _indigo.withValues(alpha: 0.1),
          border: Border.all(color: _indigo.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded, color: _indigo, size: 15),
            const SizedBox(width: 6),
            Text(
              msg.callLabel!,
              style: const TextStyle(color: _azure65, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(_ChatMessage msg) {
    final isMine = msg.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: isMine ? _indigo : _azure17,
                borderRadius: isMine ? _sentRadius : _receivedRadius,
              ),
              child: Text(
                msg.text!,
                style: TextStyle(
                  color: isMine ? Colors.white : _azure84,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              msg.time,
              style: const TextStyle(color: _azure47, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _azure17, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _azure17,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _azure27),
              ),
              child: TextField(
                controller: _inputCtrl,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(
                  color: _grey98,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                    color: _azure47,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: _indigo, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message model ─────────────────────────────────────────────
enum _MessageType { text, callLog }

class _ChatMessage {
  final _MessageType type;
  final String? text;
  final String? callLabel;
  final bool isMine;
  final String time;
  const _ChatMessage({
    this.type = _MessageType.text,
    this.text,
    this.callLabel,
    required this.isMine,
    required this.time,
  });
}
