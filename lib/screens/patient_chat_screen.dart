import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'call_screen.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Chat Screen  (Chat Thread — Patient view)
//  Figma node: 498-6030 · P-20 · Chat Thread (Patient)
//  Adds voice/video calling and voice-note messages.
// ─────────────────────────────────────────────────────────────
class PatientChatScreen extends StatefulWidget {
  const PatientChatScreen({super.key});

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  // ── Colour tokens ─────────────────────────────────────────
  static const Color _azure11  = AppTheme.surfaceColor;    // #0F172A  bg
  static const Color _azure17  = AppTheme.cardColor;       // #1E293B  received bubble / input
  static const Color _azure27  = AppTheme.borderColor;     // #334155  input border / header divider
  static const Color _azure47  = Color(0xFF64748B);        // timestamps
  static const Color _azure65  = AppTheme.textSecondary;   // #94A3B8  booking text
  static const Color _azure84  = Color(0xFFCBD5E1);        // received bubble text
  static const Color _grey98   = AppTheme.textPrimary;     // #F8FAFC
  static const Color _green45  = AppTheme.primaryGreen;    // #22C55E
  static const Color _green36  = AppTheme.primaryGreenDark;// #16A34A
  static const Color _green8   = AppTheme.bottleGreen;     // #06240F  sent bubble text
  static const Color _greenBannerBg = Color(0x1422C55E);   // green 8%
  static const Color _red      = Color(0xFFEF4444);

  // ── Bubble radii ─────────────────────────────────────────
  // Received: sharp bottom-left corner
  static const BorderRadius _receivedRadius = BorderRadius.only(
    topLeft:     Radius.circular(14),
    topRight:    Radius.circular(14),
    bottomRight: Radius.circular(14),
    bottomLeft:  Radius.circular(4),
  );
  // Sent: sharp bottom-right corner
  static const BorderRadius _sentRadius = BorderRadius.only(
    topLeft:     Radius.circular(14),
    topRight:    Radius.circular(14),
    bottomLeft:  Radius.circular(14),
    bottomRight: Radius.circular(4),
  );

