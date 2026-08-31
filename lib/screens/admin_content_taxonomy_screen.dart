import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import '../data/care_type_skill_map.dart';
import '../services/caregiver_service.dart';
import 'admin_bookings_screen.dart';
import 'admin_finance_screen.dart';

class ShiftType {
  final String id;
  final IconData icon;
  final String timeRange;
  final String label;
  ShiftType({required this.id, required this.icon, required this.timeRange, required this.label});
}

class TagUsageStat {
  final String label;
  final int count;
  final bool isLow;
  const TagUsageStat({required this.label, required this.count, this.isLow = false});
}

class AppContentItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const AppContentItem({required this.icon, required this.title, required this.subtitle});
}

class AdminContentTaxonomyScreen extends StatefulWidget {
  const AdminContentTaxonomyScreen({super.key});

  @override
  State<AdminContentTaxonomyScreen> createState() => _AdminContentTaxonomyScreenState();
}

class _AdminContentTaxonomyScreenState extends State<AdminContentTaxonomyScreen> {
  // ── Color Tokens matching Figma node 649:1031 ───────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);
  static const Color subheadingColor = Color(0xFF544632);
  static const Color sectionLabelColor = Colors.black;

  static const Color chipBorder = Color(0xFF44331C);
  static const Color chipRemove = Color(0xFFEF4444);
  static const Color addNewBg = Color(0xFFB9A084);
  static const Color addNewBorder = Color(0xFF553B1D);
  static const Color addNewText = Color(0xFF5E4323);

