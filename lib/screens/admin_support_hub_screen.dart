import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import 'admin_bookings_screen.dart';
import 'admin_finance_screen.dart';

enum SupportTicketStatus { open, waiting, closed }

enum TicketPriority { high, med, low }

class SupportTicket {
  final String id;
  final TicketPriority priority;
  final String code;
  final String elapsedLabel;
  final String title;
  final String requesterLine;
  SupportTicketStatus status;
  bool isExpanded;

  SupportTicket({
    required this.id,
    required this.priority,
    required this.code,
    required this.elapsedLabel,
    required this.title,
    required this.requesterLine,
    this.status = SupportTicketStatus.open,
    this.isExpanded = false,
  });
}

class AdminSupportHubScreen extends StatefulWidget {
  const AdminSupportHubScreen({super.key});

  @override
  State<AdminSupportHubScreen> createState() => _AdminSupportHubScreenState();
}

class _AdminSupportHubScreenState extends State<AdminSupportHubScreen> {
  // ── Color Tokens matching Figma node 647:948 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color filterActiveBg = Color(0xFF5D5445);
  static const Color filterActiveFg = Color(0xFFF8FAFC);
  static const Color filterInactiveBorder = Color(0xFF5D5445);

  static const Color ticketCardBg = Color(0xFFC4BBAC);
  static const Color ticketCardBorder = Color(0xFF44331C);

  static const Color highBadgeBg = Color(0x29EF4444);
  static const Color highBadgeText = Color(0xFFEF4444);
  static const Color medBadgeBg = Color(0x29F59E0B);
  static const Color medBadgeText = Color(0xFF976511);

  static const Color ticketMetaColor = Color(0xFF64748B);
  static const Color ticketTitleColor = Color(0xFF44331C);
  static const Color ticketSubColor = Color(0xFF655443);

  static const Color replyBtnBg = Color(0xFF44331C);
  static const Color assignBtnBorder = Color(0xFF44331C);

  static const Color sectionLabelColor = Color(0xFF070B12);

  static const Color openThreadLinkColor = Color(0xFFA05D30);
  static const Color messageBubbleBg = Color(0xFF544632);
  static const Color messageTextColor = Color(0xFFCBD5E1);
  static const Color messageTimeColor = Color(0xFF64748B);
  static const Color joinThreadBg = Color(0xFF958675);
  static const Color joinThreadBorder = Color(0xFF544632);

  static const Color textareaBg = Color(0xFFB5A998);
  static const Color textareaBorder = Color(0xFF46351D);
  static const Color textareaTextColor = Color(0xFF46351D);
  static const Color audienceChipActiveBg = Color(0xFF44331C);
  static const Color audienceChipActiveText = Color(0xFFB26915);
  static const Color audienceChipInactiveBorder = Color(0xFF44331C);

  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  SupportTicketStatus _activeFilter = SupportTicketStatus.open;

  final List<SupportTicket> _tickets = [
    SupportTicket(
      id: 'tk_1',
      priority: TicketPriority.high,
      code: 'TKT-1182',
      elapsedLabel: '25 min',
      title: 'Payment failed but booking confirmed',
      requesterLine: 'Nimali Perera · patient/family',
      isExpanded: true,
    ),
    SupportTicket(
      id: 'tk_2',
      priority: TicketPriority.med,
      code: 'TKT-1179',
      elapsedLabel: '3h',
      title: 'Cannot upload police clearance',
      requesterLine: 'Brian Kumara · caregiver · 3h',
    ),
    SupportTicket(
      id: 'tk_3',
      priority: TicketPriority.low,
      code: 'TKT-1175',
      elapsedLabel: '1d',
      title: 'How do I change my payout bank account?',
      requesterLine: 'Sanduni Perera · caregiver · 1d',
      status: SupportTicketStatus.waiting,
    ),
    SupportTicket(
      id: 'tk_4',
      priority: TicketPriority.med,
      code: 'TKT-1170',
      elapsedLabel: '2d',
      title: 'Refund received, ticket resolved',
      requesterLine: 'Kamal Perera · patient/family · 2d',
      status: SupportTicketStatus.closed,
    ),
  ];

