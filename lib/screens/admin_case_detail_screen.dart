import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

// ── Data Model ─────────────────────────────────────────────────────────────

class EvidenceItem {
  final String label;
  final IconData icon;
  const EvidenceItem({required this.label, required this.icon});
}

class IncidentData {
  final String id;          // e.g. "INC-2214"
  final String status;      // e.g. "OPEN"
  final String title;
  final String filedBy;
  final String date;
  final String description;
  final List<String> tags;
  final String complainantName;
  final String complainantRole;
  final String complainantId;
  final String respondentName;
  final String respondentRole;
  final String respondentId;
  final List<EvidenceItem> evidence;

  const IncidentData({
    required this.id,
    required this.status,
    required this.title,
    required this.filedBy,
    required this.date,
    required this.description,
    required this.tags,
    required this.complainantName,
    required this.complainantRole,
    required this.complainantId,
    required this.respondentName,
    required this.respondentRole,
    required this.respondentId,
    required this.evidence,
  });
}

// ── Static mock incidents (no Firestore collection exists for incidents) ────

final List<IncidentData> kMockIncidents = [
  const IncidentData(
    id: 'INC-2214',
    status: 'OPEN',
    title: 'Care quality complaint',
    filedBy: 'Nimali Perera (family)',
    date: '20 Aug 2026',
    description:
        'Caregiver arrived 50 minutes late twice this week and did not record the evening medication in the care journal.',
    tags: ['Tardiness', 'Care quality'],
    complainantName: 'Nimali Perera',
    complainantRole: 'Family',
    complainantId: 'PT-10428',
    respondentName: 'Ruwan J.',
    respondentRole: 'Caregiver',
    respondentId: 'CG-3391',
    evidence: [
      EvidenceItem(label: 'Chat transcript · 18–20 Aug', icon: Icons.chat_bubble_outline_rounded),
      EvidenceItem(label: 'Care journal · missing entries', icon: Icons.edit_note_rounded),
      EvidenceItem(label: 'Check-in log · 2 late arrivals', icon: Icons.access_time_rounded),
    ],
  ),
  const IncidentData(
    id: 'INC-2198',
    status: 'OPEN',
    title: 'Medication error reported',
    filedBy: 'Sanath Perera (patient)',
    date: '18 Aug 2026',
    description:
        'Patient reports that wrong dosage was administered on the evening of 17 Aug. Caregiver denies the incident.',
    tags: ['Medication', 'Safety'],
    complainantName: 'Sanath Perera',
    complainantRole: 'Patient',
    complainantId: 'PT-10392',
    respondentName: 'Asha F.',
    respondentRole: 'Caregiver',
    respondentId: 'CG-3214',
    evidence: [
      EvidenceItem(label: 'Care journal · 17 Aug entry', icon: Icons.edit_note_rounded),
      EvidenceItem(label: 'Medication log · evening shift', icon: Icons.medication_outlined),
    ],
  ),
  const IncidentData(
    id: 'INC-2187',
    status: 'OPEN',
    title: 'Unauthorised absence',
    filedBy: 'Priya Mendis (family)',
    date: '15 Aug 2026',
    description:
        'Caregiver did not show up for the morning session on 14 Aug and was unreachable for 4 hours.',
    tags: ['Absence', 'Tardiness'],
    complainantName: 'Priya Mendis',
    complainantRole: 'Family',
    complainantId: 'PT-10367',
    respondentName: 'Kamal S.',
    respondentRole: 'Caregiver',
    respondentId: 'CG-3178',
    evidence: [
      EvidenceItem(label: 'Check-in log · 14 Aug absence', icon: Icons.access_time_rounded),
      EvidenceItem(label: 'Chat transcript · 14 Aug', icon: Icons.chat_bubble_outline_rounded),
    ],
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────

class AdminCaseDetailScreen extends StatefulWidget {
  final IncidentData incident;

  const AdminCaseDetailScreen({super.key, required this.incident});

  @override
  State<AdminCaseDetailScreen> createState() => _AdminCaseDetailScreenState();
}

class _AdminCaseDetailScreenState extends State<AdminCaseDetailScreen> {
  // ── Color tokens from Figma node 641:598 ────────────────────────────────
  static const Color bgColor        = Color(0xFFF5EEDE);
  static const Color headerText     = Color(0xFF544730);
  static const Color statusBadgeBg  = Color(0x29EF4444); // rgba(239,68,68,0.16)
  static const Color statusBadgeText = Color(0xFFEF4444);

  // Dark incident summary card
  static const Color summaryCardBg  = Color(0xFF5D5445);
  static const Color summaryTitle   = Color(0xE0352D21); // rgba(53,45,33,0.88)
  static const Color summaryMeta    = Color(0xFF94A3B8);
  static const Color summaryBody    = Color(0xFFCBD5E1);

  // Tag chips
  static const Color tagOrangeBg    = Color(0x24F59E0B); // rgba(245,158,11,0.14)
  static const Color tagOrangeText  = Color(0xFFB26915);
  static const Color tagRedBg       = Color(0x24EF4444);
  static const Color tagRedText     = Color(0xFFEF4444);
  static const Color tagBlueBg      = Color(0x24818CF8);
  static const Color tagBlueText    = Color(0xFF6366F1);

  // Section labels
  static const Color sectionLabel   = Colors.black;

  // Party cards
  static const Color partyCardBg    = Color(0xFFFFF4E2);
  static const Color partyCardBorder = Color(0xFF865E1B);
  static const Color partyLabel     = Color(0xFF44331C);
  static const Color partyName      = Color(0xE0352D21);
  static const Color partyMeta      = Color(0xFF0F172A);

  // Evidence items
  static const Color evidenceBg     = Color(0xFFC7AD8B);
  static const Color evidenceBorder = Color(0xFF44331C);
  static const Color evidenceIcon   = Color(0xFF953509);
  static const Color evidenceText   = Color(0xFF953509);
  static const Color evidenceView   = Color(0xFF754600);

  // Resolution items
  static const Color resolutionBg   = Color(0xFFC4BBAC);
  static const Color resolutionBorder = Color(0xFFA97344);
  static const Color resolutionSelected = Color(0xFF604B30);
  static const Color resolutionUnselected = Color(0xFFA97344);
  static const Color radioFilled    = Color(0xFF70573C);
  static const Color radioEmpty     = Color(0xFF664835);

  // Buttons
  static const Color resolveBtnBg   = Color(0xFF412800);
  static const Color escalateBorder = Color(0xFF412800);

  int _selectedResolution = 0; // 0 = first option selected

  final List<String> _resolutionOptions = [
    'Issue warning to caregiver',
    'Partial refund to patient',
    'Suspend caregiver account',
  ];

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  Color _tagBgFor(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('tardiness') || t.contains('absence')) return tagOrangeBg;
    if (t.contains('care') || t.contains('safety') || t.contains('medication')) return tagRedBg;
    return tagBlueBg;
  }

  Color _tagTextFor(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('tardiness') || t.contains('absence')) return tagOrangeText;
    if (t.contains('care') || t.contains('safety') || t.contains('medication')) return tagRedText;
    return tagBlueText;
  }

  @override
  Widget build(BuildContext context) {
    final inc = widget.incident;
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(inc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Summary card ───────────────────────────────────────
                    _buildSummaryCard(inc),
                    const SizedBox(height: 16),

                    // ── Parties ────────────────────────────────────────────
                    _buildSectionLabel('PARTIES'),
                    const SizedBox(height: 9),
                    _buildPartiesRow(inc),
                    const SizedBox(height: 16),

                    // ── Evidence ───────────────────────────────────────────
                    _buildSectionLabel('EVIDENCE'),
                    const SizedBox(height: 9),
                    _buildEvidenceList(inc.evidence),
                    const SizedBox(height: 16),

                    // ── Resolution ─────────────────────────────────────────
                    _buildSectionLabel('RESOLUTION'),
                    const SizedBox(height: 9),
                    _buildResolutionList(),
                    const SizedBox(height: 20),

                    // ── Action buttons ─────────────────────────────────────
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(IncidentData inc) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 12, 16, 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_back_rounded, color: headerText, size: 24),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Case #${inc.id}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: headerText,
                ),
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: statusBadgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                inc.status,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: statusBadgeText,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────

  Widget _buildSummaryCard(IncidentData inc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: summaryCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            inc.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: summaryTitle,
            ),
          ),
          const SizedBox(height: 4),
          // Meta
          Text(
            'Filed by ${inc.filedBy} · ${inc.date}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: summaryMeta,
            ),
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            inc.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: summaryBody,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 10),
          // Tags
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: inc.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _tagBgFor(tag),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _tagTextFor(tag),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: sectionLabel,
        letterSpacing: 0.6,
      ),
    );
  }

  // ── Parties ───────────────────────────────────────────────────────────────

  Widget _buildPartiesRow(IncidentData inc) {
    return Row(
      children: [
        Expanded(child: _buildPartyCard('Complainant', inc.complainantName, '${inc.complainantRole} · ${inc.complainantId}')),
        const SizedBox(width: 9),
        Expanded(child: _buildPartyCard('Respondent', inc.respondentName, '${inc.respondentRole} · ${inc.respondentId}')),
      ],
    );
  }

  Widget _buildPartyCard(String label, String name, String meta) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: partyCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: partyCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: partyLabel)),
          const SizedBox(height: 3),
          Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: partyName)),
          Text(meta, style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: partyMeta)),
        ],
      ),
    );
  }

  // ── Evidence list ─────────────────────────────────────────────────────────

  Widget _buildEvidenceList(List<EvidenceItem> items) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: evidenceBg,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: evidenceBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: evidenceIcon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: evidenceText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evidence viewing isn\'t available yet.'), duration: Duration(seconds: 2)),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: evidenceView,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Resolution list ───────────────────────────────────────────────────────

  Widget _buildResolutionList() {
    return Column(
      children: List.generate(_resolutionOptions.length, (i) {
        final isSelected = _selectedResolution == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedResolution = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color: resolutionBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: resolutionBorder, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _resolutionOptions[i],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? resolutionSelected : resolutionUnselected,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected ? radioFilled : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: isSelected ? radioFilled : radioEmpty,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Center(
                            child: Icon(Icons.check, size: 11, color: Colors.white),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: resolveBtnBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Case resolution isn\'t backed by Firestore yet — no action was taken.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Center(
                  child: Text(
                    'Resolve case',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Escalation isn\'t backed by Firestore yet — no action was taken.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: escalateBorder, width: 1),
                ),
                child: const Center(
                  child: Text(
                    'Escalate',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: escalateBorder,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
