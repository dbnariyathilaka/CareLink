import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Messages List Screen  (Patient)
//  Figma node: 46-2506
// ─────────────────────────────────────────────────────────────
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  // ── Colour tokens ─────────────────────────────────────────
  static const Color _azure11  = AppTheme.surfaceColor;   // #0F172A
  static const Color _azure17  = AppTheme.cardColor;      // #1E293B  (dividers)
  static const Color _azure47  = Color(0xFF64748B);       // slate – timestamp / secondary
  static const Color _azure65  = AppTheme.textSecondary;  // #94A3B8
  static const Color _azure84  = Color(0xFFCBD5E1);       // Geyser – message preview
  static const Color _grey98   = AppTheme.textPrimary;    // #F8FAFC
  static const Color _green45  = AppTheme.primaryGreen;   // #22C55E
  static const Color _green36  = AppTheme.primaryGreenDark;// #16A34A
  static const Color _green8   = AppTheme.bottleGreen;    // #06240F
  static const Color _indigo   = Color(0xFF6366F1);       // booking ref tag
  // Amber gradient for CS
  static const Color _amber50  = Color(0xFFF59E0B);
  static const Color _amber44  = Color(0xFFD97706);
  static const Color _amberDark = Color(0xFF3B2406);      // text on amber
  // Blue gradient for BK
  static const Color _blue48   = Color(0xFF0EA5E9);
  static const Color _blue39   = Color(0xFF0284C7);

  // ── Conversation data ────────────────────────────────────
  static const List<_ConversationData> _conversations = [
    _ConversationData(
      initials: 'AF',
      avatarType: _AvatarType.green,
      name: 'Alice Fernando',
      timestamp: '2:14 PM',
      timestampColor: _green45,
      preview: "I'll be there at 8AM sharp tomorrow!",
      previewColor: _azure84,
      unreadCount: 2,
      tag: null,
      statusLabel: null,
    ),
    _ConversationData(
      initials: 'BK',
      avatarType: _AvatarType.blue,
      name: 'Brian Kumara',
      timestamp: 'Yesterday',
      timestampColor: _azure47,
      preview: 'You: Great, see you then.',
      previewColor: _azure65,
      unreadCount: 0,
      tag: 'Booking ref · Post-surgery',
      statusLabel: null,
    ),
    _ConversationData(
      initials: 'CS',
      avatarType: _AvatarType.amber,
      name: 'Carol Silva',
      timestamp: 'Nov 20',
      timestampColor: _azure47,
      preview: 'Thanks for the opportunity!',
      previewColor: _azure65,
      unreadCount: 0,
      tag: null,
      statusLabel: 'Completed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => const SizedBox.shrink(),
                itemBuilder: (context, index) =>
                    _buildConversationRow(_conversations[index], context),
              ),
            ),
            _buildInfoBar(),
          ],
        ),
      ),
    );
  }



  // ── Page header ───────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Messages',
            style: TextStyle(
              color: _grey98,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Single conversation row ───────────────────────────────
  Widget _buildConversationRow(
      _ConversationData data, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/chat');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 13, 22, 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _azure17, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Avatar ──
            _buildAvatar(data),
            const SizedBox(width: 12),
            // ── Text block ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row + timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          color: _grey98,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        data.timestamp,
                        style: TextStyle(
                          color: data.timestampColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Message preview
                  Text(
                    data.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: data.previewColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Optional tag OR status label
                  if (data.tag != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      data.tag!,
                      style: const TextStyle(
                        color: _indigo,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (data.statusLabel != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      data.statusLabel!,
                      style: const TextStyle(
                        color: _azure65,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Unread badge ──
            if (data.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: _green45,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${data.unreadCount}',
                  style: const TextStyle(
                    color: _green8,
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

  // ── Avatar ────────────────────────────────────────────────
  Widget _buildAvatar(_ConversationData data) {
    List<Color> colors;
    Color textColor;

    switch (data.avatarType) {
      case _AvatarType.green:
        colors = const [_green45, _green36];
        textColor = _green8;
        break;
      case _AvatarType.blue:
        colors = const [_blue48, _blue39];
        textColor = Colors.white;
        break;
      case _AvatarType.amber:
        colors = const [_amber50, _amber44];
        textColor = _amberDark;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          data.initials,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Bottom info bar ───────────────────────────────────────
  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _azure17, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 14),
      child: Row(
        children: const [
          Icon(Icons.lock_outline_rounded, color: _azure47, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Messages are only available for confirmed bookings.',
              style: TextStyle(
                color: _azure47,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────
enum _AvatarType { green, blue, amber }

class _ConversationData {
  final String initials;
  final _AvatarType avatarType;
  final String name;
  final String timestamp;
  final Color timestampColor;
  final String preview;
  final Color previewColor;
  final int unreadCount;
  final String? tag;
  final String? statusLabel;

  const _ConversationData({
    required this.initials,
    required this.avatarType,
    required this.name,
    required this.timestamp,
    required this.timestampColor,
    required this.preview,
    required this.previewColor,
    required this.unreadCount,
    required this.tag,
    required this.statusLabel,
  });
}