  final TextEditingController _broadcastController = TextEditingController(
    text: 'Heavy rain advisory — confirm arrival times with families before travelling.',
  );

  final Set<String> _selectedAudiences = {'Caregivers'};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

  int _countFor(SupportTicketStatus s) => _tickets.where((t) => t.status == s).length;

  List<SupportTicket> get _filteredTickets =>
      _tickets.where((t) => t.status == _activeFilter).toList();

  void _toggleExpand(SupportTicket t) => setState(() => t.isExpanded = !t.isExpanded);

  void _replyToTicket(SupportTicket t) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reply to ${t.code}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Type your reply...',
            hintStyle: const TextStyle(color: Color(0xFF6B5E4A)),
            filled: true,
            fillColor: const Color(0xFF3B3329),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: replyBtnBg),
            onPressed: () {
              setState(() => t.status = SupportTicketStatus.waiting);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reply sent for ${t.code}.'), duration: const Duration(seconds: 2)),
              );
            },
            child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _assignTicket(SupportTicket t) {
    const agents = ['Sanduni D.', 'Tharaka M.', 'You'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C251D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign ${t.code} to', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...agents.map(
              (agent) => ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: Colors.white70),
                title: Text(agent, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t.code} assigned to $agent.'), duration: const Duration(seconds: 2)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openThread() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat thread BK-8841...'), duration: Duration(seconds: 2)),
    );
  }

  void _joinThread() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Joined chat as CareLink support.'), duration: Duration(seconds: 2)),
    );
  }

  void _sendBroadcast() {
    if (_broadcastController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write an announcement before sending.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    if (_selectedAudiences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one audience.'), duration: Duration(seconds: 2)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Broadcast sent to ${_selectedAudiences.join(', ')}.'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_filteredTickets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No tickets in this view',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: titleColor.withValues(alpha: 0.6)),
                          ),
                        ),
                      )
                    else
                      ..._filteredTickets.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTicketCard(t),
                        ),
                      ),
                    const SizedBox(height: 6),
                    _buildSectionLabel('CHAT AUDIT · DISPUTED BOOKING'),
                    const SizedBox(height: 9),
                    _buildChatAuditCard(),
                    const SizedBox(height: 16),
                    _buildSectionLabel('BROADCAST'),
                    const SizedBox(height: 9),
                    _buildBroadcastCard(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 12, 22, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'Support hub',
              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
          const Icon(Icons.campaign_outlined, color: titleColor, size: 22),
        ],
      ),
    );
  }

  // ── Filter bar ──────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = [
      (SupportTicketStatus.open, 'Open ${_countFor(SupportTicketStatus.open)}'),
      (SupportTicketStatus.waiting, 'Waiting'),
      (SupportTicketStatus.closed, 'Closed'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: filters.map((f) {
          final isActive = _activeFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? filterActiveBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: filterInactiveBorder, width: isActive ? 0 : 1),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? filterActiveFg : filterInactiveBorder,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: sectionLabelColor,
        letterSpacing: 0.6,
      ),
    );
  }

  // ── Ticket card ─────────────────────────────────────────────────────────
  Widget _buildTicketCard(SupportTicket t) {
    final isHigh = t.priority == TicketPriority.high;
    final badgeBg = isHigh ? highBadgeBg : medBadgeBg;
    final badgeFg = isHigh ? highBadgeText : medBadgeText;
    final badgeText = switch (t.priority) {
      TicketPriority.high => 'HIGH',
      TicketPriority.med => 'MED',
      TicketPriority.low => 'LOW',
    };

    return GestureDetector(
      onTap: () => _toggleExpand(t),
      child: Container(
        decoration: BoxDecoration(
          color: ticketCardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: ticketCardBorder, width: 1),
        ),
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: badgeFg),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${t.code} · ${t.elapsedLabel}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: ticketMetaColor),
                  ),
                ),
                if (!t.isExpanded)
                  const Icon(Icons.chevron_right_rounded, color: ticketTitleColor, size: 20),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              t.title,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w700, color: ticketTitleColor),
            ),
            const SizedBox(height: 2),
            Text(
              t.requesterLine,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: ticketSubColor),
            ),
            if (t.isExpanded) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: replyBtnBg,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => _replyToTicket(t),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 9),
                          child: Center(
                            child: Text('Reply', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () => _assignTicket(t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: assignBtnBorder, width: 1)),
                          child: const Center(
                            child: Text('Assign', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: ticketTitleColor)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Chat audit card ─────────────────────────────────────────────────────
  Widget _buildChatAuditCard() {
    return Container(
      decoration: BoxDecoration(
        color: ticketCardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: ticketCardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 17, color: ticketTitleColor),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'BK-8841 · Nipuni ↔ Ruwan',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ticketTitleColor),
                ),
              ),
              GestureDetector(
                onTap: _openThread,
                child: const Text(
                  'Open thread',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w600, color: openThreadLinkColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildChatBubble('"I\'ll be 40 minutes late again, traffic."', '6:12 PM'),
          const SizedBox(height: 7),
          _buildChatBubble('"This is the second time this week."', '6:15 PM'),
          const SizedBox(height: 10),
          Material(
            color: joinThreadBg,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: _joinThread,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), border: Border.all(color: joinThreadBorder, width: 1)),
                child: const Row(
                  children: [
                    Icon(Icons.support_agent_rounded, size: 16, color: ticketTitleColor),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Join thread as CareLink support',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: ticketTitleColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String message, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: messageBubbleBg, borderRadius: BorderRadius.circular(9)),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w400),
          children: [
            TextSpan(text: '$message ', style: const TextStyle(color: messageTextColor)),
            TextSpan(text: '· $time', style: const TextStyle(color: messageTimeColor)),
          ],
        ),
      ),
    );
  }

  // ── Broadcast card ───────────────────────────────────────────────────────
  Widget _buildBroadcastCard() {
    final audiences = ['Caregivers', 'Patients', 'Negombo only'];
    return Container(
      decoration: BoxDecoration(
        color: ticketCardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: ticketCardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New announcement',
            style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: ticketTitleColor),
          ),
          const SizedBox(height: 9),
          Container(
            decoration: BoxDecoration(color: textareaBg, borderRadius: BorderRadius.circular(9), border: Border.all(color: textareaBorder, width: 1)),
            padding: const EdgeInsets.all(11),
            child: TextField(
              controller: _broadcastController,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w400, color: textareaTextColor),
              decoration: const InputDecoration.collapsed(hintText: 'Write an announcement...', hintStyle: TextStyle(color: textareaTextColor)),
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: audiences.map((a) {
              final isSelected = _selectedAudiences.contains(a);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedAudiences.remove(a);
                  } else {
                    _selectedAudiences.add(a);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? audienceChipActiveBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: audienceChipInactiveBorder, width: 1),
                  ),
                  child: Text(
                    a,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? audienceChipActiveText : ticketTitleColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: replyBtnBg,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: _sendBroadcast,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('Send broadcast', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar (matching Admin Dashboard) ────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'label': 'Dashboard', 'icon': Icons.insights_rounded},
      {'label': 'Users', 'icon': Icons.people_alt_outlined},
      {'label': 'Bookings', 'icon': Icons.calendar_month_outlined},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet_outlined},
      {'label': 'More', 'icon': Icons.more_horiz_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: bottomNavBg,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == 4; // More tab is active (Support lives under More)
          final color = isSelected ? navGold : Colors.white;

          return GestureDetector(
            onTap: () {
              if (index == 0 || index == 1 || index == 4) {
                Navigator.pop(context);
              } else if (index == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingsScreen()));
              } else if (index == 3) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFinanceScreen()));
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 22, color: color),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
