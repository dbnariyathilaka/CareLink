import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';
import 'admin_case_detail_screen.dart';

class AdminOpenIncidentsScreen extends StatefulWidget {
  const AdminOpenIncidentsScreen({super.key});

  @override
  State<AdminOpenIncidentsScreen> createState() => _AdminOpenIncidentsScreenState();
}

class _AdminOpenIncidentsScreenState extends State<AdminOpenIncidentsScreen> {
  // ── Color tokens ─────────────────────────────────────────────────────────
  static const Color bgColor        = Color(0xFFF5EEDE);
  static const Color titleColor     = Color(0xFF544730);

  static const Color cardBg         = Color(0xFFE2C6C6);
  static const Color cardBorder     = Color(0xFFE65555);

  static const Color incidentIdColor     = Color(0xFFD83131);
  static const Color incidentTitleColor  = Color(0xFF352D21);
  static const Color incidentMetaColor   = Color(0xFFA27070);
  static const Color incidentDescColor   = Color(0xFF604040);

  static const Color statusBadgeBg   = Color(0x29EF4444);
  static const Color statusBadgeText = Color(0xFFEF4444);

  static const Color tagOrangeBg    = Color(0x24F59E0B);
  static const Color tagOrangeText  = Color(0xFFB26915);
  static const Color tagRedBg       = Color(0x24EF4444);
  static const Color tagRedText     = Color(0xFFEF4444);
  static const Color tagBlueBg      = Color(0x24818CF8);
  static const Color tagBlueText    = Color(0xFF6366F1);

  static const Color emptyIconColor    = Color(0xFFA27070);


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
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: kMockIncidents.isEmpty
                  ? _buildEmptyState()
                  : _buildIncidentList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
                child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
              ),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Open Incidents',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ),
            // Badge showing count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBadgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${kMockIncidents.length} open',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusBadgeText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Incident list ─────────────────────────────────────────────────────────

  Widget _buildIncidentList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: kMockIncidents.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildIncidentCard(kMockIncidents[index]);
      },
    );
  }

  Widget _buildIncidentCard(IncidentData incident) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminCaseDetailScreen(incident: incident),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: Case ID + Status badge ───────────────────────
              Row(
                children: [
                  Text(
                    'Case #${incident.id}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: incidentIdColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBadgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      incident.status,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: statusBadgeText,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Arrow indicator
                  const Icon(Icons.chevron_right_rounded, size: 20, color: incidentIdColor),
                ],
              ),
              const SizedBox(height: 6),

              // ── Title ────────────────────────────────────────────────
              Text(
                incident.title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: incidentTitleColor,
                ),
              ),
              const SizedBox(height: 3),

              // ── Filed by · Date ───────────────────────────────────────
              Text(
                'Filed by ${incident.filedBy} · ${incident.date}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: incidentMetaColor,
                ),
              ),
              const SizedBox(height: 8),

              // ── Description snippet ───────────────────────────────────
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: incidentDescColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              // ── Tags ──────────────────────────────────────────────────
              Wrap(
                spacing: 7,
                runSpacing: 6,
                children: incident.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gpp_good_rounded, size: 56, color: emptyIconColor.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            const Text(
              'No open incidents',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All reported incidents have been resolved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: emptyIconColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