  // ── Seed messages ─────────────────────────────────────────
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: "Good evening! I've reviewed your mother's care needs.",
      isMine: false,
      time: '2:05 PM',
    ),
    const _ChatMessage(
      type: _MessageType.callLog,
      callLabel: 'Voice call · 4m 12s',
      isMine: false,
      time: '',
    ),
    const _ChatMessage(
      text: 'Thank you! She takes medication at 8AM and 6PM.',
      isMine: true,
      time: '2:11 PM',
    ),
    const _ChatMessage(
      text: "Noted. I'll be there at 8AM sharp tomorrow!",
      isMine: false,
      time: '2:14 PM',
    ),
    const _ChatMessage(
      type: _MessageType.voiceNote,
      voiceDuration: '0:08',
      isMine: true,
      time: '2:15 PM',
    ),
  ];

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _recordTimer?.cancel();
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

  // ── Voice note recording (simulated) ───────────────────────
  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording(send: true);
      return;
    }
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
    });
  }

  void _stopRecording({required bool send}) {
    _recordTimer?.cancel();
    final seconds = _recordSeconds;
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
    if (send && seconds > 0) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      setState(() {
        _messages.add(_ChatMessage(
          type: _MessageType.voiceNote,
          voiceDuration: '$m:${s.toString().padLeft(2, '0')}',
          isMine: true,
          time: _currentTime(),
        ));
      });
      _scrollToBottom();
    }
  }

  // ── Voice / video calling ──────────────────────────────────
  Future<void> _startCall({required bool isVideo}) async {
    final result = await Navigator.push<Duration?>(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          calleeName: 'Alice Fernando',
          initials: 'AF',
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
        border: Border(
          bottom: BorderSide(color: _azure17, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const SizedBox(width: 10),
          // Avatar
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
            child: const Center(
              child: Text(
                'AF',
                style: TextStyle(
                  color: _green8,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + online status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Alice Fernando',
                  style: TextStyle(
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
                        color: _green45,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online now',
                      style: TextStyle(
                        color: _green45,
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
          const SizedBox(width: 8),
          _headerIconButton(Icons.videocam_rounded, () => _startCall(isVideo: true)),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _azure17,
          border: Border.all(color: _azure27),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _green45, size: 20),
      ),
    );
  }

  // ── Booking banner ────────────────────────────────────────
  Widget _buildBookingBanner() {
    return Container(
      color: _greenBannerBg,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          const Icon(
            Icons.event_rounded,
            color: _azure65,
            size: 17,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Booking: Elder care · 20 Nov – 20 Dec 2025',
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
                color: _green45,
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
    switch (msg.type) {
      case _MessageType.callLog:
        return _buildCallLogPill(msg);
      case _MessageType.voiceNote:
        return _buildVoiceNoteBubble(msg);
      case _MessageType.text:
        return _buildTextBubble(msg);
    }
  }

  // ── Call log pill (centered) ───────────────────────────────
  Widget _buildCallLogPill(_ChatMessage msg) {
    final isVideo = msg.callLabel!.startsWith('Video');
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _green45.withValues(alpha: 0.1),
          border: Border.all(color: _green45.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              color: _green45,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              msg.callLabel!,
              style: const TextStyle(
                color: _azure65,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Voice note bubble ───────────────────────────────────────
  Widget _buildVoiceNoteBubble(_ChatMessage msg) {
    final isMine = msg.isMine;
    // Deterministic pseudo-waveform so it doesn't reshuffle on rebuild.
    final rnd = Random(msg.voiceDuration.hashCode);
    final bars = List.generate(10, (_) => 8.0 + rnd.nextDouble() * 12);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? _green45 : _azure17,
              borderRadius: isMine ? _sentRadius : _receivedRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: isMine ? _green8 : _grey98,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(bars.length, (i) {
                    final played = i < (bars.length * 0.5).round();
                    final color = isMine
                        ? _green8.withValues(alpha: played ? 1 : 0.4)
                        : _grey98.withValues(alpha: played ? 1 : 0.4);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        width: 2,
                        height: bars[i],
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  msg.voiceDuration!,
                  style: TextStyle(
                    color: isMine ? _green8 : _grey98,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            msg.time,
            style: const TextStyle(color: _azure47, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBubble(_ChatMessage msg) {
    final isMine = msg.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isMine ? _green45 : _azure17,
                borderRadius: isMine ? _sentRadius : _receivedRadius,
              ),
              child: Text(
                msg.text!,
                style: TextStyle(
                  color: isMine ? _green8 : _azure84,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Timestamp
            Text(
              msg.time,
              style: const TextStyle(
                color: _azure47,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldRow() {
    return Row(
      children: [
        Expanded(
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
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.attach_file_rounded, color: _azure47, size: 20),
        ),
      ],
    );
  }

  Widget _buildRecordingIndicator() {
    final m = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_recordSeconds % 60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recording… $m:$s',
              style: const TextStyle(
                color: _grey98,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _stopRecording(send: false),
            child: const Icon(Icons.delete_outline_rounded, color: _azure47, size: 20),
          ),
        ],
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
          // Text field / recording indicator
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _azure17,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _isRecording ? _red.withValues(alpha: 0.5) : _azure27),
              ),
              child: _isRecording ? _buildRecordingIndicator() : _buildTextFieldRow(),
            ),
          ),
          const SizedBox(width: 10),
          // Mic / voice note button
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isRecording ? _red.withValues(alpha: 0.15) : _azure17,
                border: Border.all(color: _isRecording ? _red : _azure27),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isRecording ? _red : _green45,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: _green45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: _green8,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message model ─────────────────────────────────────────────
enum _MessageType { text, callLog, voiceNote }

class _ChatMessage {
  final _MessageType type;
  final String? text;
  final String? callLabel;
  final String? voiceDuration;
  final bool isMine;
  final String time;
  const _ChatMessage({
    this.type = _MessageType.text,
    this.text,
    this.callLabel,
    this.voiceDuration,
    required this.isMine,
    required this.time,
  });
}
