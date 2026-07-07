import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Patient Chat Screen  (Chat Thread — Patient view)
//  Figma node: 46-2617
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
      text: 'Thank you! She takes medication at 8AM and 6PM.',
      isMine: true,
      time: '2:11 PM',
    ),
    const _ChatMessage(
      text: "Noted. I'll be there at 8AM sharp tomorrow!",
      isMine: false,
      time: '2:14 PM',
    ),
  ];

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

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
    // Scroll to bottom after frame
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(),
            _buildChatHeader(context),
            _buildBookingBanner(),
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Status bar ────────────────────────────────────────────
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: _grey98,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: const [
                Icon(Icons.signal_cellular_alt, color: _grey98, size: 18),
                SizedBox(width: 5),
                Icon(Icons.wifi, color: _grey98, size: 18),
                SizedBox(width: 5),
                Icon(Icons.battery_full, color: _grey98, size: 20),
              ],
            ),
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
        ],
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
            Icons.calendar_today_outlined,
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildBubble(_messages[index]),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
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
                msg.text,
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

  // ── Input bar ─────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _azure17, width: 1)),
      ),
      child: Row(
        children: [
          // Text field
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
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
class _ChatMessage {
  final String text;
  final bool isMine;
  final String time;
  const _ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
  });
}
