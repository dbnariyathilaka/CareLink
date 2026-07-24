import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
//  Messages List Screen  (Caregiver)
//  Figma node: 553-576 · P-19 · Messages List (Caregiver)
// ─────────────────────────────────────────────────────────────
class CaregiverMessagesScreen extends StatelessWidget {
  const CaregiverMessagesScreen({super.key});

  // ── Colour tokens ─────────────────────────────────────────
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _azure17 = AppTheme.cardColor; // #1E293B (dividers)
  static const Color _azure47 = Color(0xFF64748B); // slate – timestamp / secondary
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8
  static const Color _azure84 = Color(0xFFCBD5E1); // Geyser – message preview
  static const Color _grey98 = AppTheme.textPrimary; // #F8FAFC
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  // Green gradient for NA (patient avatar)
  static const Color _green45 = AppTheme.primaryGreen;
  static const Color _green36 = AppTheme.primaryGreenDark;
  static const Color _green8 = AppTheme.bottleGreen;
  // Blue gradient for KP
  static const Color _blue48 = Color(0xFF0EA5E9);
  static const Color _blue39 = Color(0xFF0284C7);

  static const List<_ConversationData> _conversations = [
    _ConversationData(
      initials: 'NA',
      avatarType: _AvatarType.green,
      name: 'Nipuni Ariyathilaka',
      timestamp: '10:45 AM',
      timestampColor: _indigoLight,
      preview: 'Yes please! Medication at 8AM…',
      previewColor: _azure84,
      unreadCount: 1,
      statusLabel: null,
    ),
    _ConversationData(
      initials: 'KP',
      avatarType: _AvatarType.blue,
      name: 'Kamal Perera',
      timestamp: 'Yesterday',
      timestampColor: _azure47,
      preview: "You: I'll be there at 9AM.",
      previewColor: _azure65,
      unreadCount: 0,
      statusLabel: 'Upcoming',
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
                separatorBuilder: (_, _) => const SizedBox.shrink(),
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
  Widget _buildConversationRow(_ConversationData data, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/caregiver-chat',
          arguments: {'name': data.name, 'initials': data.initials},
        );
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
            _buildAvatar(data),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (data.statusLabel != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      data.statusLabel!,
                      style: const TextStyle(
                        color: _indigoLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (data.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: _indigo,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${data.unreadCount}',
                  style: const TextStyle(
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

  // ── Avatar ────────────────────────────────────────────────
  Widget _buildAvatar(_ConversationData data) {
    List<Color> colors;
    Color textColor;

    switch (data.avatarType) {
      case _AvatarType.green:
        colors = const [_green45, _green36];
        textColor = _green8;
      case _AvatarType.blue:
        colors = const [_blue48, _blue39];
        textColor = Colors.white;
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
enum _AvatarType { green, blue }

class _ConversationData {
  final String initials;
  final _AvatarType avatarType;
  final String name;
  final String timestamp;
  final Color timestampColor;
  final String preview;
  final Color previewColor;
  final int unreadCount;
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
    required this.statusLabel,
  });
}
