import 'package:flutter/material.dart';
import 'call_screen.dart';
import '../services/patient_service.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Chat Screen  (Chat Thread — Caregiver view)
//  Figma node: 355-2086
//  Mirrors patient_chat_screen.dart's architecture from the
//  caregiver's side: no messaging backend yet, so the thread
//  starts honestly empty — no fabricated conversation history or
//  fake "Online now" presence. What IS real: the booking banner
//  (from the tapped conversation row), the patient's real name,
//  locally-typed messages sent in this session, and call/video
//  buttons that push the real (simulated) CallScreen and log the
//  actual elapsed duration once you hang up.
// ─────────────────────────────────────────────────────────────
class CaregiverChatScreen extends StatefulWidget {
  const CaregiverChatScreen({super.key});

  @override
  State<CaregiverChatScreen> createState() => _CaregiverChatScreenState();
}

enum _EntryType { text, callLog }

class _ChatEntry {
  final _EntryType type;
  final bool fromMe;
  final String text;
  final IconData? icon;
  final DateTime time;
  const _ChatEntry({
    required this.type,
    required this.fromMe,
    required this.text,
    this.icon,
    required this.time,
  });
}

class _CaregiverChatScreenState extends State<CaregiverChatScreen> {
  static const Color bg = Color(0xFF162131);
  static const Color headerBorder = Color(0xFF1E293B);
  static const Color bannerBg = Color.fromRGBO(99, 102, 241, 0.1);
  static const Color bannerAccent = Color(0xFF6366F1);
  static const Color bannerText = Color(0xFF94A3B8);
  static const Color nameText = Color(0xFFF8FAFC);
  static const Color statusUpcoming = Color(0xFF6366F1);
  static const Color statusOngoing = Color(0xFF22C55E);
  static const Color statusCompleted = Color(0xFF64748B);
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

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatEntry> _entries = [];

  Map<String, dynamic> _args = {};
  bool _loadedArgs = false;
  String? _patientName;

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

  String get _patientDisplayName => _patientName ?? 'Patient';

  String get _initials {
    final parts = _patientDisplayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String get _status => (_args['status'] as String?) ?? 'upcoming';

  Color get _statusColor {
    switch (_status) {
      case 'ongoing':
        return statusOngoing;
      case 'completed':
        return statusCompleted;
      default:
        return statusUpcoming;
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

  String _formatCallDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m}m ${s}s';
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _entries.add(_ChatEntry(type: _EntryType.text, fromMe: true, text: text, time: DateTime.now()));
    });
    _textController.clear();
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
    setState(() {
      _entries.add(_ChatEntry(
        type: _EntryType.callLog,
        fromMe: false,
        icon: isVideo ? Icons.videocam_rounded : Icons.call_rounded,
        text: '${isVideo ? 'Video' : 'Voice'} call · ${_formatCallDuration(duration)}',
        time: DateTime.now(),
      ));
    });
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
      padding: const EdgeInsets.fromLTRB(10, 12, 18, 13),
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
          const SizedBox(width: 11),
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
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.call_rounded, color: callIcon, size: 22),
            ),
          ),
          GestureDetector(
            onTap: () => _startCall(true),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.videocam_rounded, color: callIcon, size: 22),
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
      if (dateRange != null) dateRange,
    ];
    final label = parts.isEmpty ? 'Booking details' : 'Booking: ${parts.join(' · ')}';

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
                label,
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

  // ── Message thread — real entries only, honestly empty otherwise ──
  Widget _buildMessageArea() {
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'No messages yet. Say hello below, or start a call using the '
            'buttons above.',
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      itemCount: _entries.length,
      itemBuilder: (context, i) => _buildEntry(_entries[i]),
    );
  }

  Widget _buildEntry(_ChatEntry entry) {
    if (entry.type == _EntryType.callLog) {
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
                Icon(entry.icon ?? Icons.call_rounded, color: callLogBorder, size: 15),
                const SizedBox(width: 6),
                Text(
                  entry.text,
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

    final fromMe = entry.fromMe;
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
              entry.text,
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
            _formatTime(entry.time),
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
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
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
                border: Border.all(color: roundBtnBorder),
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
                border: Border.all(color: roundBtnBorder),
              ),
              child: const Icon(Icons.send_rounded, color: roundBtnIcon, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
