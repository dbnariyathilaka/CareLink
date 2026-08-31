import 'package:flutter/material.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/status_bar.dart';

class AdminSupportHubScreen extends StatefulWidget {
  const AdminSupportHubScreen({super.key});

  @override
  State<AdminSupportHubScreen> createState() => _AdminSupportHubScreenState();
}

class _AdminSupportHubScreenState extends State<AdminSupportHubScreen> {
  // ── Color Tokens matching Figma node 647:948 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color ticketCardBg = Color(0xFFC4BBAC);
  static const Color ticketCardBorder = Color(0xFF44331C);

  static const Color ticketTitleColor = Color(0xFF44331C);
  static const Color ticketSubColor = Color(0xFF655443);

  static const Color replyBtnBg = Color(0xFF44331C);

  static const Color sectionLabelColor = Color(0xFF070B12);

  static const Color textareaTextColor = Color(0xFF46351D);
  static const Color audienceChipActiveBg = Color(0xFF44331C);
  static const Color audienceChipActiveText = Color(0xFFB26915);
  static const Color audienceChipInactiveBorder = Color(0xFF44331C);


  final TextEditingController _broadcastController = TextEditingController();

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
      const SnackBar(
        content: Text('Broadcast sending isn\'t implemented yet — this message wasn\'t sent anywhere.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('SUPPORT TICKETS'),
                    const SizedBox(height: 9),
                    _buildEmptyCard(
                      icon: Icons.confirmation_num_outlined,
                      message: 'No support tickets — ticketing isn\'t tracked yet.',
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel('CHAT AUDIT'),
                    const SizedBox(height: 9),
                    _buildEmptyCard(
                      icon: Icons.visibility_outlined,
                      message: 'No conversations currently flagged for review.',
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel('BROADCAST'),
                    const SizedBox(height: 9),
                    _buildBroadcastCard(),
                  ],
                ),
              ),
            ),
            const AdminBottomNav(active: AdminNavTab.support),
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

  // ── Generic honest empty-state card ─────────────────────────────────────
  Widget _buildEmptyCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ticketCardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: ticketCardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, size: 26, color: ticketTitleColor),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: ticketSubColor),
          ),
        ],
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
          TextField(
            controller: _broadcastController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w400, color: textareaTextColor),
            decoration: const InputDecoration(
              hintText: 'Write an announcement...',
              hintStyle: TextStyle(color: textareaTextColor),
              filled: false,
              border: InputBorder.none,
              // The app's ambient ThemeData (AppTheme.darkTheme) defines
              // filled:true with a dark fillColor and a bright green
              // focusedBorder — without repeating InputBorder.none for
              // these two states, Flutter falls back to those theme
              // defaults, painting a dark box with a green focus ring
              // behind this light textarea.
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.all(11),
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

}