  static const Color shiftSelectedBg = Color(0xFFDAA057);
  static const Color shiftUnselectedBg = Color(0xFFE1D5C6);
  static const Color shiftUnselectedText = Color(0xFF0F172A);

  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF4C3A1B);
  static const Color rowDivider = Color(0x4D334155);

  static const Color tagUsageLabel = Color(0xFF745A45);
  static const Color tagUsageCount = Color(0xFF744303);
  static const Color tagUsageCountHighlight = Color(0xFFB26915);
  static const Color tagUsageSuffix = Color(0xFF7E7C7B);

  static const Color appContentTitle = Color(0xFF745A45);
  static const Color appContentSub = Color(0xFF7E7C7B);
  static const Color appContentIcon = Color(0xFFB26915);

  static const Color publishBtnBg = Color(0xFF44331C);

  static const Color bottomNavBg = Color(0xFF3A3328);
  static const Color navGold = Color(0xFFFBBC05);

  // Sourced from the app's real canonical care-type list (careTypeSkillMap in
  // ../data/care_type_skill_map.dart) rather than a separate hardcoded list,
  // so this stays in sync with the taxonomy MatchingService actually uses.
  final List<String> _careTypes = List<String>.from(careTypeSkillMap.keys);

  final List<ShiftType> _shifts = [
    ShiftType(id: 'day', icon: Icons.wb_sunny_rounded, timeRange: '8:00 AM – 5:00 PM', label: 'Day shift'),
    ShiftType(id: 'evening', icon: Icons.wb_twilight, timeRange: '2:00 PM – 10:00 PM', label: 'Evening shift'),
    ShiftType(id: 'overnight', icon: Icons.bedtime_rounded, timeRange: '10:00 PM – 6:00 AM', label: 'Overnight shift'),
  ];
  String _selectedShiftId = 'day';

  final List<String> _standoutTags = [
    'Punctual', 'Very caring', 'Good communicator', 'Patient and gentle', 'Handle medication well',
  ];

  static const List<AppContentItem> _appContent = [
    AppContentItem(icon: Icons.help_outline_rounded, title: 'Help centre & FAQs', subtitle: 'Static reference content — not backed by a live CMS'),
    AppContentItem(icon: Icons.description_outlined, title: 'Terms of service', subtitle: 'Static reference content — not backed by a live CMS'),
    AppContentItem(icon: Icons.lock_outline_rounded, title: 'Privacy policy', subtitle: 'Static reference content — not backed by a live CMS'),
    AppContentItem(icon: Icons.flag_outlined, title: 'Onboarding guide', subtitle: 'Static reference content — not backed by a live CMS'),
  ];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  void _removeCareType(String tag) => setState(() => _careTypes.remove(tag));
  void _removeStandoutTag(String tag) => setState(() => _standoutTags.remove(tag));
  void _removeShift(String id) => setState(() => _shifts.removeWhere((s) => s.id == id));
  void _selectShift(String id) => setState(() => _selectedShiftId = id);

  void _addNewTag(String sectionTitle, void Function(String value) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C251D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add to $sectionTitle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter a new tag...',
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
            style: ElevatedButton.styleFrom(backgroundColor: publishBtnBg),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) onAdd(value);
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openAppContentItem(AppContentItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening "${item.title}"...'), duration: const Duration(seconds: 2)),
    );
  }

  void _publishChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not saved — this screen isn\'t connected to persistence yet.'),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubheading('What kind of care is needed?'),
                    const SizedBox(height: 12),
                    _buildTagGrid(
                      items: _careTypes,
                      onRemove: _removeCareType,
                      sectionTitle: 'care types',
                      onAddNew: (v) => setState(() => _careTypes.add(v)),
                    ),
                    const SizedBox(height: 20),
                    _buildSubheading('Choose a shift'),
                    const SizedBox(height: 12),
                    ..._shifts.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildShiftCard(s),
                        )),
                    const SizedBox(height: 12),
                    _buildSubheading('What stood out?'),
                    const SizedBox(height: 12),
                    _buildTagGrid(
                      items: _standoutTags,
                      onRemove: _removeStandoutTag,
                      sectionTitle: 'traits',
                      onAddNew: (v) => setState(() => _standoutTags.add(v)),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionLabel('TAG USAGE'),
                    const SizedBox(height: 9),
                    _buildTagUsageSection(),
                    const SizedBox(height: 20),
                    _buildSectionLabel('APP CONTENT'),
                    const SizedBox(height: 9),
                    _buildAppContentCard(),
                    const SizedBox(height: 20),
                    _buildPublishButton(),
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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
            ),
          ),
          const Expanded(
            child: Text(
              'Content & taxonomy',
              style: TextStyle(fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubheading(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Open Sans', fontSize: 15, fontWeight: FontWeight.w600, color: subheadingColor, letterSpacing: -0.4),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: sectionLabelColor, letterSpacing: 0.6),
    );
  }

  // ── Removable tag grid (2 columns, "+ New" fills the trailing slot) ────
  Widget _buildTagGrid({
    required List<String> items,
    required void Function(String) onRemove,
    required String sectionTitle,
    required void Function(String) onAddNew,
  }) {
    final rows = <List<Widget>>[];
    for (int i = 0; i < items.length; i += 2) {
      final left = _buildRemovableChip(items[i], () => onRemove(items[i]));
      final right = (i + 1 < items.length)
          ? _buildRemovableChip(items[i + 1], () => onRemove(items[i + 1]))
          : (i + 2 == items.length + 1 ? _buildAddNewChip(sectionTitle, onAddNew) : null);
      rows.add([left, if (right != null) right]);
    }
    if (items.length.isEven) {
      rows.add([_buildAddNewChip(sectionTitle, onAddNew)]);
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: row[0]),
              const SizedBox(width: 8),
              Expanded(child: row.length > 1 ? row[1] : const SizedBox.shrink()),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRemovableChip(String label, VoidCallback onRemove) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: chipBorder, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Open Sans', fontSize: 13, fontWeight: FontWeight.w600, color: chipBorder),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.cancel_rounded, size: 15, color: chipRemove),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewChip(String sectionTitle, void Function(String) onAdd) {
    return GestureDetector(
      onTap: () => _addNewTag(sectionTitle, onAdd),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: addNewBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: addNewBorder, width: 1, style: BorderStyle.solid),
        ),
        child: const Text(
          '+ New',
          style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w600, color: addNewText),
        ),
      ),
    );
  }

  // ── Shift card ──────────────────────────────────────────────────────────
  Widget _buildShiftCard(ShiftType s) {
    final isSelected = s.id == _selectedShiftId;
    return GestureDetector(
      onTap: () => _selectShift(s.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? shiftSelectedBg : shiftUnselectedBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(s.icon, size: 22, color: isSelected ? Colors.black : shiftUnselectedText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.timeRange,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w600,
                      color: isSelected ? Colors.black : shiftUnselectedText,
                    ),
                  ),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w600,
                      color: isSelected ? Colors.black : shiftUnselectedText,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _removeShift(s.id),
              behavior: HitTestBehavior.opaque,
              child: const Icon(Icons.cancel_rounded, size: 16, color: chipRemove),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tag usage: real counts from live caregiver profiles ─────────────────
  //
  // caregiverProfiles.careTypes actually stores employment type ('Part-time'
  // / 'Full-time'), not a specialisation tag — so it can't tell us how many
  // caregivers cover "Elder care" etc. The real specialisation data lives in
  // caregiverProfiles.skills (see MatchingService's skill-match criterion),
  // so usage per care type is computed by intersecting each caregiver's
  // skills with the skill set careTypeSkillMap maps that care type to.
  Widget _buildTagUsageSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CaregiverService.streamAllCaregivers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final caregivers = snapshot.data!;
        final stats = _careTypes.map((careType) {
          final requiredSkills = careTypeSkillMap[careType] ?? const <String>{};
          final count = caregivers.where((c) {
            final skills = (c['skills'] as List?)?.cast<String>().toSet() ?? const <String>{};
            return skills.intersection(requiredSkills).isNotEmpty;
          }).length;
          return TagUsageStat(label: careType, count: count, isLow: count > 0 && count < 5);
        }).toList()
          ..sort((a, b) => b.count.compareTo(a.count));
        return _buildTagUsageCard(stats);
      },
    );
  }

  Widget _buildTagUsageCard(List<TagUsageStat> tagUsage) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        children: tagUsage.asMap().entries.map((e) {
          final isLast = e.key == tagUsage.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: rowDivider, width: 1))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.value.label,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: tagUsageLabel),
                  ),
                ),
                Text(
                  '${e.value.count}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: e.value.isLow ? tagUsageCountHighlight : tagUsageCount,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'caregivers',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: tagUsageSuffix),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── App content card ────────────────────────────────────────────────────
  Widget _buildAppContentCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        children: _appContent.asMap().entries.map((e) {
          final isLast = e.key == _appContent.length - 1;
          return GestureDetector(
            onTap: () => _openAppContentItem(e.value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: rowDivider, width: 1))),
              child: Row(
                children: [
                  Icon(e.value.icon, size: 19, color: appContentIcon),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.value.title,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w600, color: appContentTitle),
                        ),
                        Text(
                          e.value.subtitle,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: appContentSub),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 19, color: appContentTitle),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPublishButton() {
    return Material(
      color: publishBtnBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _publishChanges,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Center(
            child: Text('Publish changes', style: TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC))),
          ),
        ),
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
      {'label': 'Content', 'icon': Icons.auto_awesome_outlined},
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
          final isSelected = index == 4; // More tab is active (Content lives under More)
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
